import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';
import { prisma } from '../../lib/prisma';
import { deleteRoom } from '../../services/livekit.service';

const updateSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  description: z.string().max(500).optional(),
  maxMembers: z.number().min(2).max(500).optional(),
  isActive: z.boolean().optional(),
  isPrivate: z.boolean().optional(),
});

const addMemberSchema = z.object({
  userId: z.string().uuid(),
  role: z.enum(['MEMBER', 'MODERATOR', 'ADMIN']).default('MEMBER'),
});

export async function channelsRoute(fastify: FastifyInstance) {
  // Admin update channel (bypasses membership check)
  fastify.patch<{ Params: { id: string } }>(
    '/channels/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (!channel) {
        reply.code(404).send({ error: 'Channel not found' });
        return;
      }

      const body = updateSchema.parse(request.body);
      const updated = await prisma.channel.update({
        where: { id: request.params.id },
        data: body,
        include: {
          _count: { select: { members: true } },
          members: {
            include: { user: { include: { profile: true } } },
          },
        },
      });

      return { channel: updated };
    }
  );

  // Admin add member to channel
  fastify.post<{ Params: { id: string } }>(
    '/channels/:id/members',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const { userId, role } = addMemberSchema.parse(request.body);

      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (!channel) {
        reply.code(404).send({ error: 'Channel not found' });
        return;
      }

      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) {
        reply.code(404).send({ error: 'User not found' });
        return;
      }

      const existing = await prisma.channelMember.findUnique({
        where: { channelId_userId: { channelId: request.params.id, userId } },
      });
      if (existing) {
        reply.code(409).send({ error: 'User already a member' });
        return;
      }

      const memberCount = await prisma.channelMember.count({ where: { channelId: request.params.id } });
      if (memberCount >= channel.maxMembers) {
        reply.code(400).send({ error: 'Channel is full' });
        return;
      }

      const member = await prisma.channelMember.create({
        data: { channelId: request.params.id, userId, role },
        include: { user: { include: { profile: true } } },
      });

      return { member };
    }
  );

  // Admin remove member from channel
  fastify.delete<{ Params: { id: string; userId: string } }>(
    '/channels/:id/members/:userId',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (!channel) {
        reply.code(404).send({ error: 'Channel not found' });
        return;
      }

      const member = await prisma.channelMember.findUnique({
        where: { channelId_userId: { channelId: request.params.id, userId: request.params.userId } },
      });
      if (!member) {
        reply.code(404).send({ error: 'Member not found' });
        return;
      }

      await prisma.channelMember.delete({
        where: { channelId_userId: { channelId: request.params.id, userId: request.params.userId } },
      });

      return { success: true };
    }
  );

  // Admin delete channel
  fastify.delete<{ Params: { id: string } }>(
    '/channels/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (!channel) {
        reply.code(404).send({ error: 'Channel not found' });
        return;
      }

      try {
        await deleteRoom(channel.livekitRoomId);
      } catch {
        // Room might not exist
      }

      await prisma.channel.delete({ where: { id: request.params.id } });
      reply.send({ success: true });
    }
  );
}
