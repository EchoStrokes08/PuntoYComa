import assert from 'node:assert/strict';
import test from 'node:test';
import { randomUUID } from 'node:crypto';
import { buildApp } from '../src/app.js';
import { InMemoryReportRepository } from '../src/repository.js';

test('health endpoint returns ok', async () => {
  const app = buildApp(new InMemoryReportRepository());
  const res = await app.inject({ method: 'GET', url: '/health' });
  assert.equal(res.statusCode, 200);
  assert.equal(res.json().status, 'ok');
  await app.close();
});

test('accepts a valid community report', async () => {
  const app = buildApp(new InMemoryReportRepository());
  const res = await app.inject({
    method: 'POST',
    url: '/v1/community/reports',
    payload: {
      routeId: 'ruta-A',
      category: 'crowded',
      latitude: 4.6680,
      longitude: -74.0519,
      installationId: 'e0b15c47-7bce-4dcb-a92e-b30afebd07f7',
    },
  });
  assert.equal(res.statusCode, 202);
  assert.equal(res.json().accepted, true);
  await app.close();
});

test('rejects a report with invalid category', async () => {
  const app = buildApp(new InMemoryReportRepository());
  const res = await app.inject({
    method: 'POST',
    url: '/v1/community/reports',
    payload: {
      routeId: 'ruta-A',
      category: 'spam',
      latitude: 4.6680,
      longitude: -74.0519,
      installationId: 'e0b15c47-7bce-4dcb-a92e-b30afebd07f7',
    },
  });
  assert.equal(res.statusCode, 400);
  await app.close();
});

test('feed returns counts for a route and cell', async () => {
  const repo = new InMemoryReportRepository();
  const app = buildApp(repo);

  await repo.create({
    id: 'r1',
    routeId: 'ruta-A',
    cellId: '4.67:-74.05',
    category: 'crowded',
    anonymousDayId: 'day1-installer1',
    expiresAt: new Date(Date.now() + 30 * 60 * 1000),
  });
  await repo.create({
    id: 'r2',
    routeId: 'ruta-A',
    cellId: '4.67:-74.05',
    category: 'delay',
    anonymousDayId: 'day1-installer2',
    expiresAt: new Date(Date.now() + 30 * 60 * 1000),
  });

  const res = await app.inject({
    method: 'GET',
    url: '/v1/community/feed?routeId=ruta-A&latitude=4.6680&longitude=-74.0519',
  });
  assert.equal(res.statusCode, 200);
  const body = res.json();
  assert.equal(body.routeId, 'ruta-A');
  assert.equal(body.cellId, '4.67:-74.05');
  const counts = Object.fromEntries(body.reports.map((r: { category: string; count: number }) => [r.category, r.count]));
  assert.equal(counts.crowded, 1);
  assert.equal(counts.delay, 1);
  await app.close();
});

test('different installers can each submit reports independently', async () => {
  const alphaId = randomUUID();
  const betaId = randomUUID();

  // Cada POST usa una instancia fresca de la app para evitar problemas de
  // estado compartido entre inyecciones en el mismo servidor.
  const postReport = async (installationId: string, category: string) => {
    const app = buildApp(new InMemoryReportRepository());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/community/reports',
      payload: {
        routeId: 'ruta-A',
        latitude: 4.6680,
        longitude: -74.0519,
        installationId,
        category,
      },
    });
    await app.close();
    return res;
  };

  // Dos installers diferentes pueden enviar reportes sin interferirse
  const res1 = await postReport(alphaId, 'crowded');
  assert.equal(res1.statusCode, 202);

  const res2 = await postReport(betaId, 'delay');
  assert.equal(res2.statusCode, 202);

  // El mismo installer puede enviar múltiples reportes dentro del límite
  const res3 = await postReport(alphaId, 'crowded');
  assert.equal(res3.statusCode, 202);
});
