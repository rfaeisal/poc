import { FastifyInstance } from 'fastify';
import { usersRoute } from './users';
import { channelsRoute } from './channels';
import { statsRoute } from './stats';

export default async function adminRoutes(fastify: FastifyInstance) {
  fastify.register(statsRoute, { prefix: '/admin' });
  fastify.register(usersRoute, { prefix: '/admin' });
  fastify.register(channelsRoute, { prefix: '/admin' });
}
