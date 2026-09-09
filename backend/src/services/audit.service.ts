import { prisma } from '../lib/prisma';

export async function logPttStart(channelId: string, userId: string) {
  return prisma.pttLog.create({
    data: {
      channelId,
      userId,
      startedAt: new Date(),
    },
  });
}

export async function logPttEnd(logId: string) {
  const log = await prisma.pttLog.findUnique({ where: { id: logId } });
  if (!log) return null;

  const endedAt = new Date();
  const durationMs = endedAt.getTime() - log.startedAt.getTime();

  return prisma.pttLog.update({
    where: { id: logId },
    data: { endedAt, durationMs },
  });
}

export async function getChannelPttLogs(channelId: string, limit = 50, offset = 0) {
  return prisma.pttLog.findMany({
    where: { channelId },
    include: {
      user: { include: { profile: true } },
    },
    orderBy: { startedAt: 'desc' },
    take: limit,
    skip: offset,
  });
}
