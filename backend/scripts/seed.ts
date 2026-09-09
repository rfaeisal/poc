import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create admin user
  const adminPassword = await bcrypt.hash('admin123', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@pocpecek.local' },
    update: {},
    create: {
      email: 'admin@pocpecek.local',
      passwordHash: adminPassword,
      role: 'ADMIN',
      profile: {
        create: {
          callsign: 'ADMIN01',
          name: 'System Admin',
        },
      },
    },
  });
  console.log(`Admin user: ${admin.email}`);

  // Create test users
  const testPassword = await bcrypt.hash('test1234', 12);
  const users = [];
  for (let i = 1; i <= 5; i++) {
    const user = await prisma.user.upsert({
      where: { email: `user${i}@pocpecek.local` },
      update: {},
      create: {
        email: `user${i}@pocpecek.local`,
        passwordHash: testPassword,
        role: 'USER',
        profile: {
          create: {
            callsign: `JZ${String(i).padStart(2, '0')}TST`,
            name: `Test User ${i}`,
          },
        },
      },
    });
    users.push(user);
    console.log(`Test user: ${user.email}`);
  }

  // Create public channel
  const channel = await prisma.channel.upsert({
    where: { livekitRoomId: 'ch-seed-public-01' },
    update: {},
    create: {
      livekitRoomId: 'ch-seed-public-01',
      name: 'Channel Umum',
      description: 'Channel publik untuk testing',
      isPrivate: false,
      maxMembers: 500,
      createdById: admin.id,
      members: {
        create: [
          { userId: admin.id, role: 'ADMIN' },
          ...users.slice(0, 3).map((u) => ({ userId: u.id, role: 'MEMBER' as const })),
        ],
      },
    },
  });
  console.log(`Channel: ${channel.name}`);

  // Create private channel
  const privateChannel = await prisma.channel.upsert({
    where: { livekitRoomId: 'ch-seed-private-01' },
    update: {},
    create: {
      livekitRoomId: 'ch-seed-private-01',
      name: 'Channel Privat',
      description: 'Channel privat untuk testing',
      isPrivate: true,
      password: await bcrypt.hash('secret', 10),
      maxMembers: 50,
      createdById: admin.id,
      members: {
        create: [{ userId: admin.id, role: 'ADMIN' }],
      },
    },
  });
  console.log(`Private channel: ${privateChannel.name}`);

  // Create organization
  const org = await prisma.organization.upsert({
    where: { slug: 'test-org' },
    update: {},
    create: {
      name: 'Test Organization',
      slug: 'test-org',
      plan: 'COMMUNITY',
      maxUsers: 500,
      maxChannels: 50,
      users: {
        create: [
          { userId: admin.id, role: 'OWNER' },
          ...users.slice(0, 2).map((u) => ({ userId: u.id, role: 'MEMBER' as const })),
        ],
      },
    },
  });
  console.log(`Organization: ${org.name}`);

  console.log('Seeding complete!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
