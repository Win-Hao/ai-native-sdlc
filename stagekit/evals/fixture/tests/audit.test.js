import { test } from 'node:test';
import assert from 'node:assert/strict';
import { auditTrail } from '../src/audit.js';

const o = (id) => ({ id });

test('a complete sequence has no gaps', () => {
  assert.deepEqual(auditTrail([o('ord-0001'), o('ord-0002'), o('ord-0003')]), { checked: 3, gaps: [] });
});

test('a missing order shows as a gap', () => {
  assert.deepEqual(auditTrail([o('ord-0001'), o('ord-0004')]), { checked: 2, gaps: [{ after: 1, before: 4, missing: 2 }] });
});
