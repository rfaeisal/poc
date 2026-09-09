import { FastifyInstance } from 'fastify';
import { createRoute } from './create';
import { membersRoute } from './members';
import { settingsRoute } from './settings';

export default async function organizationRoutes(fastify: FastifyInstance) {
  fastify.register(createRoute, { prefix: '/organizations' });
  fastify.register(membersRoute, { prefix: '/organizations' });
  fastify.register(settingsRoute, { prefix: '/organizations' });
}
