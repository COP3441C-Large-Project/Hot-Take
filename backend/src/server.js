import { Server } from 'socket.io';
// To create a web server
import { createServer } from 'node:http';
// To easily work w/ URLs and query parameters
import { URL } from 'node:url';
// Acts like a fake database
import { createStore } from './data/store.js';
import { connectDB } from './data/db.js';

if (!process.env.MONGODB_URI) {
  console.error('Error: MONGODB_URI environment variable is not set.');
  process.exit(1);
}

import sgMail from '@sendgrid/mail';
sgMail.setApiKey(process.env.SENDGRID_API_KEY);
 
// Helper to send email via SendGrid
async function sendEmail({ to, subject, text, html }) {
  await sgMail.send({
    to,
    from: process.env.SENDGRID_FROM_EMAIL,
    subject,
    text,
    html,
  });
}

// No env variable available yet, so this is the port the server will run on
const PORT = Number(process.env.PORT ?? 3001);
// The IP address the server will bind to
const HOST = process.env.HOST ?? '127.0.0.1';
// Initializes the data store, which holds users, chats, and matches in memory
const store = createStore();

// Helper func to send JSON responses back to the client
function json(response, statusCode, payload){
  // Sets HTTP status code and headers
  response.writeHead(statusCode, {
    // Tells the client the response is JSON
    'Content-Type': 'application/json',
    // Allows request from any origin
    'Access-Control-Allow-Origin': '*',
    // Allows specific headers
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    // Allows specific HTTP methods
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS'
  });
  // Sends JSON response
  response.end(JSON.stringify(payload, null, 2));
}

// Helper func to read request body (POST/PUT requests)
async function readBody(request){
  // Stores incoming data chuncks
  const chunks = [];

  // Reads stream of incoming data
  for await (const chunk of request){
    // Adds each chunk to the array
    chunks.push(chunk);
  }

  // If no body was sent, return empty object instead of crashing
  if (chunks.length === 0){
    return {};
  }

  // Combines chuncks into a string and parses it as JSON
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

// Exracts Bearer token from Authorization header
function getToken(request) {
  // Gets authorization header or empty string
  const authHeader = request.headers.authorization ?? '';
  // Checks if it's a Bearer token, removes Bearer prefix and returns token, otherwise returns empty string
  return authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
}

// Validates registration payload
function isValidAuthPayload(payload){
  // Checks if username, email, and password exist and aren't empty
  return payload.username?.trim() && payload.email?.trim() && payload.password?.trim();
}

// Creates HTTP server
async function handler(request, response) {
  // If request is messed up, returns 400 Bad Request
  if (!request.url || !request.method) {
    json(response, 400, { error: 'Bad request.' });
    return;
  }

  // Handles CORS preflight requests
  if (request.method === 'OPTIONS'){
    json(response, 204, {});
    return;
  }

  // Parses URL
  const url = new URL(request.url, `http://localhost:${PORT}`);
  // Extracts token from request headers
  const token = getToken(request);

  try {
    // Health check endpoint which is used to verify the server is running
    if (request.method === 'GET' && url.pathname === '/api/health'){
      json(response, 200, { status: 'ok' });
      return;
    }

    // Registers new user
    if (request.method === 'POST' && url.pathname === '/api/auth/register'){
      // Reads request body
      const payload = await readBody(request);

      // Validates required fileds
      if (!isValidAuthPayload(payload)){
        json(response, 400, { error: 'username, email, and password are required.' });
        return;
      }

      // Stores user in database
      const result = await store.register(payload);
      // 409 is conflict, 201 is created
      json(response, result.error ? 409 : 201, result);
      return;
    }

    // Logins user
    if (request.method === 'POST' && url.pathname === '/api/auth/login'){
      // Reads request body
      const payload = await readBody(request);

      // Validates input
      if (!payload.email?.trim() || !payload.password?.trim()){
        json(response, 400, { error: 'email and password are required.' });
        return;
      }

      // Attempts login
      const result = await store.login(payload);
      // 401 is unauthorized, 200 is success
      json(response, result.error ? 401 : 200, result);
      return;
    }

    // Sends verification email after registration
    if (request.method === 'POST' && url.pathname === '/api/auth/send-verification') {
      const payload = await readBody(request);
      if (!payload.userId) {
        json(response, 400, { error: 'userId is required.' });
        return;
      }
      const result = await store.sendVerificationEmail(payload.userId, sendEmail);
      json(response, result.error ? 400 : 200, result);
      return;
    }
 
    // Verifies email from link
    if (request.method === 'POST' && url.pathname === '/api/auth/verify-email') {
      const payload = await readBody(request);
      if (!payload.token) {
        json(response, 400, { error: 'token is required.' });
        return;
      }
      const result = await store.verifyEmail(payload.token);
      json(response, result.error ? 400 : 200, result);
      return;
    }
 
    // Sends password reset email
    if (request.method === 'POST' && url.pathname === '/api/auth/forgot-password') {
      const payload = await readBody(request);
      if (!payload.email?.trim()) {
        json(response, 400, { error: 'email is required.' });
        return;
      }
      const result = await store.sendPasswordResetEmail(payload.email, sendEmail);
      json(response, result.error ? 400 : 200, result);
      return;
    }
 
    // Resets password
    if (request.method === 'POST' && url.pathname === '/api/auth/reset-password') {
      const payload = await readBody(request);
      if (!payload.token?.trim() || !payload.password?.trim()) {
        json(response, 400, { error: 'token and password are required.' });
        return;
      }
      const result = await store.resetPassword(payload.token, payload.password);
      json(response, result.error ? 400 : 200, result);
      return;
    }
 

    // Gets current logged in user
    if (request.method === 'GET' && url.pathname === '/api/me'){
      // Gets user from token
      const user = await store.getCurrentUser(token);
      json(response, user ? 200 : 401, user ? { user } : { error: 'Unauthorized.' });
      return;
    }

    // Updates user's interests/profile
    if (request.method === 'PUT' && url.pathname === '/api/interests'){
      // Reads request body
      const payload = await readBody(request);
      // Extracts bio
      const bio = payload.bio ?? '';
      // Ensures tags is an array
      const tags = Array.isArray(payload.tags) ? payload.tags : [];

      // Validates bio
      if (!bio.trim()) {
        json(response, 400, { error: 'bio is required.' });
        return;
      }

      // Updates data
      const result = await store.updateInterests(token, { bio, tags });
      json(response, result.error ? 401 : 200, result);
      return;
    }

    // Gets matches for user
    if (request.method === 'GET' && url.pathname === '/api/matches'){
      const result = await store.listMatches(token);
      json(response, result.error ? 401 : 200, result);
      return;
    }

    // Match route: api/matches/:matchId/start-chat
    const startChatMatch = url.pathname.match(/^\/api\/matches\/([^/]+)\/start-chat$/);
    if (request.method === 'POST' && startChatMatch){
      // Starts chat w/ match ID
      const result = await store.startChat(token, startChatMatch[1]);
      json(response, result.error ? 404 : 201, result);
      return;
    }

    // Gets all chats
    if (request.method === 'GET' && url.pathname === '/api/chats'){
      const result = await store.listChats(token);
      json(response, result.error ? 401 : 200, result);
      return;
    }

    // Match route: api/chats/:chatId/messages
    const messagesMatch = url.pathname.match(/^\/api\/chats\/([^/]+)\/messages$/);
    // Gets messages for a chat
    if (request.method === 'GET' && messagesMatch){
      const result = await store.getChatMessages(token, messagesMatch[1]);
      json(response, result.error ? 404 : 200, result);
      return;
    }

    // Sends a message
    if (request.method === 'POST' && messagesMatch){
      // Reads a request body
      const payload = await readBody(request);

      // Validates message text
      if (!payload.text?.trim()){
        json(response, 400, { error: 'text is required.' });
        return;
      }

      // Sends message
      const result = await store.sendMessage(token, messagesMatch[1], payload.text);
      json(response, result.error ? 404 : 201, result);
      return;
    }

    json(response, 404, { error: 'Route not found.' });
    // Catches unexpected errors
  } catch (error) {
    json(response, 500, {
      error: 'Internal server error.',
      details: error instanceof Error ? error.message : 'Unknown error.'
    });
  }
}

const server = createServer(handler);

const io = new Server(server, {
  cors: {
    origin: ['http://localhost:5173', 'http://127.0.0.1:5173'], //UPDATE WHEN REMOTELY HOSTED
    methods: ['GET', 'POST']
  }
});

io.on('connection', async (socket) => {
  const token = socket.handshake.auth.token ?? '';
  const user = await store.getCurrentUser(token);

  console.log('authenticated as:', user?.username ?? 'INVALID TOKEN');

  if (!user) {
    console.log('disconnecting — invalid token');
    socket.disconnect();
    return;
  }

  socket.on('join_chat', (chatId) => {
    console.log(`${user.username} joined chat:`, chatId);
    socket.join(chatId);
  });

  socket.on('send_message', async ({ chatId, text }) => {
    console.log(`${user.username} sent message in ${chatId}:`, text);
    const result = await store.sendMessage(token, chatId, text);
    if (result.error) return;
    socket.to(chatId).emit('receive_message', result.message);
    socket.emit('message_sent', result.message);
  });

  socket.on('typing', (chatId) => {
    socket.to(chatId).emit('typing');
  });
});

connectDB()
  .then(() => {
    server.listen(PORT, HOST, () => {
      console.log(`Hot Take backend listening on http://${HOST}:${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Failed to connect to MongoDB:', error.message);
    process.exit(1);
  });
