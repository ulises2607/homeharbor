import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import App from './App';
import { makeStore } from './redux/store';
import { clearCsrfToken } from './lib/api';
import { readPending, savePending } from './lib/reservations';

const boat = { id: 1, name: 'Aurora', description: 'Bote', port: 'Tigre', capacity: 6, daily_rate_cents: 10000, currency: 'USD', active: true, photos: [] };
const payload = { boat_id: 1, starts_on: '2099-12-10', ends_on: '2099-12-12', passengers: 4, expected_total_cents: 20000, expected_currency: 'USD' };
const quote = { available: true, days: 2, daily_rate_cents: 10000, total_cents: 20000, currency: 'USD', time_zone: 'Etc/GMT+3', occupied_intervals: [] };
const reservation = { ...payload, id: 20, boat, days: 2, status: 'confirmed', currency: 'USD', daily_rate_cents: 10000, total_cents: 20000, cancellation_deadline: '2099-12-09T03:00:00Z', can_cancel: true };
const response = (body, status = 200) => ({ ok: status < 400, status, json: async () => body });
function mount(path) {
  window.history.replaceState({}, '', path);
  return render(<Provider store={makeStore()}><App /></Provider>);
}
async function requestQuote() {
  const first = await screen.findByLabelText('Primer día de uso');
  fireEvent.change(first, { target: { value: payload.starts_on } });
  fireEvent.change(screen.getByLabelText('Disponible nuevamente desde'), { target: { value: payload.ends_on } });
  fireEvent.change(screen.getByLabelText('Pasajeros'), { target: { value: '4' } });
  await userEvent.click(screen.getByRole('button', { name: 'Consultar disponibilidad' }));
}

describe('reservations connected to the API', () => {
  let fetchMock;
  beforeEach(() => {
    sessionStorage.clear(); clearCsrfToken();
    fetchMock = vi.fn(async (url, options) => {
      if (url === '/api/v1/session') return response({ data: { user: { id: 2, name: 'Ana' }, csrf_token: 'token' } });
      if (url.endsWith('/csrf')) return response({ data: { csrf_token: 'token' } });
      if (url === '/api/v1/boats/1') return response({ data: boat });
      if (url.startsWith('/api/v1/boats/1/availability?')) return response({ data: quote });
      if (url === '/api/v1/reservations' && options.method === 'POST') return response({ data: reservation }, 201);
      if (url === '/api/v1/me/reservations/20') return response({ data: reservation });
      throw new Error('Unexpected request ' + url);
    });
    vi.stubGlobal('fetch', fetchMock);
  });
  afterEach(() => vi.unstubAllGlobals());

  it('shows server quote and exclusive end then clears it when inputs change', async () => {
    mount('/boats/1');
    await requestQuote();
    expect(await screen.findByText('Total: 200.00 USD')).toBeInTheDocument();
    expect(screen.getByText(/del 10 al 12 incluye los días 10 y 11/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Confirmar reserva' })).toBeEnabled();
    fireEvent.change(screen.getByLabelText('Pasajeros'), { target: { value: '3' } });
    expect(screen.queryByRole('button', { name: 'Confirmar reserva' })).not.toBeInTheDocument();
  });

  it('shows occupied dates and never offers confirmation for an unavailable interval', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation((url, options) => url.includes('/availability?') ? response({ data: { ...quote, available: false, occupied_intervals: [{ starts_on: payload.starts_on, ends_on: payload.ends_on }] } }) : defaults(url, options));
    mount('/boats/1');
    await requestQuote();
    expect(await screen.findByText('Hay fechas ocupadas. Probá otro intervalo.')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Confirmar reserva' })).not.toBeInTheDocument();
  });

  it('persists and reuses the operation after a lost response and a remount', async () => {
    const defaults = fetchMock.getMockImplementation();
    let posts = 0;
    fetchMock.mockImplementation((url, options) => {
      if (url === '/api/v1/reservations' && ++posts === 1) throw new Error('Lost response after commit');
      return defaults(url, options);
    });
    const firstRender = mount('/boats/1');
    await requestQuote();
    await userEvent.click(await screen.findByRole('button', { name: 'Confirmar reserva' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('No pudimos confirmar el resultado');
    const pending = readPending(2, 1);
    expect(pending.payload).toEqual(payload);
    firstRender.unmount();
    mount('/boats/1');
    await userEvent.click(await screen.findByRole('button', { name: 'Verificar confirmación' }));
    expect(await screen.findByRole('heading', { name: 'Reserva #20' })).toBeInTheDocument();
    const requests = fetchMock.mock.calls.filter(([url]) => url === '/api/v1/reservations');
    expect(requests).toHaveLength(2);
    expect(requests[0][1].headers['Idempotency-Key']).toBe(requests[1][1].headers['Idempotency-Key']);
    expect(requests[1][1].headers['X-CSRF-Token']).toBe('token');
    expect(requests[0][1].body).toBe(requests[1][1].body);
    expect(readPending(2, 1)).toBeNull();
  });

  it('retains a pending operation after a 503 instead of creating a new key', async () => {
    const defaults = fetchMock.getMockImplementation();
    savePending(2, 1, { key: 'test-operation', payload });
    fetchMock.mockImplementation((url, options) => url === '/api/v1/reservations' ? response({ error: { message: 'Service unavailable' } }, 503) : defaults(url, options));
    mount('/boats/1');
    await userEvent.click(await screen.findByRole('button', { name: 'Verificar confirmación' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('No pudimos confirmar el resultado');
    expect(readPending(2, 1).key).toBe('test-operation');
    expect(window.location.pathname).toBe('/boats/1');
  });

  it('requires a fresh quote after a price conflict and keeps the dates', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation((url, options) => url === '/api/v1/reservations' ? response({ error: { code: 'price_changed', message: 'La tarifa cambió.' } }, 409) : defaults(url, options));
    mount('/boats/1');
    await requestQuote();
    await userEvent.click(await screen.findByRole('button', { name: 'Confirmar reserva' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('La tarifa cambió');
    expect(screen.queryByRole('button', { name: 'Confirmar reserva' })).not.toBeInTheDocument();
    expect(screen.getByLabelText('Primer día de uso')).toHaveValue(payload.starts_on);
    expect(readPending(2, 1)).toBeNull();
  });

  it('a guest can quote and login keeps the chosen dates', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation((url, options) => url === '/api/v1/session' ? response({ error: { code: 'unauthenticated' } }, 401) : defaults(url, options));
    mount('/boats/1');
    await requestQuote();
    const login = await screen.findByRole('link', { name: 'Ingresar para reservar' });
    await userEvent.click(login);
    expect(window.history.state.usr.from).toContain('starts_on=2099-12-10');
  });

  it('keeps the reservation confirmed when cancellation fails', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation((url, options) => url.endsWith('/cancellation') ? response({ error: { code: 'cancellation_closed', message: 'El plazo para cancelar terminó.' } }, 409) : defaults(url, options));
    mount('/my-reservations/20');
    await userEvent.click(await screen.findByRole('button', { name: 'Cancelar reserva' }));
    await userEvent.click(screen.getByRole('button', { name: 'Confirmar cancelación' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('El plazo para cancelar terminó');
    expect(screen.getByText('Confirmada · Tigre')).toBeInTheDocument();
    expect(screen.queryByText('Reserva cancelada. Las fechas volvieron a quedar disponibles.')).not.toBeInTheDocument();
  });

  it('updates the state only after a successful cancellation response', async () => {
    const defaults = fetchMock.getMockImplementation();
    let cancelled = false;
    fetchMock.mockImplementation((url, options) => {
      if (url.endsWith('/cancellation')) { cancelled = true; return response({ data: { ...reservation, status: 'cancelled', can_cancel: false } }); }
      if (url === '/api/v1/me/reservations/20' && cancelled) return response({ data: { ...reservation, status: 'cancelled', can_cancel: false } });
      return defaults(url, options);
    });
    mount('/my-reservations/20');
    await userEvent.click(await screen.findByRole('button', { name: 'Cancelar reserva' }));
    await userEvent.click(screen.getByRole('button', { name: 'Confirmar cancelación' }));
    expect(await screen.findByText('Cancelada · Tigre')).toBeInTheDocument();
    await waitFor(() => expect(screen.queryByRole('button', { name: 'Cancelar reserva' })).not.toBeInTheDocument());
  });
});
