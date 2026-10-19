# Google Sheet License & Payment Control Setup

This guide shows you how to manage your Channel Partners' access and payments using a simple Google Sheet. You can update statuses right from your smartphone using the Google Sheets mobile app.

---

## Step 1: Create Your Google Sheet

1. Go to [Google Sheets](https://sheets.new) and create a new spreadsheet named **`CP CRM Licenses`**.
2. Set up row 1 with the following columns:

| Column A | Column B | Column C | Column D | Column E |
| :--- | :--- | :--- | :--- | :--- |
| **Phone** | **Name** | **Status** | **ValidUntil** | **Plan** |

3. Add your Channel Partners as rows. Example:

| Phone | Name | Status | ValidUntil | Plan |
| :--- | :--- | :--- | :--- | :--- |
| `9014547044` | Vaishu | `ACTIVE` | `2026-12-31` | Annual Pro |
| `9876543210` | Rahul Sharma | `INACTIVE` | `2026-10-15` | Monthly Plan |
| `9811223344` | Priya Nair | `PENDING` | `2026-11-30` | Starter Plan |

> **Accepted Status Values:**
> - `ACTIVE`: Full access granted to the CRM.
> - `INACTIVE`: Locks the app and requests payment.
> - `PENDING`: Shows "Account Under Review / Pending Approval".
> - If `ValidUntil` date is in the past, the app automatically switches to `EXPIRED`.

---

## Step 2: Add Google Apps Script (The API)

1. In your Google Sheet, click **Extensions** $\rightarrow$ **Apps Script**.
2. Delete any existing code in `Code.gs` and paste the following:

```javascript
function doGet(e) {
  var phoneParam = e.parameter.phone;
  if (!phoneParam) {
    return ContentService.createTextOutput(JSON.stringify({
      found: false,
      status: "INACTIVE",
      message: "Phone number parameter missing."
    })).setMimeType(ContentService.MimeType.JSON);
  }

  // Clean phone number (strip non-digits)
  var cleanPhone = phoneParam.replace(/[^\d]/g, '');

  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = sheet.getDataRange().getValues();

  // Row 0 is header: Phone | Name | Status | ValidUntil | Plan
  for (var i = 1; i < data.length; i++) {
    var rowPhone = String(data[i][0]).replace(/[^\d]/g, '');
    if (rowPhone === cleanPhone || rowPhone.endsWith(cleanPhone) || cleanPhone.endsWith(rowPhone)) {
      var name = data[i][1] || "Partner";
      var status = String(data[i][2] || "ACTIVE").toUpperCase().trim();
      var rawDate = data[i][3];
      var plan = data[i][4] || "Standard Plan";

      var validUntilStr = "";
      if (rawDate instanceof Date) {
        validUntilStr = Utilities.formatDate(rawDate, "GMT", "yyyy-MM-dd");
      } else if (rawDate) {
        validUntilStr = String(rawDate);
      }

      return ContentService.createTextOutput(JSON.stringify({
        found: true,
        phone: rowPhone,
        name: name,
        status: status,
        validUntil: validUntilStr,
        plan: plan,
        message: "Partner record verified."
      })).setMimeType(ContentService.MimeType.JSON);
    }
  }

  // If partner is not listed in sheet
  return ContentService.createTextOutput(JSON.stringify({
    found: false,
    status: "INACTIVE",
    message: "Partner number not found in approved licenses."
  })).setMimeType(ContentService.MimeType.JSON);
}
```

---

## Step 3: Deploy as Web App (1-Click)

1. In the top right corner of Apps Script, click **Deploy** $\rightarrow$ **New deployment**.
2. Click the gear icon next to "Select type" and choose **Web app**.
3. Fill in:
   - **Description**: `CP CRM License API`
   - **Execute as**: `Me (your email)`
   - **Who has access**: **`Anyone`** *(Crucial: allows the app to query status without Google login)*
4. Click **Deploy**.
5. Copy the **Web App URL** (looks like `https://script.google.com/macros/s/AKfycb.../exec`).

---

## Step 4: Configure the App

You can configure the URL directly in the app without rebuilding the APK:

1. Open the CP CRM app on any device.
2. If locked, or on the Lock Screen, tap the **Gear icon** in the top right corner (or tap the lock icon 5 times).
3. Paste your **Google Apps Script Web App URL**.
4. Set your Admin Phone number and WhatsApp number.
5. Tap **Save & Check**.

---

## How It Works in Everyday Use

* **Instant Access Control:** The moment a CP pays you (via UPI, cash, or transfer), open your Google Sheets app on your phone and change their status column to `ACTIVE`.
* **Automatic Expiry:** Set `ValidUntil` (e.g., `2026-12-31`). When that date arrives, the app locks automatically until renewal.
* **Offline Resilience:** If a CP is showing properties in a weak network zone, the app allows them to work offline for up to 8 hours. Whenever they regain 4G/Wi-Fi, it silently validates their status in 0.2 seconds without interrupting them.
