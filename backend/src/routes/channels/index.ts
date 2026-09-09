import { FastifyInstance } from 'fastify';
import { listRoute } from './list';
import { createRoute } from './create';
import { getRoute } from './get';
import { updateRoute } from './update';
import { deleteRoute } from './delete';
import { joinRoute } from './join';
import { leaveRoute } from './leave';
import { membersRoute } from './members';

export default async function channelRoutes(fastify: FastifyInstance) {
  fastify.register(listRoute, { prefix: '/channels' });
  fastify.register(createRoute, { prefix: '/channels' });
  fastify.register(getRoute, { prefix: '/channels' });
  fastify.register(updateRoute, { prefix: '/channels' });
  fastify.register(deleteRoute, { prefix: '/channels' });
  fastify.register(joinRoute, { prefix: '/channels' });
  fastify.register(leaveRoute, { prefix: '/channels' });
  fastify.register(membersRoute, { prefix: '/channels' });
}
