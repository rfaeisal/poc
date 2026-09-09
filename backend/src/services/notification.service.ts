import { prisma } from '../lib/prisma';

export async function registerDevice(userId: string, data: {
  deviceId: string;
  fcmToken?: string;
  platform: 'ANDROID' | 'IOS' | 'DESKTOP';
  appVersion: string;
}) {
  return prisma.device.upsert({
    where: {
      userId_deviceId: { userId, deviceId: data.deviceId },
    },
    update: {
      fcmToken: data.fcmToken,
      appVersion: data.appVersion,
      lastSeenAt: new Date(),
    },
    create: {
      userId,
      ...data,
    },
  });
}

export async function removeDevice(userId: string, deviceId: string) {
  await prisma.device.deleteMany({
    where: { userId, deviceId },
  });
}

export async function getUserDevices(userId: string) {
  return prisma.device.findMany({
    where: { userId },
    orderBy: { lastSeenAt: 'desc' },
  });
}
