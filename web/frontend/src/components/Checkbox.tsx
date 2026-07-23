import React from 'react';
import clsx from 'clsx';

interface CheckboxProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  disabled?: boolean;
}

export const Checkbox: React.FC<CheckboxProps> = ({
  checked,
  onChange,
  label,
  disabled = false,
}) => {
  return (
    <label className={clsx('flex items-center', disabled && 'opacity-50 cursor-not-allowed')}>
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        disabled={disabled}
        className={clsx(
          'w-5 h-5 text-indigo-600 border-gray-300 rounded',
          'focus:ring-indigo-500 focus:ring-2',
          disabled ? 'cursor-not-allowed' : 'cursor-pointer'
        )}
      />
      {label && <span className="ml-2 text-sm text-gray-700">{label}</span>}
    </label>
  );
};
