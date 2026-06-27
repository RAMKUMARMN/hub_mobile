# CixioHub API Integration Guide for Frontend

This guide outlines all the FastAPI backend endpoints relevant to the frontend team, detailing the HTTP methods, paths, request payloads, response data types, and authentication requirements.

---

## 🔐 Global API Details

- **Base URL:** `http://localhost:8000/api/v1` (Default local configuration)
- **Content-Type:** `application/json` (except for file/image uploads, which use `multipart/form-data`)
- **Authentication:** Most endpoints require a JWT bearer token. Include it in the headers of your requests:
  ```http
  Authorization: Bearer <your_access_token>
  ```

---

## 1. Authentication & Profile Management (`/auth`)

These endpoints manage user accounts, login/logout, OTP verification, and profiles.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/auth/register` | No | Creates a new student account. Automatically triggers a verification OTP email. |
| `POST` | `/auth/login` | No | Authenticate with credentials to receive Access & Refresh JWTs. |
| `POST` | `/auth/logout` | Yes | Revokes the provided refresh token and signs out the user. |
| `POST` | `/auth/verify-otp` | No | Verifies the 6-digit OTP code to activate the user account. |
| `POST` | `/auth/resend-otp` | No | Re-sends a new 6-digit verification OTP email to inactive accounts. |
| `POST` | `/auth/forgot-password`| No | Initiates password recovery (sends reset link to email). |
| `POST` | `/auth/reset-password` | No | Updates password using the verification token from the email. |
| `POST` | `/auth/refresh` | No | Exchanges a valid Refresh Token for a new Access + Refresh token pair. |
| `GET` | `/auth/me` | Yes | Retrieves current logged-in user profile details. |
| `PUT` | `/auth/profile` | Yes | Updates display name, phone number, and registers FCM/APNs push notification tokens. |
| `POST` | `/auth/avatar` | Yes | Uploads profile picture (`multipart/form-data`, JPEG/PNG/WebP, max 5 MB). |

### Data Contracts

#### Register Request (`POST /auth/register`)
```json
{
  "email": "student@tkmce.ac.in", // EmailStr (restricted to @tkmce.ac.in)
  "password": "securepassword123", // str
  "full_name": "John Doe", // str
  "phone": "+919876543210" // str | null (optional)
}
```

#### User Response
```json
{
  "id": "cdd36055-a904-441c-8125-ba563a3149d2", // uuid
  "email": "student@tkmce.ac.in", // str
  "full_name": "John Doe", // str
  "phone": "+919876543210", // str | null
  "avatar_url": "uploads/cdd36055.../profile.jpg", // str | null
  "is_admin": false, // bool
  "created_at": "2026-06-19T11:21:00Z" // datetime (ISO-8601)
}
```

#### Token Response (`POST /auth/login` & `POST /auth/refresh`)
```json
{
  "access_token": "eyJhbGciOi...", // str
  "refresh_token": "eyJhbGciOi...", // str
  "token_type": "bearer" // str
}
```

#### OTP Verify Request (`POST /auth/verify-otp`)
```json
{
  "email": "student@tkmce.ac.in", // EmailStr
  "otp": "123456" // str (6-digit code)
}
```

#### Password Reset Confirm Request (`POST /auth/reset-password`)
```json
{
  "token": "reset_token_from_email_query_string", // str
  "new_password": "newsecurepassword123" // str
}
```

#### Update Profile Request (`PUT /auth/profile`)
```json
{
  "full_name": "John Updated", // str | null (optional)
  "phone": "+910000000000", // str | null (optional)
  "device_token": "fcm_token_string_here" // str | null (optional)
}
```

---

## 2. Google OAuth (`/auth`)

OAuth flows for login using Google accounts.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/auth/google` | No | Redirects the client browser to Google's sign-in page. |
| `GET` | `/auth/google/callback`| No | Google redirects here with auth code. Backend authenticates and returns access/refresh tokens. |

---

## 3. AI Chat & RAG (`/chat`)

Manages conversational AI sessions and messaging.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/chat/sessions` | Yes | Starts a new chat session. |
| `GET` | `/chat/sessions` | Yes | Lists all chat sessions for the authenticated user, ordered by last update. |
| `DELETE`| `/chat/sessions/{id}`| Yes | Deletes a chat session and all its messages. |
| `GET` | `/chat/sessions/{id}/messages`| Yes | Retrieves all messages in a specific chat session (history). |
| `POST` | `/chat/sessions/{id}/messages`| Yes | **Streaming Endpoint**: Sends a message and streams the AI's response. |

### Sending a Message (Streaming Response)
- **Path:** `/api/v1/chat/sessions/{session_id}/messages`
- **Request Body (`SendMessageRequest`):**
```json
{
  "content": "What are the rules of TKM college?", // str
  "use_rag": true, // bool (set to true to enable RAG document query search)
  "thinking_mode": true // bool (set to true to enable DeepSeek step-by-step reasoning)
}
```
- **Response Format:** `text/event-stream` (Server-Sent Events)
- **Events Emitted:**
  1. **Sources Event** (only when `use_rag=true`, emitted first before tokens):
     ```http
     data: {"sources": [{"filename": "student_handbook.pdf", "text": "College rules include..."}]}
     ```
  2. **Reasoning Stream** (DeepSeek reasoning tokens, emitted if `thinking_mode=true`):
     ```http
     data: {"thinking": "Analyzing handbook rules..."}
     ```
  3. **Direct Answer Stream** (Standard content tokens):
     ```http
     data: {"delta": "According to the handbook, TKM college..."}
     ```
  4. **Completion Marker**:
     ```http
     data: [DONE]
     ```

---

## 4. Document Management (`/documents` & `/folders`)

Uploading documents for RAG, organizing them in folders, and listing/deleting them.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/documents/upload` | Yes | Uploads a document file (`multipart/form-data`, PDF/DOCX/TXT/JPEG/PNG, max 50 MB). Supports query param `?session_id=<uuid>` to scope to a specific chat session. |
| `GET` | `/documents/` | Yes | Lists all files uploaded by the authenticated user. |
| `DELETE`| `/documents/{id}` | Yes | Deletes a file, removing it from storage, purging vector indices, and database metadata. |
| `POST` | `/folders/` | Yes | Creates a new document folder. |
| `GET` | `/folders/` | Yes | Lists all document folders. |
| `DELETE`| `/folders/{id}` | Yes | Deletes a folder (removes folder reference from files without deleting the files themselves). |

### Document Responses
```json
{
  "id": "74ef57f5-0ecc-423f-b15b-72aad93c7af6", // uuid
  "session_id": "bf0721cb-e414-4607-ae6a-80df5ee55df2", // uuid | null
  "filename": "lecture_notes.pdf", // str
  "file_type": "pdf", // str
  "file_size": 245900, // int (bytes)
  "version": 1, // int (increments if the same filename is uploaded multiple times)
  "processed": false, // bool (check this to see if vector RAG indexing has finished)
  "created_at": "2026-06-19T11:15:32Z" // datetime
}
```

---

## 5. To-Dos & Subtasks (`/todos`)

Manages task tracking and reminders.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/todos/` | Yes | Lists all user to-dos. |
| `POST` | `/todos/` | Yes | Creates a new to-do item. |
| `PUT` | `/todos/{todo_id}` | Yes | Updates a to-do item's title, description, due date, priority, or reminder. |
| `PUT` | `/todos/{todo_id}/complete`| Yes | Toggles completion status of a to-do item. |
| `DELETE`| `/todos/{todo_id}` | Yes | Deletes a to-do item and all its subtasks. |
| `POST` | `/todos/{todo_id}/subtasks`| Yes | Creates a subtask. |
| `GET` | `/todos/{todo_id}/subtasks`| Yes | Lists all subtasks for a specific to-do item. |
| `PUT` | `/todos/{todo_id}/subtasks/{subtask_id}`| Yes | Updates a subtask title or toggles completion. |
| `DELETE`| `/todos/{todo_id}/subtasks/{subtask_id}`| Yes | Deletes a specific subtask. |

### To-Do Requests & Responses

#### Create To-Do Request
```json
{
  "title": "Submit assignment", // str (required)
  "description": "Lab report for ECE", // str | null (optional)
  "due_date": "2026-06-25T17:00:00Z", // datetime | null (optional)
  "priority": "high", // Literal["low", "medium", "high"] (default: "medium")
  "reminder_time": "2026-06-25T09:00:00Z" // datetime | null (optional)
}
```

#### Complete Toggle Request
```json
{
  "completed": true // bool
}
```

---

## 6. Personal Notes (`/notes`)

Manages student notes, tags, pinning/archiving, and note sharing.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/notes/` | Yes | Creates a new personal note. |
| `GET` | `/notes/` | Yes | Lists notes. Supports search/filter query parameters. |
| `GET` | `/notes/search` | Yes | Full-text query search for note titles/content. |
| `GET` | `/notes/{id}` | Yes | Retrieves a specific note by ID. |
| `PUT` | `/notes/{id}` | Yes | Updates note title, content, tags, pin/archive status. |
| `DELETE`| `/notes/{id}` | Yes | Deletes a note. |
| `POST` | `/notes/{id}/share` | Yes | Shares a note with another student (by user email). |

---

## 7. Productivity Focus Timer (`/focus`)

Pomodoro focus timer and productivity analytics.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/focus/sessions` | Yes | Starts a new focus timer session. |
| `POST` | `/focus/sessions/{id}/pause`| Yes | Pauses an active session. |
| `POST` | `/focus/sessions/{id}/resume`| Yes | Resumes a paused session. |
| `POST` | `/focus/sessions/{id}/stop`| Yes | Ends a focus timer session. |
| `GET` | `/focus/metrics` | Yes | Retrieves focus/break metrics and productivity stats. |

#### Start Focus Session Request
```json
{
  "type": "focus" // Literal["focus", "short_break", "long_break"]
}
```

#### Productivity Metrics Response
```json
{
  "total_focus_minutes": 120, // int
  "total_break_minutes": 25, // int
  "focus_to_break_ratio": 4.8, // float
  "productivity_score": 85 // int (0-100 scale)
}
```

---

## 8. Calendar Events (`/calendar`)

Scheduler for events, recurring tasks, and Google Calendar sync.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/calendar/events` | Yes | Creates a new calendar event (optional association with a to-do). |
| `GET` | `/calendar/events` | Yes | Lists all calendar events for the user. |
| `GET` | `/calendar/events/{id}`| Yes | Retrieves event details. |
| `PUT` | `/calendar/events/{id}`| Yes | Updates calendar event properties. |
| `DELETE`| `/calendar/events/{id}`| Yes | Deletes a calendar event. |
| `POST` | `/calendar/sync/google`| Yes | Simulates syncing events to Google Calendar. |
| `GET` | `/calendar/sync/status`| Yes | Retrieves Google Calendar connection sync history. |

---

## 9. Personalization & Settings (`/preferences`)

User preferences for settings and dashboard views.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/preferences/` | Yes | Retrieves theme (light/dark) and notification preferences. |
| `PUT` | `/preferences/` | Yes | Updates user preferences (theme, notification config). |
| `GET` | `/preferences/security`| Yes | Retrieves user security configuration settings. |
| `PUT` | `/preferences/security`| Yes | Updates user security preferences. |

---

## 10. Admin Dashboards & Settings (`/admin`, `/system` & `/poll`)

These endpoints are typically for admin panels, dashboard tools, or student polls.

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/poll/submit` | No | **Public / Anonymous**: Submit student pulse-check survey responses. |
| `GET` | `/poll/results` | Yes (Admin) | **Admin Only**: Retrieve aggregated survey results. |
| `GET` | `/poll/responses`| Yes (Admin) | **Admin Only**: Retrieve raw individual survey entries. |
| `GET` | `/admin/users` | Yes (Admin) | **Admin Only**: Lists all users in the system. |
| `GET` | `/admin/pending-users`| Yes (Admin) | **Admin Only**: Lists registered users awaiting admin activation. |
| `PATCH` | `/admin/approve/{id}`| Yes (Admin) | **Admin Only**: Activates a pending student user account. |
| `DELETE`| `/admin/users/{id}` | Yes (Admin) | **Admin Only**: Deletes/ban user accounts. |
| `GET` | `/admin/roles/` | Yes (Admin) | **Admin Only**: Lists all access roles. |
| `POST` | `/admin/roles/` | Yes (Admin) | **Admin Only**: Creates a new user role with specific json permissions. |
| `GET` | `/system/audit-logs` | Yes (Admin) | **Admin Only**: List system audit trails. |
| `GET` | `/system/settings` | Yes (Admin) | **Admin Only**: Read global system configuration keys. |
| `PUT` | `/system/settings/{key}`| Yes (Admin) | **Admin Only**: Create or modify global configuration keys. |
