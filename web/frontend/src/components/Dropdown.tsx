import React, { useState, useRef, useEffect } from 'react';
import clsx from 'clsx';

interface DropdownOption {
  value: string;
  label: string;
}

interface DropdownProps {
  options: DropdownOption[];
  value?: string;
  onChange: (value: string) => void;
  placeholder?: string;
  label?: string;
}

export const Dropdown: React.FC<DropdownProps> = ({
  options,
  value,
  onChange,
  placeholder = 'Select...',
  label,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectedOption = options.find((opt) => opt.value === value);

  return (
    <div className="relative" ref={dropdownRef}>
      {label && <label className="block text-sm font-medium text-gray-700 mb-1">{label}</label>}

      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={clsx(
          'w-full px-4 py-2 text-left bg-white border rounded-md shadow-sm',
          'focus:outline-none focus:ring-2 focus:ring-indigo-500',
          isOpen && 'ring-2 ring-indigo-500'
        )}
      >
        {selectedOption ? selectedOption.label : placeholder}
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-1 bg-white border rounded-md shadow-lg max-h-60 overflow-auto">
          {options.map((option) => (
            <div
              key={option.value}
              onClick={() => {
                onChange(option.value);
                setIsOpen(false);
              }}
              className={clsx(
                'px-4 py-2 cursor-pointer hover:bg-gray-100',
                value === option.value && 'bg-indigo-50 text-indigo-700'
              )}
            >
              {option.label}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
