export const config = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000',
  mqttUrl: import.meta.env.VITE_MQTT_URL || 'ws://localhost:9001',
  livekitUrl: import.meta.env.VITE_LIVEKIT_URL || 'ws://localhost:7880',
  appName: import.meta.env.VITE_APP_NAME || 'POC-Pecek Admin',
};
