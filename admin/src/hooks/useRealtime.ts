import { useEffect, useRef, useState, useCallback } from 'react';
import mqtt, { MqttClient } from 'mqtt';
import { config } from '@/config';

interface MqttMessage {
  topic: string;
  payload: Record<string, unknown>;
}

export function useRealtime(topics: string[]) {
  const clientRef = useRef<MqttClient | null>(null);
  const [messages, setMessages] = useState<MqttMessage[]>([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const client = mqtt.connect(config.mqttUrl, {
      clientId: `admin-${Date.now()}`,
      clean: true,
    });

    client.on('connect', () => {
      setConnected(true);
      topics.forEach((t) => client.subscribe(t));
    });

    client.on('message', (topic, payload) => {
      try {
        const parsed = JSON.parse(payload.toString());
        setMessages((prev) => [...prev.slice(-100), { topic, payload: parsed }]);
      } catch {
        // ignore non-JSON messages
      }
    });

    client.on('close', () => setConnected(false));
    clientRef.current = client;

    return () => {
      client.end();
    };
  }, [topics.join(',')]);

  const clearMessages = useCallback(() => setMessages([]), []);

  return { messages, connected, clearMessages };
}
