const express = require('express');
const router = express.Router();
const db = require('../config/db');
const authMiddleware = require('../middleware/auth');

// ─── SEND A MESSAGE ───────────────────────────────────────────────────────────
// POST /messages
router.post('/', authMiddleware, (req, res) => {
  const { receiver_id, content } = req.body;

  if (!receiver_id || !content) {
    return res.status(400).json({ message: 'receiver_id and content are required.' });
  }

  db.query(
    'INSERT INTO messages (sender_id, receiver_id, content) VALUES (?, ?, ?)',
    [req.user.user_id, receiver_id, content],
    (err, result) => {
      if (err) return res.status(500).json({ message: 'Failed to send message.', error: err.message });

      // Emit real-time message to receiver
      const io = req.app.get('io');
      io.emit(`message_${receiver_id}`, {
        message_id: result.insertId,
        sender_id: req.user.user_id,
        content,
        sent_at: new Date(),
      });

      res.status(201).json({ message: 'Message sent.', message_id: result.insertId });
    }
  );
});

// ─── GET CONVERSATION WITH A USER ─────────────────────────────────────────────
// GET /messages/:other_user_id
router.get('/:other_user_id', authMiddleware, (req, res) => {
  const me = req.user.user_id;
  const other = req.params.other_user_id;

  db.query(
    `SELECT m.*, u.name as sender_name
     FROM messages m
     JOIN users u ON m.sender_id = u.user_id
     WHERE (m.sender_id = ? AND m.receiver_id = ?)
        OR (m.sender_id = ? AND m.receiver_id = ?)
     ORDER BY m.sent_at ASC`,
    [me, other, other, me],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });

      // Mark messages as read
      db.query(
        'UPDATE messages SET is_read = TRUE WHERE receiver_id = ? AND sender_id = ?',
        [me, other],
        () => {}
      );

      res.json(results);
    }
  );
});

// ─── GET ALL CONVERSATIONS (inbox) ────────────────────────────────────────────
// GET /messages
router.get('/', authMiddleware, (req, res) => {
  db.query(
    `SELECT DISTINCT
       u.user_id, u.name,
       (SELECT content FROM messages
        WHERE (sender_id = ? AND receiver_id = u.user_id)
           OR (sender_id = u.user_id AND receiver_id = ?)
        ORDER BY sent_at DESC LIMIT 1) as last_message,
       (SELECT sent_at FROM messages
        WHERE (sender_id = ? AND receiver_id = u.user_id)
           OR (sender_id = u.user_id AND receiver_id = ?)
        ORDER BY sent_at DESC LIMIT 1) as last_message_time,
       (SELECT COUNT(*) FROM messages
        WHERE sender_id = u.user_id AND receiver_id = ? AND is_read = FALSE) as unread_count
     FROM users u
     WHERE u.user_id IN (
       SELECT CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END
       FROM messages
       WHERE sender_id = ? OR receiver_id = ?
     )`,
    Array(8).fill(req.user.user_id),
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      res.json(results);
    }
  );
});

module.exports = router;
