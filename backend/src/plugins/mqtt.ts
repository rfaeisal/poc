import fp from 'fastify-plugin';
import { FastifyInstance } from 'fastify';
import { mqttClient } from '../lib/mqtt';

export default fp(async (fastify: FastifyInstance) => {
  fastify.decorate('mqtt', mqttClient);

  fastify.addHook('onClose', async () => {
    mqttClient.end();
  });
});

declare module 'fastify' {
  interface FastifyInstance {
    mqtt: typeof mqttClient;
  }
}
