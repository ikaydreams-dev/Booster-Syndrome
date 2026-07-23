export enum Permission {
  USER_READ = 'user:read',
  USER_WRITE = 'user:write',
  USER_DELETE = 'user:delete',
  ADMIN_ACCESS = 'admin:access',
  ANALYTICS_READ = 'analytics:read',
  ANALYTICS_WRITE = 'analytics:write',
  SETTINGS_WRITE = 'settings:write',
}

export interface Role {
  id: string;
  name: string;
  permissions: Permission[];
  description?: string;
}

export interface UserRole {
  userId: string;
  roleId: string;
}

export class RoleBasedAccessControl {
  private roles: Map<string, Role> = new Map();
  private userRoles: Map<string, Set<string>> = new Map();

  createRole(role: Role): void {
    this.roles.set(role.id, role);
  }

  getRole(roleId: string): Role | undefined {
    return this.roles.get(roleId);
  }

  assignRoleToUser(userId: string, roleId: string): void {
    if (!this.userRoles.has(userId)) {
      this.userRoles.set(userId, new Set());
    }

    this.userRoles.get(userId)!.add(roleId);
  }

  removeRoleFromUser(userId: string, roleId: string): void {
    const roles = this.userRoles.get(userId);

    if (roles) {
      roles.delete(roleId);
    }
  }

  getUserRoles(userId: string): Role[] {
    const roleIds = this.userRoles.get(userId);

    if (!roleIds) {
      return [];
    }

    return Array.from(roleIds)
      .map((roleId) => this.roles.get(roleId))
      .filter((role): role is Role => role !== undefined);
  }

  getUserPermissions(userId: string): Permission[] {
    const roles = this.getUserRoles(userId);
    const permissions = new Set<Permission>();

    for (const role of roles) {
      for (const permission of role.permissions) {
        permissions.add(permission);
      }
    }

    return Array.from(permissions);
  }

  hasPermission(userId: string, permission: Permission): boolean {
    const permissions = this.getUserPermissions(userId);
    return permissions.includes(permission);
  }

  hasAnyPermission(userId: string, permissions: Permission[]): boolean {
    const userPermissions = this.getUserPermissions(userId);
    return permissions.some((p) => userPermissions.includes(p));
  }

  hasAllPermissions(userId: string, permissions: Permission[]): boolean {
    const userPermissions = this.getUserPermissions(userId);
    return permissions.every((p) => userPermissions.includes(p));
  }
}

export const rbac = new RoleBasedAccessControl();

rbac.createRole({
  id: 'admin',
  name: 'Administrator',
  permissions: [
    Permission.USER_READ,
    Permission.USER_WRITE,
    Permission.USER_DELETE,
    Permission.ADMIN_ACCESS,
    Permission.ANALYTICS_READ,
    Permission.ANALYTICS_WRITE,
    Permission.SETTINGS_WRITE,
  ],
  description: 'Full system access',
});

rbac.createRole({
  id: 'user',
  name: 'Regular User',
  permissions: [Permission.USER_READ, Permission.ANALYTICS_READ],
  description: 'Standard user access',
});

rbac.createRole({
  id: 'analyst',
  name: 'Analyst',
  permissions: [
    Permission.USER_READ,
    Permission.ANALYTICS_READ,
    Permission.ANALYTICS_WRITE,
  ],
  description: 'Analytics team access',
});

export function requirePermission(permission: Permission) {
  return (req: any, res: any, next: any) => {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    if (!rbac.hasPermission(userId, permission)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
}

export function requireAnyPermission(permissions: Permission[]) {
  return (req: any, res: any, next: any) => {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    if (!rbac.hasAnyPermission(userId, permissions)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
}
