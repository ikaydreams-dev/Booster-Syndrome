export interface PaginationParams {
  page: number;
  pageSize: number;
  offset: number;
}

export interface PaginatedResponse<T> {
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
  data: T[];
}

export function extractPaginationParams(
  page: number = 1,
  pageSize: number = 10
): PaginationParams {
  let validPage = Math.max(1, page);
  let validPageSize = Math.max(1, Math.min(100, pageSize));

  return {
    page: validPage,
    pageSize: validPageSize,
    offset: (validPage - 1) * validPageSize,
  };
}

export function paginate<T>(
  data: T[],
  totalItems: number,
  params: PaginationParams
): PaginatedResponse<T> {
  const totalPages = Math.ceil(totalItems / params.pageSize);

  return {
    page: params.page,
    pageSize: params.pageSize,
    totalItems,
    totalPages,
    hasNext: params.page < totalPages,
    hasPrev: params.page > 1,
    data,
  };
}

export class Paginator<T> {
  constructor(
    private page: number = 1,
    private pageSize: number = 10
  ) {}

  getParams(): PaginationParams {
    return extractPaginationParams(this.page, this.pageSize);
  }

  paginate(data: T[], totalItems: number): PaginatedResponse<T> {
    return paginate(data, totalItems, this.getParams());
  }
}
