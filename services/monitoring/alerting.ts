export enum AlertSeverity {
  INFO = 'info',
  WARNING = 'warning',
  CRITICAL = 'critical',
}

export enum AlertStatus {
  FIRING = 'firing',
  RESOLVED = 'resolved',
  ACKNOWLEDGED = 'acknowledged',
}

export interface Alert {
  id: string;
  name: string;
  severity: AlertSeverity;
  status: AlertStatus;
  message: string;
  source: string;
  metadata: Record<string, any>;
  firedAt: Date;
  resolvedAt?: Date;
  acknowledgedAt?: Date;
  acknowledgedBy?: string;
}

export interface AlertRule {
  name: string;
  condition: () => boolean | Promise<boolean>;
  severity: AlertSeverity;
  message: string;
  source: string;
  cooldown: number;
}

export class AlertingSystem {
  private alerts: Map<string, Alert> = new Map();
  private rules: AlertRule[] = [];
  private lastFired: Map<string, Date> = new Map();
  private checkInterval?: NodeJS.Timeout;

  addRule(rule: AlertRule): void {
    this.rules.push(rule);
  }

  async checkRules(): Promise<void> {
    for (const rule of this.rules) {
      const shouldFire = await rule.condition();

      if (shouldFire) {
        this.fireAlert(rule);
      }
    }
  }

  private fireAlert(rule: AlertRule): void {
    const lastFiredTime = this.lastFired.get(rule.name);
    const now = new Date();

    if (lastFiredTime) {
      const timeSinceLastFire = now.getTime() - lastFiredTime.getTime();

      if (timeSinceLastFire < rule.cooldown) {
        return;
      }
    }

    const alert: Alert = {
      id: this.generateId(),
      name: rule.name,
      severity: rule.severity,
      status: AlertStatus.FIRING,
      message: rule.message,
      source: rule.source,
      metadata: {},
      firedAt: now,
    };

    this.alerts.set(alert.id, alert);
    this.lastFired.set(rule.name, now);

    this.notifyAlert(alert);
  }

  private notifyAlert(alert: Alert): void {
    console.log(`ALERT [${alert.severity}]: ${alert.message}`);
  }

  resolveAlert(alertId: string): boolean {
    const alert = this.alerts.get(alertId);

    if (!alert || alert.status === AlertStatus.RESOLVED) {
      return false;
    }

    alert.status = AlertStatus.RESOLVED;
    alert.resolvedAt = new Date();

    return true;
  }

  acknowledgeAlert(alertId: string, userId: string): boolean {
    const alert = this.alerts.get(alertId);

    if (!alert) {
      return false;
    }

    alert.status = AlertStatus.ACKNOWLEDGED;
    alert.acknowledgedAt = new Date();
    alert.acknowledgedBy = userId;

    return true;
  }

  getActiveAlerts(): Alert[] {
    return Array.from(this.alerts.values()).filter(
      (a) => a.status === AlertStatus.FIRING || a.status === AlertStatus.ACKNOWLEDGED
    );
  }

  getAlertsBySeverity(severity: AlertSeverity): Alert[] {
    return Array.from(this.alerts.values()).filter((a) => a.severity === severity);
  }

  startMonitoring(intervalMs: number = 60000): void {
    this.checkInterval = setInterval(() => {
      this.checkRules();
    }, intervalMs);
  }

  stopMonitoring(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
    }
  }

  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}

export const alerting = new AlertingSystem();

alerting.addRule({
  name: 'high-error-rate',
  condition: async () => {
    return false;
  },
  severity: AlertSeverity.WARNING,
  message: 'Error rate is above threshold',
  source: 'error-monitoring',
  cooldown: 300000,
});

alerting.addRule({
  name: 'service-down',
  condition: async () => {
    return false;
  },
  severity: AlertSeverity.CRITICAL,
  message: 'Service is not responding',
  source: 'health-check',
  cooldown: 60000,
});
