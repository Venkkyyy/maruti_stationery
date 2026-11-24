/**
 * Quick Test Script for Maruti Stationery Gmail Automation
 * 
 * Usage:
 *   node server/send_test_email.js [your_email@example.com]
 * 
 * Tests the Gmail SMTP connection and sends a sample real order confirmation.
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const { transporter } = require('./config/email.config');
const { renderOrderConfirmedTemplate } = require('./templates/orderConfirmed');
const { renderOrderDeliveredTemplate } = require('./templates/orderDelivered');

const recipientEmail = process.argv[2] || process.env.GMAIL_USER;

if (!recipientEmail || recipientEmail === 'your_gmail_app_password_here' || recipientEmail === 'marutistationery.orders@gmail.com') {
  console.log(`
======================================================================
  Maruti Stationery — Gmail Automation Test
======================================================================

To send a real test email to your inbox:
1. Make sure you set your GMAIL_USER and GMAIL_APP_PASSWORD in server/.env
2. Run:
   node server/send_test_email.js your_personal_email@gmail.com

======================================================================
`);
  process.exit(0);
}

async function runTest() {
  console.log(`Connecting to Gmail SMTP for ${process.env.GMAIL_USER}...`);

  try {
    await transporter.verify();
    console.log('✅ Connected to Gmail SMTP successfully!');
  } catch (err) {
    console.error('❌ Could not connect to Gmail SMTP:', err.message);
    console.log('\nPlease verify your GMAIL_USER and GMAIL_APP_PASSWORD in server/.env');
    process.exit(1);
  }

  console.log(`Sending sample Order Confirmation email to: ${recipientEmail}...`);

  const html = renderOrderConfirmedTemplate({
    orderId: 'MARUTI' + Math.floor(100000 + Math.random() * 900000) + 'ST',
    customerName: 'Valued Customer',
    orderDate: new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }),
    items: [
      { name: 'Classmate Spiral Notebook A4 (Pack of 4)', qty: 2, price: 32000 },
      { name: 'Reynolds 045 Fine Carbure Blue Pens (Box of 20)', qty: 1, price: 18000 },
      { name: 'Doms Erasable Colour Pencil Set (24 Shades)', qty: 1, price: 15000 },
    ],
    subtotal: 65000,
    deliveryCharge: 0,
    discount: 5000,
    total: 60000,
    deliveryAddress: {
      name: 'Valued Customer',
      phone: '+91 98765 43210',
      street: 'Flat 402, Shanti Heights, Vesu',
      city: 'Surat',
      state: 'Gujarat',
      pincode: '395007',
    },
    deliveryCode: String(Math.floor(100000 + Math.random() * 900000)),
    supportEmail: process.env.SUPPORT_EMAIL || 'support@marutistationery.com',
    supportPhone: process.env.SUPPORT_PHONE || '+91 98765 43210',
    storeAddress: process.env.STORE_ADDRESS || 'Surat, Gujarat - 395007',
  });

  try {
    const info = await transporter.sendMail({
      from: `"${process.env.EMAIL_FROM_NAME || 'Maruti Stationery'}" <${process.env.GMAIL_USER}>`,
      to: recipientEmail,
      subject: 'Your Maruti Stationery Order is Confirmed! (Live Test)',
      html,
    });

    console.log(`\n🎉 SUCCESS! Order Confirmed email delivered to ${recipientEmail}`);
    console.log(`Message ID: ${info.messageId}`);

    console.log(`\nSending sample Order Delivered email to: ${recipientEmail}...`);
    const deliveredHtml = renderOrderDeliveredTemplate({
      orderId: 'MARUTI' + Math.floor(100000 + Math.random() * 900000) + 'ST',
      customerName: 'Valued Customer',
      deliveredAt: new Date().toLocaleString('en-IN', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }),
      deliveryAddress: {
        name: 'Valued Customer',
        street: 'Flat 402, Shanti Heights, Vesu',
        city: 'Surat',
      },
      itemCount: 4,
      supportEmail: process.env.SUPPORT_EMAIL || 'support@marutistationery.com',
      supportPhone: process.env.SUPPORT_PHONE || '+91 98765 43210',
      storeAddress: process.env.STORE_ADDRESS || 'Surat, Gujarat - 395007',
    });

    const deliveredInfo = await transporter.sendMail({
      from: `"${process.env.EMAIL_FROM_NAME || 'Maruti Stationery'}" <${process.env.GMAIL_USER}>`,
      to: recipientEmail,
      subject: 'Your Maruti Stationery Order Has Been Delivered! (Live Test)',
      html: deliveredHtml,
    });

    console.log(`🎉 SUCCESS! Order Delivered email delivered to ${recipientEmail}`);
    console.log(`Message ID: ${deliveredInfo.messageId}`);
    console.log('\nBoth emails were sent successfully! Check your inbox.');
  } catch (err) {
    console.error('❌ Failed to send email:', err.message);
  }
}

runTest();

