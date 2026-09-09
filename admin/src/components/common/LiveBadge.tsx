export function LiveBadge() {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
      <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-red-500" />
      LIVE
    </span>
  );
}
