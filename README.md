# Live Customer Support (Frontend)

Vue 3 frontend for a **live customer support** platform. It supports **two roles** (Customer / Staff), provides login/register flows, and enables **real-time 1:1 chat** over **WebSocket (STOMP + SockJS)**.

> Backend repo: `live-cust-support-b` (Spring Boot on `http://localhost:8088`)

---

## Tech Stack

- Vue 3
- Vue Router 4
- Element Plus (UI components)
- Axios (REST calls)
- SockJS + STOMP.js (real-time chat)

---

## Features (Frontend)

### Role selection
- Landing page lets you choose **Customer** or **Staff**.

### Customer (User) portal
- **Register / login** as a customer
  - Customer registration requires a valid **staffId** (called `custId` in the DB) so the user is assigned to a staff member.
- **User dashboard** shows:
  - userName / userId / assigned cust-service staffId
- **Floating “service” chat widget**
  - Click to open a chat dialog
  - Connects to WebSocket and starts a conversation
  - Sends messages to the assigned staff member
  - Persists messages to MySQL via REST (`/chat/insert/newMessages`)
  - Automatically closes the conversation when you close the widget

### Staff portal
- **Register / login** as staff
- Staff dashboard layout with sidebar navigation:
  1. **Customer Management**
     - Lists all customers assigned to the logged-in staff account
  2. **Live Chat Console**
     - Real-time incoming messages open (or focus) a **conversation tab**
     - Supports multiple active tabs simultaneously
     - Staff can reply inside each tab
     - Tabs + mappings are cached in `localStorage` (persist across refresh)
     - Staff can **manually close** a conversation (toggle)
  3. **Conversation History**
     - View past conversation records (conversationId, userId, staffId, create time, status)
     - Click **Detail** to load full message history

---

## Prerequisites

- Node.js **18+** (recommended)
- npm (comes with Node)

---

## Quick Start (Run Locally)

### 1) Start MySQL + create tables

The backend expects a database named **`live-cust-support`** and 4 tables:

- `staff`
- `user`
- `conversation`
- `message`

A schema script is included in this repo:

- `mysql_schema.sql`

Run it:

```bash
mysql -u root -p < ./mysql_schema.sql
```

### 2) Start the backend (required)

From the backend repo:

```bash
mvn spring-boot:run
```

Backend ports:
- REST: `http://localhost:8088`
- WS: `http://localhost:8088/ws`

### 3) Install dependencies

From this (frontend) repo root:

```bash
npm install
```

### 4) Run the frontend

```bash
npm run serve
```

By default Vue CLI serves at:
- `http://localhost:8080`

---

## How To Use (End-to-end flow)

1. Open the frontend: `http://localhost:8080`
2. **Create a staff account**
   - Select **Staff** → `Sign up`
   - Login as staff
   - In the staff layout header, note your **staffId** (also stored in `localStorage`)
3. **Create a customer account**
   - Go back to role selection → select **Customer** → `Sign up`
   - Enter:
     - `userName`
     - `staffId` (this is the staff’s id; stored in DB as `custId`)
   - Login as customer
4. **Start a live chat**
   - On the customer dashboard, click the floating **service** button
   - Type a message and send
5. **Reply as staff**
   - In the staff portal, open **Live Chat Console**
   - A tab for that conversation appears automatically
   - Reply in the tab; messages will be delivered in real time
6. **Close & review history**
   - Staff can manually close a conversation
   - Staff can review records under **Conversation History**

---

## Configuration

### Backend URL
This frontend currently calls the backend using hard-coded URLs:

- `http://localhost:8088/...`

If you want to change the backend host/port, search and replace in:
- `src/components/**/*.vue`

A common improvement is to create a single Axios instance with a `baseURL`.

### WebSocket
- Endpoint: `http://localhost:8088/ws`
- Send destination: `/app/sendMsg`
- Subscribe prefix: `/cust_service/.../private`

---

## Useful Scripts

```bash
npm run serve   # run dev server
npm run build   # production build
npm run lint    # lint
```

---

## Troubleshooting

- **CORS blocked**
  - Backend CORS is configured for `http://localhost:8080`
  - Make sure your frontend is running on 8080, or update backend `CorsConfig`.

- **WebSocket can’t connect**
  - Confirm backend is running and `http://localhost:8088/ws` is reachable.

- **User signup fails with “verify staff id”**
  - Register a staff first, then use that staff’s `staffId` as the customer’s `custId`.

---
