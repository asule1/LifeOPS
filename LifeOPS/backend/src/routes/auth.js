const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const router = express.Router();
const prisma = new PrismaClient();

const SALT_ROUNDS = 12;
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || '24h';
const failedAttempts = {}; // in-memory tracker

// ── POST /api/auth/register ──────────────────────────────────
router.post('/register', async (req, res) => {
  const { full_name, email, password } = req.body;
  if (!full_name || !email || !password)
    return res.status(400).json({ error: 'All fields are required.' });

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email))
    return res.status(400).json({ error: 'Invalid email format.' });

  const pwRegex = /^(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$/;
  if (!pwRegex.test(password))
    return res.status(400).json({ error: 'Password must be 8+ chars with uppercase, digit, and special character.' });

  try {
    const existing = await prisma.users.findUnique({ where: { email } });
    if (existing) return res.status(409).json({ error: 'Email already in use.' });

    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);
    const user = await prisma.users.create({
      data: { full_name, email, password_hash, role: 'user' }
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: JWT_EXPIRES }
    );

    await prisma.sessions.create({
      data: { user_id: user.id, token_hash: token, expires_at: new Date(Date.now() + 24*60*60*1000) }
    });

    res.cookie('token', token, { httpOnly: true, secure: process.env.NODE_ENV === 'production', maxAge: 24*60*60*1000 });
    res.status(201).json({ message: 'Account created successfully.', user: { id: user.id, full_name: user.full_name, email: user.email, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(503).json({ error: 'Database unavailable. Try again later.' });
  }
});

// ── POST /api/auth/login ─────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ error: 'Email and password are required.' });

  // Check lockout
  const attempts = failedAttempts[email] || { count: 0, lockedUntil: null };
  if (attempts.lockedUntil && new Date() < attempts.lockedUntil)
    return res.status(429).json({ error: 'Account locked. Try again in 15 minutes.' });

  try {
    const user = await prisma.users.findUnique({ where: { email } });
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      failedAttempts[email] = {
        count: (attempts.count || 0) + 1,
        lockedUntil: (attempts.count + 1) >= 5 ? new Date(Date.now() + 15*60*1000) : null
      };
      return res.status(401).json({ error: 'Invalid email or password.', attempts: failedAttempts[email].count });
    }

    if (!user.is_active)
      return res.status(403).json({ error: 'Account suspended. Contact administrator.' });

    // Reset failed attempts on success
    delete failedAttempts[email];

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: JWT_EXPIRES }
    );

    await prisma.sessions.create({
      data: { user_id: user.id, token_hash: token, expires_at: new Date(Date.now() + 24*60*60*1000) }
    });

    res.cookie('token', token, { httpOnly: true, secure: process.env.NODE_ENV === 'production', maxAge: 24*60*60*1000 });
    res.json({ message: 'Login successful.', user: { id: user.id, full_name: user.full_name, email: user.email, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Authentication failed.' });
  }
});

// ── POST /api/auth/logout ────────────────────────────────────
router.post('/logout', async (req, res) => {
  const token = req.cookies.token;
  if (token) {
    try {
      await prisma.sessions.updateMany({
        where: { token_hash: token },
        data: { is_revoked: true }
      });
    } catch (err) {
      console.error('Session revoke error:', err);
    }
  }
  res.clearCookie('token');
  res.json({ message: 'Logged out successfully.' });
});

// ── GET /api/auth/me ─────────────────────────────────────────
router.get('/me', async (req, res) => {
  const token = req.cookies.token;
  if (!token) return res.status(401).json({ error: 'Not authenticated.' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.users.findUnique({ where: { id: decoded.userId } });
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ id: user.id, full_name: user.full_name, email: user.email, role: user.role });
  } catch {
    res.status(401).json({ error: 'Invalid or expired token.' });
  }
});

module.exports = router;