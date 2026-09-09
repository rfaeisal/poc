import { FastifyInstance } from 'fastify';
import { WebhookReceiver } from 'livekit-server-sdk';
import { config } from '../../config';
import { prisma } from '../../lib/prisma';
import { publishPttEvent, publishMemberEvent, publishChannelStatus } from '../../services/mqtt.service';

export default async function livekitWebhookRoute(fastify: FastifyInstance) {
  const receiver = new WebhookReceiver(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET);

  fastify.post('/webhook/livekit', {
    config: { rawBody: true },
  }, async (request, reply) => {
    const authHeader = request.headers.authorization;
    if (!authHeader) {
      reply.code(401).send({ error: 'Missing authorization' });
      return;
    }

    let event;
    try {
      const body = typeof request.body === 'string' ? request.body : JSON.stringify(request.body);
      event = await receiver.receive(body, authHeader);
    } catch {
      reply.code(401).send({ error: 'Invalid webhook signature' });
      return;
    }

    const channel = event.room
      ? await prisma.channel.findUnique({ where: { livekitRoomId: event.room.name } })
      : null;

    switch (event.event) {
      case 'room_started':
        fastify.log.info({ room: event.room?.name }, 'Room started');
        break;

      case 'room_finished':
        fastify.log.info({ room: event.room?.name }, 'Room finished');
        break;

      case 'participant_joined':
        if (channel && event.participant) {
          const profile = await prisma.userProfile.findFirst({
            where: { userId: event.participant.identity },
          });
          publishMemberEvent(channel.id, event.participant.identity, profile?.callsign ?? 'unknown', 'join');

          const memberCount = await prisma.channelMember.count({ where: { channelId: channel.id } });
          publishChannelStatus(channel.id, memberCount, false);
        }
        break;

      case 'participant_left':
        if (channel && event.participant) {
          const profile = await prisma.userProfile.findFirst({
            where: { userId: event.participant.identity },
          });
          publishMemberEvent(channel.id, event.participant.identity, profile?.callsign ?? 'unknown', 'leave');

          const memberCount = await prisma.channelMember.count({ where: { channelId: channel.id } });
          publishChannelStatus(channel.id, memberCount, false);
        }
        break;

      case 'track_published':
        if (channel && event.participant && event.track?.type === 'AUDIO') {
          const profile = await prisma.userProfile.findFirst({
            where: { userId: event.participant.identity },
          });
          publishPttEvent(channel.id, event.participant.identity, profile?.callsign ?? 'unknown', 'start');

          await prisma.pttLog.create({
            data: {
              channelId: channel.id,
              userId: event.participant.identity,
              startedAt: new Date(),
            },
          });

          const memberCount = await prisma.channelMember.count({ where: { channelId: channel.id } });
          publishChannelStatus(channel.id, memberCount, true, event.participant.identity);
        }
        break;

      case 'track_unpublished':
        if (channel && event.participant && event.track?.type === 'AUDIO') {
          const profile = await prisma.userProfile.findFirst({
            where: { userId: event.participant.identity },
          });
          publishPttEvent(channel.id, event.participant.identity, profile?.callsign ?? 'unknown', 'end');

          const openLog = await prisma.pttLog.findFirst({
            where: {
              channelId: channel.id,
              userId: event.participant.identity,
              endedAt: null,
            },
            orderBy: { startedAt: 'desc' },
          });

          if (openLog) {
            const endedAt = new Date();
            await prisma.pttLog.update({
              where: { id: openLog.id },
              data: {
                endedAt,
                durationMs: endedAt.getTime() - openLog.startedAt.getTime(),
              },
            });
          }

          const memberCount = await prisma.channelMember.count({ where: { channelId: channel.id } });
          publishChannelStatus(channel.id, memberCount, false);
        }
        break;
    }

    reply.send({ ok: true });
  });
}
