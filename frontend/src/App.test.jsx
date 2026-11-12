import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import App from './App';
import { makeStore } from './redux/store';
import { clearCsrfToken } from './lib/api';

function response(body, status = 200) { return { ok: status >= 200 && status < 300, status, json: async () => body }; }
const guest = () => response({ error: { code: 'unauthenticated', message: 'Ingresá para continuar.' } }, 401);
function mount(path) {
  window.history.replaceState({}, '', path);
  const store = makeStore();
  render(<Provider store={store}><App /></Provider>);
  return store;
}

describe('accounts connected to the API', () => {
  let fetchMock;
  beforeEach(() => {
    localStorage.clear(); clearCsrfToken();
    fetchMock = vi.fn(async url => {
      if (url === '/api/v1/session/csrf') return response({ data: { csrf_token: 'csrf-one' } });
      if (url === '/api/v1/session') return guest();
      if (url.startsWith('/api/v1/me/boats')) return response({ data: [], meta: { total: 0, per_page: 12 } });
      if (url.startsWith('/api/v1/boats')) return response({ data: [], meta: { total: 0, per_page: 12 } });
      throw new Error('Unexpected request ' + url);
    });
    vi.stubGlobal('fetch', fetchMock);
  });
  afterEach(() => vi.unstubAllGlobals());

  it('ignores a forged localStorage identity and guards private routes', async () => {
    localStorage.setItem('user', JSON.stringify({ id: 999, role: 'admin' }));
    mount('/add-boat');
    expect(await screen.findByRole('heading', { name: 'Ingresar a Homeharbor' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Publicar bote' })).not.toBeInTheDocument();
    expect(localStorage.getItem('user')).toBeNull();
  });

  it('sends email password and CSRF, then renders authenticated navigation', async () => {
    fetchMock.mockImplementation(async (url, options) => {
      if (url.endsWith('/csrf')) return response({ data: { csrf_token: 'csrf-one' } });
      if (url === '/api/v1/session' && options.method === 'POST') return response({ data: { user: { id: 1, name: 'Ana' }, csrf_token: 'csrf-two' } });
      if (url === '/api/v1/session') return guest();
      return response({ data: [], meta: { total: 0, per_page: 12 } });
    });
    mount('/login');
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Correo electrónico'), 'ana@example.com');
    await user.type(screen.getByLabelText('Contraseña'), 'long-password-2026');
    await user.click(screen.getByRole('button', { name: 'Ingresar' }));
    expect(await screen.findByRole('heading', { name: 'Mis botes' })).toBeInTheDocument();
    const [, options] = fetchMock.mock.calls.find(([url, init]) => url === '/api/v1/session' && init.method === 'POST');
    expect(JSON.parse(options.body)).toEqual({ user: { email: 'ana@example.com', password: 'long-password-2026' } });
    expect(options.headers['X-CSRF-Token']).toBe('csrf-one');
    expect(options.credentials).toBe('same-origin');
    expect(localStorage.getItem('user')).toBeNull();
  });

  it('shows API login errors without a false success', async () => {
    fetchMock.mockImplementation(async url => url.endsWith('/csrf') ? response({ data: { csrf_token: 'token' } }) : guest());
    mount('/login');
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Correo electrónico'), 'ana@example.com');
    await user.type(screen.getByLabelText('Contraseña'), 'wrong-password');
    await user.click(screen.getByRole('button', { name: 'Ingresar' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Ingresá para continuar.');
    expect(screen.getByRole('heading', { name: 'Ingresar a Homeharbor' })).toBeInTheDocument();
  });

  it('registers all account fields and asks for email confirmation', async () => {
    fetchMock.mockImplementation(async url => {
      if (url.endsWith('/csrf')) return response({ data: { csrf_token: 'token' } });
      if (url.endsWith('/registrations')) return response({ data: { message: 'Revisá tu correo para confirmar la cuenta.' } }, 201);
      return guest();
    });
    mount('/signup');
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Nombre'), 'Ana');
    await user.type(screen.getByLabelText('Correo electrónico'), 'ana@example.com');
    await user.type(screen.getByLabelText('Contraseña', { exact: true }), 'long-password-2026');
    await user.type(screen.getByLabelText('Repetir contraseña'), 'long-password-2026');
    await user.click(screen.getByRole('button', { name: 'Crear cuenta' }));
    expect(await screen.findByRole('status')).toHaveTextContent('Revisá tu correo');
    const [, options] = fetchMock.mock.calls.find(([url]) => url.endsWith('/registrations'));
    expect(JSON.parse(options.body).user.password_confirmation).toBe('long-password-2026');
    expect(screen.queryByRole('button', { name: 'Cerrar sesión' })).not.toBeInTheDocument();
  });

  it('retains a session if server logout fails', async () => {
    fetchMock.mockImplementation(async (url, options) => {
      if (url.endsWith('/csrf')) return response({ data: { csrf_token: 'token' } });
      if (url === '/api/v1/session' && options.method === 'DELETE') throw new Error('Sin conexión');
      if (url === '/api/v1/session') return response({ data: { user: { id: 1, name: 'Ana' }, csrf_token: 'token' } });
      return response({ data: [], meta: { total: 0, per_page: 12 } });
    });
    const store = mount('/my-boats');
    await userEvent.click(await screen.findByRole('button', { name: 'Cerrar sesión' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Sin conexión');
    expect(store.getState().usersession.user.id).toBe(1);
  });

  it('redirects an expired session returned by a private API request', async () => {
    fetchMock.mockImplementation(async url => {
      if (url === '/api/v1/session') return response({ data: { user: { id: 1, name: 'Ana' }, csrf_token: 'token' } });
      return guest();
    });
    mount('/my-boats');
    expect(await screen.findByRole('heading', { name: 'Ingresar a Homeharbor' })).toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent('Tu sesión venció');
  });

  it('does not confirm email until the user submits the confirmation screen', async () => {
    fetchMock.mockImplementation(async url => {
      if (url.endsWith('/csrf')) return response({ data: { csrf_token: 'token' } });
      if (url.endsWith('/confirmations')) return response({ data: { message: 'Correo confirmado. Ya podés ingresar.' } });
      return guest();
    });
    mount('/confirm-email?confirmation_token=email-token');
    await waitFor(() => expect(fetchMock).toHaveBeenCalled());
    expect(fetchMock.mock.calls.some(([url]) => url.endsWith('/confirmations'))).toBe(false);
    await userEvent.click(screen.getByRole('button', { name: 'Confirmar correo' }));
    expect(await screen.findByRole('status')).toHaveTextContent('Correo confirmado');
    const [, options] = fetchMock.mock.calls.find(([url]) => url.endsWith('/confirmations'));
    expect(JSON.parse(options.body)).toEqual({ confirmation_token: 'email-token' });
  });

  it('preserves boat fields when publishing fails and does not show success', async () => {
    fetchMock.mockImplementation(async (url, options) => {
      if (url === '/api/v1/session') return response({ data: { user: { id: 1, name: 'Ana' }, csrf_token: 'token' } });
      if (url === '/api/v1/boats' && options.method === 'POST') return response({ error: { message: 'Tarifa inválida.' } }, 422);
      return guest();
    });
    mount('/add-boat');
    const user = userEvent.setup();
    await user.type(await screen.findByLabelText('Nombre del bote'), 'Harbor One');
    await user.type(screen.getByLabelText('Descripción'), 'Sailing boat');
    await user.type(screen.getByLabelText('Puerto'), 'Tigre');
    await user.type(screen.getByLabelText('Capacidad de personas'), '6');
    await user.type(screen.getByLabelText('Tarifa por día (USD)'), '100');
    await user.click(screen.getByRole('button', { name: 'Publicar bote' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Tarifa inválida');
    expect(screen.getByLabelText('Nombre del bote')).toHaveValue('Harbor One');
    const [, options] = fetchMock.mock.calls.find(([url, init]) => url === '/api/v1/boats' && init.method === 'POST');
    expect(JSON.parse(options.body).boat).not.toHaveProperty('owner_id');
  });
});
