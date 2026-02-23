const express = require('express');
const { PrismaClient } = require('@prisma/client');
const router = express.Router();
const prisma = new PrismaClient();

// GET /api/tasks
router.get('/', async (req, res) => {
  const tasks = await prisma.tasks.findMany({ where: { user_id: req.user.userId }, orderBy: { created_at: 'desc' } });
  res.json(tasks);
});

// POST /api/tasks
router.post('/', async (req, res) => {
  const { title, description, due_date, priority, tags } = req.body;
  if (!title) return res.status(400).json({ error: 'Task title is required.' });
  const task = await prisma.tasks.create({
    data: { user_id: req.user.userId, title, description, due_date: due_date ? new Date(due_date) : null, priority: priority || 'medium', tags: tags || [] }
  });
  res.status(201).json(task);
});

// PATCH /api/tasks/:id
router.patch('/:id', async (req, res) => {
  const task = await prisma.tasks.updateMany({
    where: { id: req.params.id, user_id: req.user.userId },
    data: req.body
  });
  res.json(task);
});

// DELETE /api/tasks/:id
router.delete('/:id', async (req, res) => {
  await prisma.tasks.deleteMany({ where: { id: req.params.id, user_id: req.user.userId } });
  res.json({ message: 'Task deleted.' });
});

module.exports = router;