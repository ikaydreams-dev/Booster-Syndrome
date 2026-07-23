import React from 'react';
import clsx from 'clsx';

interface SwitchProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  disabled?: boolean;
}

export const Switch: React.FC<SwitchProps> = ({
  checked,
  onChange,
  label,
  disabled = false,
}) => {
  return (
    <label className={clsx('flex items-center', disabled && 'opacity-50 cursor-not-allowed')}>
      <button
        type="button"
        onClick={() => !disabled && onChange(!checked)}
        className={clsx(
          'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
          checked ? 'bg-indigo-600' : 'bg-gray-200',
          disabled ? 'cursor-not-allowed' : 'cursor-pointer'
        )}
        disabled={disabled}
      >
        <span
          className={clsx(
            'inline-block h-4 w-4 transform rounded-full bg-white transition-transform',
            checked ? 'translate-x-6' : 'translate-x-1'
          )}
        />
      </button>
      {label && <span className="ml-3 text-sm text-gray-700">{label}</span>}
    </label>
  );
};
