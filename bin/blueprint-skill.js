#!/usr/bin/env node
'use strict';
/*
 * blueprint-skill — installs the `blueprint` agent skill into the skill folders
 * your coding agents read. Zero dependencies. Node >= 18.
 *
 *   npx blueprint-skill                 interactive: pick agents, confirm, install
 *   npx blueprint-skill --all --yes     every detected agent, no prompts
 *   npx blueprint-skill --client cursor --client codex
 *   npx blueprint-skill --project .     install into a repository instead of ~
 *   npx blueprint-skill --dry-run       print the plan only
 *   npx blueprint-skill uninstall       remove exactly what a previous run wrote
 *   npx blueprint-skill doctor          show what is installed where, and whether it is current
 *   npx blueprint-skill@latest update   reinstall the latest version into every folder in the manifest
 *   npx blueprint-skill init [dir]      write a starter docs/plans/CONSTITUTION.md into a repository
 *
 * Every run checks npm for a newer version (2 s timeout, silent when offline).
 * Turn it off with BLUEPRINT_SKILL_NO_UPDATE_CHECK=1.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const readline = require('readline');
const http = require('http');
const https = require('https');

const HOME = os.homedir();
const SKILL_NAME = 'blueprint';
const SRC = path.join(__dirname, '..', SKILL_NAME);
const STATE_DIR = path.join(HOME, '.blueprint-skill');
const MANIFEST = path.join(STATE_DIR, 'manifest');
const PKG = require(path.join(__dirname, '..', 'package.json'));
const VERSION = PKG.version;
const VERSION_FILE = '.blueprint-version'; // written into every installed copy
const REGISTRY = process.env.BLUEPRINT_SKILL_REGISTRY || 'https://registry.npmjs.org';
const UPDATE_CMD = 'npx blueprint-skill@latest update';

// Each agent: where it reads user-level skills, and which single folder we
// write by default. Agents that read the shared ~/.agents/skills get only that
// folder unless --native is passed, so Cursor/Copilot don't list the skill twice.
const AGENTS = [
  { id: 'claude',          label: 'Claude Code',            detect: ['.claude'],                 target: ['.claude', 'skills'],                   shared: false },
  { id: 'codex',           label: 'OpenAI Codex',           detect: ['.codex'],                  target: ['.codex', 'skills'],                    shared: true },
  { id: 'cursor',          label: 'Cursor',                 detect: ['.cursor'],                 target: ['.cursor', 'skills'],                   shared: true },
  // Antigravity loads global skills from {appDataDir}/skills = ~/.gemini/antigravity/skills;
  // it does not read ~/.agents/skills for global skills, so it always gets its own folder.
  { id: 'antigravity',     label: 'Google Antigravity',     detect: ['.gemini', 'antigravity'],  target: ['.gemini', 'antigravity', 'skills'],    shared: false },
  { id: 'antigravity-cli', label: 'Antigravity CLI',        detect: ['.gemini', 'antigravity-cli'], target: ['.gemini', 'antigravity-cli', 'skills'], shared: false },
  { id: 'copilot',         label: 'VS Code / GitHub Copilot', detect: ['.copilot'],              target: ['.copilot', 'skills'],                  shared: true },
];
const SHARED_DIR = path.join(HOME, '.agents', 'skills');

// ---------- args ----------
const argv = process.argv.slice(2);
const MODES = ['auto', 'simple', 'advanced', 'ask'];
const flags = { client: [], all: false, yes: false, dryRun: false, native: false, project: null, help: false, mode: 'auto', dir: null };
let command = 'install';
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === 'install' || a === 'uninstall' || a === 'doctor' || a === 'update' || a === 'init') command = a;
  else if (command === 'init' && !a.startsWith('-') && !flags.dir) flags.dir = path.resolve(a);
  else if (a === '--mode') flags.mode = argv[++i];
  else if (a.startsWith('--mode=')) flags.mode = a.split('=')[1];
  else if (a === '--client' || a === '-c') flags.client.push(argv[++i]);
  else if (a.startsWith('--client=')) flags.client.push(a.split('=')[1]);
  else if (a === '--all' || a === '-a') flags.all = true;
  else if (a === '--yes' || a === '-y') flags.yes = true;
  else if (a === '--dry-run' || a === '-n') flags.dryRun = true;
  else if (a === '--native') flags.native = true;
  else if (a === '--project' || a === '-p') flags.project = path.resolve(argv[++i] || '.');
  else if (a.startsWith('--project=')) flags.project = path.resolve(a.split('=')[1]);
  else if (a === '--help' || a === '-h') flags.help = true;
  else if (a === '--version' || a === '-v') flags.version = true;
  else { console.error(`Unknown argument: ${a}`); flags.help = true; }
}

const c = {
  dim: (s) => `\x1b[2m${s}\x1b[0m`, bold: (s) => `\x1b[1m${s}\x1b[0m`,
  green: (s) => `\x1b[32m${s}\x1b[0m`, yellow: (s) => `\x1b[33m${s}\x1b[0m`, red: (s) => `\x1b[31m${s}\x1b[0m`, cyan: (s) => `\x1b[36m${s}\x1b[0m`,
};
const exists = (p) => { try { fs.lstatSync(p); return true; } catch { return false; } };
const isSymlink = (p) => { try { return fs.lstatSync(p).isSymbolicLink(); } catch { return false; } };
const detected = (agent) => exists(path.join(HOME, ...agent.detect));

function help() {
  console.log(`
${c.bold('blueprint-skill')} ${VERSION} — install the "blueprint" skill for your coding agents

Usage:
  npx blueprint-skill [install] [options]   interactive unless --client/--all is given
  npx blueprint-skill uninstall [--dry-run] remove what a previous run wrote
  npx blueprint-skill doctor                show detected agents, installed copies and their versions
  npx blueprint-skill@latest update [-n] [-y]
                                            reinstall the latest version into every folder a previous run wrote
  npx blueprint-skill init [dir] [--mode <m>] [-n]
                                            write a starter docs/plans/CONSTITUTION.md (never overwrites)

Options:
  -c, --client <id>   one of: ${AGENTS.map((a) => a.id).join(', ')} (repeatable)
  -a, --all           every agent detected on this machine
  -p, --project <dir> install into a repository (.agents/skills, .claude/skills, .github/skills)
      --native        also write each agent's native folder, not just the shared ~/.agents/skills
      --mode <m>      init only: default mode, one of ${MODES.join(', ')} (default auto)
  -n, --dry-run       print the plan and exit
  -y, --yes           skip the confirmation prompt
  -v, --version       print the installer version
  -h, --help

Every run checks npm for a newer version and prints one line if there is one.
Set BLUEPRINT_SKILL_NO_UPDATE_CHECK=1 to turn that off.
`);
}

// ---------- prompts ----------
function ask(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((res) => rl.question(question, (ans) => { rl.close(); res(ans.trim()); }));
}

async function chooseAgents() {
  console.log(`\n${c.bold('Which coding agents should get the blueprint skill?')}\n`);
  AGENTS.forEach((a, i) => {
    const mark = detected(a) ? c.green('detected') : c.dim('not found');
    console.log(`  ${c.cyan(String(i + 1))}. ${a.label.padEnd(26)} ${mark}`);
  });
  const det = AGENTS.filter(detected).map((a) => a.id);
  console.log(`\n  ${c.cyan('a')}. All detected ${c.dim(det.length ? `(${det.join(', ')})` : '(none detected)')}  ${c.dim('← recommended')}`);
  console.log(`  ${c.cyan('e')}. Everything, detected or not`);
  console.log(`  ${c.cyan('q')}. Quit\n`);
  const ans = (await ask('Pick numbers separated by commas, or a / e / q: ')).toLowerCase();
  if (ans === 'q' || ans === '') return null;
  if (ans === 'a') return AGENTS.filter(detected);
  if (ans === 'e') return AGENTS;
  const picks = ans.split(/[,\s]+/).map((n) => AGENTS[Number(n) - 1]).filter(Boolean);
  return picks.length ? picks : null;
}

// ---------- planning ----------
function targetsFor(agents, native) {
  const set = new Set();
  for (const a of agents) {
    if (a.shared && !native) set.add(SHARED_DIR);
    else set.add(path.join(HOME, ...a.target));
    if (a.shared && native) set.add(SHARED_DIR);
  }
  return [...set].map((dir) => path.join(dir, SKILL_NAME));
}
function projectTargets(root) {
  return ['.agents', '.claude', '.github'].map((d) => path.join(root, d, 'skills', SKILL_NAME));
}

function printPlan(targets) {
  console.log(`\n${c.bold('Plan')} ${c.dim(`(source: ${SRC})`)}`);
  for (const t of targets) {
    let note = c.green('new');
    if (isSymlink(t)) note = c.red('SYMLINK — will be skipped');
    else if (exists(t)) note = c.yellow('exists — will be backed up and replaced');
    console.log(`  ${t}  ${note}`);
  }
  console.log(`  ${c.dim(`manifest: ${MANIFEST}`)}\n`);
}

// ---------- apply ----------
function copyDir(src, dst) {
  fs.mkdirSync(dst, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name), d = path.join(dst, entry.name);
    if (entry.isDirectory()) copyDir(s, d); else fs.copyFileSync(s, d);
  }
}
function readManifest() {
  if (!exists(MANIFEST)) return [];
  return fs.readFileSync(MANIFEST, 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);
}
function writeManifest(lines) {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(MANIFEST, [...new Set(lines)].join('\n') + (lines.length ? '\n' : ''));
}
function verify(target) {
  const skill = path.join(target, 'SKILL.md');
  if (!exists(skill)) return 'SKILL.md missing';
  const head = fs.readFileSync(skill, 'utf8').split('\n').slice(0, 5).join('\n');
  return /^name:\s*blueprint\s*$/m.test(head) ? null : 'name does not match folder';
}

// ---------- versions ----------
function installedVersion(target) {
  try { return fs.readFileSync(path.join(target, VERSION_FILE), 'utf8').trim() || null; } catch { return null; }
}
// Compare dotted numeric versions; prerelease tags are ignored. Returns -1, 0 or 1.
function cmpVersion(a, b) {
  const pa = String(a).split('-')[0].split('.').map(Number), pb = String(b).split('-')[0].split('.').map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const x = pa[i] || 0, y = pb[i] || 0;
    if (x !== y) return x < y ? -1 : 1;
  }
  return 0;
}
// Latest published version from the npm registry, or null when offline, slow or disabled.
function fetchLatest(timeoutMs = 2000) {
  if (process.env.BLUEPRINT_SKILL_NO_UPDATE_CHECK) return Promise.resolve(null);
  return new Promise((resolve) => {
    let done = false;
    const finish = (v) => { if (!done) { done = true; resolve(v); } };
    try {
      const url = `${REGISTRY.replace(/\/$/, '')}/blueprint-skill/latest`;
      const lib = url.startsWith('http://') ? http : https;
      const req = lib.get(url, { headers: { accept: 'application/json' }, timeout: timeoutMs }, (res) => {
        if (res.statusCode !== 200) { res.resume(); return finish(null); }
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (d) => { body += d; if (body.length > 1e6) req.destroy(); });
        res.on('end', () => { try { finish(JSON.parse(body).version || null); } catch { finish(null); } });
      });
      req.on('timeout', () => { req.destroy(); finish(null); });
      req.on('error', () => finish(null));
    } catch { finish(null); }
  });
}
function newerNotice(latest) {
  if (!latest || cmpVersion(VERSION, latest) >= 0) return;
  console.log(`\n${c.yellow('update')} blueprint-skill ${latest} is available (this installer is ${VERSION}). Run: ${c.bold(UPDATE_CMD)}`);
}

function install(targets) {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const written = [];
  for (const t of targets) {
    if (isSymlink(t)) {
      console.log(`${c.red('skip')}  ${t} is a symlink. Remove it first (rm "${t}") if you want blueprint installed there.`);
      continue;
    }
    if (exists(t)) {
      const backup = path.join(STATE_DIR, 'backups', stamp, t.replace(/[\/\\:]/g, '_'));
      fs.mkdirSync(path.dirname(backup), { recursive: true });
      fs.renameSync(t, backup);
      console.log(`${c.yellow('backup')} ${t} → ${backup}`);
    }
    copyDir(SRC, t);
    fs.writeFileSync(path.join(t, VERSION_FILE), VERSION + '\n');
    const problem = verify(t);
    if (problem) { console.log(`${c.red('FAIL')}  ${t}: ${problem}`); continue; }
    console.log(`${c.green('ok')}    ${t}`);
    written.push(t);
  }
  writeManifest([...readManifest(), ...written]);
  return written;
}

async function runInstall() {
  if (!exists(path.join(SRC, 'SKILL.md'))) { console.error(c.red(`Skill source not found at ${SRC}`)); process.exit(1); }
  let targets;
  if (flags.project) {
    targets = projectTargets(flags.project);
  } else if (flags.all) {
    targets = targetsFor(AGENTS.filter(detected), flags.native);
  } else if (flags.client.length) {
    const agents = flags.client.map((id) => AGENTS.find((a) => a.id === id) || (console.error(c.red(`Unknown client: ${id}`)), process.exit(1)));
    targets = targetsFor(agents, flags.native);
  } else if (process.stdin.isTTY) {
    const agents = await chooseAgents();
    if (!agents || !agents.length) { console.log('Nothing selected.'); return; }
    targets = targetsFor(agents, flags.native);
  } else {
    console.error('No TTY and no --client/--all/--project given. Nothing to do.');
    process.exit(2);
  }
  printPlan(targets);
  if (flags.dryRun) { console.log(c.dim('dry run — nothing written')); return; }
  if (!flags.yes) {
    const ans = (await ask('Proceed? [y/N] ')).toLowerCase();
    if (ans !== 'y' && ans !== 'yes') { console.log('Aborted.'); return; }
  }
  const written = install(targets);
  if (written.length) {
    console.log(`\n${c.green(`Installed blueprint ${VERSION}.`)} Restart your agent, then type ${c.bold('/blueprint')} (Codex: ${c.bold('$blueprint')}) and describe what you want to build.`);
  }
}

async function runUninstall() {
  const paths = readManifest();
  if (!paths.length) { console.log('Manifest is empty; nothing was installed by blueprint-skill.'); return; }
  console.log(`\n${c.bold('Will remove')}`);
  paths.forEach((p) => console.log(`  ${p} ${exists(p) ? '' : c.dim('(already gone)')}`));
  if (flags.dryRun) { console.log(c.dim('\ndry run — nothing removed')); return; }
  if (!flags.yes) {
    const ans = (await ask('\nProceed? [y/N] ')).toLowerCase();
    if (ans !== 'y' && ans !== 'yes') { console.log('Aborted.'); return; }
  }
  for (const p of paths) if (exists(p) && !isSymlink(p)) fs.rmSync(p, { recursive: true, force: true });
  fs.rmSync(MANIFEST, { force: true });
  console.log(c.green('Removed.') + c.dim(` Backups, if any, stay in ${path.join(STATE_DIR, 'backups')}.`));
}

async function runUpdate(latest) {
  if (!exists(path.join(SRC, 'SKILL.md'))) { console.error(c.red(`Skill source not found at ${SRC}`)); process.exit(1); }
  const paths = readManifest();
  if (!paths.length) { console.log(`Nothing was installed by blueprint-skill yet. Run ${c.bold('npx blueprint-skill')} to install.`); return; }
  if (latest && cmpVersion(VERSION, latest) < 0) {
    console.log(`${c.yellow('note')}  this installer is ${VERSION} but ${latest} is published. To get ${latest}, run ${c.bold(UPDATE_CMD)}`);
    console.log(c.dim('      (plain `npx blueprint-skill` can reuse an old cached copy; @latest forces the newest)'));
  }
  const targets = [];
  console.log(`\n${c.bold(`Update to blueprint ${VERSION}`)}`);
  for (const p of paths) {
    if (!exists(p) || isSymlink(p)) { console.log(`  ${p}  ${c.dim('missing or a symlink — skipped')}`); continue; }
    const v = installedVersion(p);
    if (v && cmpVersion(v, VERSION) === 0 && !verify(p)) { console.log(`  ${p}  ${c.green(`already ${VERSION}`)}`); continue; }
    console.log(`  ${p}  ${c.yellow(`${v || 'unknown version'} → ${VERSION}`)}`);
    targets.push(p);
  }
  if (!targets.length) { console.log(`\n${c.green('Already up to date.')}`); return; }
  if (flags.dryRun) { console.log(c.dim('\ndry run — nothing written')); return; }
  if (!flags.yes) {
    if (!process.stdin.isTTY) { console.error('No TTY; pass --yes to update without a prompt.'); process.exit(2); }
    const ans = (await ask('\nProceed? [y/N] ')).toLowerCase();
    if (ans !== 'y' && ans !== 'yes') { console.log('Aborted.'); return; }
  }
  console.log('');
  const written = install(targets);
  if (written.length) console.log(`\n${c.green(`Updated ${written.length} cop${written.length === 1 ? 'y' : 'ies'} to blueprint ${VERSION}.`)} Restart your agent to load it.`);
}

// Starter constitution for a repository. Project content, so it is not in the manifest
// and uninstall leaves it alone.
function runInit() {
  if (!MODES.includes(flags.mode)) { console.error(c.red(`--mode must be one of: ${MODES.join(', ')}`)); process.exit(2); }
  const src = path.join(SRC, 'assets', 'CONSTITUTION.md');
  const target = path.join(flags.dir || process.cwd(), 'docs', 'plans', 'CONSTITUTION.md');
  if (exists(target)) { console.log(`${c.yellow('exists')} ${target} — left untouched. Edit it, or delete it and run init again.`); return; }
  const d = new Date();
  const today = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const body = fs.readFileSync(src, 'utf8').replace(/<YYYY-MM-DD>/g, today).replace(/^mode: auto$/m, `mode: ${flags.mode}`);
  console.log(`\n${c.bold('Plan')}\n  ${target}  ${c.green('new')}  ${c.dim(`(mode: ${flags.mode})`)}\n`);
  if (flags.dryRun) { console.log(c.dim('dry run — nothing written')); return; }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, body);
  console.log(`${c.green('ok')}    ${target}\nAdd your MUST / SHOULD principles; blueprint checks every plan against them.`);
}

function runDoctor(latest) {
  console.log(`\n${c.bold('Versions')}`);
  console.log(`  installer        ${VERSION}`);
  console.log(`  latest on npm    ${latest || c.dim('unknown (offline or check disabled)')}`);
  console.log(`\n${c.bold('Agents on this machine')}`);
  for (const a of AGENTS) console.log(`  ${a.label.padEnd(26)} ${detected(a) ? c.green('detected') : c.dim('not found')}`);
  console.log(`\n${c.bold('blueprint copies')}`);
  let stale = false;
  const candidates = new Set([SHARED_DIR, ...AGENTS.map((a) => path.join(HOME, ...a.target))].map((d) => path.join(d, SKILL_NAME)));
  for (const t of candidates) {
    if (!exists(t)) continue;
    const problem = verify(t);
    const managed = readManifest().includes(t);
    const v = installedVersion(t);
    const newest = latest && cmpVersion(latest, VERSION) > 0 ? latest : VERSION;
    const vNote = !v ? c.yellow('version unknown') : cmpVersion(v, newest) < 0 ? c.yellow(`${v}, outdated`) : c.green(v);
    if (!v || cmpVersion(v, newest) < 0) stale = true;
    console.log(`  ${t}  ${problem ? c.red(problem) : c.green('ok')}  ${vNote} ${managed ? '' : c.yellow('(not in manifest — unmanaged)')}`);
  }
  // When this installer is newer than npm (a local checkout), @latest would go backwards.
  const cmd = latest && cmpVersion(latest, VERSION) > 0 ? UPDATE_CMD : `npx blueprint-skill@${VERSION} update`;
  if (stale) console.log(`\n  To update every copy in the manifest, run: ${c.bold(cmd)}`);
  console.log('');
}

(async () => {
  if (flags.version) return console.log(VERSION);
  if (flags.help) return help();
  const latestP = fetchLatest(); // runs while the user reads the menu or plan
  if (command === 'doctor') return runDoctor(await latestP);
  if (command === 'update') return runUpdate(await latestP);
  if (command === 'init') runInit();
  else if (command === 'uninstall') await runUninstall();
  else await runInstall();
  newerNotice(await latestP);
})().catch((e) => { console.error(c.red(e.message)); process.exit(1); });
