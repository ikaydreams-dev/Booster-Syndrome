import api from './api';

interface User {
  id: string;
  email: string;
  username: string;
  firstName?: string;
  lastName?: string;
  bio?: string;
  avatar?: string;
}

interface UpdateUserData {
  firstName?: string;
  lastName?: string;
  bio?: string;
  avatar?: string;
}

class UserService {
  async getUser(id: string): Promise<User> {
    const response = await api.get<{ data: User }>(`/users/${id}`);
    return response.data;
  }

  async updateUser(id: string, data: UpdateUserData): Promise<User> {
    const response = await api.put<{ data: User }>(`/users/${id}`, data);
    return response.data;
  }

  async getAllUsers(page: number = 1, limit: number = 10): Promise<any> {
    return await api.get('/users', { page, limit });
  }
}

export default new UserService();
