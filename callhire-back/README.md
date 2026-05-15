# CallHire — Setup Guide

## Project Structure
```
callhire/
├── backend/       ← Node.js + Express + MySQL API
└── flutter/       ← Updated Flutter app (lib folder only)
```

---

## Backend Setup

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Create MySQL Database
Open MySQL Workbench and run:
```sql
CREATE DATABASE callhire;
```

### 3. Configure Environment
Open `backend/.env` and update your MySQL password:
```
DB_PASSWORD=your_actual_password_here
```

### 4. Start the Server
```bash
node index.js
```
You should see:
```
✅ Connected to MySQL database!
✅ All tables ready!
🚀 CallHire server running on http://localhost:3000
```
Tables are created automatically — no SQL scripts needed.

---

## Flutter Setup

### 1. Add Dependencies to pubspec.yaml
Add these under `dependencies:`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.2
  socket_io_client: ^2.0.3+1
```
Then run:
```bash
flutter pub get
```

### 2. Replace lib folder
Copy the contents of the `flutter/lib` folder into your Flutter project's `lib` folder, replacing all existing files.

### 3. Configure API URL
Open `lib/services/api_service.dart` and update the base URL:
- **Android Emulator:** `http://10.0.2.2:3000`
- **Real Android/iOS device:** `http://YOUR_COMPUTER_IP:3000`
- **Web:** `http://localhost:3000`

To find your computer's IP: run `ipconfig` on Windows and look for IPv4 Address.

---

## API Endpoints Reference

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /auth/register | Register new user |
| POST | /auth/login | Login and get JWT token |

### Jobs
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /jobs | No | Get all open jobs |
| GET | /jobs/:id | No | Get single job |
| POST | /jobs | Employer | Post a new job |
| PUT | /jobs/:id | Employer | Update a job |
| DELETE | /jobs/:id | Employer | Delete a job |
| GET | /jobs/employer/mine | Employer | Get my posted jobs |

### Applications
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /applications | Seeker | Apply to a job |
| GET | /applications/my | Seeker | Get my applications |
| GET | /applications/employer | Employer | Get received applications |
| PUT | /applications/:id | Employer | Accept or reject |

### Messages
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /messages | Any | Get inbox |
| GET | /messages/:user_id | Any | Get conversation |
| POST | /messages | Any | Send a message |

---

## Database Schema

6 tables: `users`, `profiles`, `companies`, `jobs`, `applications`, `messages`

All tables are created automatically when the server starts.

---

## WebSocket Events

Connect using socket.io client and emit `join` with your user_id to receive real-time events:
- `new_job` — fired when a new job is posted
- `employer_{id}` — fired when someone applies to your job
- `seeker_{id}` — fired when your application status changes
- `message_{id}` — fired when you receive a new message
