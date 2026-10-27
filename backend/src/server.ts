import { buildApp } from './app.js';
import { Pool } from 'pg';
import { InMemoryReportRepository, PostgresReportRepository } from './repository.js';

const databaseUrl = process.env.DATABASE_URL;
const pool = databaseUrl ? new Pool({ connectionString: databaseUrl }) : undefined;
const inMemory = new InMemoryReportRepository();
const repository = pool ? new PostgresReportRepository(pool) : inMemory;
const corsOrigin = process.env.CORS_ORIGIN;
const app = buildApp(repository, corsOrigin ? { corsOrigin } : {});

// The API only answers while reports expire: aggregation loses meaning if
// stale counts survive. Purge once a minute; harmless for the in-memory repo.
const purgeTimer = setInterval(async () => {
  try {
    await repository.purgeExpired(new Date());
  } catch (error) {
    app.log.error(error, 'purge_expired_failed');
  }
}, 60_000);
purgeTimer.unref?.();

const shutdown = async () => {
  clearInterval(purgeTimer);
  await app.close();
  await pool?.end();
  process.exit(0);
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

await app.listen({ port: Number(process.env.PORT ?? 3000), host: '0.0.0.0' });
