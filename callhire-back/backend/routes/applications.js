const express = require('express');
const router = express.Router();
const db = require('../config/db');
const authMiddleware = require('../middleware/auth');

// ─── APPLY TO A JOB (seeker only) ────────────────────────────────────────────
// POST /applications
router.post('/', authMiddleware, (req, res) => {
  if (req.user.role !== 'seeker') {
    return res.status(403).json({ message: 'Only job seekers can apply.' });
  }

  const { job_id } = req.body;
  if (!job_id) return res.status(400).json({ message: 'job_id is required.' });

  // Check if already applied
  db.query(
    'SELECT application_id FROM applications WHERE job_id = ? AND seeker_id = ?',
    [job_id, req.user.user_id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      if (results.length > 0) return res.status(409).json({ message: 'You have already applied to this job.' });

      db.query(
        'INSERT INTO applications (job_id, seeker_id) VALUES (?, ?)',
        [job_id, req.user.user_id],
        (err, result) => {
          if (err) return res.status(500).json({ message: 'Failed to apply.', error: err.message });

          // Notify employer via WebSocket
          db.query(
            `SELECT c.recruiter_id, j.title, u.name as seeker_name
             FROM jobs j
             JOIN companies c ON j.company_id = c.company_id
             JOIN users u ON u.user_id = ?
             WHERE j.job_id = ?`,
            [req.user.user_id, job_id],
            (err, info) => {
              if (!err && info.length > 0) {
                const io = req.app.get('io');
                io.emit(`employer_${info[0].recruiter_id}`, {
                  event: 'new_application',
                  message: `${info[0].seeker_name} applied for ${info[0].title}`,
                });
              }
            }
          );

          res.status(201).json({ message: 'Application submitted successfully.', application_id: result.insertId });
        }
      );
    }
  );
});

// ─── GET MY APPLICATIONS (seeker) ────────────────────────────────────────────
// GET /applications/my
router.get('/my', authMiddleware, (req, res) => {
  if (req.user.role !== 'seeker') {
    return res.status(403).json({ message: 'Only seekers can access this.' });
  }

  db.query(
    `SELECT a.application_id, a.status, a.applied_at,
            j.job_id, j.title, j.salary, j.category,
            c.company_name, c.location
     FROM applications a
     JOIN jobs j ON a.job_id = j.job_id
     JOIN companies c ON j.company_id = c.company_id
     WHERE a.seeker_id = ?
     ORDER BY a.applied_at DESC`,
    [req.user.user_id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      res.json(results);
    }
  );
});

// ─── GET APPLICATIONS FOR EMPLOYER ───────────────────────────────────────────
// GET /applications/employer
router.get('/employer', authMiddleware, (req, res) => {
  if (req.user.role !== 'employer') {
    return res.status(403).json({ message: 'Only employers can access this.' });
  }

  db.query(
    `SELECT a.application_id, a.status, a.applied_at,
            j.job_id, j.title,
            u.user_id as seeker_id, u.name as seeker_name, u.email as seeker_email,
            p.skills, p.experience_years, p.cv_url, p.contact_info
     FROM applications a
     JOIN jobs j ON a.job_id = j.job_id
     JOIN companies c ON j.company_id = c.company_id
     JOIN users u ON a.seeker_id = u.user_id
     LEFT JOIN profiles p ON u.user_id = p.user_id
     WHERE c.recruiter_id = ?
     ORDER BY a.applied_at DESC`,
    [req.user.user_id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      res.json(results);
    }
  );
});

// ─── UPDATE APPLICATION STATUS (employer only) ────────────────────────────────
// PUT /applications/:id
router.put('/:id', authMiddleware, (req, res) => {
  if (req.user.role !== 'employer') {
    return res.status(403).json({ message: 'Only employers can update application status.' });
  }

  const { status } = req.body;
  if (!['accepted', 'rejected', 'pending'].includes(status)) {
    return res.status(400).json({ message: 'Status must be accepted, rejected, or pending.' });
  }

  db.query(
    'UPDATE applications SET status = ? WHERE application_id = ?',
    [status, req.params.id],
    (err, result) => {
      if (err) return res.status(500).json({ message: 'Failed to update status.', error: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ message: 'Application not found.' });

      // Notify seeker via WebSocket
      db.query(
        `SELECT a.seeker_id, j.title
         FROM applications a
         JOIN jobs j ON a.job_id = j.job_id
         WHERE a.application_id = ?`,
        [req.params.id],
        (err, info) => {
          if (!err && info.length > 0) {
            const io = req.app.get('io');
            io.emit(`seeker_${info[0].seeker_id}`, {
              event: 'application_update',
              message: `Your application for ${info[0].title} was ${status}.`,
              status,
            });
          }
        }
      );

      res.json({ message: `Application ${status} successfully.` });
    }
  );
});

module.exports = router;
