import React from 'react';

export const Footer = () => {
  return (
    <footer className="bg-gray-800 text-white py-6">
      <div className="max-w-7xl mx-auto px-4">
        <div className="flex justify-between">
          <div>
            <p>&copy; 2024 Booster Syndrome. All rights reserved.</p>
          </div>

          <div className="flex space-x-4">
            <a href="/privacy" className="hover:text-gray-300">Privacy</a>
            <a href="/terms" className="hover:text-gray-300">Terms</a>
            <a href="/contact" className="hover:text-gray-300">Contact</a>
          </div>
        </div>
      </div>
    </footer>
  );
};
