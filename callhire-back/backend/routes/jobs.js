const express = require('express');
const router = express.Router();
const db = require('../config/db');
const authMiddleware = require('../middleware/auth');

// ─── GET ALL OPEN JOBS ────────────────────────────────────────────────────────
// GET /jobs
router.get('/', (req, res) => {
  const { category, search } = req.query;

  let sql = `
    SELECT j.*, c.company_name, c.location
    FROM jobs j
    JOIN companies c ON j.company_id = c.company_id
    WHERE j.status = 'open'
  `;
  const params = [];

  if (category && category !== 'All') {
    sql += ' AND j.category = ?';
    params.push(category);
  }

  if (search) {
    sql += ' AND (j.title LIKE ? OR c.company_name LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  sql += ' ORDER BY j.posted_at DESC';

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
    res.json(results);
  });
});

// ─── GET SINGLE JOB ──────────────────────────────────────────────────────────
// GET /jobs/:id
router.get('/:id', (req, res) => {
  db.query(
    `SELECT j.*, c.company_name, c.location, c.description as company_description
     FROM jobs j
     JOIN companies c ON j.company_id = c.company_id
     WHERE j.job_id = ?`,
    [req.params.id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      if (results.length === 0) return res.status(404).json({ message: 'Job not found.' });
      res.json(results[0]);
    }
  );
});

// ─── POST A JOB (employer only) ───────────────────────────────────────────────
// POST /jobs
router.post('/', authMiddleware, (req, res) => {
  if (req.user.role !== 'employer') {
    return res.status(403).json({ message: 'Only employers can post jobs.' });
  }

  const { title, description, salary, job_type, category, experience_required, language, language_level } = req.body;

  if (!title || !description) {
    return res.status(400).json({ message: 'Title and description are required.' });
  }

  // Get employer's company
  db.query(
    'SELECT company_id FROM companies WHERE recruiter_id = ?',
    [req.user.user_id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      if (results.length === 0) return res.status(404).json({ message: 'No company found for this employer.' });

      const company_id = results[0].company_id;

      db.query(
        `INSERT INTO jobs (company_id, title, description, salary, job_type, category, experience_required, language, language_level)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [company_id, title, description, salary || null, job_type || 'full-time', category || null, experience_required || null, language || null, language_level || null],
        (err, result) => {
          if (err) return res.status(500).json({ message: 'Failed to post job.', error: err.message });

          // Emit real-time event to all connected clients
          const io = req.app.get('io');
          io.emit('new_job', { job_id: result.insertId, title, company_id });

          res.status(201).json({ message: 'Job posted successfully.', job_id: result.insertId });
        }
      );
    }
  );
});

// ─── UPDATE JOB (employer only) ──────────────────────────────────────────────
// PUT /jobs/:id
router.put('/:id', authMiddleware, (req, res) => {
  if (req.user.role !== 'employer') {
    return res.status(403).json({ message: 'Only employers can update jobs.' });
  }

  const { title, description, salary, job_type, category, experience_required, language, language_level, status } = req.body;

  db.query(
    `UPDATE jobs SET
      title = COALESCE(?, title),
      description = COALESCE(?, description),
      salary = COALESCE(?, salary),
      job_type = COALESCE(?, job_type),
      category = COALESCE(?, category),
      experience_required = COALESCE(?, experience_required),
      language = COALESCE(?, language),
      language_level = COALESCE(?, language_level),
      status = COALESCE(?, status)
     WHERE job_id = ?`,
    [title, description, salary, job_type, category, experience_required, language, language_level, status, req.params.id],
    (err, result) => {
      if (err) return res.status(500).json({ message: 'Failed to update job.', error: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ message: 'Job not found.' });
      res.json({ message: 'Job updated successfully.' });
    }
  );
});

// ─── DELETE JOB (employer only) ──────────────────────────────────────────────
// DELETE /jobs/:id
router.delete('/:id', authMiddleware, (req, res) => {
  if (req.user.role !== 'employer') {
    return res.status(403).json({ message: 'Only employers can delete jobs.' });
  }

  db.query('DELETE FROM jobs WHERE job_id = ?', [req.params.id], (err, result) => {
    if (err) return res.status(500).json({ message: 'Failed to delete job.', error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'Job not found.' });
    res.json({ message: 'Job deleted successfully.' });
  });
});

// ─── GET EMPLOYER'S OWN JOBS ─────────────────────────────────────────────────
// GET /jobs/employer/mine
router.get('/employer/mine', authMiddleware, (req, res) => {
  if (req.user.role !== 'employer') {
    return res.status(403).json({ message: 'Only employers can access this.' });
  }

  db.query(
    `SELECT j.*, c.company_name
     FROM jobs j
     JOIN companies c ON j.company_id = c.company_id
     WHERE c.recruiter_id = ?
     ORDER BY j.posted_at DESC`,
    [req.user.user_id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      res.json(results);
    }
  );
});

module.exports = router;
