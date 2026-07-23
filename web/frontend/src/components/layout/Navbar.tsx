import React from 'react';
import { Link } from 'react-router-dom';

export const Navbar = () => {
  return (
    <nav className="bg-white shadow-md">
      <div className="max-w-7xl mx-auto px-4">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <Link to="/" className="text-2xl font-bold text-blue-600">
              Booster Syndrome
            </Link>
          </div>

          <div className="flex items-center space-x-4">
            <Link to="/dashboard" className="hover:text-blue-600">Dashboard</Link>
            <Link to="/analytics" className="hover:text-blue-600">Analytics</Link>
            <Link to="/users" className="hover:text-blue-600">Users</Link>
            <Link to="/settings" className="hover:text-blue-600">Settings</Link>
          </div>
        </div>
      </div>
    </nav>
  );
};
