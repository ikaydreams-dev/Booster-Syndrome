import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api/v1';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('auth_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor
    this.client.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // Token expired, try to refresh
          const refreshToken = localStorage.getItem('refresh_token');
          if (refreshToken) {
            try {
              const response = await this.refreshToken(refreshToken);
              localStorage.setItem('auth_token', response.data.token);
              // Retry original request
              error.config.headers.Authorization = `Bearer ${response.data.token}`;
              return this.client.request(error.config);
            } catch (refreshError) {
              // Refresh failed, logout user
              localStorage.removeItem('auth_token');
              localStorage.removeItem('refresh_token');
              window.location.href = '/login';
            }
          }
        }
        return Promise.reject(error);
      }
    );
  }

  async get<T>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.get<T>(url, config);
  }

  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.post<T>(url, data, config);
  }

  async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.put<T>(url, data, config);
  }

  async patch<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.patch<T>(url, data, config);
  }

  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> {
    return this.client.delete<T>(url, config);
  }

  private async refreshToken(refreshToken: string): Promise<AxiosResponse> {
    return axios.post(`${API_BASE_URL}/auth/refresh`, { refreshToken });
  }
}

export const apiClient = new ApiClient();

// Auth API
export const authApi = {
  login: (email: string, password: string) =>
    apiClient.post('/auth/login', { email, password }),

  register: (email: string, password: string, username: string) =>
    apiClient.post('/auth/register', { email, password, username }),

  logout: () => apiClient.post('/auth/logout'),

  verifyEmail: (token: string) =>
    apiClient.post('/auth/verify-email', { token }),

  resetPassword: (email: string) =>
    apiClient.post('/auth/reset-password', { email }),
};

// User API
export const userApi = {
  getProfile: (userId: string) =>
    apiClient.get(`/users/${userId}`),

  updateProfile: (userId: string, data: any) =>
    apiClient.put(`/users/${userId}`, data),

  deleteAccount: (userId: string) =>
    apiClient.delete(`/users/${userId}`),

  getUsers: (params?: { page?: number; limit?: number }) =>
    apiClient.get('/users', { params }),
};

// Analytics API
export const analyticsApi = {
  trackEvent: (eventType: string, properties: any) =>
    apiClient.post('/analytics/events', { eventType, properties }),

  getAnalytics: (userId: string, startDate: string, endDate: string) =>
    apiClient.get(`/analytics/users/${userId}`, {
      params: { startDate, endDate },
    }),
};

export default apiClient;
