const fs = require('fs');
const path = require('path');

const LOG_FILE = path.join(__dirname, '../email_logs.json');

class IdempotencyService {
  constructor() {
    this.logs = new Map();
    this._loadLogs();
  }

  _loadLogs() {
    try {
      if (fs.existsSync(LOG_FILE)) {
        const raw = fs.readFileSync(LOG_FILE, 'utf-8');
        const data = JSON.parse(raw);
        for (const [key, value] of Object.entries(data)) {
          this.logs.set(key, value);
        }
      }
    } catch (err) {
      console.warn('⚠️ [Idempotency] Could not load persisted email logs:', err.message);
    }
  }

  _saveLogs() {
    try {
      const obj = Object.fromEntries(this.logs);
      fs.writeFileSync(LOG_FILE, JSON.stringify(obj, null, 2), 'utf-8');
    } catch (err) {
      console.error('❌ [Idempotency] Could not persist email logs:', err.message);
    }
  }

  /**
   * Generates a unique key for duplicate prevention.
   */
  getKey(orderId, eventType) {
    return `${orderId.trim().toUpperCase()}_${eventType.trim().toLowerCase()}`;
  }

  /**
   * Checks if an email was already sent successfully for this order event.
   */
  hasBeenSent(orderId, eventType) {
    const key = this.getKey(orderId, eventType);
    const existing = this.logs.get(key);
    return existing && existing.status === 'sent';
  }

  /**
   * Gets log record for an order event.
   */
  getRecord(orderId, eventType) {
    const key = this.getKey(orderId, eventType);
    return this.logs.get(key) || null;
  }

  /**
   * Records that an email sending process started or succeeded or failed.
   */
  recordEmailStatus({ orderId, eventType, recipientEmail, status, providerResponse, error }) {
    const key = this.getKey(orderId, eventType);
    const record = {
      orderId: orderId.trim().toUpperCase(),
      eventType: eventType.trim().toLowerCase(),
      recipientEmail,
      status, // 'in_progress' | 'sent' | 'failed'
      timestamp: new Date().toISOString(),
      providerResponse: providerResponse || null,
      error: error || null,
    };

    this.logs.set(key, record);
    this._saveLogs();
    return record;
  }
}

module.exports = new IdempotencyService();

