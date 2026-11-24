/**
 * Generates responsive, email-client safe HTML for Order Delivered.
 * STRICT REQUIREMENT: Does NOT include the delivery PIN.
 */
function renderOrderDeliveredTemplate({
  orderId,
  customerName = 'Valued Customer',
  deliveredAt = new Date().toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }),
  deliveryAddress = {},
  itemCount = 0,
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

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Maruti Stationery Order #${formattedOrderId} Has Been Delivered!</title>
  <style>
    body { margin: 0; padding: 0; background-color: #FAF7EE; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; }
    table { border-collapse: collapse; }
    @media only screen and (max-width: 600px) {
      .container { width: 100% !important; padding: 12px !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 24px 0; background-color: #FAF7EE;">

  <!-- Preheader Text (Hidden in body, visible in inbox preview) -->
  <div style="display: none; font-size: 1px; color: #FAF7EE; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden;">
    Your order has been delivered successfully. Thank you for shopping with us.
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

          <!-- Delivered Success Badge -->
          <tr>
            <td align="center" style="padding: 32px 28px 12px 28px;">
              <div style="width: 64px; height: 64px; line-height: 64px; background-color: #DCFCE7; border: 2px solid #86EFAC; border-radius: 50%; font-size: 32px; text-align: center; margin-bottom: 16px;">
                ✅
              </div>
              <div style="display: inline-block; padding: 4px 12px; background-color: #DCFCE7; border-radius: 20px; font-size: 12px; font-weight: 800; color: #15803D; letter-spacing: 0.5px; margin-bottom: 10px;">
                PACKAGE DELIVERED
              </div>
              <h1 style="margin: 0; font-size: 22px; font-weight: 800; color: #0F172A; line-height: 1.3;">
                Your parcel has arrived, ${customerName}!
              </h1>
              <p style="margin: 10px 0 0 0; font-size: 14.5px; color: #475569; line-height: 1.6; max-width: 460px;">
                Your order <strong>#${formattedOrderId}</strong> ${itemCount > 0 ? `(${itemCount} items) ` : ''}has been successfully delivered and handed over following secure PIN verification.
              </p>
            </td>
          </tr>

          <!-- Delivery Details Card -->
          <tr>
            <td style="padding: 16px 28px 24px 28px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 14px; padding: 18px;">
                <tr>
                  <td style="padding-bottom: 12px; border-bottom: 1px solid #E2E8F0;">
                    <div style="font-size: 11.5px; font-weight: 700; color: #64748B; text-transform: uppercase; letter-spacing: 0.5px;">Order ID</div>
                    <div style="font-size: 14px; font-weight: 800; color: #0F172A; margin-top: 2px;">#${formattedOrderId}</div>
                  </td>
                  <td style="padding-bottom: 12px; border-bottom: 1px solid #E2E8F0; text-align: right;">
                    <div style="font-size: 11.5px; font-weight: 700; color: #64748B; text-transform: uppercase; letter-spacing: 0.5px;">Delivery Time</div>
                    <div style="font-size: 14px; font-weight: 700; color: #15803D; margin-top: 2px;">${deliveredAt}</div>
                  </td>
                </tr>
                <tr>
                  <td colspan="2" style="padding-top: 12px;">
                    <div style="font-size: 11.5px; font-weight: 700; color: #64748B; text-transform: uppercase; letter-spacing: 0.5px;">Delivered To</div>
                    <div style="font-size: 13.5px; font-weight: 600; color: #0F172A; margin-top: 2px;">${addressLine}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Feedback & Appreciation Note -->
          <tr>
            <td style="padding: 0 28px 24px 28px; text-align: center;">
              <div style="background-color: #FAF7EE; border-radius: 12px; padding: 16px 20px; border: 1px solid #E9E3D3;">
                <div style="font-size: 14px; font-weight: 700; color: #0F172A; margin-bottom: 4px;">
                  We hope you love your new stationery! ✏️ 📚
                </div>
                <div style="font-size: 12.5px; color: #475569; line-height: 1.5;">
                  If any item is missing, damaged, or not as expected, please reach out to our support team within 48 hours for hassle-free assistance or replacement.
                </div>
              </div>
            </td>
          </tr>

          <!-- Support & Footer -->
          <tr>
            <td style="background-color: #F1F5F9; padding: 22px 28px; text-align: center; border-top: 1px solid #E2E8F0;">
              <div style="font-size: 13px; font-weight: 700; color: #0F172A; margin-bottom: 4px;">
                Questions about your delivery?
              </div>
              <div style="font-size: 12.5px; color: #475569; line-height: 1.5;">
                Contact us anytime at <a href="mailto:${supportEmail}" style="color: #173A9B; text-decoration: none; font-weight: 600;">${supportEmail}</a> 
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
  renderOrderDeliveredTemplate,
};

