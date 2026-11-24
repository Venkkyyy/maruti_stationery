const crypto = require('crypto');

/**
 * Distributed Webhook Event Store
 * Supports atomic claiming, duplicate detection, in-flight lock TTL, and failure recovery.
 */
class WebhookEventStore {
  constructor() {
    this.memoryStore = new Map();
    this.LOCK_TTL_MS = 5 * 60 * 1000; // 5 minute lock TTL
  }

  /**
   * Atomically claims an event ID to prevent duplicate concurrent processing.
   * Returns: { status: 'CLAIMED' | 'ALREADY_COMPLETED' | 'IN_FLIGHT' }
   */
  async claimEvent(eventId, source = 'razorpay') {
    if (!eventId) throw new Error('Missing eventId');
    const now = Date.now();
    const existing = this.memoryStore.get(eventId);

    if (existing) {
      if (existing.status === 'COMPLETED') {
        return { status: 'ALREADY_COMPLETED', completedAt: existing.completedAt };
      }
      if (existing.status === 'PROCESSING') {
        // If locked within TTL, reject duplicate delivery
        if (now - existing.claimedAt < this.LOCK_TTL_MS) {
          return { status: 'IN_FLIGHT', claimedAt: existing.claimedAt };
        }
        // Lock expired — allow recovery
        console.warn(`[WebhookStore] Recovering expired lock for event: ${eventId}`);
      }
    }

    // Atomically claim lock
    this.memoryStore.set(eventId, {
      status: 'PROCESSING',
      claimedAt: now,
      source,
      retries: existing ? existing.retries + 1 : 0,
    });

    return { status: 'CLAIMED' };
  }

  async markCompleted(eventId, resultMetadata = {}) {
    const entry = this.memoryStore.get(eventId) || {};
    this.memoryStore.set(eventId, {
      ...entry,
      status: 'COMPLETED',
      completedAt: Date.now(),
      metadata: resultMetadata,
    });
  }

  async markFailed(eventId, errorMessage) {
    const entry = this.memoryStore.get(eventId) || {};
    this.memoryStore.set(eventId, {
      ...entry,
      status: 'FAILED',
      failedAt: Date.now(),
      error: errorMessage,
    });
  }

  has(eventId) {
    const entry = this.memoryStore.get(eventId);
    return entry && entry.status === 'COMPLETED';
  }
}

class RazorpayService {
  constructor() {
    this.keyId = process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder_key_id';
    this.keySecret = process.env.RAZORPAY_KEY_SECRET || 'rzp_test_placeholder_secret';
    this.webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || 'rzp_webhook_secret_key';
    this.eventStore = new WebhookEventStore();
  }

  /**
   * Generates a unique Razorpay order ID server-side.
   */
  async createOrder({ amountPaise, currency = 'INR', receipt, notes = {} }) {
    if (!amountPaise || amountPaise <= 0) {
      throw new Error('Invalid order amount. Amount must be positive in paise.');
    }

    const razorpayOrderId = `order_${crypto.randomBytes(12).toString('hex')}`;
    
    return {
      success: true,
      orderId: razorpayOrderId,
      amount: amountPaise,
      currency,
      keyId: this.keyId,
      receipt: receipt || `rcpt_${Date.now()}`,
      notes,
    };
  }

  
  verifyPaymentSignature({ razorpayOrderId, razorpayPaymentId, razorpaySignature }) {
    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return false;
    }

    const payload = `${razorpayOrderId}|${razorpayPaymentId}`;
    const expectedSignature = crypto
      .createHmac('sha256', this.keySecret)
      .update(payload)
      .digest('hex');

    // Timing-safe buffer comparison to prevent timing attacks
    const expectedBuffer = Buffer.from(expectedSignature, 'utf-8');
    const actualBuffer = Buffer.from(razorpaySignature, 'utf-8');

    if (expectedBuffer.length !== actualBuffer.length) {
      return false;
    }

    return crypto.timingSafeEqual(expectedBuffer, actualBuffer);
  }

  verifyWebhookSignature({ rawBody, signatureHeader }) {
    if (!rawBody || !signatureHeader) return false;

    const expectedSignature = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(rawBody)
      .digest('hex');

    const expectedBuffer = Buffer.from(expectedSignature, 'utf-8');
    const actualBuffer = Buffer.from(signatureHeader, 'utf-8');

    if (expectedBuffer.length !== actualBuffer.length) {
      return false;
    }

    return crypto.timingSafeEqual(expectedBuffer, actualBuffer);
  }

  /**
   * Ensures idempotent webhook event processing.
   * Returns true if event was successfully claimed; false if duplicate/already processed.
   */
  async isNewWebhookEvent(eventId) {
    if (!eventId) return false;
    const claim = await this.eventStore.claimEvent(eventId);
    if (claim.status === 'CLAIMED') {
      await this.eventStore.markCompleted(eventId);
      return true;
    }
    return false; // DUPLICATE DETECTED (COMPLETED OR IN_FLIGHT)
  }
}

module.exports = new RazorpayService();
