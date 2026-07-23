export interface FeatureFlag {
  name: string;
  enabled: boolean;
  percentage?: number;
  users?: string[];
  groups?: string[];
  metadata?: Record<string, any>;
}

export class FeatureFlagManager {
  private flags: Map<string, FeatureFlag> = new Map();

  createFlag(flag: FeatureFlag): void {
    this.flags.set(flag.name, flag);
  }

  isEnabled(flagName: string, userId?: string, groups?: string[]): boolean {
    const flag = this.flags.get(flagName);

    if (!flag) {
      return false;
    }

    if (!flag.enabled) {
      return false;
    }

    if (userId && flag.users && flag.users.includes(userId)) {
      return true;
    }

    if (groups && flag.groups) {
      const hasGroup = groups.some((g) => flag.groups!.includes(g));
      if (hasGroup) {
        return true;
      }
    }

    if (flag.percentage !== undefined) {
      const hash = userId ? this.hashString(userId) : Math.random();
      return hash < flag.percentage / 100;
    }

    return flag.enabled;
  }

  enableFlag(flagName: string): void {
    const flag = this.flags.get(flagName);

    if (flag) {
      flag.enabled = true;
    }
  }

  disableFlag(flagName: string): void {
    const flag = this.flags.get(flagName);

    if (flag) {
      flag.enabled = false;
    }
  }

  setPercentage(flagName: string, percentage: number): void {
    const flag = this.flags.get(flagName);

    if (flag) {
      flag.percentage = percentage;
    }
  }

  addUser(flagName: string, userId: string): void {
    const flag = this.flags.get(flagName);

    if (flag) {
      if (!flag.users) {
        flag.users = [];
      }

      if (!flag.users.includes(userId)) {
        flag.users.push(userId);
      }
    }
  }

  removeUser(flagName: string, userId: string): void {
    const flag = this.flags.get(flagName);

    if (flag && flag.users) {
      flag.users = flag.users.filter((u) => u !== userId);
    }
  }

  getAllFlags(): FeatureFlag[] {
    return Array.from(this.flags.values());
  }

  private hashString(str: string): number {
    let hash = 0;

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash;
    }

    return Math.abs(hash) / 2147483647;
  }
}

export const featureFlags = new FeatureFlagManager();

featureFlags.createFlag({
  name: 'new-dashboard',
  enabled: true,
  percentage: 50,
});

featureFlags.createFlag({
  name: 'beta-features',
  enabled: true,
  groups: ['beta-testers'],
});

featureFlags.createFlag({
  name: 'advanced-analytics',
  enabled: false,
});
