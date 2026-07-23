export const isEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const isStrongPassword = (password: string): boolean => {
  return (
    password.length >= 8 &&
    /[A-Z]/.test(password) &&
    /[a-z]/.test(password) &&
    /[0-9]/.test(password)
  );
};

export const isValidUsername = (username: string): boolean => {
  return (
    username.length >= 3 &&
    username.length <= 50 &&
    /^[a-zA-Z0-9_-]+$/.test(username)
  );
};

export const sanitizeString = (input: string): string => {
  return input.trim().replace(/[<>]/g, '');
};

export const validatePaginationParams = (page: number, limit: number): boolean => {
  return page > 0 && limit > 0 && limit <= 100;
};
