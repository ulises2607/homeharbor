import { expect, it, vi, afterEach } from 'vitest';
import { makeStore } from '../store';
import { login, restoreSession } from './usersessionsSlice';
import { clearCsrfToken } from '../../lib/api';

afterEach(() => { vi.unstubAllGlobals(); clearCsrfToken(); });
it('ignores an anonymous session response arriving after successful login', async () => {
  let finishRestore;
  vi.stubGlobal('fetch', vi.fn(async (url, options) => {
    if (url.endsWith('/csrf')) return { ok: true, status: 200, json: async () => ({ data: { csrf_token: 'token' } }) };
    if (options.method === 'POST') return { ok: true, status: 200, json: async () => ({ data: { user: { id: 42, name: 'Ana' }, csrf_token: 'new-token' } }) };
    return new Promise(resolve => { finishRestore = resolve; });
  }));
  const store = makeStore();
  const pendingRestore = store.dispatch(restoreSession());
  await store.dispatch(login({ email: 'ana@example.test', password: 'example-password' })).unwrap();
  finishRestore({ ok: false, status: 401, json: async () => ({ error: { code: 'unauthenticated' } }) });
  await pendingRestore;
  expect(store.getState().usersession.user.id).toBe(42);
});
