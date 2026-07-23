import React from 'react';

interface AlertProps {
  children: React.ReactNode;
  type?: 'success' | 'error' | 'warning' | 'info';
  onClose?: () => void;
}

export const Alert: React.FC<AlertProps> = ({ children, type = 'info', onClose }) => {
  const typeStyles = {
    success: 'bg-green-50 border-green-400 text-green-800',
    error: 'bg-red-50 border-red-400 text-red-800',
    warning: 'bg-yellow-50 border-yellow-400 text-yellow-800',
    info: 'bg-blue-50 border-blue-400 text-blue-800',
  };

  const icons = {
    success: '✓',
    error: '✕',
    warning: '⚠',
    info: 'ⓘ',
  };

  return (
    <div className={`border-l-4 p-4 ${typeStyles[type]} relative`} role="alert">
      <div className="flex items-start">
        <div className="flex-shrink-0">
          <span className="text-xl">{icons[type]}</span>
        </div>
        <div className="ml-3 flex-1">
          <p className="text-sm">{children}</p>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="flex-shrink-0 ml-3 text-gray-400 hover:text-gray-600"
          >
            ✕
          </button>
        )}
      </div>
    </div>
  );
};

export default Alert;
