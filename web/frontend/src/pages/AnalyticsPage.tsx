import React from 'react';
import { Card } from '../components/ui/Card';

export const AnalyticsPage = () => {
  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Analytics</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <Card>
          <h3 className="text-sm text-gray-600">Total Events</h3>
          <p className="text-3xl font-bold mt-2">125,430</p>
        </Card>
        <Card>
          <h3 className="text-sm text-gray-600">Active Users</h3>
          <p className="text-3xl font-bold mt-2">8,245</p>
        </Card>
        <Card>
          <h3 className="text-sm text-gray-600">Conversion Rate</h3>
          <p className="text-3xl font-bold mt-2">12.4%</p>
        </Card>
      </div>

      <Card>
        <h2 className="text-xl font-semibold mb-4">Event Timeline</h2>
        <div className="h-64 bg-gray-100 rounded"></div>
      </Card>
    </div>
  );
};
