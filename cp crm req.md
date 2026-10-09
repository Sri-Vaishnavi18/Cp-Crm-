# CP CRM (Light Edition) — Mobile Application Requirements Specification

**Document Version:** 1.0.0  
**Target Platform:** Mobile Only (iOS & Android via Flutter)  
**Application Name:** **CP CRM**  
**Module Type:** Lightweight Channel Partner (CP) Field Management System  

---

## 1. Executive Summary & Objective

**CP CRM** is a dedicated, ultra-responsive, and streamlined mobile application built specifically for **Channel Partners (Real Estate Brokers, Realtors, and Partner Agencies)**. 

While enterprise real estate CRMs are often burdened by complex corporate hierarchies and cumbersome verification steps, **CP CRM Light** focuses purely on high-velocity field utility:
- Instant lead registration and duplicate protection
- Real-time project catalog and inventory availability
- Frictionless digital site visit scheduling
- 1-tap co-branded marketing collateral sharing via WhatsApp/Email
- Real-time client status tracking and builder announcements

---

## 2. Explicit Scope Definition: Exclusions vs. Inclusions

Per design mandate, CP CRM strips away administrative bottlenecks, verification delays, and accounting overhead.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CP CRM MOBILE SCOPE                              │
├──────────────────────────────────────┬──────────────────────────────────────┤
│       ❌ EXCLUDED MODULES             │       ✅ INCLUDED MODULES            │
│  (Omitted for Lightweight Agility)   │    (Optimized for Mobile Field Use)  │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ 1. Commissions & Payouts             │ 1. Frictionless Auth & Biometrics    │
│    - No commission slabs/rates       │ 2. Executive Mobile Dashboard        │
│    - No payout request workflows     │ 3. Instant Lead Registration         │
│    - No GST invoices / TDS claims    │ 4. Real-Time Pipeline Tracker        │
│ 2. OTP (One-Time Password) Friction  │ 5. Project Catalog & Unit Inventory  │
│    - No SMS OTP on Lead Entry        │ 6. 1-Tap Collateral & WhatsApp Kit   │
│    - No OTP on Login / Registration  │ 7. QR Site Visit Pass (No OTP)       │
│    - No OTP at Site Visit Reception  │ 8. Builder SPOC & Helpdesk           │
│ 3. CPSM Approval Workflow            │ 9. Push Notifications & Broadcasts   │
│    - No CPSM hierarchy / assignment  │ 10. Offline Media & Data Caching     │
│    - No in-person GPS check-in visit │                                      │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### 2.1 Detailed Explanation of Excluded Workflows

#### 1. No Commissions Workflow
*   **What is removed:** Commission slabs, tiered percentages, brokerage earnings dashboards, payout claim forms, GST invoice uploads, TDS deductions, and mandatory bank account validation for payouts.
*   **Why:** Commission settlements are financial accounting events handled centrally by builder finance teams or enterprise ERPs. Removing this from the CP mobile app eliminates UI clutter, reduces sensitive financial data exposure on mobile devices, and keeps the partner focused on closing deals.

#### 2. No OTP (One-Time Password) Friction
*   **What is removed:** 
    *   No SMS OTP verification for lead submission.
    *   No OTP verification required at the site visit reception desk (GRE desk).
    *   No OTP login barriers.
*   **Why:** In competitive real estate sales, requiring a prospective client to read out an SMS OTP while standing with a broker causes severe drop-offs, buyer hesitation, and awkward delays due to SMS gateway failures. CP CRM relies on algorithmic duplicate checks and digital QR visit passes instead.

#### 3. No CPSM (Channel Partner Sourcing Manager) Hierarchy Workflow
*   **What is removed:** Channel Partner Sourcing Manager assignment, CPSM performance reporting, mandatory in-person GPS selfie verification meetings by CPSMs for CP activation, and multi-tier internal approval matrices.
*   **Why:** Channel Partners should be empowered to register and begin sharing projects immediately. Partner vetting is direct, lightweight, and managed centrally without field sourcing bottlenecks.

---

## 3. Core Functional Requirements (Mobile Only)

### Module 1: Fast Authentication, Onboarding & Partner Profile
*   **1.1 Partner Registration:**
    *   Type selection: **Individual Realtor** or **Real Estate Agency / Firm**.
    *   Required inputs: Firm/Individual Name, RERA Registration Number, Contact Person Name, Primary Mobile Number, Email Address, City/State.
    *   Quick KYC Upload (Optional on signup, required for booking): Direct camera/gallery upload of RERA Certificate and Business Card.
*   **1.2 Frictionless Login:**
    *   Mobile Number / Email + Password login.
    *   **Biometric Quick Unlock:** Face ID (iOS) and Fingerprint/Biometrics (Android) via local device keychain.
    *   Persistent session token (JWT) with automatic background silent refresh.
*   **1.3 Sub-Broker / Team Management:**
    *   Agency owners can invite and register team members/sub-agents under their account.
    *   Sub-agents can register leads and schedule visits attributed to the parent agency.
*   **1.4 Partner Profile:**
    *   Editable contact information, firm logo upload, and office address.

---

### Module 2: Executive Mobile Dashboard
*   **2.1 Real-Time KPI Cards:**
    *   **Active Leads:** Current prospects actively engaged in discussion.
    *   **Site Visits Scheduled:** Upcoming visits for the week.
    *   **Visits Completed:** Prospects who successfully visited the project.
    *   **Bookings / Closures:** Total deals successfully booked.
*   **2.2 Pipeline Funnel:**
    *   Visual progress bar illustrating lead conversion across stages (New ➔ Visit Fixed ➔ Visit Done ➔ Negotiating ➔ Booked).
*   **2.3 Quick Action Floating Dock:**
    *   Prominent floating buttons for:
        *   `+ Add Lead` (Instant lead capture)
        *   `📅 Book Visit` (Schedule client site visit)
        *   `🏢 Projects` (Browse active inventory)
        *   `📤 Share Kit` (Quick-share project marketing deck)
*   **2.4 Builder Announcements Carousel:**
    *   High-impact banners displaying upcoming tower pre-launches, festival pricing, and priority inventory alerts.
*   **2.5 Chronological Activity Stream:**
    *   Live updates on client milestones (e.g., *"Rajesh Kumar completed site visit at Palm Meadows 20 mins ago"*).

---

### Module 3: Instant Lead Registration & Pipeline Management
*   **3.1 Fast Lead Entry Form:**
    *   Client Name (First Name, Last Name).
    *   Primary Mobile Number & Alternative Mobile Number.
    *   Email ID (Optional).
    *   Budget Range (e.g., ₹50L - ₹80L, ₹80L - ₹1.2Cr, ₹1.2Cr+).
    *   Preferred Configuration: Checkboxes for `1 BHK`, `2 BHK`, `3 BHK`, `4 BHK`, `Penthouse`, `Plot/Villa`.
    *   Target Project Selection (Dropdown of active builder projects).
    *   Expected Purchase Timeline: `Immediate (<15 days)`, `1 Month`, `3 Months`, `Exploring`.
    *   Notes & Specific Requirements (e.g., East facing, Higher floor).
*   **3.2 Algorithmic Duplicate Protection (Zero-OTP):**
    *   Instant validation on phone number input.
    *   If phone number already exists within an active protection window (e.g., 30–90 days), clear alert shows: *"Lead already active with another partner or direct walk-in"*.
    *   Prevents broker disputes without disturbing the prospective customer with OTPs.
*   **3.3 Lead Pipeline & Status Stages:**
    *   `NEW`: Lead registered by CP.
    *   `CONTACTED`: Presales / Sales connected with client.
    *   `VISIT_SCHEDULED`: Site visit date and time confirmed.
    *   `VISIT_COMPLETED`: Client visited project premises.
    *   `TOKEN_PAID / BOOKING`: Unit reserved / booking initiated.
    *   `LOST / INACTIVE`: Lead disqualified or bought elsewhere.
*   **3.4 1-Tap Field Communication:**
    *   Native phone dialer integration (`tel:`) to call client directly.
    *   Pre-configured WhatsApp message triggers (`https://wa.me/`) with project summaries.
    *   Direct SMS integration.
*   **3.5 Filter, Search & Grouping:**
    *   Instant search by client name or phone.
    *   Filter by: Project, Lead Stage, Budget, and Registration Date Range.

---

### Module 4: Project Catalog & Interactive Inventory Explorer
*   **4.1 Project Directory:**
    *   Grid and List views for `Ongoing`, `Ready to Move`, and `Upcoming Pre-Launch` developments.
    *   Key summary badges: Starting Price, Location, RERA Number, Handover Date.
*   **4.2 Project Details Screen:**
    *   High-resolution architectural renders & photo gallery.
    *   Interactive Google Maps integration (Distance from airport, metro, schools, tech parks).
    *   List of master amenities (Clubhouse, Swimming Pool, Gym, EV Charging, etc.).
    *   Approved Bank List (HDFC, SBI, ICICI, etc.) for client home loans.
*   **4.3 Real-Time Inventory & Unit Availability:**
    *   Tower & Floor Selector.
    *   Unit status badges:
        *   🟩 **Available** (Ready for booking)
        *   🟧 **Blocked** (Under temporary token hold)
        *   🟥 **Sold**
    *   Unit specs: Carpet Area, Super Built-up Area, Facing (East, West, North), Balcony count.
*   **4.4 Instant Mobile Cost Estimator:**
    *   Simple on-site calculator: Base Price + Floor Rise + Amenities + Parking + Estimated Stamp Duty & Registration.
    *   Generates an estimated quote that can be shared instantly as a clean text card via WhatsApp.

---

### Module 5: Co-Branded Marketing Collateral & 1-Tap Sharing
*   **5.1 Marketing Collateral Hub:**
    *   High-Definition E-Brochures (PDF).
    *   Floor Plans & Master Layout Plans (Images/PDFs).
    *   Pricing & Payment Schedule Sheets.
    *   Walkthrough Videos (YouTube / Cloud streaming).
    *   RERA & Government Clearances / Approvals.
*   **5.2 Dynamic Co-Branded Brochure Generation:**
    *   The app dynamically watermarks/stamps the Channel Partner’s Firm Name, Contact Person, and Phone Number on the cover and footer of digital brochures before sharing.
    *   Ensures prospective clients always call back the Channel Partner.
*   **5.3 Native OS Share Sheet:**
    *   1-tap native sharing via WhatsApp, WhatsApp Business, Telegram, Email, and AirDrop/Bluetooth.
*   **5.4 Offline Media Caching:**
    *   Downloaded brochures and floor plans are cached on the device storage (`Hive` / local cache) so brokers can present floor plans in basements or low-signal construction sites.

---

### Module 6: Site Visit Booking & Digital Entry Pass
*   **6.1 Site Visit Scheduling:**
    *   Select Lead from registered list (or quick-add new).
    *   Select Project and Preferred Date & Time Slot.
    *   Cab / Pickup Request toggle (if builder provides client pickup).
    *   Accompanying Status: `Accompanying Client` vs `Client Arriving Directly`.
*   **6.2 Frictionless Digital Visit Pass (Replaces OTP):**
    *   Generates a dynamic **Digital Visit Pass** with a scannable **QR Code** and unique Visit ID.
    *   When the client arrives at the site office, the reception desk (GRE) scans the QR code or types the Visit ID to mark attendance.
    *   **No SMS OTP required from the client.**
*   **6.3 Real-Time Visit Status Feed:**
    *   Push notification and status update triggered when:
        *   *Client checked in at site.*
        *   *Assigned Sales Executive.*
        *   *Visit completed with feedback summary.*

---

### Module 7: Builder SPOC Directory & Dedicated Helpdesk
*   **7.1 Project SPOC Directory:**
    *   Directory of assigned Project Sales Heads, Site Reception Desks, and Channel Partner Relations desks.
    *   1-tap direct Call and WhatsApp buttons.
*   **7.2 Quick Enquiry / Unit Hold Request:**
    *   Lightweight form to request a 24-hour temporary unit hold for a serious buyer while booking token is arranged.
    *   Simple ticket tracker for resolving broker enquiries.

---

### Module 8: Push Notifications & Alerts
*   **8.1 Critical Mobile Push Notifications:**
    *   Lead Status Updates (e.g., *"Lead Deepak Verma visited Palm Meadows"*).
    *   Visit Reminders (1 hour before scheduled site visit).
    *   New Project & Tower Launch Broadcasts.
    *   Flash Price Incentives & Limited Inventory Releases.
*   **8.2 In-App Notification Center:**
    *   Categorized alerts (Leads, Visits, System/Broadcasts).
    *   Deep-linking: Tapping a notification opens the exact lead or project screen.

---

## 4. Mobile User Experience (UI/UX) Specifications

*   **Platform Standards:** Full conformance with **iOS Human Interface Guidelines** and **Android Material 3 Design**.
*   **Ergonomics for Field Use:**
    *   All primary actions (Add Lead, Call, Share, Book Visit) placed in the bottom thumb zone.
    *   Pull-to-refresh on all lists and dashboards.
    *   Swipe actions: Swipe right on a lead to initiate Call; swipe left to open WhatsApp.
*   **Forms & Input Polish:**
    *   Mandatory minimum tap targets of 48×48 dp.
    *   Text input font size ≥ 16px to prevent iOS Safari / WebKit auto-zooming.
    *   Numerical keyboards automatically set for Phone, Budget, and RERA fields.
*   **Visual Aesthetics:**
    *   Modern glassmorphic / card-based architecture with subtle elevation.
    *   Theme support: System-aware **Light Mode** and **Dark Mode** (OLED optimized).
    *   Full support for iPhone Notch, Dynamic Island, and Android gesture navigation bars.

---

## 5. Technical Architecture & Tech Stack (Mobile Only)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       CP CRM MOBILE ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  UI Layer (Flutter):                                                        │
│  - Cupertino & Material 3 Widgets                                           │
│  - Custom Thumb-zone Navigation & Bottom Sheets                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  State Management:                                                          │
│  - Provider / Riverpod for reactive state & dependency injection            │
├─────────────────────────────────────────────────────────────────────────────┤
│  Networking & APIs:                                                         │
│  - Dio / Http with JWT Auth Bearer Interceptors & Auto-Retry                │
│  - Background Queue for Lead Sync                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  Local Persistence & Offline Cache:                                         │
│  - flutter_secure_storage: Encrypted tokens & credentials                   │
│  - Hive / SQLite: Projects, Collateral metadata & Recent Leads cache         │
│  - path_provider & open_filex: Local PDF brochure viewer & storage          │
├─────────────────────────────────────────────────────────────────────────────┤
│  Device Capabilities & Plugins:                                             │
│  - local_auth: Face ID & Fingerprint biometric login                        │
│  - url_launcher: Native Phone (tel:), WhatsApp & Email launcher             │
│  - share_plus: Native iOS / Android Share Sheet for brochures               │
│  - qr_flutter / mobile_scanner: Digital Visit Pass generation               │
│  - firebase_messaging + flutter_local_notifications: Push alerts            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Required Dependencies (`pubspec.yaml` snippet):
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  local_auth: ^2.1.8
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  qr_flutter: ^4.1.0
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  flutter_pdfview: ^1.3.2
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^17.0.0
```

---

## 6. Backend API Integration Contracts

The mobile app integrates with existing backend services using simplified endpoints (stripping commission, OTP, and CPSM dependencies):

| Method | Endpoint | Description | Notes |
|---|---|---|---|
| `POST` | `/api/auth/token/` | Channel Partner Login | Returns JWT access & refresh tokens |
| `POST` | `/api/auth/register-cp/` | Direct CP Self-Registration | No CPSM assignment required |
| `GET` | `/api/cp/dashboard-light/` | KPI counts, recent activity, alerts | Stripped of commission cards |
| `GET` | `/api/cp/leads/` | List all leads registered by CP | Supports search, stage & date filters |
| `POST` | `/api/cp/leads/` | Register new lead | Algorithmic duplicate check (No OTP) |
| `GET` | `/api/cp/leads/{id}/` | Detailed lead history & notes | Timeline view |
| `GET` | `/api/projects/` | Active projects catalog | Includes photos, amenities, brochures |
| `GET` | `/api/projects/{id}/inventory/` | Tower & unit live availability | Available / Blocked / Sold |
| `POST` | `/api/cp/site-visits/` | Schedule site visit | Generates Visit ID & QR code (No OTP) |
| `GET` | `/api/cp/site-visits/` | List upcoming and past visits | Real-time status tracker |
| `GET` | `/api/cp/documents/` | Project marketing collaterals | PDFs, images, price lists |
| `POST` | `/api/notifications/register-device/` | Register FCM/APNs push token | Mobile push delivery |

---

## 7. Quality & Security Assurance

1.  **Zero OTP Fallback Security:** Because client OTPs are eliminated, broker-stealing is prevented through **cryptographic timestamping and phone number deduplication rules** enforced on the server.
2.  **Encrypted Token Storage:** JWT tokens and refresh credentials must always be stored in the iOS Keychain and Android Keystore via `flutter_secure_storage`.
3.  **Graceful Low Connectivity Handling:**
    *   If a broker registers a lead while in an underground parking lot or low-signal construction zone, the app stores the lead in a local offline queue and syncs automatically once network connectivity resumes.
4.  **Privacy & Permissions (`Info.plist` / `AndroidManifest.xml`):**
    *   `NSCameraUsageDescription`: For uploading RERA certificates and business cards.
    *   `NSPhotoLibraryUsageDescription`: For selecting existing documents or photos.
    *   `LSApplicationQueriesSchemes`: Configured for `whatsapp`, `tel`, `mailto`, and `sms`.

---

## 8. Summary of Advantages of CP CRM Light

1. **10x Faster Onboarding:** Brokers install the app, enter basic details, and start registering leads in under 2 minutes without waiting for a CPSM physical meeting.
2. **Zero Client Discomfort:** No awkward OTP demands from high-net-worth clients during casual conversations or first introductions.
3. **Dedicated & Uncluttered:** Eliminates complex finance and commission disputes from the mobile app, providing an agile, high-converting deal closure companion for the field.
