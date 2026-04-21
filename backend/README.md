# Hot Take Backend

This backend is the main working part of the project right now. It provides account creation, email verification, sign-in, interests storage, match generation, chat creation, and message sending on top of MongoDB.

The server is a small Node.js HTTP app in `src/server.js`, with MongoDB access in `src/data/` and matching/email helpers in `src/services/`.

## What it does

- registers users with hashed passwords
- requires email verification before login
- stores users in MongoDB
- creates in-memory session tokens after login
- saves a user's bio and topic tags
- scores matches from shared tags and overlapping bio terms
- creates chats and stores messages in MongoDB

## Requirements

- Node.js with npm
- a MongoDB database reachable through `MONGODB_URI`

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `MONGODB_URI` | Yes | MongoDB connection string used by `MongoClient` |
| `PORT` | No | HTTP port, default `3001` |
| `HOST` | No | Bind host, default `127.0.0.1` |
| `FRONTEND_URL` | No | Base URL used to build email verification links, default `http://localhost:5173` |
| `RESEND_API_KEY` | No | Resend API key for real email delivery |
| `EMAIL_FROM` | No | Verified sender identity used by Resend |

If `MONGODB_URI` is missing, the server exits on startup.

If `RESEND_API_KEY` or `EMAIL_FROM` is missing, registration still works, but the verification link is printed in the backend terminal instead of being emailed.

## Install and run

```bash
cd backend
npm install
npm run dev
```

Example `.env`:

```env
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/hot-take
PORT=3001
HOST=127.0.0.1
FRONTEND_URL=http://localhost:5173
RESEND_API_KEY=
EMAIL_FROM=
```

Default local server URL:

```text
http://127.0.0.1:3001
```

## Scripts

- `npm run dev` runs `node --watch src/server.js`
- `npm start` runs `node src/server.js`

## Architecture

### `src/server.js`

- validates required environment variables
- creates the HTTP server
- parses JSON request bodies
- handles routing and CORS
- connects to MongoDB before listening

### `src/data/db.js`

- creates the shared MongoDB client
- connects once at startup
- exposes `getDB()` for collection access

### `src/data/store.js`

- contains the main application logic
- stores login sessions in memory with `Map`
- reads and writes `users` and `chats`
- sanitizes user objects before returning them to clients

### `src/services/email.js`

- builds verification URLs from `FRONTEND_URL`
- sends email through Resend when configured
- falls back to logging verification links locally

### `src/services/matching.js`

- calculates match scores from shared tags and shared terms in user bios

## Data model

The code currently relies on MongoDB collections with shapes like these.

### `users`

```json
{
  "_id": "ObjectId",
  "id": "user_ab12cd34",
  "username": "demo_user",
  "email": "demo@hottake.app",
  "passwordHash": "bcrypt hash",
  "emailVerified": false,
  "emailVerificationTokenHash": "sha256 hash",
  "emailVerificationExpiresAt": "2026-04-21T15:00:00.000Z",
  "bio": "",
  "tags": [],
  "createdAt": "2026-04-20T15:00:00.000Z",
  "updatedAt": "2026-04-20T15:00:00.000Z",
  "lastActiveAt": "2026-04-20T15:00:00.000Z"
}
```

### `chats`

```json
{
  "_id": "ObjectId",
  "id": "chat_ab12cd34",
  "participantIds": ["user_one", "user_two"],
  "createdAt": "2026-04-20T15:00:00.000Z",
  "updatedAt": "2026-04-20T15:00:00.000Z",
  "messages": [
    {
      "id": "msg_ab12cd34",
      "senderId": "user_one",
      "text": "Message body",
      "sentAt": "2026-04-20T15:05:00.000Z"
    }
  ]
}
```

Matches are computed on demand from the `users` collection rather than stored in a dedicated collection.

## API routes

### Auth

#### `POST /api/auth/register`

Creates a user account and sends or logs a verification link.

Request body:

```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123"
}
```

Successful response:

```json
{
  "message": "Account created. Check your email to verify your account before signing in.",
  "user": {
    "id": "user_xxxxxxxx",
    "username": "testuser",
    "email": "test@example.com",
    "emailVerified": false,
    "bio": "",
    "tags": [],
    "createdAt": "2026-04-20T15:00:00.000Z",
    "updatedAt": "2026-04-20T15:00:00.000Z"
  },
  "verificationUrl": "http://localhost:5173/verify-email?token=..."
}
```

Notes:

- `verificationUrl` is only included when the app is using local log mode instead of Resend.
- If the email already exists but is still unverified, the backend refreshes the verification token and returns a new verification link instead of creating a duplicate user.

#### `POST /api/auth/login`

Request body:

```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

Successful response:

```json
{
  "token": "session-token",
  "user": {
    "id": "user_xxxxxxxx",
    "username": "testuser",
    "email": "test@example.com",
    "emailVerified": true,
    "bio": "",
    "tags": [],
    "createdAt": "2026-04-20T15:00:00.000Z",
    "updatedAt": "2026-04-20T15:00:00.000Z"
  }
}
```

Common failures:

- `401` for invalid email/password
- `401` if the account has not been verified yet

#### `GET /api/auth/verify-email?token=...`

Marks the user as verified if the token hash matches and the token is still within its 24-hour lifetime.

#### `GET /api/me`

Returns the current signed-in user for a valid bearer token.

### Interests

#### `PUT /api/interests`

Requires `Authorization: Bearer <token>`.

Request body:

```json
{
  "bio": "I want to debate whether modern horror is better than prestige drama.",
  "tags": ["film", "horror", "tv"]
}
```

Behavior:

- trims the bio
- lowercases tags
- removes duplicate tags
- limits the saved tag list to 10 items

### Matches

#### `GET /api/matches`

Requires authentication.

Returns scored candidate matches based on:

- shared tags
- shared terms extracted from user bios

Only matches with a score greater than `0` are returned.

#### `POST /api/matches/:matchUserId/start-chat`

Requires authentication.

- creates a new chat if one does not already exist
- returns the existing `chatId` if the pair already has a chat

### Chats

#### `GET /api/chats`

Returns all chats for the current user, including:

- the other participant
- computed match score
- shared tags
- the last message

#### `GET /api/chats/:chatId/messages`

Returns the messages for a chat the current user belongs to.

#### `POST /api/chats/:chatId/messages`

Request body:

```json
{
  "text": "hear me out..."
}
```

Creates a message object and appends it to the chat's `messages` array.

## Local testing flow

1. Start the backend with a real `MONGODB_URI`.
2. Register a user with `POST /api/auth/register`.
3. Copy the logged `verificationUrl` from the backend terminal if email delivery is not configured.
4. Open `GET /api/auth/verify-email?token=...` directly or use the frontend `/verify-email` page.
5. Log in with `POST /api/auth/login`.
6. Use the returned bearer token for `/api/me`, `/api/interests`, `/api/matches`, and chat routes.

## Important implementation notes

- sessions are in memory, so restarting the server invalidates all active login tokens
- the server uses a native Node HTTP server, not Express
- CORS is currently open to all origins
- chats store messages inline inside each chat document
- there is no automated test suite in the backend yet

## Good next steps

1. Replace the in-memory session map with JWTs or persistent sessions.
2. Add request-level validation helpers for cleaner error handling.
3. Split chat messages into their own collection if message volume grows.
4. Add automated API tests for auth, verification, and chat flows.
5. Wire the frontend matches and auth screens to these live endpoints.
