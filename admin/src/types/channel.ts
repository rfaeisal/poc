import { User } from './user';

export interface Channel {
  id: string;
  livekitRoomId: string;
  name: string;
  description: string | null;
  isPrivate: boolean;
  maxMembers: number;
  isActive: boolean;
  createdAt: string;
  createdById: string;
  organizationId: string | null;
  _count?: { members: number };
  members?: ChannelMember[];
}

export interface ChannelMember {
  id: string;
  channelId: string;
  userId: string;
  role: 'MEMBER' | 'MODERATOR' | 'ADMIN';
  joinedAt: string;
  isMuted: boolean;
  user: User;
}
