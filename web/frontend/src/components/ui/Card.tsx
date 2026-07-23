import React, { HTMLAttributes } from 'react';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  padding?: 'none' | 'small' | 'medium' | 'large';
  shadow?: boolean;
  hover?: boolean;
}

export const Card: React.FC<CardProps> = ({
  children,
  padding = 'medium',
  shadow = true,
  hover = false,
  className = '',
  ...props
}) => {
  const paddingClasses = {
    none: '',
    small: 'p-2',
    medium: 'p-4',
    large: 'p-6',
  };

  return (
    <div
      className={`
        bg-white rounded-lg
        ${shadow ? 'shadow-md' : ''}
        ${hover ? 'hover:shadow-lg transition-shadow duration-200' : ''}
        ${paddingClasses[padding]}
        ${className}
      `}
      {...props}
    >
      {children}
    </div>
  );
};

export default Card;
