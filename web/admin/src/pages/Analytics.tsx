import React from 'react';

const Analytics: React.FC = () => {
  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Analytics</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Traffic Overview</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Chart Placeholder
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">User Growth</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Chart Placeholder
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Revenue Trends</h2>
          <div className="h-64 flex items-center justify-center text-gray-400">
            Chart Placeholder
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Top Pages</h2>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span>/dashboard</span>
              <span className="font-semibold">45%</span>
            </div>
            <div className="flex justify-between items-center">
              <span>/analytics</span>
              <span className="font-semibold">28%</span>
            </div>
            <div className="flex justify-between items-center">
              <span>/users</span>
              <span className="font-semibold">18%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Analytics;
