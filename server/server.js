const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const emailRoutes = require('./routes/emailRoutes');

const app = express();
const PORT = process.env.PORT || 5001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logger
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms`);
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'Maruti Stationery Gmail Automation Service',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    configuredGmailUser: process.env.GMAIL_USER ? process.env.GMAIL_USER.replace(/(.{3})(.*)(@.*)/, '$1***$3') : 'NOT_CONFIGURED',
  });
});

// Email API routes
app.use('/api/email', emailRoutes);

// Root greeting
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'Maruti Stationery Gmail Automation API',
    endpoints: [
      'POST /api/email/order-confirmed',
      'POST /api/email/order-delivered',
      'GET  /api/email/status/:orderId/:eventType',
      'GET  /health',
    ],
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Endpoint not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err);
  res.status(500).json({ success: false, error: err.message || 'Internal server error' });
});

// Start Server
const server = app.listen(PORT, () => {
  console.log(`🚀 [Maruti Stationery] Gmail Automation Service running on http://localhost:${PORT}`);
  console.log(`📧 Configured Gmail account: ${process.env.GMAIL_USER || 'None'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received. Closing HTTP server.');
  server.close(() => {
    console.log('HTTP server closed.');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received. Closing HTTP server.');
  server.close(() => {
    console.log('HTTP server closed.');
  });
});

module.exports = app;

