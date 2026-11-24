const nodemailer = require('nodemailer');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

/**
 * Creates and configures the Nodemailer Gmail SMTP transporter.
 * Uses official Google Gmail SMTP settings (smtp.gmail.com).
 */
function createTransporter() {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASSWORD;

  if (!user || !pass || pass === 'your_gmail_app_password_here') {
    console.warn(
      '⚠️ [Gmail Service] GMAIL_USER or GMAIL_APP_PASSWORD is not configured in .env. Emails will run in mock/log mode.'
    );
  }

  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // SSL
    auth: {
      user: user,
      pass: pass ? pass.replace(/\s+/g, '') : '', // strip spaces if user copied "abcd efgh ijkl mnop"
    },
    // Pool connections to avoid opening new connections on every send
    pool: true,
    maxConnections: 5,
    maxMessages: 100,
    rateLimit: 14, // Gmail send rate limit safe margin
  });

  return transporter;
}

const transporter = createTransporter();

// Verify SMTP connection on startup if credentials exist
if (process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD && process.env.GMAIL_APP_PASSWORD !== 'your_gmail_app_password_here') {
  transporter.verify((error) => {
    if (error) {
      console.error('❌ [Gmail SMTP] Transporter verification failed:', error.message);
    } else {
      console.log('✅ [Gmail SMTP] Connected successfully to smtp.gmail.com with account:', process.env.GMAIL_USER);
    }
  });
}

module.exports = {
  transporter,
  createTransporter,
};

