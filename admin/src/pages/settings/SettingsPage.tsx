import { config } from '@/config';

export function SettingsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Settings</h1>

      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">System Info</h2>
        <div className="space-y-3">
          <div className="flex items-center justify-between border-b border-gray-100 pb-2">
            <span className="text-sm text-gray-500">API URL</span>
            <span className="font-mono text-sm text-gray-900">{config.apiBaseUrl}</span>
          </div>
          <div className="flex items-center justify-between border-b border-gray-100 pb-2">
            <span className="text-sm text-gray-500">MQTT URL</span>
            <span className="font-mono text-sm text-gray-900">{config.mqttUrl}</span>
          </div>
          <div className="flex items-center justify-between border-b border-gray-100 pb-2">
            <span className="text-sm text-gray-500">LiveKit URL</span>
            <span className="font-mono text-sm text-gray-900">{config.livekitUrl}</span>
          </div>
        </div>
      </div>
    </div>
  );
}
