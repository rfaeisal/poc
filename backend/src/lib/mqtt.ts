import mqtt from 'mqtt';
import { config } from '../config';

export const mqttClient = mqtt.connect(config.MQTT_URL, {
  username: config.MQTT_USERNAME,
  password: config.MQTT_PASSWORD,
  clientId: `backend-${process.pid}`,
  clean: true,
  reconnectPeriod: 5000,
});

mqttClient.on('error', (err) => {
  console.error('MQTT connection error:', err.message);
});
