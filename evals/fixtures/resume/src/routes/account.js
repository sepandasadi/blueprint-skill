import { Router } from 'express';
import { requireUser } from '../auth.js';

export const account = Router();

account.get('/account', requireUser, (req, res) => {
  res.json({ id: req.user.id, email: req.user.email, memberSince: req.user.createdAt });
});
