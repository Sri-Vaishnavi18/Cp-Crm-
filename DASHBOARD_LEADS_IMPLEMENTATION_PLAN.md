# Implementation Plan: Dashboard Leads Section & UI Refinement

## 1. Objective
Based on your feedback and reference screenshot:
1. **Remove the Builder Announcements & Pre-Launches** carousel section completely from the Dashboard.
2. **Replace the "Live Milestone Activity Stream"** with a dedicated **"Leads"** section:
   - Display real lead names clearly (e.g. Deepak Verma, Ananya Iyer, Siddharth Mehta, Vikram Rao).
   - Remove verbose descriptive sentences.
   - Display structured lead metadata:
     - **Lead Full Name** & Circular Avatar (with initials/image)
     - **Stage Status Badge** (`SITE TOUR COMPLETE`, `VISIT SCHEDULED`, `NEW`, `TOKEN / BOOKED`, `CONTACTED`)
     - **Project Name** with building icon 🏢 (e.g., `Prestige Serenity Palms`)
     - **Configuration & Budget** (e.g., `3 BHK • ₹1 Cr - ₹1.5 Cr`)
     - **Timestamp / Date** (e.g., `Today 11:30 AM`, `Yesterday 2:15 PM`)
     - **Quick Actions**: Call button 📞 and `Project Details >` / `View Lead` link.
3. **Upgrade Pipeline Health**:
   - Refine the pipeline component to match the top card from your screenshot (`Pipeline Health` title, `6 Active Prospects` subtitle, connected timeline bar with circular stage nodes for `New`, `Contacted`, `Visit Set`, `Visit Done`, `Booked`).
4. **Seamless Date Filter Integration**:
   - The Leads list will dynamically filter according to the selected date filter (`Today`, `Yesterday`, `7 Days`, `30 Days`, or `Custom Range`).

---

## 2. Proposed Changes

### A. Shared Widgets (`lib/shared/widgets/app_widgets.dart`)
- **`PipelineFunnelBar` / `PipelineHealthBar`**:
  - Re-skin into the connected step timeline matching the screenshot:
    - Left header: `Pipeline Health`
    - Right header: `${total} Active Prospects`
    - Multi-colored connected progress track with round badge nodes for:
      - `1` **New** (Blue)
      - `👤` or count **Contacted** (Purple)
      - `1` **Visit Set** (Amber)
      - `2` **Visit Done** (Teal)
      - `1` **Booked** (Emerald Green)
- **`DashboardLeadItemCard`**:
  - Clean card layout with:
    - User circular avatar (initials with gradient or photo).
    - Header row: Bold Lead Name + Stage Badge (e.g. `SITE TOUR COMPLETE`, `VISIT SCHEDULED`).
    - Subtitle row: 🏢 Project Name `•` Timestamp (e.g. `Prestige Serenity • Today 11:30 AM`).
    - Tags row: Configuration (`3 BHK`), Budget (`₹1.2 Cr`), and quick action buttons.

### B. Dashboard Screen (`lib/features/dashboard/dashboard_screen.dart`)
- **Remove**:
  - Remove `Builder Announcements & Pre-Launches` section.
- **Replace Activity Stream**:
  - Add section header: **`Leads`** (on the left) + **`View All`** (on the right, jumps to Leads tab).
  - List `state.dashboardLeads` (takes the first 4-5 leads or date-filtered leads).
  - Show empty state illustration if no leads match the active date filter with a quick `Reset Filter` button.
- **Connect Pipeline Health**:
  - Render the upgraded `PipelineHealthBar` hooked to `state.funnelNewLeadsCount`, `state.funnelContactedCount`, etc.

### C. Testing & Verification
- Update unit/widget tests in `test/dashboard_filters_test.dart` and `test/widget_test.dart`.
- Run `flutter test` to ensure 100% test pass rate.

---

## 3. User Interface Visual Mockup

```
┌────────────────────────────────────────────────────────┐
│  Pipeline Health                   6 Active Prospects  │
│                                                        │
│   ( 1 )━━━━━( 👤 )━━━━━( 1 )━━━━━( 2 )━━━━━( 1 )       │
│    New    Contacted  Visit Set Visit Done   Booked     │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│  Leads                                       View All  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ (DV) Deepak Verma          [SITE TOUR COMPLETE]  │  │
│  │      🏢 Prestige Serenity • Today 11:30 AM       │  │
│  │      3 BHK • ₹1 Cr - ₹1.5 Cr                     │  │
│  │                                  Lead Details >  │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ (AI) Ananya Iyer            [VISIT SCHEDULED]    │  │
│  │      🏢 Prestige Serenity • Yesterday 2:15 PM    │  │
│  │      2 BHK, 3 BHK • ₹80 L - ₹1.2 Cr              │  │
│  │                                  Lead Details >  │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## 4. Verification Plan
- **Verification Command**: `flutter test`
- **Checklist**:
  1. Builder announcements section removed.
  2. Live activity stream replaced with structured Leads list.
  3. Lead cards show real lead names, stage badges, project name, budget/config, and timestamp.
  4. Date filtering (Today, Yesterday, 7D, 30D, Custom) updates the Leads list accordingly.
  5. All tests passing.
