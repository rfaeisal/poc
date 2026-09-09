import { mqttClient } from '../lib/mqtt';

function publish(topic: string, payload: Record<string, unknown>) {
  mqttClient.publish(topic, JSON.stringify(payload), { qos: 1 });
}

export function publishPttEvent(channelId: string, userId: string, callsign: string, action: 'start' | 'end') {
  publish(`poc/channels/${channelId}/ptt`, { userId, callsign, action, timestamp: Date.now() });
}

export function publishMemberEvent(channelId: string, userId: string, callsign: string, action: 'join' | 'leave') {
  publish(`poc/channels/${channelId}/members`, { userId, callsign, action, timestamp: Date.now() });
}

export function publishChannelStatus(channelId: string, activeUsers: number, isTransmitting: boolean, transmitterId?: string) {
  publish(`poc/channels/${channelId}/status`, { activeUsers, isTransmitting, transmitterId, timestamp: Date.now() });
}

export function publishUserPresence(userId: string, status: 'online' | 'offline', extra?: { battery?: number; signalStrength?: number }) {
  publish(`poc/users/${userId}/presence`, { status, ...extra, timestamp: Date.now() });
}

export function publishUserLocation(userId: string, lat: number, lng: number) {
  publish(`poc/users/${userId}/location`, { lat, lng, timestamp: Date.now() });
}

export function publishSystemAnnouncement(message: string) {
  publish('poc/system/announcements', { message, timestamp: Date.now() });
}

export function publishOrgAlert(orgId: string, message: string) {
  publish(`poc/organizations/${orgId}/alerts`, { message, timestamp: Date.now() });
}
