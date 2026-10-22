import express from 'express';
import { account } from './routes/account.js';

export const app = express();
app.use(express.json());
app.use(account);

if (process.env.NODE_ENV !== 'test') {
  app.listen(3000, () => console.log('listening on :3000'));
}
