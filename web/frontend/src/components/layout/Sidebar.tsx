import React from 'react';
import { Link } from 'react-router-dom';

export const Sidebar = () => {
  return (
    <aside className="w-64 bg-gray-800 text-white h-screen">
      <div className="p-4">
        <h2 className="text-xl font-bold mb-6">Menu</h2>

        <nav className="space-y-2">
          <Link to="/dashboard" className="block px-4 py-2 rounded hover:bg-gray-700">
            Dashboard
          </Link>
          <Link to="/analytics" className="block px-4 py-2 rounded hover:bg-gray-700">
            Analytics
          </Link>
          <Link to="/users" className="block px-4 py-2 rounded hover:bg-gray-700">
            Users
          </Link>
          <Link to="/settings" className="block px-4 py-2 rounded hover:bg-gray-700">
            Settings
          </Link>
        </nav>
      </div>
    </aside>
  );
};
