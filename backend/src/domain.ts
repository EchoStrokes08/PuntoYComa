import { createHash, randomUUID } from 'node:crypto';

export const reportCategories = ['crowded', 'delay', 'safety', 'accessibility'] as const;
export type ReportCategory = (typeof reportCategories)[number];

/** A coarse ~1 km cell. Raw coordinates never reach storage or feeds. */
export function privacyCell(latitude: number, longitude: number): string {
  return `${(Math.round(latitude * 100) / 100).toFixed(2)}:${(Math.round(longitude * 100) / 100).toFixed(2)}`;
}

/** Rotates each UTC day so reports cannot be used to follow a person. */
export function rotatingReporterId(installationId: string, day = new Date()): string {
  const date = day.toISOString().slice(0, 10);
  return createHash('sha256').update(`${installationId}:${date}`).digest('hex');
}

export function newReportId(): string { return randomUUID(); }
