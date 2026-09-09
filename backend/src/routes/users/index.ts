import { FastifyInstance } from 'fastify';
import { profileRoute } from './profile';
import { searchRoute } from './search';
import { devicesRoute } from './devices';

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.register(searchRoute, { prefix: '/users' });
  fastify.register(profileRoute, { prefix: '/users' });
  fastify.register(devicesRoute, { prefix: '/users' });
}
