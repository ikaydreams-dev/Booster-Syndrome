export interface Query {
  type: string;
  params: any;
}

export interface QueryResult<T> {
  data: T;
  metadata?: Record<string, any>;
}

export interface QueryHandler<TQuery extends Query, TResult> {
  handle(query: TQuery): Promise<QueryResult<TResult>>;
}

export class QueryBus {
  private handlers: Map<string, QueryHandler<any, any>> = new Map();

  registerHandler<TQuery extends Query, TResult>(
    queryType: string,
    handler: QueryHandler<TQuery, TResult>
  ): void {
    this.handlers.set(queryType, handler);
  }

  async execute<TQuery extends Query, TResult>(
    query: TQuery
  ): Promise<QueryResult<TResult>> {
    const handler = this.handlers.get(query.type);

    if (!handler) {
      throw new Error(`No handler registered for query type: ${query.type}`);
    }

    return handler.handle(query);
  }
}

export class GetUserQuery implements Query {
  type = 'GetUser';

  constructor(public params: { userId: string }) {}
}

export class GetUsersQuery implements Query {
  type = 'GetUsers';

  constructor(public params: { page: number; pageSize: number }) {}
}

export class GetUserHandler implements QueryHandler<GetUserQuery, any> {
  async handle(query: GetUserQuery): Promise<QueryResult<any>> {
    return {
      data: {
        id: query.params.userId,
        email: 'user@example.com',
        username: 'testuser',
      },
    };
  }
}

export class GetUsersHandler implements QueryHandler<GetUsersQuery, any[]> {
  async handle(query: GetUsersQuery): Promise<QueryResult<any[]>> {
    return {
      data: [
        { id: '1', email: 'user1@example.com', username: 'user1' },
        { id: '2', email: 'user2@example.com', username: 'user2' },
      ],
      metadata: {
        page: query.params.page,
        pageSize: query.params.pageSize,
        totalItems: 2,
      },
    };
  }
}

export class ReadModel {
  private data: Map<string, any> = new Map();

  update(id: string, value: any): void {
    this.data.set(id, value);
  }

  get(id: string): any | undefined {
    return this.data.get(id);
  }

  getAll(): any[] {
    return Array.from(this.data.values());
  }

  delete(id: string): void {
    this.data.delete(id);
  }
}
