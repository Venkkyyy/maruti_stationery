const { describe, it } = require('node:test');
const assert = require('assert');
const crypto = require('crypto');
const razorpayService = require('../services/razorpayService');

describe('Razorpay Server-Side Payment Security Tests', () => {
  const testKeySecret = 'test_secret_1234567890abcdef';
  razorpayService.keySecret = testKeySecret;
  razorpayService.webhookSecret = 'test_webhook_secret_xyz';

  it('generates a valid Razorpay order structure server-side', async () => {
    const order = await razorpayService.createOrder({
      amountPaise: 49900,
      currency: 'INR',
      receipt: 'order_test_001',
    });

    assert.strictEqual(order.success, true);
    assert.strictEqual(order.amount, 49900);
    assert.strictEqual(order.currency, 'INR');
    assert.ok(order.orderId.startsWith('order_'));
  });

  it('rejects order creation with negative or zero amount', async () => {
    await assert.rejects(async () => {
      await razorpayService.createOrder({ amountPaise: -500 });
    }, /Invalid order amount/);

    await assert.rejects(async () => {
      await razorpayService.createOrder({ amountPaise: 0 });
    }, /Invalid order amount/);
  });

  it('cryptographically verifies valid Razorpay payment signature', () => {
    const razorpayOrderId = 'order_DA2918BA8219';
    const razorpayPaymentId = 'pay_921839218491';
    
    // Correct HMAC SHA256 signature
    const signature = crypto
      .createHmac('sha256', testKeySecret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    const isValid = razorpayService.verifyPaymentSignature({
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature: signature,
    });

    assert.strictEqual(isValid, true, 'Valid HMAC signature must verify as true');
  });

  it('rejects tampered or invalid Razorpay payment signature', () => {
    const razorpayOrderId = 'order_DA2918BA8219';
    const razorpayPaymentId = 'pay_921839218491';
    const tamperedSignature = 'deadbeef0123456789abcdef0123456789abcdef0123456789abcdef01234567';

    const isValid = razorpayService.verifyPaymentSignature({
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature: tamperedSignature,
    });

    assert.strictEqual(isValid, false, 'Tampered signature must be rejected');
  });

  it('prevents replay attacks by detecting duplicate webhook events', async () => {
    const eventId = `event_replay_test_${Date.now()}`;

    // First delivery — should be accepted as new
    const isNewFirstTime = await razorpayService.isNewWebhookEvent(eventId);
    assert.strictEqual(isNewFirstTime, true, 'First event must be treated as new');

    // Duplicate replay — MUST be rejected
    const isNewSecondTime = await razorpayService.isNewWebhookEvent(eventId);
    assert.strictEqual(isNewSecondTime, false, 'Replay of same eventId must be rejected as duplicate');
  });

  it('atomically detects in-flight duplicate webhook deliveries', async () => {
    const eventId = `event_inflight_${Date.now()}`;
    const claim1 = await razorpayService.eventStore.claimEvent(eventId);
    assert.strictEqual(claim1.status, 'CLAIMED');

    // Simultaneous duplicate arrival while first is still processing
    const claim2 = await razorpayService.eventStore.claimEvent(eventId);
    assert.strictEqual(claim2.status, 'IN_FLIGHT');
  });
});
