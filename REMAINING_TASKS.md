# AcadeME — Remaining Core Tasks (Firebase + Study Buddy Matching + Chat)

This document lists **all remaining tasks** needed to complete the app’s core functionality, with complete implementation details for:

- **Study Buddy matching (Tinder-like swipe)**
- **Real-time chat system**
- Firebase backend (Firestore/Storage/FCM/Cloud Functions) required to support them

---

## 0) Current state (what exists vs. what’s missing)

### What exists in the codebase
- **Authentication + profile persistence** via Firebase Auth + Firestore `users/{uid}` profile doc.
- UI placeholders:
  - `FindBuddyScreen` shows a **static card** and “like/dislike” buttons; no swipe deck; no backend.
  - `MatchDialog` always shows a match with “Maria”; opens `ChatScreen`.
  - `ChatScreen` is **hardcoded UI only** (static messages, no Firestore, no sending).

### What is missing (high-level)
- No implemented **Firestore schema** for swipes/matches/conversations/messages.
- No **security rules** files (Firestore/Storage) present in repo.
- No **Cloud Functions** project present in repo.
- No **FCM push notification** integration.
- No real swipe deck mechanics, candidate discovery, or mutual-match logic.

---

## 1) Firebase setup and infrastructure tasks

### 1.1 Enable / verify Firebase services in Firebase Console
- **Authentication**
  - Email/Password enabled (already used).
- **Cloud Firestore**
  - Create database.
  - Choose region (keep consistent with Storage/Functions for latency).
- **Firebase Storage**
  - Already used for profile photos; ensure bucket exists and rules will be defined.
- **Cloud Functions (2nd gen recommended)**
  - Enable billing if needed (many notification or scheduled functions require it).
- **Cloud Messaging (FCM)**
  - Enable for push notifications.

### 1.2 Add Firebase CLI + project configuration into repo
- Add a Firebase project config at repo root:
  - `firebase.json`
  - Firestore rules file (example: `firestore.rules`)
  - Storage rules file (example: `storage.rules`)
  - Optional: `firestore.indexes.json`
  - Optional: `functions/` folder (Cloud Functions code)

### 1.3 Local development support (optional but recommended)
- Configure Firebase emulators:
  - Auth emulator
  - Firestore emulator
  - Storage emulator
- Add a documented workflow:
  - How to run emulators
  - How to seed test users

---

## 2) Canonical Firestore data model (required)

This section defines a **recommended** schema for:
- user discovery
- swipes
- matches
- conversations
- messages
- reporting/blocking

> You can adjust names, but keep the invariants.

### 2.1 `users/{uid}` (already exists; extend it)
**Purpose**: primary profile used for discovery.

Required fields (add if missing):
- `uid`: string (optional, since doc id is uid)
- `fullName`: string
- `photoUrl`: string
- `age`: number
- `studentId`: string
- `birthday`: string

Add **matching/discovery fields**:
- `track`: string (e.g., STEM/ABM/HUMSS/TVL)
- `gradeLevel`: number (11/12)
- `subjectsInterested`: array<string>
  - Use curriculum titles or codes; be consistent.
- `studyGoals`: array<string> (e.g., “Exam prep”, “Homework”, “Projects”)
- `availability`: map
  - example: `{ days: ["Mon","Wed"], timeSlots: ["3:00 PM","4:30 PM"], timezone: "Asia/Manila" }`
- `bio`: string
- `location`: map (optional)
  - `{ campus: string, city: string }`
- `matchPreferences`: map
  - `{ sameTrackOnly: bool, gradeLevel: [11,12], subjects: [..], distanceKm: number }`
- `isDiscoverable`: bool (default true)
- `lastActiveAt`: timestamp
- `createdAt`: timestamp
- `updatedAt`: timestamp

**Important invariants**:
- Don’t store extremely sensitive info.
- Keep discovery fields queryable.

### 2.2 Swipe tracking
You need to prevent showing the same person repeatedly and to detect mutual likes.

Recommended structure:

#### Option A (simple): `users/{uid}/swipes/{otherUid}`
Document id: `otherUid`
Fields:
- `direction`: string enum: `like | nope | superlike`
- `createdAt`: timestamp

Pros:
- Simple security rules (only owner reads/writes)

Cons:
- Mutual-match check requires a read of the other user’s swipe.

#### Option B (scalable): top-level `swipes/{docId}`
Doc id: `${uid}_${otherUid}`
Fields:
- `fromUid`
- `toUid`
- `direction`
- `createdAt`

Pros:
- Easier to query/aggregate; can be used by Functions.

Cons:
- Rules slightly more complex.

### 2.3 Matches
A **match** exists when both users liked each other.

Recommended: top-level `matches/{matchId}`
- `matchId`: stable id derived from both uids: `minUid_maxUid`
Fields:
- `users`: array<string> length 2 (both uids)
- `createdAt`: timestamp
- `createdBy`: string (uid) (optional)
- `isActive`: bool (true)
- `lastMessageAt`: timestamp (optional, for sorting)
- `lastMessageText`: string (optional)
- `lastMessageSenderId`: string (optional)

### 2.4 Conversations (chat threads)
In a Tinder-like system, a conversation usually maps 1:1 to a match.

Recommended: `conversations/{conversationId}`
- `conversationId` can equal `matchId`.
Fields:
- `type`: `match_chat`
- `matchId`: string
- `participants`: array<string> length 2
- `createdAt`: timestamp
- `updatedAt`: timestamp
- `lastMessage`: map
  - `{ text: string, senderId: string, createdAt: timestamp, type: string }`
- `unreadCount`: map
  - `{ uid1: number, uid2: number }` (denormalized)
- `isActive`: bool

### 2.5 Messages
Store messages as a subcollection for each conversation.

`conversations/{conversationId}/messages/{messageId}`
Fields:
- `senderId`: string
- `type`: enum: `text | image | file | system`
- `text`: string (optional)
- `mediaUrl`: string (optional)
- `fileName`: string (optional)
- `fileSize`: number (optional)
- `createdAt`: timestamp
- `deletedFor`: array<string> (uids) (optional)
- `clientId`: string (idempotency token; optional)

### 2.6 Message read receipts (recommended)
Simplest:
- Maintain read state per conversation:

`conversations/{conversationId}`:
- `lastReadAt`: map `{ uid: timestamp }`

Or store:
`conversations/{conversationId}/reads/{uid}` doc:
- `lastReadAt`: timestamp

### 2.7 Blocking and reporting
Required for safety.

- `users/{uid}/blocks/{otherUid}`
  - `{ createdAt }`
- `reports/{reportId}`
  - `{ reporterUid, reportedUid, reason, createdAt, conversationId? }`

Blocking invariants:
- Blocked users cannot message or appear in discovery.

---

## 3) Firestore security rules (required)

### 3.1 Core rule requirements
- **Users**
  - A user can read their own doc.
  - Discovery reading can be allowed in a limited form (read-only subset) or through a server-mediated approach.
- **Swipes**
  - Only the swiping user can write their swipe.
- **Matches/Conversations/Messages**
  - Only participants can read.
  - Only participants can write messages.

### 3.2 Practical rule strategy
- Keep public discovery reads minimal.
- Use Cloud Functions to create matches and conversations.
- Enforce:
  - conversation participants cannot be changed by clients.
  - message sender must equal `request.auth.uid`.

### 3.3 Storage rules (chat attachments)
- Profile photos: `profile_photos/{uid}.jpg`
  - read can be public or authenticated-only.
  - write only by owner.
- Chat attachments: `chat_attachments/{conversationId}/{messageId}/{filename}`
  - write only by participants.
  - read only by participants.

---

## 4) Tinder-like “Find Study Buddy” system — ALL remaining tasks

### 4.1 Product behavior requirements
- **Discovery**
  - Show a stack of candidate student cards.
  - Each card includes: photo, name/age, track/grade, subjects, bio, availability.
- **Actions**
  - Swipe right = like
  - Swipe left = pass
  - Optional: super-like
- **Match**
  - If both users like each other, create a match and allow chat.
- **Safety**
  - Block/report from profile card and from chat.

### 4.2 Candidate discovery algorithm (client + query design)
Firestore can’t do complex ranking easily; start simple.

**Phase 1 (simple)**
- Query candidates by:
  - `isDiscoverable == true`
  - not current user
  - optional filters: `track`, `gradeLevel`
- Exclude already swiped:
  - Maintain a local set of swiped uids.
  - Fetch swipes subcollection once at screen load.
- Paginate:
  - Use `limit(20)` + `startAfterDocument`.

**Phase 2 (better matching)**
- Score candidates client-side:
  - overlap subjects
  - overlapping availability slots
  - same track/grade preferences
- Sort top N.

**Phase 3 (best scalability)**
- Use Cloud Functions to precompute “recommendations”
  - `users/{uid}/recommendations/{otherUid}` docs

### 4.3 Swipe deck UI tasks (Flutter)
- Replace placeholder card with a real swipe deck.
- Implement gestures:
  - drag threshold
  - animate off-screen
  - show like/nope overlay
- Implement buttons to trigger same actions programmatically.
- Loading states:
  - show skeleton while fetching candidates
  - empty state when no candidates

### 4.4 Profile card UI model
Create a consistent model for a “candidate summary”:
- uid
- displayName
- photoUrl
- age
- track
- gradeLevel
- subjectsInterested
- bio
- availability summary

### 4.5 Swipe write tasks
On swipe action:
- Write swipe record (subcollection or top-level swipe doc).
- Immediately remove candidate from local deck.
- Prevent duplicate writes with idempotency:
  - use `otherUid` as swipe doc id.

### 4.6 Mutual match creation (recommended Cloud Function)
**Goal**: prevent client-side race conditions and ensure consistent match creation.

Trigger options:
- Trigger on swipe write:
  - If `A` likes `B`, check if `B` already liked `A`.
  - If yes, create:
    - `matches/{matchId}`
    - `conversations/{conversationId}`
    - optional system message: “You matched!”

Idempotency:
- `matchId = minUid_maxUid`
- Use transaction to ensure single creation.

### 4.7 Match dialog + navigation
- `MatchDialog` must display:
  - both user photos
  - name
  - CTA: “Start Chat”
- Start Chat should open **Conversation-based** chat screen:
  - navigate with `conversationId`

### 4.8 Matches list screen (missing)
You need a screen listing all matches/conversations.

Features:
- List sorted by `lastMessageAt` / `createdAt`.
- Show:
  - other person avatar
  - name
  - last message preview
  - unread badge
- Tap opens chat.

---

## 5) Real-time Chat system — ALL remaining tasks

### 5.1 Required screens
- **Conversations list** (inbox)
- **Chat screen** (per conversation)
- **User profile preview** from chat header
- **Attachment picker UI** (image/file)

### 5.2 Replace placeholder `ChatScreen` with Firestore-backed implementation
Core tasks:
- Accept parameters:
  - `conversationId`
  - `otherUid`
- Stream messages:
  - query `conversations/{conversationId}/messages`
  - order by `createdAt desc`
  - paginate older messages
- Send message:
  - write a new message doc
  - update `conversations/{conversationId}.lastMessage`
  - increment unread count for other participant

### 5.3 Message types
Implement at minimum:
- `text`
- `image` (upload to Storage, then store URL)

Optional:
- `file` (pdf/doc)
- `system` (match created, session scheduled, etc.)

### 5.4 Uploading attachments
- Storage path:
  - `chat_attachments/{conversationId}/{messageId}/{filename}`
- Steps:
  - pick file/image
  - create message doc in “pending” state (optional)
  - upload to Storage
  - update message doc with `mediaUrl` and metadata

### 5.5 Read receipts / unread counts
Minimum viable:
- When user opens conversation:
  - set `lastReadAt[uid] = now`
  - set unread count for that uid to 0

### 5.6 Presence (online/last seen)
Options:
- Simple:
  - update `users/{uid}.lastActiveAt` on app foreground / periodic heartbeat
- Better:
  - use Realtime Database presence (more complex)

### 5.7 Push notifications (FCM)
- On new message:
  - Cloud Function triggers on message create
  - Determine recipient
  - Send FCM notification to recipient tokens

You need:
- Store device tokens:
  - `users/{uid}/fcmTokens/{token}`
- Token lifecycle:
  - add on login
  - remove on logout
  - handle token refresh

### 5.8 Moderation / abuse prevention
- Report user/message
- Block user:
  - should prevent:
    - discovery
    - future messages
    - (optional) hide conversation

### 5.9 Performance requirements
- Use pagination for messages.
- Avoid downloading large attachments automatically.
- Denormalize `lastMessage` into conversation doc.

---

## 6) Study Sessions integration (recommended)

### 6.1 Data model
`studySessions/{sessionId}`
Fields:
- `hostUid`
- `guestUid`
- `conversationId` (optional)
- `subjectCode` / `subjectTitle`
- `scheduledAt`: timestamp
- `status`: `pending | confirmed | completed | cancelled`
- `createdAt`

### 6.2 Chat integration
- In chat:
  - “Plan Study Session” creates a session request
  - Post a `system` message to chat
- In sessions screen:
  - show upcoming/past
  - confirm/cancel

---

## 7) App-wide remaining Firebase tasks (non-chat/non-matching)

### 7.1 Profile completeness gates
- Ensure users can’t enter matching/chat until:
  - profile exists
  - has required matching fields

### 7.2 Settings
- Manage:
  - discovery preferences
  - notification toggles
  - privacy (discoverable on/off)
  - blocked users list

### 7.3 Analytics / metrics (optional)
Track:
- swipe count
- match rate
- message sends

---

## 8) Implementation checklist (suggested milestones)

### Milestone A — Backend foundation
- Create Firestore schema + rules
- Create Storage rules
- Add indexes
- Add Cloud Functions skeleton

### Milestone B — Matching MVP
- Candidate discovery
- Swipe writes
- Mutual match function
- Matches list

### Milestone C — Chat MVP
- Conversations list
- Real-time messages
- Send text
- Read receipts + unread counts

### Milestone D — Attachments + Notifications
- Image upload
- FCM tokens
- Notifications on new messages

### Milestone E — Safety + polish
- Block/report
- Better recommendation scoring
- Presence

---

## 9) Testing / QA checklist

### Matching
- Swipe left/right persists and excludes swiped users
- Mutual like creates exactly one match + one conversation
- Match dialog shows correct user data

### Chat
- Messages appear in real-time
- Only participants can read/write
- Unread counts update correctly

### Notifications
- New message notification arrives for recipient

### Security
- Attempt unauthorized reads/writes should fail

---

## 10) Open questions (you should answer before implementation)
- **What should be the “matching basis”?**
  - Same track/grade only, or cross-track allowed?
- **What fields are required on the swipe card?**
- **Should chats exist only after match, or can users message without match?**
- **Do you want group study chats or only 1:1?**
- **Should curriculum selection be required for matching?**
