const express = require('express');
const router = express.Router();
const emailService = require('../services/emailService');
const idempotencyService = require('../services/idempotencyService');

/**
 * POST /api/email/order-confirmed
 * Trigger: Order successfully created and saved.
 */
router.post('/order-confirmed', async (req, res) => {
  try {
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
    } = req.body;

    if (!to) {
      return res.status(400).json({ success: false, error: 'Customer email ("to") is required.' });
    }
    if (!orderId) {
      return res.status(400).json({ success: false, error: 'Order ID ("orderId") is required.' });
    }

    const result = await emailService.sendOrderConfirmedEmail({
      to,
      orderId,
      customerName,
      orderDate,
      items: items || [],
      subtotal: subtotal || 0,
      deliveryCharge: deliveryCharge || 0,
      discount: discount || 0,
      total: total || 0,
      deliveryAddress: deliveryAddress || {},
      deliveryCode: deliveryCode || '',
    });

    return res.status(200).json({
      success: true,
      message: result.alreadySent ? 'Email already sent previously (idempotent)' : 'Order confirmation email sent successfully',
      data: result,
    });
  } catch (err) {
    console.error('Error in /api/email/order-confirmed:', err);
    return res.status(500).json({
      success: false,
      error: err.message || 'Failed to send order confirmation email',
    });
  }
});

/**
 * POST /api/email/order-delivered
 * Trigger: Order status successfully changes to delivered after PIN verification.
 * STRICT: Does NOT accept or send the delivery PIN.
 */
router.post('/order-delivered', async (req, res) => {
  try {
    const {
      to,
      orderId,
      customerName,
      deliveredAt,
      deliveryAddress,
      itemCount,
    } = req.body;

    if (!to) {
      return res.status(400).json({ success: false, error: 'Customer email ("to") is required.' });
    }
    if (!orderId) {
      return res.status(400).json({ success: false, error: 'Order ID ("orderId") is required.' });
    }

    const result = await emailService.sendOrderDeliveredEmail({
      to,
      orderId,
      customerName,
      deliveredAt,
      deliveryAddress: deliveryAddress || {},
      itemCount: itemCount || 0,
    });

    return res.status(200).json({
      success: true,
      message: result.alreadySent ? 'Email already sent previously (idempotent)' : 'Order delivered email sent successfully',
      data: result,
    });
  } catch (err) {
    console.error('Error in /api/email/order-delivered:', err);
    return res.status(500).json({
      success: false,
      error: err.message || 'Failed to send order delivered email',
    });
  }
});

/**
 * GET /api/email/status/:orderId/:eventType
 * Query whether an email was sent for a specific order event.
 */
router.get('/status/:orderId/:eventType', (req, res) => {
  const { orderId, eventType } = req.params;
  const record = idempotencyService.getRecord(orderId, eventType);
  if (!record) {
    return res.status(404).json({ success: false, message: 'No email record found for this order event.' });
  }
  return res.status(200).json({ success: true, record });
});

module.exports = router;

