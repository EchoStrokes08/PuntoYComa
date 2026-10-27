import assert from 'node:assert/strict';
import test from 'node:test';
import { privacyCell, rotatingReporterId } from '../src/domain.js';

test('converts exact positions into coarse non-identifying cells', () => {
  assert.equal(privacyCell(4.651234, -74.061234), '4.65:-74.06');
});

test('rotating reporter id changes on the next day', () => {
  const id = 'e0b15c47-7bce-4dcb-a92e-b30afebd07f7';
  assert.notEqual(rotatingReporterId(id, new Date('2026-01-01')), rotatingReporterId(id, new Date('2026-01-02')));
});
