import { createHash, randomUUID } from 'node:crypto';
export const reportCategories = ['crowded', 'delay', 'safety', 'accessibility'];
/** A coarse ~1 km cell. Raw coordinates never reach storage or feeds. */
export function privacyCell(latitude, longitude) {
    return `${(Math.round(latitude * 100) / 100).toFixed(2)}:${(Math.round(longitude * 100) / 100).toFixed(2)}`;
}
/** Rotates each UTC day so reports cannot be used to follow a person. */
export function rotatingReporterId(installationId, day = new Date()) {
    const date = day.toISOString().slice(0, 10);
    return createHash('sha256').update(`${installationId}:${date}`).digest('hex');
}
export function newReportId() { return randomUUID(); }
