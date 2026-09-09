import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import bcrypt from 'bcrypt';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';
import { prisma } from '../../lib/prisma';

const banSchema = z.object({
  reason: z.string().min(1).max(500),
});

const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  callsign: z.string().min(2).max(20),
  name: z.string().min(1).max(100),
  role: z.enum(['USER', 'MODERATOR', 'ADMIN']).default('USER'),
});

const updateUserSchema = z.object({
  email: z.string().email().optional(),
  callsign: z.string().min(2).max(20).optional(),
  name: z.string().min(1).max(100).optional(),
  role: z.enum(['USER', 'MODERATOR', 'ADMIN']).optional(),
  password: z.string().min(6).optional(),
  bio: z.string().max(500).optional(),
});

export async function usersRoute(fastify: FastifyInstance) {
  // List users
  fastify.get('/users', { preHandler: [authenticate, authorize('ADMIN')] }, async (request) => {
    const query = request.query as { page?: string; limit?: string; q?: string };
    const page = Math.max(1, parseInt(query.page ?? '1'));
    const limit = Math.min(100, Math.max(1, parseInt(query.limit ?? '20')));

    const where = query.q
      ? {
          OR: [
            { email: { contains: query.q, mode: 'insensitive' as const } },
            { profile: { callsign: { contains: query.q, mode: 'insensitive' as const } } },
            { profile: { name: { contains: query.q, mode: 'insensitive' as const } } },
          ],
        }
      : {};

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: { profile: true },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.user.count({ where }),
    ]);

    return {
      users: users.map((u) => ({
        id: u.id,
        email: u.email,
        role: u.role,
        isActive: u.isActive,
        isBanned: u.isBanned,
        bannedReason: u.bannedReason,
        createdAt: u.createdAt,
        lastSeenAt: u.lastSeenAt,
        profile: u.profile,
      })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  });

  // Get single user
  fastify.get<{ Params: { id: string } }>(
    '/users/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const user = await prisma.user.findUnique({
        where: { id: request.params.id },
        include: {
          profile: true,
          channelMembers: {
            include: { channel: { select: { id: true, name: true } } },
          },
          _count: { select: { devices: true, pttLogs: true, refreshTokens: true } },
        },
      });
      if (!user) {
        reply.code(404).send({ error: 'User not found' });
        return;
      }
      return {
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          isActive: user.isActive,
          isBanned: user.isBanned,
          bannedReason: user.bannedReason,
          createdAt: user.createdAt,
          lastSeenAt: user.lastSeenAt,
          profile: user.profile,
          channels: user.channelMembers.map((cm) => ({
            id: cm.channel.id,
            name: cm.channel.name,
            role: cm.role,
            joinedAt: cm.joinedAt,
          })),
          _count: user._count,
        },
      };
    }
  );

  // Create user
  fastify.post(
    '/users',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const body = createUserSchema.parse(request.body);

      const existing = await prisma.user.findUnique({ where: { email: body.email } });
      if (existing) {
        reply.code(409).send({ error: 'Email already in use' });
        return;
      }

      const existingCallsign = await prisma.userProfile.findUnique({ where: { callsign: body.callsign } });
      if (existingCallsign) {
        reply.code(409).send({ error: 'Callsign already in use' });
        return;
      }

      const passwordHash = await bcrypt.hash(body.password, 12);
      const user = await prisma.user.create({
        data: {
          email: body.email,
          passwordHash,
          role: body.role,
          profile: {
            create: {
              callsign: body.callsign,
              name: body.name,
            },
          },
        },
        include: { profile: true },
      });

      reply.code(201).send({
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          isActive: user.isActive,
          isBanned: user.isBanned,
          createdAt: user.createdAt,
          profile: user.profile,
        },
      });
    }
  );

  // Update user
  fastify.patch<{ Params: { id: string } }>(
    '/users/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const body = updateUserSchema.parse(request.body);
      const userId = request.params.id;

      const existing = await prisma.user.findUnique({ where: { id: userId }, include: { profile: true } });
      if (!existing) {
        reply.code(404).send({ error: 'User not found' });
        return;
      }

      if (body.email && body.email !== existing.email) {
        const emailTaken = await prisma.user.findUnique({ where: { email: body.email } });
        if (emailTaken) {
          reply.code(409).send({ error: 'Email already in use' });
          return;
        }
      }

      if (body.callsign && body.callsign !== existing.profile?.callsign) {
        const callsignTaken = await prisma.userProfile.findUnique({ where: { callsign: body.callsign } });
        if (callsignTaken) {
          reply.code(409).send({ error: 'Callsign already in use' });
          return;
        }
      }

      const userUpdate: Record<string, unknown> = {};
      if (body.email) userUpdate.email = body.email;
      if (body.role) userUpdate.role = body.role;
      if (body.password) userUpdate.passwordHash = await bcrypt.hash(body.password, 12);

      const profileUpdate: Record<string, unknown> = {};
      if (body.callsign) profileUpdate.callsign = body.callsign;
      if (body.name) profileUpdate.name = body.name;
      if (body.bio !== undefined) profileUpdate.bio = body.bio;

      const user = await prisma.user.update({
        where: { id: userId },
        data: {
          ...userUpdate,
          ...(Object.keys(profileUpdate).length > 0
            ? { profile: { update: profileUpdate } }
            : {}),
        },
        include: { profile: true },
      });

      return {
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          isActive: user.isActive,
          isBanned: user.isBanned,
          createdAt: user.createdAt,
          lastSeenAt: user.lastSeenAt,
          profile: user.profile,
        },
      };
    }
  );

  // Delete user
  fastify.delete<{ Params: { id: string } }>(
    '/users/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const userId = request.params.id;

      if (userId === request.user.sub) {
        reply.code(400).send({ error: 'Cannot delete yourself' });
        return;
      }

      const existing = await prisma.user.findUnique({ where: { id: userId } });
      if (!existing) {
        reply.code(404).send({ error: 'User not found' });
        return;
      }

      await prisma.user.delete({ where: { id: userId } });
      reply.send({ success: true });
    }
  );

  // Ban user
  fastify.post<{ Params: { id: string } }>(
    '/users/:id/ban',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const { reason } = banSchema.parse(request.body);
      await prisma.user.update({
        where: { id: request.params.id },
        data: { isBanned: true, bannedReason: reason },
      });
      reply.send({ success: true });
    }
  );

  // Unban user
  fastify.post<{ Params: { id: string } }>(
    '/users/:id/unban',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      await prisma.user.update({
        where: { id: request.params.id },
        data: { isBanned: false, bannedReason: null },
      });
      reply.send({ success: true });
    }
  );
}
