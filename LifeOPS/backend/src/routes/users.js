const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { requireAdmin } = require('../middleware/auth');
const router = express.Router();
const prisma = new PrismaClient();

// ── GET /api/users — Admin only ──────────────────────────────
router.get('/', requireAdmin, async (req, res) => {
  try {
    const users = await prisma.users.findMany({
      select: { id:true, full_name:true, email:true, role:true, is_active:true, created_at:true },
      orderBy: { created_at: 'desc' }
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users.' });
  }
});

// ── PATCH /api/users/:id/suspend — Admin only ────────────────
router.patch('/:id/suspend', requireAdmin, async (req, res) => {
  try {
    if (req.params.id === req.user.userId)
      return res.status(400).json({ error: 'You cannot suspend your own account.' });

    const user = await prisma.users.update({
      where: { id: req.params.id },
      data: { is_active: false }
    });
    await prisma.audit_logs.create({
      data: { admin_id: req.user.userId, action_type: 'SUSPEND_USER', target_user_id: req.params.id, details: { email: user.email } }
    });
    res.json({ message: 'User suspended.' });
  } catch {
    res.status(500).json({ error: 'Failed to suspend user.' });
  }
});

// ── DELETE /api/users/:id — Admin only ──────────────────────
router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    if (req.params.id === req.user.userId)
      return res.status(400).json({ error: 'You cannot delete your own account.' });

    const user = await prisma.users.delete({ where: { id: req.params.id } });
    await prisma.audit_logs.create({
      data: { admin_id: req.user.userId, action_type: 'DELETE_USER', target_user_id: req.params.id, details: { email: user.email } }
    });
    res.json({ message: 'User deleted.' });
  } catch {
    res.status(500).json({ error: 'Failed to delete user.' });
  }
});

module.exports = router;
