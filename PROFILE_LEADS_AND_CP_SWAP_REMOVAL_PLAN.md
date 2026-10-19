# CP CRM - Profile Cleanup, CP Account Swapping Removal & Leads Menu Verification Implementation Plan

## 1. Executive Summary & Changes Made

1. **Profile Screen Menu Streamlined**:
   - **Removed**: `My Team`, `Performance`, and `Targets & Incentives` menu items along with their respective dividers from [`lib/features/profile/profile_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/profile/profile_screen.dart).
   - **Resulting Menu**: Displays only essential, high-value sections:
     1. `Notifications` (4)
     2. `KYC Documents & Invoices` (83% KYC)
     3. `Commissions & Payouts` (₹1.88 Lakhs)
     4. `Help & Support`
     5. `App Settings`
     6. `Logout`

2. **Channel Partner Account Swapper Removed**:
   - **Removed**: The entire `Switch Channel Partner Account` section (which listed other CPs on device like Rahul Sharma, Priya Nair, Vikram Seth with swap icons) from `UserProfileModalSheet` in [`lib/shared/widgets/app_widgets.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/shared/widgets/app_widgets.dart).
   - **Resulting Modal**: CPs can view their credentials, firm name, contact details, RERA scanner tile, and Commissions Ledger, leading directly to the `Sign Out from CP CRM` action without any account swapping mechanism.

3. **Leads Page 3-Dots Menu Verified**:
   - Confirmed in [`lib/features/leads/leads_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/leads/leads_screen.dart) that the 3-dots popup menu (`Icons.more_vert_rounded`) is completely removed from all lead cards.
   - Lead cards cleanly display customer name, configuration, project, and status pill badge (`COLD`, `SITE VISITED`, `BOOKED`), with `[Call]`, `[WhatsApp]`, and `[View Details]` buttons below.

---

## 2. Modified Files

| File | Changes |
| :--- | :--- |
| [`lib/features/profile/profile_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/profile/profile_screen.dart) | Removed `My Team`, `Performance`, and `Targets & Incentives` tiles and dividers. |
| [`lib/shared/widgets/app_widgets.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/shared/widgets/app_widgets.dart) | Removed `Switch Channel Partner Account` list and swap handlers from `UserProfileModalSheet`. |
| [`lib/features/leads/leads_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/leads/leads_screen.dart) | Verified clean lead card layout with no 3-dots menu. |

---

## 3. Verification

- Ran `flutter analyze`: **No issues found! (ran in 25.4s, 0 errors, 0 warnings)**.
