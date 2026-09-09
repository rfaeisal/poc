import { NavLink } from 'react-router-dom';
import { config } from '@/config';

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: 'BarChart3' },
  { to: '/users', label: 'Users', icon: 'Users' },
  { to: '/channels', label: 'Channels', icon: 'Radio' },
  { to: '/organizations', label: 'Organizations', icon: 'Building2' },
  { to: '/monitor', label: 'Live Monitor', icon: 'Activity' },
  { to: '/audit', label: 'Audit Logs', icon: 'ClipboardList' },
  { to: '/settings', label: 'Settings', icon: 'Settings' },
];

export function Sidebar() {
  return (
    <aside className="flex w-64 flex-col border-r border-gray-200 bg-white">
      <div className="flex h-16 items-center gap-2 border-b border-gray-200 px-6">
        <span className="text-xl">📻</span>
        <span className="font-semibold text-gray-900">{config.appName}</span>
      </div>
      <nav className="flex-1 space-y-1 px-3 py-4">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
              }`
            }
          >
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
