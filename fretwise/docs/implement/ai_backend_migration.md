# Fretwise AI Backend Migration Notes

## Purpose
This document is a practical guide for migrating Fretwise from mockup-driven state to Firebase-backed state.

## Current Status
The current Flutter app is still mostly mockup-driven:
- local app state is stored in memory
- several screens use static or random placeholder data
- no Firebase integration is wired yet
- AI replies are currently mocked in the chat UI

## Target Firebase Shape
- `users/{uid}`:
  - root account fields
  - embedded `profile` map
  - embedded `preferences` map
- `users/{uid}/songLibrary/{songId}`
- `users/{uid}/songProfiles/{songId}`
- `users/{uid}/songLibrary/{songId}/practiceMaterials/{materialId}`
- `users/{uid}/sessions/{sessionId}`
- `users/{uid}/practicePlans/{planId}`
- `users/{uid}/practiceDays/{dayId}`
- `users/{uid}/practiceTasks/{taskId}`
- `users/{uid}/feed/{feedItemId}`

## What Each Existing Mock Source Becomes
- in-memory `AppState` library data -> `users/{uid}/songLibrary`
- song-specific learning state -> `users/{uid}/songProfiles`
- in-memory diary entries -> `users/{uid}/sessions`
- hardcoded profile AI note -> `sessions/{sessionId}.sessionInfo.aiComment`
- hardcoded calendar circles and day states -> `users/{uid}/practiceDays`
- hardcoded today-plan and coming-up cards -> `practicePlans` + `practiceDays` + `practiceTasks`
- random add-song metadata -> `searchSong(...)` result persisted to `songLibrary/{songId}`
- mocked inspiration feed -> `users/{uid}/feed`
- mocked practice material -> `users/{uid}/songLibrary/{songId}/practiceMaterials`

## Model Refactor Notes
The current app models are simpler than the shared backend models. When moving from mockup to backend:
- create a `UserAccount` model for `users/{uid}` with embedded `profile` and `preferences`
- extend the current `Song` model into a backend-aligned `SongEntry`
- create a `SongProfile` model separate from `SongEntry`
- extend the current diary entry model into `SessionLog` plus nested `SessionInfo`
- add `practiceDate` and optional `planId` to session records
- add `PracticePlan`, `PracticeDay`, and movable `PracticeTask` models
- stop generating random song metadata in the UI
- stop hardcoding AI comments in the profile screen
- treat AI outputs as saved backend documents, not temporary widget state

## Screen-to-Backend Migration

### User and App State
- replace the current `AppState` user summary fields with Firestore reads from `users/{uid}`
- move `profile` and `preferences` into embedded maps on the user document

### Library and Inspiration
- replace local `extraSongs` and removed-song tracking with `songLibrary`
- when a song is added, write a `SongEntry` document and optionally initialize `SongProfile`
- replace static inspiration cards with `feed`

### Practicing
- load the active song from `songLibrary/{songId}`
- load learning state from `songProfiles/{songId}`
- read the active material from `songLibrary/{songId}/practiceMaterials`
- when AI refreshes material, create a new material document and mark previous active material inactive

### Session Complete and Profile
- on session completion, write a `sessions/{sessionId}` document
- include `practiceDate` so diary and day-detail screens can group sessions by date
- include nested `sessionInfo` for AI reflection
- update the matching `songProfile` and root user summary fields if needed

### Calendar and Home
- store plan-level info in `practicePlans`
- store one summary document per date in `practiceDays`
- store movable tasks in top-level `practiceTasks`
- reschedule tasks by updating `dayId` instead of moving documents
- derive home-page “today” content from active `PracticePlan`, today’s `PracticeDay`, and today’s `PracticeTask` records

## Suggested Write Ownership
- client writes:
  - user root fields that come directly from UI
  - simple UI flags if kept locally
  - explicit user actions such as like, dislike, archive, favorite
- backend function writes:
  - generated practice materials
  - generated session summaries
  - generated practice plans
  - preference updates inferred from AI workflows

This split is safer because AI-generated fields should be validated before saving.

## Recommended First Backend Slice
If implementation starts incrementally, the best first vertical slice is:
- Practicing Page
- Session Complete Page
- Profile Page

Reason:
- the flow already exists in the UI
- it forces definition of `SongProfile`, `SessionLog`, `SessionInfo`, and recording storage
- those models are later reused by calendar and AI personalization

## Suggested Implementation Order
1. Add Firebase Auth, Firestore, and Storage packages.
2. Create `users/{uid}` root with embedded `profile` and `preferences` maps.
3. Replace mock library with `songLibrary`.
4. Introduce `songProfiles` for learning-specific state.
5. Add song-nested `practiceMaterials`.
6. Replace session-complete diary flow with `sessions`.
7. Add `practicePlans` plus linked `practiceDays`.
8. Add top-level movable `practiceTasks`.
9. Add `feed`.

## Migration Checklist
- confirm the Firestore document paths match `firebase_schema.md`
- make sure `profile` and `preferences` are stored on `users/{uid}`, not as separate singleton documents
- make sure sessions include `practiceDate`
- make sure practice tasks use top-level `practiceTasks/{taskId}`
- make sure practice materials are nested under the song
- replace hardcoded profile diary AI text with `sessionInfo.aiComment`
- replace hardcoded calendar data with `practiceDays`
- replace hardcoded today/upcoming task UI with `practiceTasks`
