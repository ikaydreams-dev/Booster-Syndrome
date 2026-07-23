import admin from 'firebase-admin';

export interface PushNotification {
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
  clickAction?: string;
}

export interface NotificationTarget {
  token?: string;
  topic?: string;
  tokens?: string[];
}

export class PushNotificationService {
  private messaging: admin.messaging.Messaging;

  constructor(serviceAccount: any) {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }

    this.messaging = admin.messaging();
  }

  async sendToDevice(token: string, notification: PushNotification): Promise<string | null> {
    try {
      const message: admin.messaging.Message = {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: notification.data,
        webpush: notification.clickAction
          ? {
              fcmOptions: {
                link: notification.clickAction,
              },
            }
          : undefined,
      };

      const response = await this.messaging.send(message);
      return response;
    } catch (error) {
      console.error('Push notification send failed:', error);
      return null;
    }
  }

  async sendToMultipleDevices(
    tokens: string[],
    notification: PushNotification
  ): Promise<admin.messaging.BatchResponse> {
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
      },
      data: notification.data,
    };

    return this.messaging.sendEachForMulticast(message);
  }

  async sendToTopic(topic: string, notification: PushNotification): Promise<string | null> {
    try {
      const message: admin.messaging.Message = {
        topic,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: notification.data,
      };

      const response = await this.messaging.send(message);
      return response;
    } catch (error) {
      console.error('Topic notification send failed:', error);
      return null;
    }
  }

  async subscribeToTopic(tokens: string[], topic: string): Promise<void> {
    try {
      await this.messaging.subscribeToTopic(tokens, topic);
    } catch (error) {
      console.error('Topic subscription failed:', error);
    }
  }

  async unsubscribeFromTopic(tokens: string[], topic: string): Promise<void> {
    try {
      await this.messaging.unsubscribeFromTopic(tokens, topic);
    } catch (error) {
      console.error('Topic unsubscription failed:', error);
    }
  }

  async sendScheduled(
    target: NotificationTarget,
    notification: PushNotification,
    scheduledTime: Date
  ): Promise<void> {
    const delay = scheduledTime.getTime() - Date.now();

    if (delay > 0) {
      setTimeout(async () => {
        if (target.token) {
          await this.sendToDevice(target.token, notification);
        } else if (target.topic) {
          await this.sendToTopic(target.topic, notification);
        } else if (target.tokens) {
          await this.sendToMultipleDevices(target.tokens, notification);
        }
      }, delay);
    }
  }
}

export function createPushService(serviceAccount: any): PushNotificationService {
  return new PushNotificationService(serviceAccount);
}
