export interface Variant {
  name: string;
  weight: number;
  config?: Record<string, any>;
}

export interface Experiment {
  id: string;
  name: string;
  variants: Variant[];
  isActive: boolean;
  startDate: Date;
  endDate?: Date;
}

export interface ExperimentAssignment {
  userId: string;
  experimentId: string;
  variant: string;
  assignedAt: Date;
}

export class ABTestingManager {
  private experiments: Map<string, Experiment> = new Map();
  private assignments: Map<string, Map<string, ExperimentAssignment>> = new Map();

  createExperiment(experiment: Experiment): void {
    this.experiments.set(experiment.id, experiment);
    this.assignments.set(experiment.id, new Map());
  }

  assignVariant(userId: string, experimentId: string): string | null {
    const experiment = this.experiments.get(experimentId);

    if (!experiment || !experiment.isActive) {
      return null;
    }

    const now = new Date();

    if (now < experiment.startDate) {
      return null;
    }

    if (experiment.endDate && now > experiment.endDate) {
      return null;
    }

    const existingAssignment = this.assignments
      .get(experimentId)
      ?.get(userId);

    if (existingAssignment) {
      return existingAssignment.variant;
    }

    const variant = this.selectVariant(experiment, userId);

    const assignment: ExperimentAssignment = {
      userId,
      experimentId,
      variant: variant.name,
      assignedAt: new Date(),
    };

    this.assignments.get(experimentId)!.set(userId, assignment);

    return variant.name;
  }

  private selectVariant(experiment: Experiment, userId: string): Variant {
    const hash = this.hashString(userId + experiment.id);
    const totalWeight = experiment.variants.reduce((sum, v) => sum + v.weight, 0);

    let cumulative = 0;

    for (const variant of experiment.variants) {
      cumulative += variant.weight / totalWeight;

      if (hash < cumulative) {
        return variant;
      }
    }

    return experiment.variants[0];
  }

  getAssignment(userId: string, experimentId: string): string | null {
    return this.assignments.get(experimentId)?.get(userId)?.variant || null;
  }

  getExperimentStats(experimentId: string): Record<string, number> {
    const assignments = this.assignments.get(experimentId);

    if (!assignments) {
      return {};
    }

    const stats: Record<string, number> = {};

    for (const assignment of assignments.values()) {
      stats[assignment.variant] = (stats[assignment.variant] || 0) + 1;
    }

    return stats;
  }

  stopExperiment(experimentId: string): void {
    const experiment = this.experiments.get(experimentId);

    if (experiment) {
      experiment.isActive = false;
      experiment.endDate = new Date();
    }
  }

  private hashString(str: string): number {
    let hash = 0;

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash;
    }

    return Math.abs(hash) / 2147483647;
  }
}

export const abTesting = new ABTestingManager();

abTesting.createExperiment({
  id: 'homepage-redesign',
  name: 'Homepage Redesign Test',
  variants: [
    { name: 'control', weight: 50 },
    { name: 'variant-a', weight: 50 },
  ],
  isActive: true,
  startDate: new Date(),
});
