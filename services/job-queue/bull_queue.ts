import Queue from 'bull';
import { Job, JobOptions } from 'bull';

export interface JobData {
  type: string;
  payload: any;
}

export class BullQueueManager {
  private queues: Map<string, Queue.Queue> = new Map();

  createQueue(name: string, redisUrl: string): Queue.Queue {
    const queue = new Queue(name, redisUrl, {
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 2000,
        },
        removeOnComplete: true,
        removeOnFail: false,
      },
    });

    this.queues.set(name, queue);

    return queue;
  }

  getQueue(name: string): Queue.Queue | undefined {
    return this.queues.get(name);
  }

  async addJob(
    queueName: string,
    data: JobData,
    options?: JobOptions
  ): Promise<Job<JobData>> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    return queue.add(data, options);
  }

  async addBulkJobs(
    queueName: string,
    jobs: Array<{ data: JobData; opts?: JobOptions }>
  ): Promise<Job<JobData>[]> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    return queue.addBulk(jobs);
  }

  registerProcessor(
    queueName: string,
    concurrency: number,
    processor: (job: Job<JobData>) => Promise<any>
  ): void {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    queue.process(concurrency, async (job) => {
      return processor(job);
    });

    queue.on('completed', (job, result) => {
      console.log(`Job ${job.id} completed with result:`, result);
    });

    queue.on('failed', (job, err) => {
      console.error(`Job ${job.id} failed with error:`, err);
    });

    queue.on('stalled', (job) => {
      console.warn(`Job ${job.id} stalled`);
    });
  }

  async pauseQueue(queueName: string): Promise<void> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    await queue.pause();
  }

  async resumeQueue(queueName: string): Promise<void> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    await queue.resume();
  }

  async getJobCounts(queueName: string): Promise<Queue.JobCounts> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    return queue.getJobCounts();
  }

  async cleanQueue(
    queueName: string,
    grace: number = 0,
    status?: 'completed' | 'wait' | 'active' | 'delayed' | 'failed'
  ): Promise<void> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    await queue.clean(grace, status);
  }

  async closeQueue(queueName: string): Promise<void> {
    const queue = this.queues.get(queueName);

    if (!queue) {
      throw new Error(`Queue ${queueName} not found`);
    }

    await queue.close();
    this.queues.delete(queueName);
  }
}

export function createEmailQueue(redisUrl: string): Queue.Queue {
  const manager = new BullQueueManager();
  const queue = manager.createQueue('emails', redisUrl);

  manager.registerProcessor('emails', 5, async (job) => {
    console.log('Sending email:', job.data.payload);
    return { sent: true };
  });

  return queue;
}
