# Hot Take Backend

This backend is a starter API for the mockup flows:

- account creation and sign in
- saving a user's interests and takes
- generating matches from shared tags and overlapping opinion text
- opening chats and sending messages

It uses MongoDB for all data storage.

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `MONGODB_URI` | Yes | Full MongoDB connection string, e.g. `mongodb+srv://user:pass@cluster.mongodb.net/mernapp` |
| `PORT` | No | Port to listen on (default `3001`) |

The server will refuse to start if `MONGODB_URI` is not set.

## Run it

```bash
cd backend
MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/mernapp" npm run dev
```

The API starts on `http://localhost:3001`.

## Suggested data model for MongoDB

### `users`

```json
{
  "_id": "ObjectId",
  "username": "demo_user",
  "email": "demo@hottake.app",
  "passwordHash": "hashed password",
  "bio": "What the user wants to talk about and their opinions",
  "tags": ["film", "philosophy", "writing"],
  "createdAt": "ISO date",
  "updatedAt": "ISO date",
  "lastActiveAt": "ISO date"
}
```

### `matches`

You can compute matches live at first, or persist them later if you want:

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "matchedUserId": "ObjectId",
  "score": 92,
  "sharedTags": ["film", "philosophy"],
  "sharedTerms": ["classics", "cinema"],
  "createdAt": "ISO date"
}
```

### `chats`

```json
{
  "_id": "ObjectId",
  "participantIds": ["ObjectId", "ObjectId"],
  "createdAt": "ISO date",
  "updatedAt": "ISO date"
}
```

### `messages`

```json
{
  "_id": "ObjectId",
  "chatId": "ObjectId",
  "senderId": "ObjectId",
  "text": "Message body",
  "sentAt": "ISO date"
}
```

## Endpoints

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/me`

## Postman testing

### 1. Register a new user

- Method: `POST`
- URL: `http://localhost:3001/api/auth/register`
- Headers: `Content-Type: application/json`
- Body (raw JSON):

```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123"
}
```

Expected response `201`:

```json
{
  "token": "<session-token>",
  "user": {
    "id": "user_xxxxxxxx",
    "username": "testuser",
    "email": "test@example.com",
    "bio": "",
    "tags": [],
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

Copy the `token` value. You will use it as the Bearer token for all protected routes.

If the email is already registered you will get `409` with `{ "error": "Email already registered." }`.

### 2. Login

- Method: `POST`
- URL: `http://localhost:3001/api/auth/login`
- Headers: `Content-Type: application/json`
- Body (raw JSON):

```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

Expected response `200`:

```json
{
  "token": "<session-token>",
  "user": {
    "id": "user_xxxxxxxx",
    "username": "testuser",
    "email": "test@example.com",
    "bio": "",
    "tags": [],
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

Wrong credentials return `401` with `{ "error": "Invalid email or password." }`.

### 3. Using the token in Postman

For any protected route (`/api/me`, `/api/interests`, `/api/matches`, etc.):

1. Go to the **Authorization** tab
2. Select type **Bearer Token**
3. Paste the `token` value from the register or login response

### Interests

- `PUT /api/interests`

Example body:

```json
{
  "bio": "I want to debate whether modern horror is better than prestige drama.",
  "tags": ["film", "horror", "tv"]
}
```

### Matches

- `GET /api/matches`
- `POST /api/matches/:matchUserId/start-chat`

### Chat

- `GET /api/chats`
- `GET /api/chats/:chatId/messages`
- `POST /api/chats/:chatId/messages`

All protected routes expect:

```http
Authorization: Bearer <token>
```

## Good next steps

1. Replace the random session token map with JWTs so sessions survive server restarts.
2. Add Socket.IO for live chat updates.
3. Let the frontend call `GET /api/matches` after the user saves their interests page.
