import React from 'react';
import { Card } from '../components/ui/Card';

export const SettingsPage = () => {
  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <Card className="mb-6">
        <h2 className="text-xl font-semibold mb-4">Profile Settings</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input type="email" className="w-full border px-3 py-2 rounded" />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Username</label>
            <input type="text" className="w-full border px-3 py-2 rounded" />
          </div>
        </div>
      </Card>

      <Card>
        <h2 className="text-xl font-semibold mb-4">Notifications</h2>
        <div className="space-y-2">
          <label className="flex items-center">
            <input type="checkbox" className="mr-2" />
            Email notifications
          </label>
          <label className="flex items-center">
            <input type="checkbox" className="mr-2" />
            Push notifications
          </label>
        </div>
      </Card>
    </div>
  );
};
