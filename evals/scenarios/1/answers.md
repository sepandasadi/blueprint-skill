# Scripted user answers — Scenario 1

Read these in order. Each time the agent asks the user something, the next unused answer below is the user's reply. The agent must ask ONE question per message. For A2, A4 and A5, answer each question individually: if it concerns a topic named in the bullets, give that bullet; otherwise reply "Use your recommended default." If the agent shows more than one question in a message, record that as a failure. If the agent asks something not covered, the reply is: "Use your recommended default."

## A0 — mode (if asked)
"advanced"

## A1 — interpretation
"The one that is a personal notes app where I can share individual notes with other people by link or by inviting them."

## A2 — requirements track
"Defaults, except where these apply:
- Notes must be end-to-end encrypted. The server must never be able to read note content.
- I need full-text search across all my notes, and it has to be server-side so it works from any device instantly.
- Sharing: a public link anyone can open (with a rich preview card showing the first lines of the note when pasted in Slack), plus invite-by-email with view or edit rights.
- No signup friction: magic-link email login only."

## A3 — follow-up (if asked about the encryption / search / preview conflict)
"Good catch. Encryption matters most. Search can be client-side over notes already synced to the device. Public links can skip encryption for that note only — the user chooses to make it public."

## A4 — design track
"Use your recommended default for every question. Deploy on whatever is cheapest. Expect maybe 500 users."

## A5 — testing track
"All defaults, but I want end-to-end tests for the sharing flows."

## A6 — Gate 1
"Approved."

## A7 — Gate 2
"Approved."
