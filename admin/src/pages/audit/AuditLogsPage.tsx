export function AuditLogsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Audit Logs</h1>
      <div className="rounded-xl border border-gray-200 bg-white p-8 text-center">
        <p className="text-gray-500">PTT audit logs — enterprise feature</p>
        <p className="mt-1 text-sm text-gray-400">
          Filter by channel, user, date range. Export to CSV.
        </p>
      </div>
    </div>
  );
}
