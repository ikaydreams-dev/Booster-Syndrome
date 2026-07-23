import React from 'react';
import { Card } from '../components/ui/Card';

export const DashboardPage = () => {
  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <h1 className="text-3xl font-bold mb-6">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <h3 className="text-lg font-semibold">Total Users</h3>
          <p className="text-4xl font-bold mt-2">1,234</p>
        </Card>

        <Card>
          <h3 className="text-lg font-semibold">Active Sessions</h3>
          <p className="text-4xl font-bold mt-2">567</p>
        </Card>

        <Card>
          <h3 className="text-lg font-semibold">API Calls</h3>
          <p className="text-4xl font-bold mt-2">89,123</p>
        </Card>
      </div>
    </div>
  );
};
