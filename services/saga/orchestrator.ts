export interface SagaStep {
  name: string;
  execute: () => Promise<any>;
  compensate: () => Promise<void>;
}

export enum SagaStatus {
  PENDING = 'pending',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  COMPENSATING = 'compensating',
  FAILED = 'failed',
}

export class Saga {
  private steps: SagaStep[] = [];
  private executedSteps: SagaStep[] = [];
  public status: SagaStatus = SagaStatus.PENDING;

  addStep(step: SagaStep): this {
    this.steps.push(step);
    return this;
  }

  async execute(): Promise<void> {
    this.status = SagaStatus.IN_PROGRESS;

    try {
      for (const step of this.steps) {
        await step.execute();
        this.executedSteps.push(step);
      }

      this.status = SagaStatus.COMPLETED;
    } catch (error) {
      console.error('Saga execution failed:', error);
      await this.compensate();
      this.status = SagaStatus.FAILED;
      throw error;
    }
  }

  private async compensate(): Promise<void> {
    this.status = SagaStatus.COMPENSATING;

    for (let i = this.executedSteps.length - 1; i >= 0; i--) {
      const step = this.executedSteps[i];

      try {
        await step.compensate();
      } catch (error) {
        console.error(`Compensation failed for step ${step.name}:`, error);
      }
    }
  }
}

export class SagaOrchestrator {
  async createOrderSaga(orderId: string, userId: string, items: any[]): Promise<void> {
    const saga = new Saga();

    saga
      .addStep({
        name: 'Reserve Inventory',
        execute: async () => {
          console.log('Reserving inventory for items:', items);
          return { reserved: true };
        },
        compensate: async () => {
          console.log('Releasing inventory reservation');
        },
      })
      .addStep({
        name: 'Process Payment',
        execute: async () => {
          console.log('Processing payment for order:', orderId);
          return { paymentId: 'pay_123' };
        },
        compensate: async () => {
          console.log('Refunding payment');
        },
      })
      .addStep({
        name: 'Update User Credits',
        execute: async () => {
          console.log('Updating user credits for user:', userId);
        },
        compensate: async () => {
          console.log('Reverting user credits');
        },
      })
      .addStep({
        name: 'Send Confirmation',
        execute: async () => {
          console.log('Sending order confirmation');
        },
        compensate: async () => {
          console.log('Sending cancellation notice');
        },
      });

    await saga.execute();
  }

  async createUserRegistrationSaga(
    email: string,
    username: string,
    password: string
  ): Promise<void> {
    const saga = new Saga();

    saga
      .addStep({
        name: 'Create User Account',
        execute: async () => {
          console.log('Creating user account:', username);
          return { userId: 'user_123' };
        },
        compensate: async () => {
          console.log('Deleting user account');
        },
      })
      .addStep({
        name: 'Send Welcome Email',
        execute: async () => {
          console.log('Sending welcome email to:', email);
        },
        compensate: async () => {
          console.log('No compensation needed for email');
        },
      })
      .addStep({
        name: 'Create Default Settings',
        execute: async () => {
          console.log('Creating default user settings');
        },
        compensate: async () => {
          console.log('Deleting user settings');
        },
      });

    await saga.execute();
  }
}
