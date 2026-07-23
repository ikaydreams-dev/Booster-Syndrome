export enum NotificationType {
  INFO = 'info',
  SUCCESS = 'success',
  WARNING = 'warning',
  ERROR = 'error',
}

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  read: boolean;
  actionUrl?: string;
  metadata?: Record<string, any>;
  createdAt: Date;
  expiresAt?: Date;
}

export interface NotificationPreferences {
  userId: string;
  emailEnabled: boolean;
  pushEnabled: boolean;
  smsEnabled: boolean;
  categories: {
    [category: string]: boolean;
  };
}

export class NotificationCenter {
  private notifications: Map<string, Notification[]> = new Map();
  private preferences: Map<string, NotificationPreferences> = new Map();

  createNotification(notification: Omit<Notification, 'id' | 'createdAt' | 'read'>): Notification {
    const newNotification: Notification = {
      ...notification,
      id: this.generateId(),
      read: false,
      createdAt: new Date(),
    };

    if (!this.notifications.has(notification.userId)) {
      this.notifications.set(notification.userId, []);
    }

    this.notifications.get(notification.userId)!.push(newNotification);

    return newNotification;
  }

  getUserNotifications(userId: string, unreadOnly: boolean = false): Notification[] {
    const userNotifications = this.notifications.get(userId) || [];

    const filtered = userNotifications.filter((n) => {
      if (n.expiresAt && new Date() > n.expiresAt) {
        return false;
      }

      if (unreadOnly && n.read) {
        return false;
      }

      return true;
    });

    return filtered.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  getNotification(userId: string, notificationId: string): Notification | undefined {
    const userNotifications = this.notifications.get(userId) || [];
    return userNotifications.find((n) => n.id === notificationId);
  }

  markAsRead(userId: string, notificationId: string): boolean {
    const notification = this.getNotification(userId, notificationId);

    if (!notification) {
      return false;
    }

    notification.read = true;

    return true;
  }

  markAllAsRead(userId: string): number {
    const userNotifications = this.notifications.get(userId) || [];
    let count = 0;

    for (const notification of userNotifications) {
      if (!notification.read) {
        notification.read = true;
        count++;
      }
    }

    return count;
  }

  deleteNotification(userId: string, notificationId: string): boolean {
    const userNotifications = this.notifications.get(userId);

    if (!userNotifications) {
      return false;
    }

    const initialLength = userNotifications.length;
    const filtered = userNotifications.filter((n) => n.id !== notificationId);

    this.notifications.set(userId, filtered);

    return filtered.length < initialLength;
  }

  clearAllNotifications(userId: string): void {
    this.notifications.set(userId, []);
  }

  getUnreadCount(userId: string): number {
    const userNotifications = this.notifications.get(userId) || [];
    return userNotifications.filter((n) => !n.read).length;
  }

  setPreferences(preferences: NotificationPreferences): void {
    this.preferences.set(preferences.userId, preferences);
  }

  getPreferences(userId: string): NotificationPreferences | undefined {
    return this.preferences.get(userId);
  }

  shouldNotify(userId: string, channel: 'email' | 'push' | 'sms', category?: string): boolean {
    const prefs = this.preferences.get(userId);

    if (!prefs) {
      return true;
    }

    if (channel === 'email' && !prefs.emailEnabled) {
      return false;
    }

    if (channel === 'push' && !prefs.pushEnabled) {
      return false;
    }

    if (channel === 'sms' && !prefs.smsEnabled) {
      return false;
    }

    if (category && prefs.categories[category] === false) {
      return false;
    }

    return true;
  }

  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}

export const notificationCenter = new NotificationCenter();

export function createNotification(
  userId: string,
  type: NotificationType,
  title: string,
  message: string,
  actionUrl?: string
): Notification {
  return notificationCenter.createNotification({
    userId,
    type,
    title,
    message,
    actionUrl,
  });
}
