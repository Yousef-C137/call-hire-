const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

// ─── REGISTER ───────────────────────────────────────────────────────────────
// POST /auth/register
router.post('/register', (req, res) => {
  const {
    name, email, password, role,
    // seeker fields
    skills, experience_years, cv_url, contact_info,
    // employer fields
    company_name, industry, location,
  } = req.body;

  if (!name || !email || !password || !role) {
    return res.status(400).json({ message: 'Name, email, password and role are required.' });
  }

  if (!['seeker', 'employer'].includes(role)) {
    return res.status(400).json({ message: 'Role must be seeker or employer.' });
  }

  // Check if email already exists
  db.query('SELECT user_id FROM users WHERE email = ?', [email], (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
    if (results.length > 0) return res.status(409).json({ message: 'Email already registered.' });

    // Hash password
    const password_hash = bcrypt.hashSync(password, 10);

    // Insert user
    db.query(
      'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [name, email, password_hash, role],
      (err, result) => {
        if (err) return res.status(500).json({ message: 'Failed to create user.', error: err.message });

        const user_id = result.insertId;

        // Insert profile
        db.query(
          'INSERT INTO profiles (user_id, skills, experience_years, cv_url, contact_info) VALUES (?, ?, ?, ?, ?)',
          [user_id, skills || null, experience_years || 0, cv_url || null, contact_info || null],
          (err) => {
            if (err) return res.status(500).json({ message: 'Failed to create profile.', error: err.message });

            // If employer, create company
            if (role === 'employer' && company_name) {
              db.query(
                'INSERT INTO companies (recruiter_id, company_name, industry, location) VALUES (?, ?, ?, ?)',
                [user_id, company_name, industry || null, location || null],
                (err) => {
                  if (err) return res.status(500).json({ message: 'Failed to create company.', error: err.message });
                  return res.status(201).json({ message: 'Employer registered successfully.' });
                }
              );
            } else {
              return res.status(201).json({ message: 'Seeker registered successfully.' });
            }
          }
        );
      }
    );
  });
});

// ─── LOGIN ───────────────────────────────────────────────────────────────────
// POST /auth/login
router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  db.query(
    `SELECT u.user_id, u.name, u.email, u.password_hash, u.role,
            p.skills, p.experience_years, p.cv_url, p.contact_info,
            c.company_id, c.company_name
     FROM users u
     LEFT JOIN profiles p ON u.user_id = p.user_id
     LEFT JOIN companies c ON u.user_id = c.recruiter_id
     WHERE u.email = ?`,
    [email],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error.', error: err.message });
      if (results.length === 0) return res.status(401).json({ message: 'Invalid email or password.' });

      const user = results[0];
      const passwordMatch = bcrypt.compareSync(password, user.password_hash);
      if (!passwordMatch) return res.status(401).json({ message: 'Invalid email or password.' });

      // Generate JWT token
      const token = jwt.sign(
        { user_id: user.user_id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      res.json({
        message: 'Login successful.',
        token,
        user: {
          user_id: user.user_id,
          name: user.name,
          email: user.email,
          role: user.role,
          skills: user.skills,
          experience_years: user.experience_years,
          cv_url: user.cv_url,
          contact_info: user.contact_info,
          company_id: user.company_id,
          company_name: user.company_name,
        },
      });
    }
  );
});

module.exports = router;
