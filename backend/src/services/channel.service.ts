import crypto from 'crypto';
import bcrypt from 'bcrypt';
import { prisma } from '../lib/prisma';

export async function createChannel(data: {
  name: string;
  description?: string;
  isPrivate: boolean;
  password?: string;
  maxMembers?: number;
  organizationId?: string;
  createdById: string;
}) {
  const livekitRoomId = `ch-${crypto.randomBytes(8).toString('hex')}`;
  const hashedPassword = data.password ? await bcrypt.hash(data.password, 10) : null;

  const channel = await prisma.channel.create({
    data: {
      livekitRoomId,
      name: data.name,
      description: data.description,
      isPrivate: data.isPrivate,
      password: hashedPassword,
      maxMembers: data.maxMembers ?? 500,
      organizationId: data.organizationId,
      createdById: data.createdById,
      members: {
        create: {
          userId: data.createdById,
          role: 'ADMIN',
        },
      },
    },
    include: { members: true },
  });

  return channel;
}

export async function listChannels(userId: string) {
  return prisma.channel.findMany({
    where: {
      isActive: true,
      OR: [
        { isPrivate: false },
        { members: { some: { userId } } },
      ],
    },
    include: {
      _count: { select: { members: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
}

export async function getChannel(channelId: string) {
  return prisma.channel.findUnique({
    where: { id: channelId },
    include: {
      members: {
        include: {
          user: { include: { profile: true } },
        },
      },
      _count: { select: { members: true } },
    },
  });
}

export async function joinChannel(channelId: string, userId: string, password?: string) {
  const channel = await prisma.channel.findUnique({ where: { id: channelId } });
  if (!channel || !channel.isActive) return { error: 'Channel not found' };

  const existingMember = await prisma.channelMember.findUnique({
    where: { channelId_userId: { channelId, userId } },
  });
  if (existingMember) return { channel, member: existingMember };

  const memberCount = await prisma.channelMember.count({ where: { channelId } });
  if (memberCount >= channel.maxMembers) return { error: 'Channel is full' };

  if (channel.isPrivate && channel.password) {
    if (!password) return { error: 'Password required' };
    const valid = await bcrypt.compare(password, channel.password);
    if (!valid) return { error: 'Invalid password' };
  }

  const member = await prisma.channelMember.create({
    data: { channelId, userId },
  });

  return { channel, member };
}

export async function leaveChannel(channelId: string, userId: string) {
  await prisma.channelMember.deleteMany({
    where: { channelId, userId },
  });
}

export async function getChannelMembers(channelId: string) {
  return prisma.channelMember.findMany({
    where: { channelId },
    include: {
      user: { include: { profile: true } },
    },
  });
}

export async function updateMemberRole(channelId: string, userId: string, role: 'MEMBER' | 'MODERATOR' | 'ADMIN') {
  return prisma.channelMember.update({
    where: { channelId_userId: { channelId, userId } },
    data: { role },
  });
}

export async function muteMember(channelId: string, userId: string, isMuted: boolean) {
  return prisma.channelMember.update({
    where: { channelId_userId: { channelId, userId } },
    data: { isMuted },
  });
}

export async function kickMember(channelId: string, userId: string) {
  await prisma.channelMember.deleteMany({
    where: { channelId, userId },
  });
}
