/**
 * Generates responsive, email-client safe HTML for Order Confirmation.
 */
function renderOrderConfirmedTemplate({
  orderId,
  customerName = 'Valued Customer',
  orderDate = new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }),
  items = [],
  subtotal = 0,
  deliveryCharge = 0,
  discount = 0,
  total = 0,
  deliveryAddress = {},
  deliveryCode = '',
  supportEmail = 'support@marutistationery.com',
  supportPhone = '+91 98765 43210',
  storeAddress = 'Surat, Gujarat - 395007',
}) {
  const formattedOrderId = orderId.toUpperCase();
  const addressLine = [
    deliveryAddress.street,
    deliveryAddress.city,
    deliveryAddress.state,
    deliveryAddress.pincode,
  ].filter(Boolean).join(', ') || 'Address on file';

  const recipientName = deliveryAddress.name || customerName;
  const recipientPhone = deliveryAddress.phone || '';

  // Render item rows
  const itemRowsHtml = items.map((item, index) => {
    const itemName = item.name || 'Stationery Item';
    const itemQty = item.qty || 1;
    const itemPrice = ((item.price || 0) / 100).toFixed(2);
    const itemTotal = (((item.price || 0) * itemQty) / 100).toFixed(2);
    const isEven = index % 2 === 0;

    return `
      <tr style="background-color: ${isEven ? '#FFFFFF' : '#F8FAFC'};">
        <td style="padding: 12px 14px; font-size: 13.5px; color: #0F172A; border-bottom: 1px solid #E2E8F0; font-weight: 500;">
          ${itemName}
        </td>
        <td style="padding: 12px 14px; font-size: 13px; color: #475569; text-align: center; border-bottom: 1px solid #E2E8F0;">
          ${itemQty}
        </td>
        <td style="padding: 12px 14px; font-size: 13px; color: #475569; text-align: right; border-bottom: 1px solid #E2E8F0;">
          ₹${itemPrice}
        </td>
        <td style="padding: 12px 14px; font-size: 13.5px; color: #0F172A; text-align: right; font-weight: 700; border-bottom: 1px solid #E2E8F0;">
          ₹${itemTotal}
        </td>
      </tr>
    `;
  }).join('');

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Maruti Stationery Order #${formattedOrderId} is Confirmed!</title>
  <style>
    body { margin: 0; padding: 0; background-color: #FAF7EE; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; }
    table { border-collapse: collapse; }
    @media only screen and (max-width: 600px) {
      .container { width: 100% !important; padding: 12px !important; }
      .pin-box { font-size: 28px !important; letter-spacing: 6px !important; }
      .mobile-stack { display: block !important; width: 100% !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 24px 0; background-color: #FAF7EE;">

  <!-- Preheader Text (Hidden in body, visible in inbox preview) -->
  <div style="display: none; font-size: 1px; color: #FAF7EE; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden;">
    Your order is confirmed. Keep your delivery verification PIN safe.
  </div>

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAF7EE;">
    <tr>
      <td align="center">
        <!-- Main Card Container -->
        <table role="presentation" class="container" width="580" cellpadding="0" cellspacing="0" style="max-width: 580px; width: 100%; background-color: #FFFFFF; border-radius: 18px; overflow: hidden; box-shadow: 0 4px 18px rgba(15, 23, 42, 0.08); border: 1px solid #E2E8F0;">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, #173A9B 0%, #1E42BA 100%); padding: 30px 28px; text-align: center;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <div style="display: inline-block; width: 44px; height: 44px; line-height: 44px; background-color: #FFFFFF; border-radius: 12px; font-weight: 900; font-size: 22px; color: #173A9B; text-align: center; margin-bottom: 8px;">
                      M
                    </div>
                    <div style="color: #FFFFFF; font-size: 22px; font-weight: 800; letter-spacing: -0.3px; margin-top: 4px;">
                      Maruti Stationery
                    </div>
                    <div style="color: #FFC09F; font-size: 11.5px; font-weight: 600; text-transform: uppercase; letter-spacing: 1.2px; margin-top: 2px;">
                      Premium Stationery & Office Supplies
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Confirmation Badge & Greeting -->
          <tr>
            <td style="padding: 28px 28px 16px 28px;">
              <div style="display: inline-block; padding: 4px 12px; background-color: #EBF2FC; border-radius: 20px; font-size: 12px; font-weight: 700; color: #173A9B; margin-bottom: 12px;">
                ORDER CONFIRMED
              </div>
              <h1 style="margin: 0; font-size: 21px; font-weight: 800; color: #0F172A; line-height: 1.3;">
                Thank you for your order, ${customerName}! 🎉
              </h1>
              <p style="margin: 8px 0 0 0; font-size: 14px; color: #475569; line-height: 1.5;">
                We've received your order <strong>#${formattedOrderId}</strong> placed on <strong>${orderDate}</strong>. Our team is carefully packing your stationery essentials.
              </p>
            </td>
          </tr>

          <!-- PROMINENT DELIVERY VERIFICATION PIN BOX -->
          ${deliveryCode ? `
          <tr>
            <td style="padding: 10px 28px 20px 28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(180deg, #FAF7EE 0%, #FFFDF8 100%); border: 2px dashed #173A9B; border-radius: 16px; padding: 20px 18px; text-align: center;">
                <tr>
                  <td>
                    <div style="font-size: 11.5px; font-weight: 800; color: #173A9B; text-transform: uppercase; letter-spacing: 1.4px; margin-bottom: 6px;">
                      Your Delivery Verification PIN
                    </div>
                    <div class="pin-box" style="font-size: 32px; font-weight: 900; font-family: 'Courier New', Courier, monospace; letter-spacing: 8px; color: #173A9B; background-color: #FFFFFF; display: inline-block; padding: 8px 22px; border-radius: 12px; border: 1px solid #C7DCF8; margin: 4px 0 10px 0;">
                      ${deliveryCode}
                    </div>
                    <div style="background-color: #FFF3E0; border-left: 4px solid #FF681F; border-radius: 6px; padding: 10px 12px; text-align: left; margin-top: 10px;">
                      <div style="font-size: 12px; font-weight: 700; color: #B43403; display: flex; align-items: center;">
                        ⚠️ Important Delivery Security Rule:
                      </div>
                      <div style="font-size: 11.5px; color: #78350F; line-height: 1.4; margin-top: 2px;">
                        Share the PIN with the delivery partner <strong>only when your parcel physically arrives</strong> and is safely handed to you. Never share it over phone calls or messages.
                      </div>
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          ` : ''}

          <!-- Order Summary Section -->
          <tr>
            <td style="padding: 10px 28px 10px 28px;">
              <h2 style="margin: 0 0 12px 0; font-size: 15px; font-weight: 800; color: #0F172A; text-transform: uppercase; letter-spacing: 0.5px;">
                Items in Your Order
              </h2>
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border: 1px solid #E2E8F0; border-radius: 12px; overflow: hidden;">
                <thead>
                  <tr style="background-color: #F1F5F9;">
                    <th style="padding: 10px 14px; font-size: 11.5px; font-weight: 700; color: #475569; text-align: left; text-transform: uppercase; border-bottom: 1px solid #CBD5E1;">Item</th>
                    <th style="padding: 10px 14px; font-size: 11.5px; font-weight: 700; color: #475569; text-align: center; text-transform: uppercase; border-bottom: 1px solid #CBD5E1;">Qty</th>
                    <th style="padding: 10px 14px; font-size: 11.5px; font-weight: 700; color: #475569; text-align: right; text-transform: uppercase; border-bottom: 1px solid #CBD5E1;">Price</th>
                    <th style="padding: 10px 14px; font-size: 11.5px; font-weight: 700; color: #475569; text-align: right; text-transform: uppercase; border-bottom: 1px solid #CBD5E1;">Total</th>
                  </tr>
                </thead>
                <tbody>
                  ${itemRowsHtml}
                </tbody>
              </table>
            </td>
          </tr>

          <!-- Price Breakdown Table -->
          <tr>
            <td style="padding: 12px 28px 20px 28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="55%"></td>
                  <td width="45%">
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #475569;">Subtotal:</td>
                        <td style="padding: 4px 0; font-size: 13px; color: #0F172A; text-align: right; font-weight: 600;">₹${(subtotal / 100).toFixed(2)}</td>
                      </tr>
                      ${discount > 0 ? `
                      <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #16A34A;">Discount:</td>
                        <td style="padding: 4px 0; font-size: 13px; color: #16A34A; text-align: right; font-weight: 700;">-₹${(discount / 100).toFixed(2)}</td>
                      </tr>
                      ` : ''}
                      <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #475569;">Delivery Charge:</td>
                        <td style="padding: 4px 0; font-size: 13px; color: #0F172A; text-align: right; font-weight: 600;">
                          ${deliveryCharge > 0 ? `₹${(deliveryCharge / 100).toFixed(2)}` : '<span style="color: #16A34A; font-weight: 700;">FREE</span>'}
                        </td>
                      </tr>
                      <tr>
                        <td colspan="2" style="padding-top: 6px;"><div style="border-top: 1px solid #E2E8F0;"></div></td>
                      </tr>
                      <tr>
                        <td style="padding: 8px 0; font-size: 15px; font-weight: 800; color: #0F172A;">Total Paid:</td>
                        <td style="padding: 8px 0; font-size: 17px; font-weight: 900; color: #173A9B; text-align: right;">₹${(total / 100).toFixed(2)}</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Delivery Address Box -->
          <tr>
            <td style="padding: 0 28px 24px 28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 12px; padding: 16px;">
                <tr>
                  <td>
                    <div style="font-size: 12px; font-weight: 800; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px;">
                      📍 Delivery Address
                    </div>
                    <div style="font-size: 13.5px; font-weight: 700; color: #0F172A;">
                      ${recipientName} ${recipientPhone ? `• ${recipientPhone}` : ''}
                    </div>
                    <div style="font-size: 13px; color: #475569; line-height: 1.4; margin-top: 2px;">
                      ${addressLine}
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Support & Footer -->
          <tr>
            <td style="background-color: #F1F5F9; padding: 22px 28px; text-align: center; border-top: 1px solid #E2E8F0;">
              <div style="font-size: 13px; font-weight: 700; color: #0F172A; margin-bottom: 4px;">
                Need help with your order?
              </div>
              <div style="font-size: 12.5px; color: #475569; line-height: 1.5;">
                Email us at <a href="mailto:${supportEmail}" style="color: #173A9B; text-decoration: none; font-weight: 600;">${supportEmail}</a> 
                ${supportPhone ? `or call <a href="tel:${supportPhone}" style="color: #173A9B; text-decoration: none; font-weight: 600;">${supportPhone}</a>` : ''}
              </div>
              <div style="font-size: 11px; color: #94A3B8; margin-top: 12px;">
                ${storeAddress}<br>© ${new Date().getFullYear()} Maruti Stationery. All rights reserved.
              </div>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
  `;
}

module.exports = {
  renderOrderConfirmedTemplate,
};

