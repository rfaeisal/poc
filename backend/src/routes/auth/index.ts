import { FastifyInstance } from 'fastify';
import { registerRoute } from './register';
import { loginRoute } from './login';
import { refreshRoute } from './refresh';
import { logoutRoute } from './logout';
import { meRoute } from './me';

export default async function authRoutes(fastify: FastifyInstance) {
  fastify.register(registerRoute, { prefix: '/auth' });
  fastify.register(loginRoute, { prefix: '/auth' });
  fastify.register(refreshRoute, { prefix: '/auth' });
  fastify.register(logoutRoute, { prefix: '/auth' });
  fastify.register(meRoute, { prefix: '/auth' });
}
