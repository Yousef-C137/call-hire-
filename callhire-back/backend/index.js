const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const jobRoutes = require('./routes/jobs');
const applicationRoutes = require('./routes/applications');
const messageRoutes = require('./routes/messages');

// Initialize DB (creates tables automatically)
require('./config/db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// ─── MIDDLEWARE ───────────────────────────────────────────────────────────────
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// ─── ROUTES ───────────────────────────────────────────────────────────────────
app.use('/auth', authRoutes);
app.use('/jobs', jobRoutes);
app.use('/applications', applicationRoutes);
app.use('/messages', messageRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ message: '✅ CallHire API is running!' });
});

// ─── WEBSOCKET ────────────────────────────────────────────────────────────────
io.on('connection', (socket) => {
  console.log(`🔌 User connected: ${socket.id}`);

  // Client sends their user_id to join a personal room
  socket.on('join', (user_id) => {
    socket.join(`user_${user_id}`);
    console.log(`👤 User ${user_id} joined their room`);
  });

  socket.on('disconnect', () => {
    console.log(`🔌 User disconnected: ${socket.id}`);
  });
});

// Make io accessible in routes
app.set('io', io);

// ─── START SERVER ─────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 CallHire server running on http://localhost:${PORT}`);
});
