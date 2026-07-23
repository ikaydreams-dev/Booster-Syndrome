export interface Team {
  id: string;
  name: string;
  description?: string;
  organizationId: string;
  members: TeamMember[];
  createdAt: Date;
}

export interface TeamMember {
  userId: string;
  role: 'owner' | 'admin' | 'member';
  joinedAt: Date;
}

export interface TeamInvite {
  id: string;
  teamId: string;
  email: string;
  role: 'admin' | 'member';
  invitedBy: string;
  expiresAt: Date;
  status: 'pending' | 'accepted' | 'declined' | 'expired';
}

export interface SharedResource {
  id: string;
  teamId: string;
  resourceType: string;
  resourceId: string;
  permissions: ('read' | 'write' | 'delete')[];
  sharedBy: string;
  sharedAt: Date;
}

export class TeamCollaboration {
  private teams: Map<string, Team> = new Map();
  private invites: Map<string, TeamInvite> = new Map();
  private sharedResources: Map<string, SharedResource[]> = new Map();

  createTeam(team: Omit<Team, 'createdAt' | 'members'>): Team {
    const newTeam: Team = {
      ...team,
      members: [],
      createdAt: new Date(),
    };

    this.teams.set(team.id, newTeam);

    return newTeam;
  }

  getTeam(teamId: string): Team | undefined {
    return this.teams.get(teamId);
  }

  addMember(teamId: string, userId: string, role: TeamMember['role']): boolean {
    const team = this.teams.get(teamId);

    if (!team) {
      return false;
    }

    const existingMember = team.members.find((m) => m.userId === userId);

    if (existingMember) {
      return false;
    }

    team.members.push({
      userId,
      role,
      joinedAt: new Date(),
    });

    return true;
  }

  removeMember(teamId: string, userId: string): boolean {
    const team = this.teams.get(teamId);

    if (!team) {
      return false;
    }

    const initialLength = team.members.length;
    team.members = team.members.filter((m) => m.userId !== userId);

    return team.members.length < initialLength;
  }

  updateMemberRole(
    teamId: string,
    userId: string,
    role: TeamMember['role']
  ): boolean {
    const team = this.teams.get(teamId);

    if (!team) {
      return false;
    }

    const member = team.members.find((m) => m.userId === userId);

    if (!member) {
      return false;
    }

    member.role = role;

    return true;
  }

  createInvite(invite: Omit<TeamInvite, 'status'>): TeamInvite {
    const newInvite: TeamInvite = {
      ...invite,
      status: 'pending',
    };

    this.invites.set(invite.id, newInvite);

    return newInvite;
  }

  acceptInvite(inviteId: string, userId: string): boolean {
    const invite = this.invites.get(inviteId);

    if (!invite || invite.status !== 'pending') {
      return false;
    }

    if (new Date() > invite.expiresAt) {
      invite.status = 'expired';
      return false;
    }

    invite.status = 'accepted';

    this.addMember(invite.teamId, userId, invite.role);

    return true;
  }

  declineInvite(inviteId: string): boolean {
    const invite = this.invites.get(inviteId);

    if (!invite || invite.status !== 'pending') {
      return false;
    }

    invite.status = 'declined';

    return true;
  }

  shareResource(resource: SharedResource): void {
    if (!this.sharedResources.has(resource.teamId)) {
      this.sharedResources.set(resource.teamId, []);
    }

    this.sharedResources.get(resource.teamId)!.push(resource);
  }

  getSharedResources(teamId: string): SharedResource[] {
    return this.sharedResources.get(teamId) || [];
  }

  unshareResource(teamId: string, resourceId: string): boolean {
    const resources = this.sharedResources.get(teamId);

    if (!resources) {
      return false;
    }

    const initialLength = resources.length;
    const filtered = resources.filter((r) => r.resourceId !== resourceId);

    this.sharedResources.set(teamId, filtered);

    return filtered.length < initialLength;
  }

  canUserAccessResource(
    userId: string,
    teamId: string,
    resourceId: string,
    permission: 'read' | 'write' | 'delete'
  ): boolean {
    const team = this.teams.get(teamId);

    if (!team) {
      return false;
    }

    const member = team.members.find((m) => m.userId === userId);

    if (!member) {
      return false;
    }

    const resources = this.sharedResources.get(teamId) || [];
    const resource = resources.find((r) => r.resourceId === resourceId);

    if (!resource) {
      return false;
    }

    return resource.permissions.includes(permission);
  }
}

export const teamCollaboration = new TeamCollaboration();
