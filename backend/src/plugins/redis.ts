import fp from 'fastify-plugin';
import { FastifyInstance } from 'fastify';
import { redis } from '../lib/redis';

export default fp(async (fastify: FastifyInstance) => {
  fastify.decorate('redis', redis);

  fastify.addHook('onClose', async () => {
    redis.disconnect();
  });
});

declare module 'fastify' {
  interface FastifyInstance {
    redis: typeof redis;
  }
}
