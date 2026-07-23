import api from './api';

interface LoginCredentials {
  email: string;
  password: string;
}

interface RegisterData {
  email: string;
  username: string;
  password: string;
}

interface AuthResponse {
  user: any;
  tokens: {
    access_token: string;
    refresh_token: string;
  };
}

class AuthService {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    return await api.post<AuthResponse>('/auth/login', credentials);
  }

  async register(data: RegisterData): Promise<AuthResponse> {
    return await api.post<AuthResponse>('/auth/register', data);
  }

  async logout(): Promise<void> {
    const refreshToken = localStorage.getItem('refresh_token');
    await api.post('/auth/logout', { refresh_token: refreshToken });
    localStorage.removeItem('token');
    localStorage.removeItem('refresh_token');
  }

  async refreshToken(): Promise<AuthResponse> {
    const refreshToken = localStorage.getItem('refresh_token');
    return await api.post<AuthResponse>('/auth/refresh', {
      refresh_token: refreshToken,
    });
  }
}

export default new AuthService();
