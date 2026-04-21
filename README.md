# Hot Take

Hot Take is a full-stack discussion and matching app. The project pairs users based on shared tags and overlapping language in their bios, then lets them start one-on-one chats.

This repository currently contains:

- a React 19 + Vite frontend in `frontend/`
- a Node.js backend in `backend/`
- MongoDB persistence for users and chats
- email verification support, with optional Resend delivery

## Current project status

The backend is functional and includes:

- registration and login
- email verification
- authenticated profile lookup
- bio and tag updates
- match generation
- chat creation and messaging

The frontend is partially integrated:

- the `/verify-email` route is live and calls the backend
- the `/matches` route renders the current chat UI
- several routes still use placeholder screens
- the matches page still uses mock data instead of calling the backend

That means the backend is the source of truth for the current feature set, while the frontend is still being wired up to those APIs.

## Repository structure

```text
.
├── backend/     # Node HTTP API, MongoDB access, matching logic, email verification
├── frontend/    # React + Vite client
├── package.json # minimal root-level dev dependencies
└── README.md
```

## Tech stack

- Frontend: React 19, React Router 7, Vite 8, Tailwind CSS 4, TypeScript
- Backend: Node.js, native `http` server, MongoDB, bcrypt
- Email: Resend API when configured, console-logged verification links otherwise

## Getting started

### 1. Install dependencies

Install packages in each app directory:

```bash
cd backend
npm install
```

```bash
cd frontend
npm install
```

### 2. Configure the backend

Create `backend/.env` with at least:

```env
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/hot-take
PORT=3001
HOST=127.0.0.1
FRONTEND_URL=http://localhost:5173
```

Optional email settings:

```env
RESEND_API_KEY=your_resend_api_key
EMAIL_FROM=Hot Take <verify@yourdomain.com>
```

Notes:

- `MONGODB_URI` is required. The server exits immediately if it is missing.
- If `RESEND_API_KEY` or `EMAIL_FROM` is missing, verification emails are not sent. The backend logs the verification URL to the terminal instead.
- The backend binds to `127.0.0.1` by default unless `HOST` is set.

### 3. Start the backend

```bash
cd backend
npm run dev
```

Default API URL: `http://127.0.0.1:3001`

### 4. Start the frontend

```bash
cd frontend
npm run dev
```

Default frontend URL: `http://localhost:5173`

If you want the frontend verification page to hit a different API origin, set:

```env
VITE_API_BASE_URL=http://127.0.0.1:3001
```

## Development workflow

Run the apps in separate terminals:

1. `cd backend && npm run dev`
2. `cd frontend && npm run dev`

The typical local flow is:

1. Register a user through the backend.
2. Open the verification link from Resend, or copy the logged verification URL from the backend terminal.
3. Verify the account.
4. Log in and use the authenticated endpoints for interests, matches, and chats.

## Useful scripts

### Root

- no shared workspace scripts are configured yet

### Backend

- `npm run dev` starts the API with Node watch mode
- `npm start` starts the API normally

### Frontend

- `npm run dev` starts the Vite dev server
- `npm run build` builds the production bundle
- `npm run lint` runs ESLint
- `npm run preview` previews the production build

## API overview

The backend exposes these route groups:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/verify-email?token=...`
- `GET /api/me`
- `PUT /api/interests`
- `GET /api/matches`
- `POST /api/matches/:matchUserId/start-chat`
- `GET /api/chats`
- `GET /api/chats/:chatId/messages`
- `POST /api/chats/:chatId/messages`

Protected routes expect:

```http
Authorization: Bearer <token>
```

More backend-specific details and sample requests live in [backend/README.md](./backend/README.md).

## Known gaps

- sessions are stored in memory, so restarting the backend signs everyone out
- the frontend auth flow is not fully connected to backend routes yet
- the frontend matches page still uses mocked match data
- no automated test suite is set up yet
