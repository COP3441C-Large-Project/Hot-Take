import { Server } from 'socket.io';
import { createServer } from 'node:http';
import { URL } from 'node:url';
import { createStore } from './data/store.js';
import { connectDB } from './data/db.js';
import { MatchingService } from './services/matching.js';
import sgMail from '@sendgrid/mail';

if (!process.env.MONGODB_URI) {
  console.error('Error: MONGODB_URI environment variable is not set.');
  process.exit(1);
}

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function sendEmail({ to, subject, text, html }) {
  await sgMail.send({
    to,
    from: process.env.SENDGRID_FROM_EMAIL,
    subject,
    text,
    html,
  });
}

const PORT = Number(process.env.PORT ?? 3001);
const HOST = process.env.HOST ?? '0.0.0.0';
const CLIENT_URL = process.env.APP_URL ?? 'http://localhost:5173';

// --- NEW DYNAMIC CORS LOGIC ---
const ALLOWED_ORIGINS = [
  CLIENT_URL,
  'http://localhost:5173',
  'http://localhost:59008',
  'http://localhost:65292',
  'http://127.0.0.1:5173',
  'http://4331project.xyz',
  'https://4331project.xyz'
];

function getAllowOrigin(request) {
  const origin = request.headers.origin;
  // If the origin is in our whitelist, return it. 
  // Otherwise, fallback to the main CLIENT_URL.
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    return origin;
  }
  return CLIENT_URL;
}
// ------------------------------

const store = createStore();
const matchingService = new MatchingService();

function json(request, response, statusCode, payload) {
  const allowOrigin = getAllowOrigin(request);
  
  response.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
    'Access-Control-Allow-Credentials': 'true'
  });
  response.end(JSON.stringify(payload, null, 2));
}

async function readBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function getToken(request) {
  const authHeader = request.headers.authorization ?? '';
  return authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
}

function isValidAuthPayload(payload) {
  return payload.username?.trim() && payload.email?.trim() && payload.password?.trim();
}

async function handler(request, response) {
  if (!request.url || !request.method) {
    json(request, response, 400, { error: 'Bad request.' });
    return;
  }

  // UPDATED OPTIONS HANDLER
  if (request.method === 'OPTIONS') {
    const allowOrigin = getAllowOrigin(request);
    response.writeHead(204, {
      'Access-Control-Allow-Origin': allowOrigin,
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
      'Access-Control-Allow-Credentials': 'true'
    });
    response.end();
    return;
  }

  const url = new URL(request.url, `http://${HOST}:${PORT}`);
  const token = getToken(request);

  try {
    if (request.method === 'GET' && url.pathname === '/api/health') {
      json(request, response, 200, { status: 'ok' });
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/register') {
      const payload = await readBody(request);
      if (!isValidAuthPayload(payload)) {
        json(request, response, 400, { error: 'username, email, and password are required.' });
        return;
      }
      const result = await store.register(payload);
      json(request, response, result.error ? 409 : 201, result);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/login') {
      const payload = await readBody(request);
      if (!payload.email?.trim() || !payload.password?.trim()) {
        json(request, response, 400, { error: 'email and password are required.' });
        return;
      }
      const result = await store.login(payload);
      json(request, response, result.error ? 401 : 200, result);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/send-verification') {
      const payload = await readBody(request);
      if (!payload.userId) {
        json(request, response, 400, { error: 'userId is required.' });
        return;
      }
      const result = await store.sendVerificationEmail(payload.userId, sendEmail);
      json(request, response, result.error ? 400 : 200, result);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/verify-email') {
      const payload = await readBody(request);
      const result = await store.verifyEmail(payload.token);
      json(request, response, result.error ? 400 : 200, result);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/forgot-password') {
      const payload = await readBody(request);
      const result = await store.sendPasswordResetEmail(payload.email, sendEmail);
      json(request, response, result.error ? 400 : 200, result);
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/auth/reset-password') {
      const payload = await readBody(request);
      const result = await store.resetPassword(payload.token, payload.password);
      json(request, response, result.error ? 400 : 200, result);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/me') {
      const user = await store.getCurrentUser(token);
      json(request, response, user ? 200 : 401, user ? { user } : { error: 'Unauthorized.' });
      return;
    }

    if (request.method === 'PUT' && url.pathname === '/api/interests') {
      const payload = await readBody(request);
      const bio = payload.bio ?? '';
      const tags = Array.isArray(payload.tags) ? payload.tags : [];
      if (!bio.trim()) {
        json(request, response, 400, { error: 'bio is required.' });
        return;
      }
      const result = await store.updateInterests(token, { bio, tags });
      if (result.error) {
        json(request, response, 401, result);
        return;
      }
      const matchingResult = await matchingService.updateUserAndFindMatches({
        userId: result.user.id,
        bio,
        tags,
      });
      json(request, response, 200, { ...result, matches: matchingResult.matches });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/interests') {
      const user = await store.getCurrentUser(token);
      if (!user) {
        json(request, response, 401, { error: 'Unauthorized.' });
        return;
      }
      json(request, response, 200, { bio: user.bio ?? '', tags: user.tags ?? [] });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/matches') {
      const result = await store.listMatches(token);
      json(request, response, result.error ? 401 : 200, result);
      return;
    }

    const startChatMatch = url.pathname.match(/^\/api\/matches\/([^/]+)\/start-chat$/);
    if (request.method === 'POST' && startChatMatch) {
      const result = await store.startChat(token, startChatMatch[1]);
      json(request, response, result.error ? 404 : 201, result);
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/chats') {
      const result = await store.listChats(token);
      json(request, response, result.error ? 401 : 200, result);
      return;
    }


    const messagesMatch = url.pathname.match(/^\/api\/chats\/([^/]+)\/messages$/);
    if (request.method === 'GET' && messagesMatch) {
      const result = await store.getChatMessages(token, messagesMatch[1]);
      json(request, response, result.error ? 404 : 200, result);
      return;
    }

    if (request.method === 'POST' && messagesMatch) {
      const payload = await readBody(request);
      const result = await store.sendMessage(token, messagesMatch[1], payload.text);
      json(request, response, result.error ? 404 : 201, result);
      return;
    }

    json(request, response, 404, { error: 'Route not found.' });
  } catch (error) {
    console.error("=== 500 ERROR ===", error);
    json(request, response, 500, { error: 'Internal server error.' });
  }
}

const server = createServer(handler);

const io = new Server(server, {
  cors: {
    // Dynamic Origin for Socket.io
    origin: (origin, callback) => {
      if (!origin || ALLOWED_ORIGINS.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ['GET', 'POST'],
    credentials: true
  }
});

io.on('connection', async (socket) => {
  const token = socket.handshake.auth.token ?? '';
  const user = await store.getCurrentUser(token);
  if (!user) {
    socket.disconnect();
    return;
  }
  socket.on('join_chat', (chatId) => {

    socket.join(chatId);
  });
  socket.on('send_message', async ({ chatId, text }) => {
    const result = await store.sendMessage(token, chatId, text);
    if (result.error) return;
    socket.to(chatId).emit('receive_message', result.message);
    socket.emit('message_sent', result.message);
  });
});

connectDB()
  .then(() => matchingService.init())
  .then(() => {
    server.listen(PORT, HOST, () => {
      console.log(`Backend live on http://${HOST}:${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Failed to connect to MongoDB:', error.message);
    process.exit(1);
  });