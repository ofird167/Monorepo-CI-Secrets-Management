const http = require('http');
const server = require('./index');

afterAll((done) => {
  server.close(done);
});

test('Health check endpoint returns status UP', (done) => {
  http.get('http://127.0.0.1:3000/health', (res) => {
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    res.on('end', () => {
      const body = JSON.parse(data);
      expect(res.statusCode).toBe(200);
      expect(body.status).toBe('UP');
      expect(body.service).toBe('user-service');
      done();
    });
  });
});
