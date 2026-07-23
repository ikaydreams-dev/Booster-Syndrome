export interface Organization {
  id: string;
  name: string;
  parentId?: string;
  type: 'company' | 'department' | 'team';
  settings: Record<string, any>;
  createdAt: Date;
}

export interface OrganizationMember {
  userId: string;
  organizationId: string;
  role: string;
  joinedAt: Date;
}

export class OrganizationHierarchy {
  private organizations: Map<string, Organization> = new Map();
  private members: Map<string, OrganizationMember[]> = new Map();

  createOrganization(org: Omit<Organization, 'createdAt'>): Organization {
    const newOrg: Organization = {
      ...org,
      createdAt: new Date(),
    };

    this.organizations.set(org.id, newOrg);

    return newOrg;
  }

  getOrganization(orgId: string): Organization | undefined {
    return this.organizations.get(orgId);
  }

  getChildren(parentId: string): Organization[] {
    return Array.from(this.organizations.values()).filter(
      (org) => org.parentId === parentId
    );
  }

  getAncestors(orgId: string): Organization[] {
    const ancestors: Organization[] = [];
    let current = this.organizations.get(orgId);

    while (current?.parentId) {
      const parent = this.organizations.get(current.parentId);

      if (parent) {
        ancestors.push(parent);
        current = parent;
      } else {
        break;
      }
    }

    return ancestors;
  }

  getDescendants(orgId: string): Organization[] {
    const descendants: Organization[] = [];
    const queue = [orgId];

    while (queue.length > 0) {
      const currentId = queue.shift()!;
      const children = this.getChildren(currentId);

      descendants.push(...children);
      queue.push(...children.map((c) => c.id));
    }

    return descendants;
  }

  addMember(member: Omit<OrganizationMember, 'joinedAt'>): OrganizationMember {
    const newMember: OrganizationMember = {
      ...member,
      joinedAt: new Date(),
    };

    if (!this.members.has(member.organizationId)) {
      this.members.set(member.organizationId, []);
    }

    this.members.get(member.organizationId)!.push(newMember);

    return newMember;
  }

  removeMember(userId: string, organizationId: string): boolean {
    const orgMembers = this.members.get(organizationId);

    if (!orgMembers) {
      return false;
    }

    const filtered = orgMembers.filter((m) => m.userId !== userId);
    this.members.set(organizationId, filtered);

    return filtered.length < orgMembers.length;
  }

  getMembers(organizationId: string): OrganizationMember[] {
    return this.members.get(organizationId) || [];
  }

  getUserOrganizations(userId: string): Organization[] {
    const orgIds = new Set<string>();

    for (const [orgId, members] of this.members) {
      if (members.some((m) => m.userId === userId)) {
        orgIds.add(orgId);
      }
    }

    return Array.from(orgIds)
      .map((id) => this.organizations.get(id))
      .filter((org): org is Organization => org !== undefined);
  }

  isUserInOrganization(userId: string, organizationId: string): boolean {
    const members = this.getMembers(organizationId);
    return members.some((m) => m.userId === userId);
  }

  canUserAccessOrganization(userId: string, organizationId: string): boolean {
    if (this.isUserInOrganization(userId, organizationId)) {
      return true;
    }

    const ancestors = this.getAncestors(organizationId);
    return ancestors.some((org) => this.isUserInOrganization(userId, org.id));
  }
}

export const orgHierarchy = new OrganizationHierarchy();
