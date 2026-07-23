export enum ActivityType {
  USER_CREATED = 'user_created',
  USER_UPDATED = 'user_updated',
  USER_DELETED = 'user_deleted',
  POST_CREATED = 'post_created',
  POST_LIKED = 'post_liked',
  COMMENT_ADDED = 'comment_added',
  FILE_UPLOADED = 'file_uploaded',
  TEAM_JOINED = 'team_joined',
  SETTING_CHANGED = 'setting_changed',
}

export interface Activity {
  id: string;
  userId: string;
  type: ActivityType;
  action: string;
  entityType: string;
  entityId: string;
  metadata?: Record<string, any>;
  timestamp: Date;
}

export interface ActivityFeedFilter {
  userId?: string;
  types?: ActivityType[];
  entityType?: string;
  startDate?: Date;
  endDate?: Date;
}

export class ActivityFeed {
  private activities: Activity[] = [];

  logActivity(activity: Omit<Activity, 'id' | 'timestamp'>): Activity {
    const newActivity: Activity = {
      ...activity,
      id: this.generateId(),
      timestamp: new Date(),
    };

    this.activities.push(newActivity);

    return newActivity;
  }

  getActivities(filter?: ActivityFeedFilter, limit: number = 50): Activity[] {
    let filtered = this.activities;

    if (filter) {
      if (filter.userId) {
        filtered = filtered.filter((a) => a.userId === filter.userId);
      }

      if (filter.types && filter.types.length > 0) {
        filtered = filtered.filter((a) => filter.types!.includes(a.type));
      }

      if (filter.entityType) {
        filtered = filtered.filter((a) => a.entityType === filter.entityType);
      }

      if (filter.startDate) {
        filtered = filtered.filter((a) => a.timestamp >= filter.startDate!);
      }

      if (filter.endDate) {
        filtered = filtered.filter((a) => a.timestamp <= filter.endDate!);
      }
    }

    return filtered
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(0, limit);
  }

  getUserActivity(userId: string, limit: number = 20): Activity[] {
    return this.getActivities({ userId }, limit);
  }

  getRecentActivity(limit: number = 50): Activity[] {
    return this.activities
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(0, limit);
  }

  getActivityByEntity(entityType: string, entityId: string): Activity[] {
    return this.activities.filter(
      (a) => a.entityType === entityType && a.entityId === entityId
    );
  }

  clearOldActivities(daysToKeep: number = 30): number {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    const initialLength = this.activities.length;

    this.activities = this.activities.filter((a) => a.timestamp >= cutoffDate);

    return initialLength - this.activities.length;
  }

  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}

export const activityFeed = new ActivityFeed();

export function logUserActivity(
  userId: string,
  type: ActivityType,
  action: string,
  entityType: string,
  entityId: string,
  metadata?: Record<string, any>
): Activity {
  return activityFeed.logActivity({
    userId,
    type,
    action,
    entityType,
    entityId,
    metadata,
  });
}

export function formatActivityMessage(activity: Activity): string {
  const { type, action, entityType, metadata } = activity;

  switch (type) {
    case ActivityType.USER_CREATED:
      return `User ${metadata?.username} was created`;

    case ActivityType.POST_CREATED:
      return `Created a new ${entityType}`;

    case ActivityType.POST_LIKED:
      return `Liked a ${entityType}`;

    case ActivityType.COMMENT_ADDED:
      return `Added a comment to ${entityType}`;

    case ActivityType.FILE_UPLOADED:
      return `Uploaded ${metadata?.fileName || 'a file'}`;

    case ActivityType.TEAM_JOINED:
      return `Joined team ${metadata?.teamName}`;

    default:
      return action;
  }
}
