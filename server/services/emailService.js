const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { transporter } = require('../config/email.config');
const idempotencyService = require('./idempotencyService');
const { renderOrderConfirmedTemplate } = require('../templates/orderConfirmed');
const { renderOrderDeliveredTemplate } = require('../templates/orderDelivered');

const MAX_RETRIES = parseInt(process.env.MAX_RETRY_ATTEMPTS || '3', 10);
const RETRY_DELAY_MS = parseInt(process.env.RETRY_DELAY_MS || '1500', 10);

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class EmailService {
  /**
   * Helper that executes an email send with safe exponential retry.
   */
  async _sendWithRetry(mailOptions, maxRetries = MAX_RETRIES) {
    let lastError = null;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const info = await transporter.sendMail(mailOptions);
        return { success: true, info, attempts: attempt };
      } catch (err) {
        lastError = err;
        console.warn(`⚠️ [EmailService] Send attempt ${attempt}/${maxRetries} failed: ${err.message}`);
        if (attempt < maxRetries) {
          const waitTime = RETRY_DELAY_MS * Math.pow(2, attempt - 1);
          await delay(waitTime);
        }
      }
    }
    throw lastError;
  }

  /**
   * Sends the Order Confirmation Email.
   * Trigger: Order successfully created and saved.
   */
  async sendOrderConfirmedEmail(data) {
    const {
      to,
      orderId,
      customerName,
      orderDate,
      items,
      subtotal,
      deliveryCharge,
      discount,
      total,
      deliveryAddress,
      deliveryCode,
    } = data;

    if (!to || !orderId) {
      throw new Error('Recipient email (to) and orderId are required.');
    }

    const eventType = 'order_confirmed';

    // 1. Duplicate Prevention Check
    if (idempotencyService.hasBeenSent(orderId, eventType)) {
      const existing = idempotencyService.getRecord(orderId, eventType);
      console.log(`ℹ️ [EmailService] Order confirmed email for #${orderId} already sent. Skipping duplicate.`);
      return {
        success: true,
        alreadySent: true,
        record: existing,
        message: `Email already sent previously for order #${orderId}`,
      };
    }

    // 2. Render HTML
    const html = renderOrderConfirmedTemplate({
      orderId,
      customerName,
      orderDate,
      items,
      subtotal,
      deliveryCharge,
      discount,
      total,
      deliveryAddress,
      deliveryCode,
      supportEmail: process.env.SUPPORT_EMAIL || 'support@marutistationery.com',
      supportPhone: process.env.SUPPORT_PHONE || '+91 98765 43210',
      storeAddress: process.env.STORE_ADDRESS || 'Surat, Gujarat - 395007',
    });

    const fromName = process.env.EMAIL_FROM_NAME || 'Maruti Stationery';
    const fromAddress = process.env.EMAIL_FROM_ADDRESS || process.env.GMAIL_USER || 'no-reply@marutistationery.com';

    const mailOptions = {
      from: `"${fromName}" <${fromAddress}>`,
      to,
      subject: `Your Maruti Stationery Order #${orderId.toUpperCase()} is Confirmed!`,
      html,
    };

    // 3. Mark in progress
    idempotencyService.recordEmailStatus({
      orderId,
      eventType,
      recipientEmail: to,
      status: 'in_progress',
    });

    // 4. Send with retry
    try {
      const result = await this._sendWithRetry(mailOptions);

      // 5. Record Success
      const record = idempotencyService.recordEmailStatus({
        orderId,
        eventType,
        recipientEmail: to,
        status: 'sent',
        providerResponse: {
          messageId: result.info.messageId,
          response: result.info.response,
          attempts: result.attempts,
        },
      });

      console.log(`✅ [EmailService] Order confirmed email sent to ${to} for #${orderId} (ID: ${result.info.messageId})`);
      return {
        success: true,
        alreadySent: false,
        messageId: result.info.messageId,
        record,
      };
    } catch (err) {
      // Record Failure
      idempotencyService.recordEmailStatus({
        orderId,
        eventType,
        recipientEmail: to,
        status: 'failed',
        error: err.message,
      });

      console.error(`❌ [EmailService] Failed to send order confirmed email to ${to} for #${orderId}:`, err.message);
      throw err;
    }
  }

  /**
   * Sends the Order Delivered Email.
   * Trigger: Order status successfully changes to delivered after PIN verification.
   * STRICT: Does NOT include the delivery PIN.
   */
  async sendOrderDeliveredEmail(data) {
    const {
      to,
      orderId,
      customerName,
      deliveredAt,
      deliveryAddress,
      itemCount,
    } = data;

    if (!to || !orderId) {
      throw new Error('Recipient email (to) and orderId are required.');
    }

    const eventType = 'order_delivered';

    // 1. Duplicate Prevention Check
    if (idempotencyService.hasBeenSent(orderId, eventType)) {
      const existing = idempotencyService.getRecord(orderId, eventType);
      console.log(`ℹ️ [EmailService] Order delivered email for #${orderId} already sent. Skipping duplicate.`);
      return {
        success: true,
        alreadySent: true,
        record: existing,
        message: `Delivered email already sent previously for order #${orderId}`,
      };
    }

    // 2. Render HTML
    const html = renderOrderDeliveredTemplate({
      orderId,
      customerName,
      deliveredAt,
      deliveryAddress,
      itemCount,
      supportEmail: process.env.SUPPORT_EMAIL || 'support@marutistationery.com',
      supportPhone: process.env.SUPPORT_PHONE || '+91 98765 43210',
      storeAddress: process.env.STORE_ADDRESS || 'Surat, Gujarat - 395007',
    });

    const fromName = process.env.EMAIL_FROM_NAME || 'Maruti Stationery';
    const fromAddress = process.env.EMAIL_FROM_ADDRESS || process.env.GMAIL_USER || 'no-reply@marutistationery.com';

    const mailOptions = {
      from: `"${fromName}" <${fromAddress}>`,
      to,
      subject: `Your Maruti Stationery Order #${orderId.toUpperCase()} Has Been Delivered!`,
      html,
    };

    // 3. Mark in progress
    idempotencyService.recordEmailStatus({
      orderId,
      eventType,
      recipientEmail: to,
      status: 'in_progress',
    });

    // 4. Send with retry
    try {
      const result = await this._sendWithRetry(mailOptions);

      // 5. Record Success
      const record = idempotencyService.recordEmailStatus({
        orderId,
        eventType,
        recipientEmail: to,
        status: 'sent',
        providerResponse: {
          messageId: result.info.messageId,
          response: result.info.response,
          attempts: result.attempts,
        },
      });

      console.log(`✅ [EmailService] Order delivered email sent to ${to} for #${orderId} (ID: ${result.info.messageId})`);
      return {
        success: true,
        alreadySent: false,
        messageId: result.info.messageId,
        record,
      };
    } catch (err) {
      // Record Failure
      idempotencyService.recordEmailStatus({
        orderId,
        eventType,
        recipientEmail: to,
        status: 'failed',
        error: err.message,
      });

      console.error(`❌ [EmailService] Failed to send order delivered email to ${to} for #${orderId}:`, err.message);
      throw err;
    }
  }
}

module.exports = new EmailService();

