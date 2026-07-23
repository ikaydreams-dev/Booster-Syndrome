export enum FilterOperator {
  EQUALS = 'eq',
  NOT_EQUALS = 'ne',
  GREATER_THAN = 'gt',
  GREATER_THAN_OR_EQUAL = 'gte',
  LESS_THAN = 'lt',
  LESS_THAN_OR_EQUAL = 'lte',
  CONTAINS = 'contains',
  STARTS_WITH = 'startsWith',
  ENDS_WITH = 'endsWith',
  IN = 'in',
  NOT_IN = 'notIn',
}

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

export interface Filter {
  field: string;
  operator: FilterOperator;
  value: any;
}

export interface Sort {
  field: string;
  order: SortOrder;
}

export interface SearchParams {
  filters: Filter[];
  sorts: Sort[];
  searchTerm?: string;
  searchFields?: string[];
}

export class QueryBuilder {
  private filters: Filter[] = [];
  private sorts: Sort[] = [];
  private searchTerm?: string;
  private searchFields?: string[];

  addFilter(field: string, operator: FilterOperator, value: any): this {
    this.filters.push({ field, operator, value });
    return this;
  }

  addSort(field: string, order: SortOrder = SortOrder.ASC): this {
    this.sorts.push({ field, order });
    return this;
  }

  setSearch(term: string, fields: string[]): this {
    this.searchTerm = term;
    this.searchFields = fields;
    return this;
  }

  build(): SearchParams {
    return {
      filters: this.filters,
      sorts: this.sorts,
      searchTerm: this.searchTerm,
      searchFields: this.searchFields,
    };
  }

  toSQLWhere(): string {
    const conditions = this.filters.map((filter) => {
      switch (filter.operator) {
        case FilterOperator.EQUALS:
          return `${filter.field} = '${filter.value}'`;
        case FilterOperator.NOT_EQUALS:
          return `${filter.field} != '${filter.value}'`;
        case FilterOperator.GREATER_THAN:
          return `${filter.field} > ${filter.value}`;
        case FilterOperator.GREATER_THAN_OR_EQUAL:
          return `${filter.field} >= ${filter.value}`;
        case FilterOperator.LESS_THAN:
          return `${filter.field} < ${filter.value}`;
        case FilterOperator.LESS_THAN_OR_EQUAL:
          return `${filter.field} <= ${filter.value}`;
        case FilterOperator.CONTAINS:
          return `${filter.field} LIKE '%${filter.value}%'`;
        case FilterOperator.STARTS_WITH:
          return `${filter.field} LIKE '${filter.value}%'`;
        case FilterOperator.ENDS_WITH:
          return `${filter.field} LIKE '%${filter.value}'`;
        case FilterOperator.IN:
          return `${filter.field} IN (${filter.value.map((v: any) => `'${v}'`).join(',')})`;
        case FilterOperator.NOT_IN:
          return `${filter.field} NOT IN (${filter.value.map((v: any) => `'${v}'`).join(',')})`;
        default:
          return '';
      }
    });

    if (this.searchTerm && this.searchFields) {
      const searchConditions = this.searchFields
        .map((field) => `${field} LIKE '%${this.searchTerm}%'`)
        .join(' OR ');
      conditions.push(`(${searchConditions})`);
    }

    return conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : '';
  }

  toSQLOrderBy(): string {
    if (this.sorts.length === 0) return '';

    const orderBy = this.sorts
      .map((sort) => `${sort.field} ${sort.order.toUpperCase()}`)
      .join(', ');

    return `ORDER BY ${orderBy}`;
  }
}

export function applyFilters<T>(data: T[], params: SearchParams): T[] {
  let result = [...data];

  for (const filter of params.filters) {
    result = result.filter((item: any) => {
      const fieldValue = item[filter.field];

      switch (filter.operator) {
        case FilterOperator.EQUALS:
          return fieldValue === filter.value;
        case FilterOperator.NOT_EQUALS:
          return fieldValue !== filter.value;
        case FilterOperator.GREATER_THAN:
          return fieldValue > filter.value;
        case FilterOperator.GREATER_THAN_OR_EQUAL:
          return fieldValue >= filter.value;
        case FilterOperator.LESS_THAN:
          return fieldValue < filter.value;
        case FilterOperator.LESS_THAN_OR_EQUAL:
          return fieldValue <= filter.value;
        case FilterOperator.CONTAINS:
          return String(fieldValue).includes(filter.value);
        case FilterOperator.STARTS_WITH:
          return String(fieldValue).startsWith(filter.value);
        case FilterOperator.ENDS_WITH:
          return String(fieldValue).endsWith(filter.value);
        case FilterOperator.IN:
          return filter.value.includes(fieldValue);
        case FilterOperator.NOT_IN:
          return !filter.value.includes(fieldValue);
        default:
          return true;
      }
    });
  }

  if (params.searchTerm && params.searchFields) {
    result = result.filter((item: any) => {
      return params.searchFields!.some((field) =>
        String(item[field])
          .toLowerCase()
          .includes(params.searchTerm!.toLowerCase())
      );
    });
  }

  return result;
}

export function applySort<T>(data: T[], sorts: Sort[]): T[] {
  const sorted = [...data];

  sorted.sort((a: any, b: any) => {
    for (const sort of sorts) {
      const aVal = a[sort.field];
      const bVal = b[sort.field];

      if (aVal < bVal) return sort.order === SortOrder.ASC ? -1 : 1;
      if (aVal > bVal) return sort.order === SortOrder.ASC ? 1 : -1;
    }
    return 0;
  });

  return sorted;
}
