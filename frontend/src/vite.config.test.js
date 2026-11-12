import { describe, expect, it } from 'vitest';
import config from '../vite.config';

describe('development routing', () => {
  it('keeps React login and signup routes out of the backend proxy', () => {
    const { server } = config({ mode: 'test' });
    expect(server.proxy).not.toHaveProperty('/login');
    expect(server.proxy).not.toHaveProperty('/signup');
    expect(server.proxy).not.toHaveProperty('/legacy-auth');
    expect(server.proxy).toHaveProperty('/api');
  });
});
