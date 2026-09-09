import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { registerDevice, removeDevice, getUserDevices } from '../../services/notification.service';

const registerDeviceSchema = z.object({
  deviceId: z.string().min(1),
  fcmToken: z.string().optional(),
  platform: z.enum(['ANDROID', 'IOS', 'DESKTOP']),
  appVersion: z.string().min(1),
});

export async function devicesRoute(fastify: FastifyInstance) {
  fastify.get('/devices', { preHandler: [authenticate] }, async (request) => {
    const devices = await getUserDevices(request.user.sub);
    return { devices };
  });

  fastify.post('/devices', { preHandler: [authenticate] }, async (request, reply) => {
    const body = registerDeviceSchema.parse(request.body);
    const device = await registerDevice(request.user.sub, body);
    reply.code(201).send({ device });
  });

  fastify.delete<{ Params: { deviceId: string } }>(
    '/devices/:deviceId',
    { preHandler: [authenticate] },
    async (request, reply) => {
      await removeDevice(request.user.sub, request.params.deviceId);
      reply.send({ success: true });
    }
  );
}
