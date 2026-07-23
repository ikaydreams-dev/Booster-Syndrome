export const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
export const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
export const USERNAME_REGEX = /^[a-zA-Z0-9_-]{3,20}$/;

export interface ValidationError {
  field: string;
  message: string;
}

export const isValidEmail = (email: string): boolean => {
  return EMAIL_REGEX.test(email.trim());
};

export const isValidPassword = (password: string): boolean => {
  return password.length >= 8 && PASSWORD_REGEX.test(password);
};

export const isValidUsername = (username: string): boolean => {
  return USERNAME_REGEX.test(username.trim());
};

export const isRequired = (value: any): boolean => {
  if (typeof value === 'string') return value.trim().length > 0;
  if (Array.isArray(value)) return value.length > 0;
  return value !== null && value !== undefined && value !== '';
};

export const minLength = (value: string, min: number): boolean => {
  return value.length >= min;
};

export const maxLength = (value: string, max: number): boolean => {
  return value.length <= max;
};

export const isNumeric = (value: string): boolean => {
  return !isNaN(Number(value)) && value.trim() !== '';
};

export const isUrl = (url: string): boolean => {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

export const passwordsMatch = (password: string, confirm: string): boolean => {
  return password === confirm;
};

export const getPasswordStrength = (password: string): {
  strength: 'weak' | 'medium' | 'strong' | 'very-strong';
  score: number;
} => {
  let score = 0;

  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (/[a-z]/.test(password)) score++;
  if (/[A-Z]/.test(password)) score++;
  if (/\d/.test(password)) score++;
  if (/[@$!%*?&#]/.test(password)) score++;
  if (password.length >= 16) score++;

  let strength: 'weak' | 'medium' | 'strong' | 'very-strong';
  if (score <= 2) strength = 'weak';
  else if (score <= 4) strength = 'medium';
  else if (score <= 5) strength = 'strong';
  else strength = 'very-strong';

  return { strength, score };
};

export const sanitizeInput = (input: string): string => {
  return input
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;');
};

export const validateForm = <T extends Record<string, any>>(
  data: T,
  rules: Partial<Record<keyof T, ((value: any) => boolean)[]>>
): ValidationError[] => {
  const errors: ValidationError[] = [];

  for (const [field, validators] of Object.entries(rules)) {
    const value = data[field as keyof T];
    for (const validator of validators as ((value: any) => boolean)[]) {
      if (!validator(value)) {
        errors.push({
          field,
          message: `${field} validation failed`,
        });
      }
    }
  }

  return errors;
};

export default {
  isValidEmail,
  isValidPassword,
  isValidUsername,
  isRequired,
  minLength,
  maxLength,
  isNumeric,
  isUrl,
  passwordsMatch,
  getPasswordStrength,
  sanitizeInput,
  validateForm,
};
