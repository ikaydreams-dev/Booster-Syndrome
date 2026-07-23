import { useState, useEffect } from 'react';
import userService from '../services/userService';

export const useUser = (userId: string | null) => {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!userId) return;

    const fetchUser = async () => {
      setLoading(true);
      try {
        const userData = await userService.getUser(userId);
        setUser(userData);
        setError(null);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, [userId]);

  const updateUser = async (data: any) => {
    if (!userId) return;

    try {
      const updated = await userService.updateUser(userId, data);
      setUser(updated);
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  return { user, loading, error, updateUser };
};
