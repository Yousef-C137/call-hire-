-- =========================
-- CallHire Database Schema
-- =========================

CREATE DATABASE IF NOT EXISTS CallHire;
USE CallHire;

-- =========================
-- 1. Users Table
-- =========================
CREATE TABLE Users (
    user_id      INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100)  NOT NULL,
    email        VARCHAR(150)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role         ENUM('seeker', 'employer') NOT NULL,  -- changed 'recruiter' → 'employer' to match app
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP    -- ADDED
);

-- =========================
-- 2. Profiles Table
-- =========================
CREATE TABLE Profiles (
    profile_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT NOT NULL,
    bio              TEXT,
    skills           TEXT,
    experience_years INT DEFAULT 0,
    cv_url           VARCHAR(255),
    contact_info     VARCHAR(150),                     -- ADDED
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- =========================
-- 3. Companies Table
-- =========================
CREATE TABLE Companies (
    company_id   INT AUTO_INCREMENT PRIMARY KEY,
    recruiter_id INT NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    industry     VARCHAR(100),
    location     VARCHAR(150),
    description  TEXT,
    FOREIGN KEY (recruiter_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- =========================
-- 4. Jobs Table
-- =========================
CREATE TABLE Jobs (
    job_id              INT AUTO_INCREMENT PRIMARY KEY,
    company_id          INT NOT NULL,
    title               VARCHAR(150) NOT NULL,
    description         TEXT NOT NULL,
    salary              VARCHAR(100),                  -- changed DECIMAL → VARCHAR to support "10,000 EGP" format
    job_type            ENUM('full-time', 'part-time', 'remote') NOT NULL,
    category            VARCHAR(100),                  -- ADDED (Customer Service, Calling, Technical Support)
    experience_required VARCHAR(100),                  -- ADDED
    language            VARCHAR(100),                  -- ADDED
    language_level      VARCHAR(50),                   -- ADDED
    status              ENUM('open', 'closed') DEFAULT 'open',
    posted_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES Companies(company_id) ON DELETE CASCADE
);

-- =========================
-- 5. Applications Table
-- =========================
CREATE TABLE Applications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id         INT NOT NULL,
    seeker_id      INT NOT NULL,
    status         ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
    applied_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id)    REFERENCES Jobs(job_id)    ON DELETE CASCADE,
    FOREIGN KEY (seeker_id) REFERENCES Users(user_id)  ON DELETE CASCADE,
    UNIQUE KEY unique_application (job_id, seeker_id)  -- ADDED: prevents duplicate applications
);

-- =========================
-- 6. Messages Table
-- =========================
CREATE TABLE Messages (
    message_id   INT AUTO_INCREMENT PRIMARY KEY,
    sender_id    INT NOT NULL,
    receiver_id  INT NOT NULL,
    message_text TEXT NOT NULL,
    sent_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_read      BOOLEAN DEFAULT FALSE,                -- ADDED
    FOREIGN KEY (sender_id)   REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
SHOW TABLES;

SELECT * FROM Users;
SELECT * FROM Companies;
SELECT * FROM Jobs;
SELECT * FROM Applications;