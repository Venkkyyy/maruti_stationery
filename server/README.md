# Maruti Stationery — Gmail Automation Service

Production Node.js + Express + Nodemailer microservice that handles automated transactional emails for Maruti Stationery order events via official Gmail SMTP.

## 1. Supported Email Triggers

### Email 1: Order Confirmation
* **Trigger:** Customer successfully places an order.
* **Subject:** `Your Maruti Stationery Order #{{order_id}} is Confirmed!`
* **Preheader:** `Your order is confirmed. Keep your delivery verification PIN safe.`
* **Key Features:**
  * Order items, quantities, unit prices, subtotal, discount, delivery fee, and total.
  * Prominent delivery verification PIN box.
  * Security warning: *Share the PIN with the delivery partner only when your parcel physically arrives.*
  * Delivery address and support contacts.

### Email 2: Order Delivered
* **Trigger:** Delivery partner verifies the 6-digit PIN and marks order `delivered`.
* **Subject:** `Your Maruti Stationery Order #{{order_id}} Has Been Delivered!`
* **Preheader:** `Your order has been delivered successfully. Thank you for shopping with us.`
* **Key Features:**
  * Delivery timestamp and delivery address.
  * Confirmation and appreciation message.
  * **Strict Security Rule:** Does **NOT** include the delivery verification PIN.

---

## 2. Setup & Configuration

### A. Generate a Google Gmail App Password
Gmail requires an **App Password** for SMTP authentication:
1. Open your Google Account: [https://myaccount.google.com/security](https://myaccount.google.com/security)
2. Ensure **2-Step Verification** is turned **ON**.
3. Under *2-Step Verification*, scroll down to **App passwords**.
4. In the app name field, enter `Maruti Stationery Server` and click **Create**.
5. Copy the generated **16-character code** (e.g. `abcd efgh ijkl mnop`).

### B. Configure `.env`
Edit `server/.env`:
```env
PORT=5001
GMAIL_USER=your-store-email@gmail.com
GMAIL_APP_PASSWORD=abcdefghijklmnop
EMAIL_FROM_NAME=Maruti Stationery
EMAIL_FROM_ADDRESS=your-store-email@gmail.com
SUPPORT_EMAIL=support@marutistationery.com
SUPPORT_PHONE=+91 98765 43210
STORE_ADDRESS=Surat, Gujarat - 395007
```

---

## 3. Running the Service

### Development Mode (auto-reloads on file changes)
```bash
cd server
npm run dev
```

### Production Mode
```bash
cd server
npm start
```

### Health Check
```bash
curl http://localhost:5001/health
```

---

## 4. API Endpoints

### 1. `POST /api/email/order-confirmed`
```json
{
  "to": "customer@gmail.com",
  "orderId": "MS-2026-001",
  "customerName": "Rahul Sharma",
  "orderDate": "31 Oct 2026",
  "items": [
    { "name": "Classmate Notebook (Pack of 6)", "qty": 2, "price": 36000 },
    { "name": "Reynolds Ball Pen 045", "qty": 5, "price": 5000 }
  ],
  "subtotal": 97000,
  "discount": 10000,
  "deliveryCharge": 0,
  "total": 87000,
  "deliveryAddress": {
    "name": "Rahul Sharma",
    "phone": "+91 9876543210",
    "street": "Flat 202, Vesu",
    "city": "Surat",
    "state": "Gujarat",
    "pincode": "395007"
  },
  "deliveryCode": "489201"
}
```

### 2. `POST /api/email/order-delivered`
```json
{
  "to": "customer@gmail.com",
  "orderId": "MS-2026-001",
  "customerName": "Rahul Sharma",
  "deliveredAt": "31 Oct 2026 at 02:45 PM",
  "deliveryAddress": {
    "name": "Rahul Sharma",
    "street": "Flat 202, Vesu",
    "city": "Surat"
  },
  "itemCount": 7
}
```

---

## 5. Duplicate Prevention & Resilience
* **Idempotency Guarantee:** Every order event is hashed as `${orderId}_${eventType}`. Duplicate requests return HTTP 200 with `{ alreadySent: true }` without re-sending emails.
* **Automatic Retry:** Transporter failures are retried up to 3 times using exponential backoff (`1.5s`, `3.0s`, `6.0s`).
* **Audit Trail:** Every send attempt is recorded in `server/email_logs.json` and in Firestore `/email_logs`.

