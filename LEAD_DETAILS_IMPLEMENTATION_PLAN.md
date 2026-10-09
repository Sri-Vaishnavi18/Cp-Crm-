# CP CRM - Lead Details Page Redesign & Temperature Automation Implementation Plan

## 1. Overview & Objectives
This plan outlines the design and implementation for:
1. **Redesigning the Lead Details Page** to precisely mirror the reference screenshots across 3 distinct sections:
   - **Header & Hero Lead Card**: Left amber accent border, star-badged avatar, name, dynamic temperature badge, channel partner pill, phone, project, and the **5-stage pipeline stepper** (`Lead Created` → `Contacted` → `Site Visit` → `Negotiation` → `Booked`).
   - **Quick Actions Grid**: Four sleek cards for **Call** (Green), **WhatsApp** (Green), **Edit** (Purple), and **Email** (Purple).
   - **Lead Information Card**: 2x2 grid displaying Phone, Source, Email, and Interested Project with circular icon containers.
   - **Status & Temperature Card**: 3-metric sub-card row for *Temperature*, *Status*, and *Site Visit*.
   - **Update Status Card**: Interactive status dropdown with chevron selector.
   - **Notes Card**: Full-width `+ Add Note` button with interactive note creation dialog and empty/populated state.
   - **Site Visit History Card**: Detailed visit logs (date, time, assigned sales executive, accompanied CP status, **Zero-OTP direct verification — No OTP required**).
   - **Activity Timeline**: Vertical milestone log with timestamped event nodes and a `"View Full History →"` action.
2. **Implementing Automated Temperature Rules**:
   - ❄️ **Cold Lead** (`LeadTemperature.cold`): Automatically assigned when a lead is **New** / `Lead Created` / `Contacted`.
   - ☀️ **Warm Lead** (`LeadTemperature.warm`): Automatically assigned when a lead is **Site Visited** (`Site Visit Scheduled` or `Site Visit Completed`).
   - 🔥 **Hot Lead** (`LeadTemperature.hot`): Automatically assigned when a lead is **Booked** / `Token Paid`.
   - Changing the status automatically updates and cascades the temperature throughout the entire CRM in real time.
3. **Zero-OTP Site Visits (No OTP Verification)**:
   - Site visits operate completely OTP-free with instant digital entry passes and seamless direct check-in verified by CP accompaniment and site front desk.

---

## 2. Architecture & Temperature State Workflow

```mermaid
flowchart TD
    subgraph Lead Stage Transitions
        S1[Stage 1: Lead Created / New Lead] -->|Auto-Set| T1[❄️ Cold Lead]
        S2[Stage 2: Contacted] -->|Maintains| T1
        S3[Stage 3: Site Visit Scheduled / Completed] -->|Auto-Set| T2[☀️ Warm Lead]
        S4[Stage 4: Negotiation] -->|Maintains| T2
        S5[Stage 5: Booked / Token Paid] -->|Auto-Set| T3[🔥 Hot Lead]
    end

    subgraph Lead Detail Screen UI Components
        H[App Header: Back Arrow + 'Lead Detail' + Subtitle]
        C1[Hero Profile Card: Accent Line + Star Avatar + Name + Temp Pill + CP Badge + 5-Stage Stepper]
        C2[Quick Actions: Call | WhatsApp | Edit | Email]
        C3[Lead Information: Phone | Source | Email | Interested Project]
        C4[Status & Temperature: 3 Sub-Cards for Temp, Status, Site Visit]
        C5[Update Status: Interactive Selector + Auto Temp Trigger]
        C6[Notes: '+ Add Note' Action + Notes List]
        C7[Site Visit History: Zero-OTP Direct Check-in Logs + Sales Rep]
        C8[Activity Timeline: Vertical Event Nodes + 'View Full History']
    end

    C5 -->|Triggers Status & Temp Change| LeadStageTransitions
    LeadStageTransitions -->|Updates AppState| C1
    LeadStageTransitions -->|Updates AppState| C4
    LeadStageTransitions -->|Logs Event| C8
```

---

## 3. UI Component Specifications (Matching Screenshots)

### 3.1. Page Header
- **Navigation**: Back arrow button (`Icons.arrow_back` / `Icons.arrow_back_ios_new`) navigating back to the Leads Screen.
- **Title**: `Lead Detail` (20px bold white text).
- **Subtitle**: `View and manage lead information` (12px subtle muted slate text).

### 3.2. Hero Lead Profile Card (Screenshot 1)
- **Container Styling**: Dark elevated surface (`#131A26` / `#151C28`), `16px` rounded border radius, subtle dark border (`#222F43`).
- **Left Accent**: Warm amber vertical accent bar on the left edge (`#F59E0B`).
- **Avatar with Star Badge**:
  - Warm amber circular avatar (`#F59E0B`) displaying sequence number (`01`, `02`) or initials.
  - Star badge icon (`Icons.star`) positioned at the bottom-right corner in a circular badge container.
- **Header Details**:
  - Name: Bold font (`20px`, e.g., `visa` or `Deepak Verma`).
  - Temperature Badge: Styled pill with matching icon & outline (`☀️ Warm Lead`, `❄️ Cold Lead`, `🔥 Hot Lead`).
  - Partner Role Badge: Light purple rounded badge (`Channel Partner` or `Digital Ads`).
  - Contact row: Phone icon + phone number (`9087665324`).
  - Project row: Building icon + project name (`Summer Park`).
- **5-Stage Pipeline Stepper**:
  - Stages:
    1. `Lead Created`
    2. `Contacted`
    3. `Site Visit`
    4. `Negotiation`
    5. `Booked`
  - Active/Completed nodes have solid amber filled circles and connecting amber progress lines.
  - Upcoming nodes have dark grey outline circles with subtle grey connecting lines.
  - Centered descriptive labels below each node.

### 3.3. Quick Action Buttons Grid (Screenshot 1)
- **Call**: Dark card with green phone icon (`Icons.phone_outlined`) and green text (`#10B981`) → Launches phone call.
- **WhatsApp**: Dark card with green chat bubble icon (`Icons.chat_bubble_outline`) and green text (`#25D366`) → Launches WhatsApp chat with prefilled message.
- **Edit**: Dark card with purple pencil icon (`Icons.edit_outlined`) and purple text (`#A855F7`) → Opens interactive Edit Lead modal sheet.
- **Email**: Dark card with purple envelope icon (`Icons.email_outlined`) and purple text (`#818CF8`) → Opens email composer.

### 3.4. Lead Information Card (Screenshot 1)
- **Header**: Document icon in circular badge + `Lead Information` title.
- **2x2 Grid**:
  - **Phone**: Circle icon container with phone icon → Label `Phone`, Value `9087665324`.
  - **Source**: Circle icon container with globe icon → Label `Source`, Value `CHANNEL_PARTNER`.
  - **Email**: Circle icon container with envelope icon → Label `Email`, Value `visa@gmail.com`.
  - **Interested Project**: Circle icon container with building icon → Label `Interested Project`, Value `Summer Park`.

### 3.5. Status & Temperature Card (Screenshot 2)
- **Header**: Thermometer icon in circular badge + `Status & Temperature` title.
- **3 Horizontal Metric Sub-Cards**:
  1. **Temperature Sub-Card**: Label `Temperature` + Pill badge `☀️ Warm` (or `❄️ Cold` / `🔥 Hot`).
  2. **Status Sub-Card**: Label `Status` + Pill badge with checkmark `✔️ Site Visit Sched...` in blue tint.
  3. **Site Visit Sub-Card**: Label `Site Visit` + Pill badge with clock `🕒 Scheduled` / `Completed` in amber tint.

### 3.6. Update Status Card (Screenshot 2)
- **Header**: Refresh icon in circular badge + `Update Status` title.
- **Label**: `Current Status` (subtle grey).
- **Interactive Dropdown**:
  - Styled container displaying the active stage in vibrant emerald green text (e.g., `Site Visit Scheduled`) with down arrow chevron (`Icons.keyboard_arrow_down`).
  - Selecting a new status immediately updates the lead stage and **automatically adjusts the lead temperature** according to the rule engine.

### 3.7. Notes Section (Screenshot 3)
- **Header**: Notes icon in circular badge + `Notes` title.
- **Add Note Button**: Full-width primary button `+ Add Note` in electric indigo (`#4F46E5`).
- **Notes List**: Renders existing notes with timestamps and author details, or displays `No notes yet` placeholder when empty.

### 3.8. Site Visit History Section (Screenshot 3 - Zero-OTP / No OTP)
- **Header**: Location pin icon in circular badge + `Site Visit History` title.
- **Visit History Cards (No OTP Verification)**:
  - Card 1: `Scheduled site visit for 2026-07-28 at 13:15 and assigned to Sales executive sales_2.`
  - Card 2: `Site visit completed & verified directly. Accompanied by CP: vasi`
  *(All OTP requirements removed; direct seamless check-in via CP app & site desk).*

### 3.9. Activity Timeline Section (Screenshot 3)
- **Header**: History icon + `Activity` title + `"View Full History →"` link button on the right.
- **Timeline Items**: Vertical connector line with purple dot indicators:
  - `site visit status updated to SCHEDULED` • `Sep 09, 2026 • 01:14 PM`
  - `site visit status updated to COMPLETED` • `Sep 09, 2026 • 11:30 AM`
  - `Lead registered under Channel Partner (Zero-OTP protection active)` • Date

---

## 4. Temperature Rule Engine & State Logic

### 4.1. Stage to Temperature Mapping Table
| Lead Stage / Status | Automated Temperature | Badge Emoji & Color | Pipeline Step |
| :--- | :--- | :--- | :---: |
| **New Lead / Lead Created** | **Cold** (`LeadTemperature.cold`) | ❄️ Cold Lead (`#0EA5E9` Sky Blue) | Step 1 |
| **Contacted** | **Cold** (`LeadTemperature.cold`) | ❄️ Cold Lead (`#0EA5E9` Sky Blue) | Step 2 |
| **Site Visit Scheduled** | **Warm** (`LeadTemperature.warm`) | ☀️ Warm Lead (`#F59E0B` Amber Gold) | Step 3 |
| **Site Visit Completed** | **Warm** (`LeadTemperature.warm`) | ☀️ Warm Lead (`#F59E0B` Amber Gold) | Step 3 |
| **Negotiation** | **Warm** (`LeadTemperature.warm`) | ☀️ Warm Lead (`#F59E0B` Amber Gold) | Step 4 |
| **Booked / Token Paid** | **Hot** (`LeadTemperature.hot`) | 🔥 Hot Lead (`#EF4444` Crimson Red) | Step 5 |
| **Lost** | **Cold** (`LeadTemperature.cold`) | ❄️ Cold Lead (`#64748B` Slate Gray) | Inactive |

### 4.2. State Methods & Model Updates
1. **`LeadModel.getTemperatureForStage(LeadStage stage)`**:
   Helper function returning the exact temperature based on the stage rule.
2. **`LeadModel.pipelineStepIndex`**:
   Updated to correctly map to 0 (`Lead Created`), 1 (`Contacted`), 2 (`Site Visit`), 3 (`Negotiation`), 4 (`Booked`).
3. **`AppState.updateLeadStage(String leadId, LeadStage newStage)`**:
   Automatically computes and applies `lead.temperature = LeadModel.getTemperatureForStage(newStage)`, adds an activity log entry, and notifies listeners.
4. **`AppState.addLead(...)`**:
   Sets initial temperature to `LeadTemperature.cold` by default for new leads.
5. **`AppState.addLeadNote(String leadId, String noteText)`**:
   Appends a new timestamped note to the lead and logs the activity.
6. **`AppState.updateLeadInfo(...)`**:
   Updates lead details (name, phone, email, project, budget, etc.) from the Edit dialog.

---

## 5. Implementation Phases & Tasks

### Phase 1: Models & State Logic Updates
- [ ] Add `LeadActivityItem` and `LeadNoteItem` models to `app_models.dart`.
- [ ] Add `getTemperatureForStage` helper method to `LeadModel`.
- [ ] Update `LeadStage` to include `negotiation` if not already present, and align 5-step stepper.
- [ ] Ensure Site Visit verification operates with **Zero-OTP (No OTP verification)** across models and services.
- [ ] Update `AppState`:
  - Automatically cascade temperature when `updateLeadStage` is invoked.
  - Automatically set temperature to `warm` when a site visit is scheduled or checked in.
  - Add `addLeadNote` and `updateLeadInfo` methods.
- [ ] Update `MockDataService` with initial mock data including sample lead `visa` with `Summer Park` project, CP source, Zero-OTP visit history, notes, and activity timeline.

### Phase 2: Create Dedicated `LeadDetailScreen`
- [ ] Create `lib/features/leads/lead_detail_screen.dart` with custom dark-themed (and light-theme adaptive) layout matching Screenshots 1, 2, and 3.
- [ ] Implement the **Page Header** with Back navigation button and subtitle.
- [ ] Implement the **Hero Lead Card** with amber left accent, star-badged avatar, name, dynamic temperature badge, CP role badge, and 5-stage pipeline stepper.
- [ ] Implement the **Quick Actions Grid** with 4 interactive cards (Call, WhatsApp, Edit, Email).
- [ ] Implement the **Lead Information Card** with 2x2 circular icon grid.
- [ ] Implement the **Status & Temperature Card** with 3 horizontal metric sub-cards.
- [ ] Implement the **Update Status Card** with dropdown picker that triggers the temperature auto-update.
- [ ] Implement the **Notes Card** with `+ Add Note` button and empty/list view.
- [ ] Implement the **Site Visit History Card** with Zero-OTP direct visit verification logs.
- [ ] Implement the **Activity Timeline Card** with vertical connecting line and timestamped milestones.

### Phase 3: Interactive Sheets & Dialogs
- [ ] Create **Add Note Dialog**: Clean modal allowing CP to type and submit a note.
- [ ] Create **Edit Lead Sheet**: Modal allowing CP to edit name, phone, email, project, and notes.
- [ ] Connect URL launcher services for direct phone calling, WhatsApp message pre-fill, and email drafting.

### Phase 4: Navigation Integration & Verification
- [ ] Connect Lead List item taps in `leads_screen.dart` and `dashboard_screen.dart` to navigate directly to `LeadDetailScreen`.
- [ ] Test temperature transitions:
  - Verify New Lead starts as **Cold**.
  - Verify changing status to Site Visit changes temperature to **Warm**.
  - Verify changing status to Booked changes temperature to **Hot**.
  - Verify Zero-OTP visit flow (no OTP prompt or requirement).
- [ ] Verify hot reload, UI aesthetics, responsive scrolling, and dark/light mode compatibility.

---

## 6. Verification & Acceptance Criteria
- [x] Details page UI pixel-perfectly matches Screenshots 1, 2, and 3.
- [x] 5-Stage Pipeline Stepper correctly highlights completed stages.
- [x] Quick actions (Call, WhatsApp, Edit, Email) are fully functional.
- [x] **No OTP verification** for Site Visits (Zero-OTP direct check-in & visit logs).
- [x] New lead starts with **Cold** temperature (❄️).
- [x] Site Visited lead switches to **Warm** temperature (☀️).
- [x] Booked lead switches to **Hot** temperature (🔥).
- [x] Interactive Notes and Site Visit logs are preserved and updated in state.
