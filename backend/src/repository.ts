import type { ReportCategory } from './domain.js';
import type { Pool } from 'pg';

export type Report = { id: string; routeId: string; cellId: string; category: ReportCategory; anonymousDayId: string; expiresAt: Date };
export interface ReportRepository {
  create(report: Report): Promise<void>;
  feed(routeId: string, cellId: string, now: Date): Promise<Array<{ category: ReportCategory; count: number }>>;
  purgeExpired(now: Date): Promise<void>;
}

export class InMemoryReportRepository implements ReportRepository {
  private reports: Report[] = [];
  async create(report: Report) { this.reports.push(report); }
  async feed(routeId: string, cellId: string, now: Date) {
    const counts = new Map<ReportCategory, number>();
    for (const report of this.reports) if (report.routeId === routeId && report.cellId === cellId && report.expiresAt > now) counts.set(report.category, (counts.get(report.category) ?? 0) + 1);
    return [...counts].map(([category, count]) => ({ category, count }));
  }
  async purgeExpired(now: Date) {
    this.reports = this.reports.filter((report) => report.expiresAt > now);
  }
}

export class PostgresReportRepository implements ReportRepository {
  constructor(private readonly pool: Pool) {}

  async create(report: Report) {
    await this.pool.query(
      `INSERT INTO community_reports (id, route_id, cell_id, category, anonymous_day_id, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (anonymous_day_id, route_id, cell_id, category) WHERE status IN ('pending', 'approved') DO NOTHING`,
      [report.id, report.routeId, report.cellId, report.category, report.anonymousDayId, report.expiresAt],
    );
  }

  async feed(routeId: string, cellId: string, now: Date) {
    const result = await this.pool.query<{ category: ReportCategory; count: string }>(
      `SELECT category, count(*)::text AS count FROM community_reports
       WHERE route_id = $1 AND cell_id = $2 AND status IN ('pending', 'approved') AND expires_at > $3
       GROUP BY category`,
       // Nota: hasta que exista moderación, 'pending' es el estado por defecto de
       // todo reporte; el feed solo eliminará 'pending' cuando haya curatoría activa.
      [routeId, cellId, now],
    );
    return result.rows.map((row) => ({ category: row.category, count: Number(row.count) }));
  }

  async purgeExpired(now: Date) {
    await this.pool.query(`DELETE FROM community_reports WHERE expires_at < $1`, [now]);
  }
}
