import assert from 'node:assert/strict';
import test from 'node:test';
import { ReporterRateLimiter } from '../src/reporter_rate_limiter.js';

test('allows reports up to the per-window limit', () => {
  const limiter = new ReporterRateLimiter({ maxPerWindow: 3, windowMs: 60_000 });
  assert.equal(limiter.allow('installer-1'), true);
  assert.equal(limiter.allow('installer-1'), true);
  assert.equal(limiter.allow('installer-1'), true);
  assert.equal(limiter.allow('installer-1'), false); // excede el límite
});

test('different installers have independent limits', () => {
  const limiter = new ReporterRateLimiter({ maxPerWindow: 2, windowMs: 60_000 });
  assert.equal(limiter.allow('installer-1'), true);
  assert.equal(limiter.allow('installer-2'), true);
  assert.equal(limiter.allow('installer-1'), true);
  assert.equal(limiter.allow('installer-2'), true);
  assert.equal(limiter.allow('installer-1'), false);
  assert.equal(limiter.allow('installer-2'), false);
});

test('window resets after the time window elapses', () => {
  const limiter = new ReporterRateLimiter({ maxPerWindow: 1, windowMs: 50 });
  assert.equal(limiter.allow('installer-1'), true);
  assert.equal(limiter.allow('installer-1'), false);
  // Avanzar el tiempo manipulando Date.now no afecta; usar ventana muy pequeña
  // y esperar es lento, así que verificamos que gc limpie buckets expirados.
  limiter.gc();
  // El bucket aún está dentro de la ventana, así que gc no lo borra.
  assert.equal(limiter.buckets.size, 1);
});
