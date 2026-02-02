# AcadeME Admin Interface — Implementation Plan (Client-side)

This document defines a **separate Admin interface** for the AcadeME app.

Constraints / requirements:
- **Separate code folder** for admin UI.
- **Separate entrypoint** (new `main_admin.dart`) so the admin app can be run independently.
- **Hardcoded admin username + password** (for the admin login screen).
- **No Firebase Cloud Functions**.
- Admin interface must implement *all* features listed below (from the provided screenshot), with complete details.

---

## 1) Target folder structure (separate admin app)

Create a new folder under `lib/` so it doesn’t mix with the student app UI.

- `lib/admin_app/`
  - `admin_config.dart` (hardcoded admin username/password + admin UID list)
  - `admin_app.dart` (root `MaterialApp`)
  - `routing/admin_routes.dart`
  - `screens/`
    - `admin_login_screen.dart`
    - `admin_dashboard_screen.dart`
    - `user_management/`
      - `users_list_screen.dart`
      - `user_detail_screen.dart`
      - `user_edit_status_sheet.dart`
    - `profile_monitoring/`
      - `profile_audit_screen.dart`
      - `inappropriate_content_review_screen.dart`
    - `forum_moderation/`
      - `forum_overview_screen.dart`
      - `post_detail_screen.dart`
    - `match_monitoring/`
      - `matches_overview_screen.dart`
      - `match_detail_screen.dart`
    - `reports_blacklist/`
      - `reports_list_screen.dart`
      - `report_detail_screen.dart`
      - `warnings_suspensions_screen.dart`
    - `analytics/`
      - `analytics_dashboard_screen.dart`
      - `analytics_drilldown_screen.dart`
    - `feedback_ratings/`
      - `ratings_overview_screen.dart`
      - `user_ratings_screen.dart`
    - `academic_structure/`
      - `subjects_screen.dart`
      - `strands_screen.dart`
      - `grade_levels_screen.dart`
  - `services/`
    - `admin_auth_service.dart`
    - `admin_user_service.dart`
    - `admin_reports_service.dart`
    - `admin_forum_service.dart`
    - `admin_matches_service.dart`
    - `admin_analytics_service.dart`
    - `admin_academics_service.dart`
    - `admin_ratings_service.dart`
  - `widgets/`
    - `admin_shell.dart` (drawer / navigation rail)
    - `stat_card.dart`
    - `admin_table.dart`
    - `confirm_dialog.dart`
    - `filter_bar.dart`

New entrypoint file:
- `lib/main_admin.dart`

Running:
- Student app: `flutter run -t lib/main.dart`
- Admin app: `flutter run -t lib/main_admin.dart`

---

## 2) Admin Authentication (Feature #1)

### 2.1 Login behavior
- Show a dedicated login screen (`AdminLoginScreen`) with fields:
  - `username`
  - `password`
- Compare input to **hardcoded credentials** in `admin_config.dart`.
- If valid:
  - Create an in-memory session flag (and optionally persist using `shared_preferences` or `flutter_secure_storage`).
  - Navigate to `AdminDashboardScreen`.

### 2.2 Hardcoded credentials (required)
- Store in `admin_config.dart` as constants, e.g.
  - `const adminUsername = 'admin';`
  - `const adminPassword = 'academe_admin_2026';`

### 2.3 Firebase access requirement (production safety)
The admin app will need privileged Firestore read/write access. A purely hardcoded UI login **does not** secure Firestore.

Recommended approach (still no Cloud Functions):
- Create a dedicated Firebase Auth admin account manually in Firebase Console.
- In admin app, after passing hardcoded UI login, also call `FirebaseAuth.signInWithEmailAndPassword` using a **hardcoded admin email/password** (or prompt separately).
- In Firestore rules, allow admin privileges for:
  - specific admin UID(s) (`request.auth.uid in [ ... ]`).

This avoids Cloud Functions while ensuring Firestore isn’t publicly open.

---

## 3) Admin Navigation / Shell

### 3.1 Layout
Use an `AdminShell` layout with:
- Left `NavigationRail` (desktop/tablet) or `Drawer` (mobile)
- Routes:
  - Dashboard
  - User Management
  - Profile Monitoring
  - Forum Moderation
  - Match Monitoring
  - Reports / Blacklist
  - Analytics
  - Feedback & Ratings
  - Academic Structure

### 3.2 Access control
- Every admin screen checks admin session state (redirect to login if not authenticated).

---

## 4) Firestore model extensions needed for admin features

The current app already uses:
- `users/{uid}`
- `matches/{matchId}`
- `conversations/{conversationId}` + `messages` subcollection
- `reports/{reportId}`
- `studySessions/{sessionId}`
- `users/{uid}/swipes/{otherUid}`

Admin features require additional fields/collections:

### 4.1 Users: account state + moderation state
Add to `users/{uid}`:
- `isActive`: bool (default `true`) — used for activate/deactivate
- `suspendedUntil`: timestamp? (optional)
- `warningsCount`: number (default `0`)
- `lastWarningAt`: timestamp?
- `adminNotes`: string? (optional)

Client-side enforcement in student app:
- On app start / AuthGate, fetch user profile and block usage if `isActive == false` or `suspendedUntil > now`.

### 4.2 Reports: lifecycle fields
Extend `reports/{reportId}`:
- `status`: `open | reviewing | resolved | dismissed`
- `reviewedByAdminUid`: string?
- `reviewedAt`: timestamp?
- `actionTaken`: `none | warning | suspend | deactivate`
- `actionReason`: string?

### 4.3 Warnings / suspensions audit log
Create:
- `adminActions/{actionId}`
  - `adminUid`
  - `targetUid`
  - `type`: `warning | suspend | deactivate | reactivate | content_hide | content_delete | match_cancel | subject_add | subject_remove ...`
  - `payload`: map
  - `createdAt`

### 4.4 Forum content (required by Feature #4)
If not already present, create:
- `forumPosts/{postId}`
  - `authorUid`
  - `title`
  - `body`
  - `createdAt`
  - `updatedAt`
  - `isHidden`: bool
  - `isLocked`: bool
  - `hiddenReason`: string?
- `forumPosts/{postId}/comments/{commentId}`
  - `authorUid`
  - `text`
  - `createdAt`
  - `isHidden`: bool
  - `hiddenReason`: string?

### 4.5 Ratings / feedback (required by Feature #8)
Create:
- `ratings/{ratingId}`
  - `fromUid`
  - `toUid`
  - `sessionId` (optional)
  - `matchId` (optional)
  - `conversationId` (optional)
  - `rating`: number (1..5)
  - `comment`: string
  - `createdAt`

### 4.6 Academic structure (required by Feature #9)
Create admin-managed collections:
- `academic/subjects/{subjectId}`
  - `name`
  - `isActive`
  - `createdAt`
- `academic/strands/{strandId}`
  - `name` (e.g. STEM/ABM/HUMSS/TVL)
  - `isActive`
- `academic/gradeLevels/{gradeId}`
  - `value`: 11/12
  - `isActive`

---

## 5) Features specification (from screenshot)

### Feature #1 — Admin Authentication
**Goal:** secure admin login.

Admin UI must:
- Validate hardcoded username/password.
- Establish admin session.
- Provide logout.
- (Recommended) also sign into Firebase Auth admin account to unlock Firestore rules.

Acceptance criteria:
- Wrong credentials show error.
- Session persists until logout (optional persistence).
- Direct URL/route navigation redirects to login.

---

### Feature #2 — User Management
**Goal:** manage registered students.

#### 2.1 View all registered students
Screen: `UsersListScreen`
- Displays a paginated table/list of users from `users` collection.
- Columns:
  - Photo
  - Full Name
  - Grade Level
  - Strand/Track
  - Subjects Interested (summary)
  - Status (Active/Suspended/Deactivated)
  - Last Active

Firestore query:
- `FirebaseFirestore.instance.collection('users')`
- Order by `createdAt desc` or `updatedAt desc`.

#### 2.2 Search/filter by
- Name
- Grade level
- Strand
- Subject

Implementation details:
- Name search:
  - Option A (simple): client-side filtering on fetched page(s)
  - Option B (better): store `fullNameLowercase` and use prefix search.
- Grade/strand filter: Firestore `.where('gradeLevel', isEqualTo: X)` and `.where('track', isEqualTo: Y)`.
- Subject filter:
  - `.where('subjectsInterested', arrayContains: 'Subject Name')`

#### 2.3 Activate / deactivate accounts
- Action button in `UserDetailScreen`:
  - Deactivate: set `users/{uid}.isActive = false`
  - Activate: set `users/{uid}.isActive = true`
- Log to `adminActions`.

#### 2.4 Reset passwords
True password resets require Admin SDK (typically via Cloud Functions). Without Cloud Functions:
- Provide “Send password reset email” feature.
- Requires user email field in `users/{uid}` or query by auth email.

Implementation:
- Add `email` to user profile doc.
- Admin triggers `FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail)`.

Acceptance criteria:
- Admin can trigger password reset email.
- Confirmation dialog prevents accidental triggers.

---

### Feature #3 — Profile Monitoring
**Goal:** view student profiles and detect problematic content.

#### 3.1 View student profiles
Screen: `ProfileAuditScreen`
- Shows full profile details pulled from `users/{uid}`.
- Add quick flags:
  - Incomplete profile
  - Potentially inappropriate content

#### 3.2 Detect incomplete profiles
Rules for “incomplete” (align with existing Profile Completeness Gate):
- Missing photoUrl
- Missing track
- Missing bio
- Empty subjectsInterested

Implementation:
- Admin screen provides filter “Show incomplete only”.
- Derived fields are computed client-side.

#### 3.3 Detect inappropriate usernames/descriptions
No Cloud Functions constraint means detection is client-side:
- Implement keyword/regex scanning (admin-reviewed; not automatic deletion).
- Present highlights for:
  - `fullName`
  - `bio`
- Admin actions:
  - Warn user
  - Suspend user
  - Deactivate user
  - Add admin note

---

### Feature #4 — Forum Moderation
**Goal:** moderate posts and comments.

Screens:
- `ForumOverviewScreen`: list posts
- `PostDetailScreen`: view post + comments

#### 4.1 View all posts and comments
- List `forumPosts` ordered by `createdAt desc`.
- Post detail loads comments subcollection.

#### 4.2 Delete or hide inappropriate content
Actions:
- Hide post/comment: set `isHidden=true` and `hiddenReason`.
- Delete post/comment (optional): delete doc.

Recommendation:
- Prefer **hide** over delete to preserve audit trail.
- Log moderation actions to `adminActions`.

#### 4.3 Lock threads if needed
- Set `forumPosts/{postId}.isLocked=true`.
- Student app must block new comments if locked.

---

### Feature #5 — Match Monitoring
**Goal:** monitor and manage matching states.

#### 5.1 View active matches
Screen: `MatchesOverviewScreen`
- Query `matches` where `isActive == true`.

#### 5.2 View pending match requests
Interpretation without Cloud Functions:
- A “pending request” = one-sided like that has not become a match.

Implementation:
- Use `collectionGroup('swipes')` and filter `direction == 'like'`.
- Group by `(fromUid,toUid)` and check if reciprocal swipe exists (requires reads).

#### 5.3 View declined matches
Interpretation:
- “Declined” = swipe direction `nope`.

Implementation:
- `collectionGroup('swipes').where('direction', isEqualTo: 'nope')`.

#### 5.4 Cancel matches if needed
- Update `matches/{matchId}.isActive=false`.
- Optionally also set `conversations/{conversationId}.isActive=false`.
- Log `adminActions`.

---

### Feature #6 — Blacklist / Reporting System
**Goal:** review reported users and take action.

Screens:
- `ReportsListScreen`: list open reports
- `ReportDetailScreen`: full report context
- `WarningsSuspensionsScreen`: history + controls

#### 6.1 View reported users
- Query `reports` ordered by `createdAt desc`.
- Provide filters by `status`.

#### 6.2 Issue warnings
- Increment `users/{uid}.warningsCount` and set `lastWarningAt`.
- Add `adminActions` record.

#### 6.3 Temporarily suspend accounts
- Set `users/{uid}.suspendedUntil = now + duration`.
- Student app must block access until expiration.
- Add `adminActions` record.

Acceptance criteria:
- Admin can resolve report with an action.
- Users are effectively blocked by the student app UI when suspended.

---

### Feature #7 — System Analytics Dashboard
**Goal:** show high-level operational metrics.

Screen: `AnalyticsDashboardScreen`

Metrics required (from screenshot):
1. **Number of registered users**
2. **Daily/weekly active users**
3. **Number of matches per day**
4. **Most requested subjects**
5. **Match acceptance rate**

Implementation details (no Cloud Functions):
- Use Firestore aggregation queries when possible (`.count().get()`).
- Otherwise compute from queried docs with pagination.

Definitions:
- Registered users: count of `users`.
- DAU/WAU:
  - DAU: users where `lastActiveAt >= now - 1 day`
  - WAU: users where `lastActiveAt >= now - 7 days`
- Matches per day:
  - group `matches.createdAt` by day for a selected time range.
- Most requested subjects:
  - Option A: frequency from `users.subjectsInterested` across all users
  - Option B: frequency from `studySessions.subject`
- Match acceptance rate:
  - `#matchesCreated / #likesSent`
  - likesSent derived from `collectionGroup('swipes')` where direction == like.

UI elements:
- Date range picker
- Stat cards + charts (bar/line)
- Drilldowns (tap a card to open filtered lists)

---

### Feature #8 — Feedback & Ratings Overview
**Goal:** view match/session ratings and identify patterns.

Screen: `RatingsOverviewScreen`

Required features (from screenshot):
- View average match ratings
- Identify:
  1. High-performing students
  2. Repeatedly problematic users

Data source:
- `ratings` collection.

Definitions:
- Average rating:
  - per user: `avg(ratings where toUid == uid)`
  - per match: `avg(ratings where matchId == matchId)`
- High-performing:
  - users with `avgRating >= threshold` and `ratingCount >= minCount`
- Repeatedly problematic:
  - low avg rating OR high report count OR high warningsCount.
  - combine signals into a simple score.

Admin actions:
- View user rating history
- Open user profile
- Warn/suspend/deactivate

---

### Feature #9 — Academic Structure Management
**Goal:** manage subject list, strands, grade levels.

Screens:
- `SubjectsScreen`
- `StrandsScreen`
- `GradeLevelsScreen`

Required actions (from screenshot):
- Manage:
  1. Subject list
  2. Strands
  3. Grade levels
- Add/remove outdated subjects

Implementation details:
- CRUD operations on:
  - `academic/subjects`
  - `academic/strands`
  - `academic/gradeLevels`
- Use `isActive` rather than deletion for history.
- Student app should use these collections to populate dropdowns and filter UI.

---

## 6) Security rules plan (admin privileges)

Current rules restrict `users` reads to owner and disallow creating/updating matches and conversations by clients.

To enable admin interface safely:

### 6.1 Define admin UID allowlist
In `firestore.rules`:
- Add function `isAdmin()` that checks `request.auth.uid in [ADMIN_UID_1, ADMIN_UID_2]`.

### 6.2 Grant admin reads/writes
- `users/{uid}`:
  - allow admin to read all
  - allow admin to update moderation fields (`isActive`, `suspendedUntil`, `warningsCount`, `adminNotes`)
- `reports/{reportId}`:
  - allow admin to read/update report lifecycle fields
- `matches/{matchId}` and `conversations/{conversationId}`:
  - allow admin to update `isActive` for cancellation
- `forumPosts` and comments:
  - allow admin to hide/lock
- `academic/*`:
  - allow admin write

Note: This requires admin to be authenticated in Firebase Auth.

---

## 7) Milestones (implementation order)

1. Admin skeleton
- Create folder structure
- Create `main_admin.dart`
- Create login + admin shell navigation

2. User Management
- Users list + filters
- User detail + activate/deactivate + password reset email

3. Reports/Blacklist
- Reports list + report detail
- Warning + suspend + deactivate

4. Match Monitoring
- Active matches view
- Pending/declined via swipe collectionGroup
- Cancel match action

5. Analytics
- Stat cards + date ranges
- Basic charts

6. Feedback & Ratings
- Ratings ingestion (from student app)
- Admin overview + rankings

7. Forum Moderation
- Forum collections + admin moderation

8. Academic Structure
- Subjects/strands/grade levels CRUD

---

## 8) Notes / limitations (client-side only)

- **Resetting passwords**: only feasible as “send password reset email” without Admin SDK.
- **True admin security** requires Firebase Auth + rule checks (recommended). Hardcoded UI credentials alone are not secure.
- **Analytics at scale** may require indexes and/or pre-aggregation; for MVP, compute with aggregation queries and limited date ranges.

---

## 9) Definition of Done

Admin interface is considered complete when:
- Admin app launches via `lib/main_admin.dart` and shows login.
- All 9 features above exist as functional screens, backed by Firestore data.
- Admin actions update Firestore consistently and create `adminActions` logs.
- Student app respects account status (`isActive`, `suspendedUntil`).
- Firestore rules safely allow admin reads/writes only for admin UID(s).
