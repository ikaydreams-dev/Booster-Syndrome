export interface Tenant {
  id: string;
  name: string;
  domain?: string;
  settings: Record<string, any>;
  isActive: boolean;
  createdAt: Date;
}

export interface TenantContext {
  tenantId: string;
  tenant: Tenant;
}

export class TenantManager {
  private tenants: Map<string, Tenant> = new Map();

  createTenant(tenant: Omit<Tenant, 'createdAt'>): Tenant {
    const newTenant: Tenant = {
      ...tenant,
      createdAt: new Date(),
    };

    this.tenants.set(tenant.id, newTenant);

    return newTenant;
  }

  getTenant(tenantId: string): Tenant | undefined {
    return this.tenants.get(tenantId);
  }

  getTenantByDomain(domain: string): Tenant | undefined {
    return Array.from(this.tenants.values()).find((t) => t.domain === domain);
  }

  updateTenant(tenantId: string, updates: Partial<Tenant>): Tenant | undefined {
    const tenant = this.tenants.get(tenantId);

    if (!tenant) {
      return undefined;
    }

    const updated = { ...tenant, ...updates };
    this.tenants.set(tenantId, updated);

    return updated;
  }

  deleteTenant(tenantId: string): boolean {
    return this.tenants.delete(tenantId);
  }

  getAllTenants(): Tenant[] {
    return Array.from(this.tenants.values());
  }
}

export const tenantManager = new TenantManager();

export function extractTenantMiddleware(req: any, res: any, next: any) {
  const tenantId =
    req.headers['x-tenant-id'] ||
    req.query.tenantId ||
    req.subdomains[0];

  if (!tenantId) {
    return res.status(400).json({ error: 'Tenant ID is required' });
  }

  const tenant = tenantManager.getTenant(tenantId);

  if (!tenant) {
    return res.status(404).json({ error: 'Tenant not found' });
  }

  if (!tenant.isActive) {
    return res.status(403).json({ error: 'Tenant is inactive' });
  }

  req.tenant = tenant;
  req.tenantId = tenantId;

  next();
}

export function getTenantDatabase(tenantId: string): string {
  return `tenant_${tenantId}`;
}

export function getTenantSchema(tenantId: string): string {
  return `tenant_${tenantId}`;
}

export class TenantAwareRepository<T> {
  constructor(private tableName: string) {}

  async find(tenantId: string, query: any): Promise<T[]> {
    console.log(`Querying ${this.tableName} for tenant ${tenantId}`, query);
    return [];
  }

  async findById(tenantId: string, id: string): Promise<T | null> {
    console.log(`Finding ${this.tableName} by id ${id} for tenant ${tenantId}`);
    return null;
  }

  async create(tenantId: string, data: Partial<T>): Promise<T> {
    console.log(`Creating ${this.tableName} for tenant ${tenantId}`, data);
    return data as T;
  }

  async update(tenantId: string, id: string, data: Partial<T>): Promise<T | null> {
    console.log(`Updating ${this.tableName} ${id} for tenant ${tenantId}`, data);
    return null;
  }

  async delete(tenantId: string, id: string): Promise<boolean> {
    console.log(`Deleting ${this.tableName} ${id} for tenant ${tenantId}`);
    return true;
  }
}
