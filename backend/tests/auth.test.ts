import { buildApp } from '../src/app';

describe('Auth Routes', () => {
  const app = buildApp();

  afterAll(async () => {
    await app.close();
  });

  it('should have health check endpoint', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });
    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.payload)).toHaveProperty('status', 'ok');
  });

  it('should reject register with invalid email', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        email: 'not-an-email',
        password: 'password123',
        callsign: 'TEST01',
        name: 'Test',
      },
    });
    expect(response.statusCode).toBe(400);
  });

  it('should reject register with short password', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        email: 'test@example.com',
        password: 'short',
        callsign: 'TEST01',
        name: 'Test',
      },
    });
    expect(response.statusCode).toBe(400);
  });
});
