# Hot Take Backend

This backend is a starter API for the mockup flows:

- account creation and sign in
- saving a user's interests and takes
- generating matches from shared tags and overlapping opinion text
- opening chats and sending messages

It uses an in-memory store right now so the frontend team can start integrating immediately. The route contract is meant to survive the move to MongoDB later.

## Run it

```bash
cd backend
npm run dev
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

1. Replace the in-memory store with MongoDB collections and Mongoose models.
2. Swap the demo password hashing for `bcrypt`.
3. Replace the random session token map with JWTs.
4. Add Socket.IO for live chat updates.
5. Let the frontend call `GET /api/matches` after the user saves their interests page.
