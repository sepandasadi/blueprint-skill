import { sessions, users } from './db.js';

export function requireUser(req, res, next) {
  const token = (req.headers.authorization || '').replace(/^Bearer /, '');
  const userId = sessions.get(token);
  if (!userId) return res.status(401).json({ error: 'unauthorized' });
  req.user = users.get(userId);
  next();
}
