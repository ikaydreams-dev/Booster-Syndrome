import React from 'react';

const Profile: React.FC = () => {
  return (
    <div className="max-w-4xl mx-auto">
      <h1 className="text-4xl font-bold text-gray-900 mb-8">Profile</h1>

      <div className="bg-white p-8 rounded-lg shadow">
        <div className="flex items-center mb-6">
          <div className="w-24 h-24 bg-indigo-600 rounded-full flex items-center justify-center text-white text-3xl font-bold">
            JD
          </div>
          <div className="ml-6">
            <h2 className="text-2xl font-bold text-gray-900">John Doe</h2>
            <p className="text-gray-600">john@example.com</p>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Username</label>
            <input
              type="text"
              defaultValue="johndoe"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Bio</label>
            <textarea
              rows={4}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
              defaultValue="Software developer passionate about microservices"
            />
          </div>
          <button className="bg-indigo-600 text-white py-2 px-6 rounded-md hover:bg-indigo-700">
            Save Changes
          </button>
        </div>
      </div>
    </div>
  );
};

export default Profile;
