# Projects Page & Leads Page UI Optimization Implementation Plan

## 1. Executive Summary & Changes Made

1. **Projects Page Action Buttons Refactor**:
   - **Removed**: Redundant `[Units]` and `[Price List]` buttons from project cards.
   - **Added**: A clean, primary brand blue **`[Details]`** button (`Icons.visibility_outlined`) that opens the comprehensive `ProjectDetailScreen`.
   - **Enhanced**: Made the cover image tappable so clicking it also directly opens the project details.
   - **Resulting Action Row**: Three balanced buttons: `[Details]`, `[Brochure]`, and `[Share]`.
   - **Inside Project Details**: Clearly labeled **"Unit Inventory & Pricing Matrix"** where channel partners can filter by tower and status (Available, Blocked, Sold), and view each unit's configuration, carpet area, facing, floor, and **exact unit price** (`₹xx.xx Lakhs`).

2. **Leads Page - Removed 3-Dots Menu**:
   - **Removed**: The `PopupMenuButton` containing the 3-dots icon (`Icons.more_vert_rounded`) from each lead card header.
   - **Clean Layout**: The status badge (`COLD`, `SITE VISITED`, `BOOKED`, etc.) now sits neatly on the right edge of the card header without visual clutter.
   - **Retained**: Direct, high-intent action buttons (`[Call]`, `[WhatsApp]`, and `[View Details]`) at the bottom of each lead card.

---

## 2. Modified Files

| Target File | Modifications |
| :--- | :--- |
| [`lib/features/projects/projects_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/projects/projects_screen.dart) | Replaced `Units` and `Price List` with `Details`; balanced action buttons to 3 items; made cover image tappable. |
| [`lib/features/projects/project_detail_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/projects/project_detail_screen.dart) | Updated unit matrix section title to "Unit Inventory & Pricing Matrix". |
| [`lib/features/leads/leads_screen.dart`](file:///c:/Users/Y%20SRI%20VAISHNAVI/OneDrive/Desktop/CP%20CRM/lib/features/leads/leads_screen.dart) | Removed 3-dots popup menu from the lead card header and cleaned up unused helper method. |

---

## 3. Verification

- Ran `flutter analyze`: **No issues found! (ran in 20.8s, 0 errors, 0 warnings)**.
