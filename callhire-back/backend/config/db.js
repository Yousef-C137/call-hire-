const mysql = require('mysql2');
require('dotenv').config();

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  multipleStatements: true,
});

db.connect((err) => {
  if (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  }
  console.log('✅ Connected to MySQL database!');
  createTables();
});

function createTables() {
  const sql = `
    CREATE TABLE IF NOT EXISTS users (
      user_id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(150) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      role ENUM('seeker', 'employer') NOT NULL,
      created_at DATETIME DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS profiles (
      profile_id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      bio TEXT,
      skills TEXT,
      experience_years INT DEFAULT 0,
      cv_url VARCHAR(255),
      contact_info VARCHAR(150),
      FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS companies (
      company_id INT AUTO_INCREMENT PRIMARY KEY,
      recruiter_id INT NOT NULL,
      company_name VARCHAR(150) NOT NULL,
      industry VARCHAR(100),
      location VARCHAR(150),
      description TEXT,
      FOREIGN KEY (recruiter_id) REFERENCES users(user_id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS jobs (
      job_id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT NOT NULL,
      title VARCHAR(150) NOT NULL,
      description TEXT NOT NULL,
      salary VARCHAR(100),
      job_type ENUM('full-time', 'part-time', 'remote') DEFAULT 'full-time',
      category VARCHAR(100),
      experience_required VARCHAR(100),
      language VARCHAR(100),
      language_level VARCHAR(50),
      status ENUM('open', 'closed') DEFAULT 'open',
      posted_at DATETIME DEFAULT NOW(),
      FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS applications (
      application_id INT AUTO_INCREMENT PRIMARY KEY,
      job_id INT NOT NULL,
      seeker_id INT NOT NULL,
      status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
      applied_at DATETIME DEFAULT NOW(),
      FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
      FOREIGN KEY (seeker_id) REFERENCES users(user_id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS messages (
      message_id INT AUTO_INCREMENT PRIMARY KEY,
      sender_id INT NOT NULL,
      receiver_id INT NOT NULL,
      content TEXT NOT NULL,
      sent_at DATETIME DEFAULT NOW(),
      is_read BOOLEAN DEFAULT FALSE,
      FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
      FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE
    );
  `;

  db.query(sql, (err) => {
    if (err) {
      console.error('❌ Failed to create tables:', err.message);
    } else {
      console.log('✅ All tables ready!');
    }
  });
}

module.exports = db;
