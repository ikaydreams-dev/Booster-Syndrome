import React from 'react';
import { Link } from 'react-router-dom';

const NotFound: React.FC = () => {
  return (
    <div className="max-w-2xl mx-auto text-center py-16">
      <h1 className="text-6xl font-bold text-gray-900 mb-4">404</h1>
      <p className="text-2xl text-gray-600 mb-8">Page not found</p>
      <Link
        to="/"
        className="inline-block bg-indigo-600 text-white py-2 px-6 rounded-md hover:bg-indigo-700"
      >
        Go Home
      </Link>
    </div>
  );
};

export default NotFound;
