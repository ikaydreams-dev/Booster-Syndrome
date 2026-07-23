import React from 'react';

const Analytics: React.FC = () => {
  return (
    <div className="max-w-7xl mx-auto">
      <h1 className="text-4xl font-bold text-gray-900 mb-8">Analytics</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Event Distribution</h3>
          <div className="h-64 flex items-center justify-center text-gray-500">
            Chart Placeholder
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">User Growth</h3>
          <div className="h-64 flex items-center justify-center text-gray-500">
            Chart Placeholder
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Events</h3>
        <table className="min-w-full">
          <thead>
            <tr className="border-b">
              <th className="text-left py-2">Event</th>
              <th className="text-left py-2">User</th>
              <th className="text-left py-2">Time</th>
            </tr>
          </thead>
          <tbody>
            <tr className="border-b">
              <td className="py-2">Login</td>
              <td className="py-2">user@example.com</td>
              <td className="py-2">2 min ago</td>
            </tr>
            <tr className="border-b">
              <td className="py-2">File Upload</td>
              <td className="py-2">admin@example.com</td>
              <td className="py-2">5 min ago</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Analytics;
