import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { joinChannel } from '../../services/channel.service';
import { generateChannelToken } from '../../services/livekit.service';
import { publishMemberEvent } from '../../services/mqtt.service';
import { prisma } from '../../lib/prisma';

const joinSchema = z.object({
  password: z.string().optional(),
});

export async function joinRoute(fastify: FastifyInstance) {
  fastify.post<{ Params: { id: string } }>('/:id/join', { preHandler: [authenticate] }, async (request, reply) => {
    const body = joinSchema.parse(request.body ?? {});
    const result = await joinChannel(request.params.id, request.user.sub, body.password);

    if ('error' in result) {
      const code = result.error === 'Channel not found' ? 404 : 400;
      reply.code(code).send({ error: result.error });
      return;
    }

    const profile = await prisma.userProfile.findUnique({
      where: { userId: request.user.sub },
    });

    const memberRole = result.member!.role.toLowerCase() as 'member' | 'moderator' | 'admin';
    const token = await generateChannelToken(
      request.user.sub,
      profile?.callsign ?? 'unknown',
      result.channel!.id,
      result.channel!.livekitRoomId,
      memberRole
    );

    publishMemberEvent(result.channel!.id, request.user.sub, profile?.callsign ?? 'unknown', 'join');

    reply.send({
      channel: result.channel,
      livekitToken: token,
      livekitUrl: process.env.LIVEKIT_URL,
    });
  });
}
