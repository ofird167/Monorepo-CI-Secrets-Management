const express = require('express');
const app = express();

const port = process.env.PORT || 3000;
const host = process.env.HOST || '127.0.0.1';

// Setup basic JSON body parser
app.use(express.json());

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'UP',
    service: 'user-service',
    timestamp: new Date().toISOString()
  });
});

// Users List Endpoint
app.get('/api/users', (req, res) => {
  res.json([
    { id: 1, name: 'Alice', email: 'alice@example.com' },
    { id: 2, name: 'Bob', email: 'bob@example.com' }
  ]);
});

// Start listening
const server = app.listen(port, host, () => {
  console.log(`User Service listening on http://${host}:${port}`);
});

module.exports = server;
