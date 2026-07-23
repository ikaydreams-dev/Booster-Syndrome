import cron from 'node-cron';

export interface ScheduledTask {
  name: string;
  schedule: string;
  handler: () => Promise<void> | void;
  enabled: boolean;
}

export class CronScheduler {
  private tasks: Map<string, { task: ScheduledTask; cronTask: cron.ScheduledTask }> = new Map();

  addTask(task: ScheduledTask): void {
    if (!cron.validate(task.schedule)) {
      throw new Error(`Invalid cron schedule: ${task.schedule}`);
    }

    const cronTask = cron.schedule(
      task.schedule,
      async () => {
        try {
          console.log(`Running scheduled task: ${task.name}`);
          await task.handler();
          console.log(`Completed scheduled task: ${task.name}`);
        } catch (error) {
          console.error(`Error in scheduled task ${task.name}:`, error);
        }
      },
      {
        scheduled: task.enabled,
      }
    );

    this.tasks.set(task.name, { task, cronTask });
  }

  removeTask(name: string): void {
    const entry = this.tasks.get(name);

    if (entry) {
      entry.cronTask.stop();
      this.tasks.delete(name);
    }
  }

  startTask(name: string): void {
    const entry = this.tasks.get(name);

    if (entry) {
      entry.cronTask.start();
      entry.task.enabled = true;
    }
  }

  stopTask(name: string): void {
    const entry = this.tasks.get(name);

    if (entry) {
      entry.cronTask.stop();
      entry.task.enabled = false;
    }
  }

  getTasks(): ScheduledTask[] {
    return Array.from(this.tasks.values()).map((entry) => entry.task);
  }

  stopAll(): void {
    for (const [_, entry] of this.tasks) {
      entry.cronTask.stop();
    }
  }
}

export const scheduler = new CronScheduler();

scheduler.addTask({
  name: 'cleanup-old-sessions',
  schedule: '0 0 * * *',
  handler: async () => {
    console.log('Cleaning up old sessions...');
  },
  enabled: true,
});

scheduler.addTask({
  name: 'generate-daily-reports',
  schedule: '0 6 * * *',
  handler: async () => {
    console.log('Generating daily reports...');
  },
  enabled: true,
});

scheduler.addTask({
  name: 'backup-database',
  schedule: '0 2 * * *',
  handler: async () => {
    console.log('Backing up database...');
  },
  enabled: true,
});

scheduler.addTask({
  name: 'send-digest-emails',
  schedule: '0 8 * * 1',
  handler: async () => {
    console.log('Sending weekly digest emails...');
  },
  enabled: true,
});

export default scheduler;
