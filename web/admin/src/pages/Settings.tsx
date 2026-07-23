import React from 'react';

const Settings: React.FC = () => {
  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <h2 className="text-xl font-semibold mb-4">General Settings</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Site Name
            </label>
            <input
              type="text"
              defaultValue="Booster Syndrome"
              className="w-full px-3 py-2 border rounded-md"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Contact Email
            </label>
            <input
              type="email"
              defaultValue="admin@example.com"
              className="w-full px-3 py-2 border rounded-md"
            />
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <h2 className="text-xl font-semibold mb-4">API Configuration</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              API Key
            </label>
            <input
              type="text"
              value="••••••••••••••••"
              className="w-full px-3 py-2 border rounded-md"
              readOnly
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Rate Limit (requests/min)
            </label>
            <input
              type="number"
              defaultValue="100"
              className="w-full px-3 py-2 border rounded-md"
            />
          </div>
        </div>
      </div>

      <button className="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700">
        Save Changes
      </button>
    </div>
  );
};

export default Settings;
