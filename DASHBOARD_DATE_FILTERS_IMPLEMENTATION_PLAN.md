# CP CRM - Dashboard UI Redesign & Dynamic Date Filtering Plan

## 1. Executive Summary
This document outlines the detailed implementation plan to:
1. **Redesign the Dashboard UI** to precisely match the reference screenshot provided by the user (custom 2x2 stat KPI cards with dual-icon headers, clean rounded off-white surfaces, updated header with SYNCED status pill, theme switch, notification badge, and partner avatar).
2. **Implement Interactive Date Range Filters** (`Today`, `Yesterday`, `7 Days`, `30 Days`, `📅 Custom Calendar Range`, and a `↺ Reset` button).
3. **Connect Dynamic Metrics**: Ensure all KPI counts (Active Leads, Visits Scheduled, Visits Completed, Bookings/Holds) and conversion pipeline metrics dynamically calculate and update in real-time according to the selected date filter.

---

## 2. Visual & Architectural Comparison

```mermaid
graph TD
    subgraph UI Layout Redesign
        A1[App Header: Briefcase Icon + Firm Name + RERA]
        A2[Top Right: SYNCED pill + Theme Toggle + Bell '4' + Avatar 'V']
        A3[Greeting: 'Welcome back, Vaishu ˇ' + '✔ REALTOR' pill]
        A4[Date Filter Bar: Today | Yesterday | 7 Days | 30 Days | 📅 Calendar | ↺ Reset]
        A5[2x2 KPI Cards: Dual-Icon Badges + Clean Bold Numbers]
        A6[Dynamic Pipeline Funnel & Activity Stream]
        A7[Bottom Nav with Active Pill Indicator + SPOC Headset FAB]
    end

    subgraph State & Date Engine
        B1[AppState: dashboardDateFilter]
        B2[Presets: Today, Yesterday, 7D, 30D, Custom]
        B3[DateRangePicker Integration]
        B4[Dynamic KPI Filtering Logic]
        B5[Reset Action: Restores Full Pipeline]
    end

    A4 --> B1
    B1 --> B4
    B4 --> A5
    B4 --> A6
```

---

## 3. Detailed Feature Specifications

### 3.1. Dashboard UI Overhaul (Matching Screenshot)
- **Top App Header**:
  - Left: Dark navy briefcase rounded icon (`Icons.business_center_rounded`).
  - Title: Channel Partner / Firm Name (`Vaishu` or dynamic logged-in CP).
  - Subtitle: `RERA: <RERA Number>`.
  - Right Actions:
    1. `SYNCED` status pill (emerald green outline with checkmark).
    2. Theme mode pill toggle (sun / moon).
    3. Notification bell with blue circular unread badge (`4`).
    4. Circular partner monogram avatar (`V` on deep navy background) with 1-tap profile sheet.
- **Greeting & Partner Pill**:
  - `Welcome back,` (subtle muted grey).
  - `<User Name> ˇ` (bold font with dropdown caret to switch accounts).
  - Purple badge on right: `✔ REALTOR` or `✔ AGENCY` (dynamic based on partner type).

### 3.2. 2x2 Stat KPI Cards (Dual-Icon Graphic Cards)
Each card features the distinct dual-icon presentation from the reference:
1. **Active Leads Card**:
   - Left: Pastel blue container with group icon (`Icons.people_alt_rounded`).
   - Right: Green rising bar chart graphic badge (`Icons.trending_up_rounded`).
   - Metric: Large bold number (e.g. `4`).
   - Title: `Active Leads`.
   - Subtext: `Zero-OTP protection locked` (emerald green text).
2. **Visits Scheduled Card**:
   - Left: Pastel amber container with calendar icon (`Icons.calendar_today_rounded`).
   - Right: Analog clock graphic badge (`Icons.access_time_filled_rounded`).
   - Metric: Large bold number (e.g. `1`).
   - Title: `Visits Scheduled`.
   - Subtext: `Digital passes generated` (golden amber text).
3. **Visits Completed Card**:
   - Left: Pastel emerald container with checklist icon (`Icons.fact_check_rounded`).
   - Right: Verification seal badge (`Icons.verified_rounded`).
   - Metric: Large bold number (e.g. `1`).
   - Title: `Visits Completed`.
   - Subtext: `Site tours completed` (teal green text).
4. **Bookings / Holds Card**:
   - Left: Pastel mint container with ribbon badge (`Icons.workspace_premium_rounded`).
   - Right: Handshake & security shield graphic badge (`Icons.handshake_rounded`).
   - Metric: Large bold number (e.g. `1`).
   - Title: `Bookings / Holds`.
   - Subtext: `Deals closed / hold active` (cyan blue text).

---

### 3.3. Date Filters & Interactive Calendar System
- **Filter Bar Options**:
  - `All Time` (Default)
  - `Today` (Current day: 00:00 to 23:59)
  - `Yesterday` (Previous day: 00:00 to 23:59)
  - `7 Days` (Last 7 days from today)
  - `30 Days` (Last 30 days from today)
  - `📅 Custom Range` (Opens Flutter's native interactive `showDateRangePicker` dialog)
  - `↺ Reset` (Visible whenever a date filter is active, clears filter back to `All Time`)
- **Active Filter Indicator Banner**:
  - When a date range is active, displays a clean feedback pill (e.g., `Filtered: Oct 1, 2026 – Oct 8, 2026`).

---

## 4. State Management & Dynamic KPI Calculations

### 4.1. `AppState` Filtering Logic
```dart
enum DashboardDatePreset { allTime, today, yesterday, last7Days, last30Days, custom }

// Date range calculation
DateTimeRange? getDateRangeForPreset(DashboardDatePreset preset) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (preset) {
    case DashboardDatePreset.today:
      return DateTimeRange(start: todayStart, end: todayEnd);
    case DashboardDatePreset.yesterday:
      final yStart = todayStart.subtract(const Duration(days: 1));
      final yEnd = todayEnd.subtract(const Duration(days: 1));
      return DateTimeRange(start: yStart, end: yEnd);
    case DashboardDatePreset.last7Days:
      return DateTimeRange(start: todayStart.subtract(const Duration(days: 6)), end: todayEnd);
    case DashboardDatePreset.last30Days:
      return DateTimeRange(start: todayStart.subtract(const Duration(days: 29)), end: todayEnd);
    case DashboardDatePreset.custom:
    case DashboardDatePreset.allTime:
      return null;
  }
}
```

### 4.2. Filtered Dynamic Getters
- `int get filteredActiveLeadsCount`: counts leads created within the selected range with active stage.
- `int get filteredVisitsScheduledCount`: counts site visits scheduled within the selected range.
- `int get filteredVisitsCompletedCount`: counts site visits marked completed/checked-in within the range.
- `int get filteredBookingsCount`: counts leads moved to `tokenPaid` within the range.
- `Map<LeadStage, int> get filteredFunnelCounts`: updates the pipeline funnel bar dynamically.

---

## 5. File Modification Breakdown

| File Path | Action | Key Responsibilities |
| :--- | :--- | :--- |
| `lib/core/state/app_state.dart` | **Modify** | Add `DashboardDatePreset`, `dashboardDateRange`, `setDashboardDateFilter()`, `resetDashboardDateFilter()`, and dynamic date-filtered KPI getters. |
| `lib/shared/widgets/app_widgets.dart` | **Modify** | Update `StatKpiCard` with dual-icon badges (left pastel icon box + right custom graphic badge), and update `AppHeader` to match the reference layout. |
| `lib/features/dashboard/dashboard_screen.dart` | **Modify** | Implement horizontal date filter bar (`Today`, `Yesterday`, `7D`, `30D`, `Calendar`, `Reset`), date picker trigger, active date chip indicator, and connect to dynamic KPI cards. |

---

## 6. Verification & Acceptance Criteria
- [ ] Dashboard visual styling matches the provided screenshot (KPI cards, greeting, header elements).
- [ ] Tapping `Today` filters metrics to today's data.
- [ ] Tapping `Yesterday` filters metrics to yesterday's data.
- [ ] Tapping `7 Days` and `30 Days` filters metrics to their respective windows.
- [ ] Tapping `📅 Calendar` opens the date range picker; selecting custom dates recalculates all KPI cards and funnel metrics.
- [ ] Tapping `↺ Reset` restores the dashboard to `All Time` data.
- [ ] All unit and widget tests pass cleanly (`flutter test` = 0).
