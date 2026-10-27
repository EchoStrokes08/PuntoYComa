export class InMemoryReportRepository {
    reports = [];
    async create(report) { this.reports.push(report); }
    async feed(routeId, cellId, now) {
        const counts = new Map();
        for (const report of this.reports)
            if (report.routeId === routeId && report.cellId === cellId && report.expiresAt > now)
                counts.set(report.category, (counts.get(report.category) ?? 0) + 1);
        return [...counts].map(([category, count]) => ({ category, count }));
    }
    async purgeExpired(now) {
        this.reports = this.reports.filter((report) => report.expiresAt > now);
    }
}
export class PostgresReportRepository {
    pool;
    constructor(pool) {
        this.pool = pool;
    }
    async create(report) {
        await this.pool.query(`INSERT INTO community_reports (id, route_id, cell_id, category, anonymous_day_id, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (anonymous_day_id, route_id, cell_id, category) WHERE status IN ('pending', 'approved') DO NOTHING`, [report.id, report.routeId, report.cellId, report.category, report.anonymousDayId, report.expiresAt]);
    }
    async feed(routeId, cellId, now) {
        const result = await this.pool.query(`SELECT category, count(*)::text AS count FROM community_reports
       WHERE route_id = $1 AND cell_id = $2 AND status IN ('pending', 'approved') AND expires_at > $3
       GROUP BY category`, 
        // Nota: hasta que exista moderación, 'pending' es el estado por defecto de
        // todo reporte; el feed solo eliminará 'pending' cuando haya curatoría activa.
        [routeId, cellId, now]);
        return result.rows.map((row) => ({ category: row.category, count: Number(row.count) }));
    }
    async purgeExpired(now) {
        await this.pool.query(`DELETE FROM community_reports WHERE expires_at < $1`, [now]);
    }
}
