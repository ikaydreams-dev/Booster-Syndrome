export interface Command {
  type: string;
  aggregateId: string;
  data: any;
  metadata?: Record<string, any>;
}

export interface CommandResult {
  success: boolean;
  aggregateId: string;
  version: number;
  error?: string;
}

export interface CommandHandler<T extends Command> {
  handle(command: T): Promise<CommandResult>;
}

export class CommandBus {
  private handlers: Map<string, CommandHandler<any>> = new Map();

  registerHandler<T extends Command>(
    commandType: string,
    handler: CommandHandler<T>
  ): void {
    this.handlers.set(commandType, handler);
  }

  async execute<T extends Command>(command: T): Promise<CommandResult> {
    const handler = this.handlers.get(command.type);

    if (!handler) {
      return {
        success: false,
        aggregateId: command.aggregateId,
        version: 0,
        error: `No handler registered for command type: ${command.type}`,
      };
    }

    return handler.handle(command);
  }
}

export class CreateUserCommand implements Command {
  type = 'CreateUser';

  constructor(
    public aggregateId: string,
    public data: { email: string; username: string; password: string }
  ) {}
}

export class UpdateUserCommand implements Command {
  type = 'UpdateUser';

  constructor(
    public aggregateId: string,
    public data: { firstName?: string; lastName?: string }
  ) {}
}

export class CreateUserHandler implements CommandHandler<CreateUserCommand> {
  async handle(command: CreateUserCommand): Promise<CommandResult> {
    return {
      success: true,
      aggregateId: command.aggregateId,
      version: 1,
    };
  }
}

export class UpdateUserHandler implements CommandHandler<UpdateUserCommand> {
  async handle(command: UpdateUserCommand): Promise<CommandResult> {
    return {
      success: true,
      aggregateId: command.aggregateId,
      version: 2,
    };
  }
}
