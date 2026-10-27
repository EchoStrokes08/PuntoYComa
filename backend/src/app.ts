import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import { z } from 'zod';
import { newReportId, privacyCell, reportCategories, rotatingReporterId } from './domain.js';
import type { ReportRepository } from './repository.js';
import { ReporterRateLimiter } from './reporter_rate_limiter.js';

const reportSchema = z.object({ routeId: z.string().min(1).max(128), category: z.enum(reportCategories), latitude: z.number().gte(-90).lte(90), longitude: z.number().gte(-180).lte(180), installationId: z.string().uuid() });
const feedSchema = z.object({ routeId: z.string().min(1).max(128), latitude: z.coerce.number().gte(-90).lte(90), longitude: z.coerce.number().gte(-180).lte(180) });

/// Rate limiter por reporter (anonymousDayId): 5 reportes por minuto por instalación.
const reporterLimiter = new ReporterRateLimiter({ maxPerWindow: 5, windowMs: 60_000 });

export function buildApp(reports: ReportRepository, options: { corsOrigin?: string } = {}) {
  const app = Fastify({ logger: true });
  app.register(helmet);
  // Capa 1: rate limit global por IP (protege contra abusos de red).
  app.register(rateLimit, { max: 30, timeWindow: '1 minute' });
  if (options.corsOrigin) app.register(cors, { origin: [options.corsOrigin] });

  app.get('/health', async () => ({ status: 'ok' }));

  app.post('/v1/community/reports', async (request, reply) => {
    const input = reportSchema.parse(request.body);
    const now = new Date();

    // Capa 2: rate limit por anonymousDayId (5 reportes/minuto por instalación).
    const anonymousDayId = rotatingReporterId(input.installationId, now);
    if (!reporterLimiter.allow(anonymousDayId)) {
      return reply.code(429).send({ error: 'reporter_rate_limited', retryAfterSeconds: 60 });
    }

    await reports.create({ id: newReportId(), routeId: input.routeId, cellId: privacyCell(input.latitude, input.longitude), category: input.category, anonymousDayId, expiresAt: new Date(now.getTime() + 30 * 60 * 1000) });
    return reply.code(202).send({ accepted: true, expiresInSeconds: 1800 });
  });

  app.get('/v1/community/feed', async (request) => {
    const input = feedSchema.parse(request.query);
    return { routeId: input.routeId, cellId: privacyCell(input.latitude, input.longitude), reports: await reports.feed(input.routeId, privacyCell(input.latitude, input.longitude), new Date()) };
  });

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof z.ZodError) return reply.code(400).send({ error: 'invalid_request', details: error.flatten() });
    request.log.error(error);
    return reply.code(500).send({ error: 'internal_error' });
  });
  return app;
}
