import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import App from './App';
import { makeStore } from './redux/store';
import { clearCsrfToken } from './lib/api';

const boat = { id: 1, name: 'Aurora', description: 'Bote de prueba', port: 'Tigre', capacity: 6, daily_rate_cents: 12000, currency: 'USD', photos: [] };
const photo = { id: 9, url: '/api/v1/boats/1/photos/9' };
const response = (body, status = 200) => ({ ok: status < 400, status, json: async () => body });
function mount(path) {
  window.history.replaceState({}, '', path);
  render(<Provider store={makeStore()}><App /></Provider>);
}

describe('catalog and owner photos', () => {
  let fetchMock;
  beforeEach(() => {
    clearCsrfToken();
    fetchMock = vi.fn(async url => {
      if (url === '/api/v1/session') return response({ data: { user: { id: 1, name: 'Ana' }, csrf_token: 'token' } });
      if (url.endsWith('/csrf')) return response({ data: { csrf_token: 'token' } });
      if (url === '/api/v1/me/boats/1') return response({ data: boat });
      return response({ data: [boat], meta: { page: 2, total: 25, per_page: 12 } });
    });
    vi.stubGlobal('fetch', fetchMock);
  });
  afterEach(() => vi.unstubAllGlobals());

  it('keeps filters in the URL, resets page when searching and preserves filters when paging', async () => {
    mount('/boats?page=2&port=Delta');
    const user = userEvent.setup();
    await screen.findByRole('heading', { name: 'Aurora' });
    await user.clear(screen.getByLabelText('Puerto'));
    await user.type(screen.getByLabelText('Puerto'), 'Tigre');
    await user.type(screen.getByLabelText('Personas'), '4');
    await user.click(screen.getByRole('button', { name: 'Buscar botes' }));
    expect(window.location.search).toBe('?port=Tigre&min_capacity=4');
    await screen.findByRole('heading', { name: 'Aurora' });
    expect(fetchMock.mock.calls.some(([url]) => url === '/api/v1/boats?port=Tigre&min_capacity=4')).toBe(true);
    await user.click(screen.getByRole('button', { name: 'Siguiente' }));
    expect(window.location.search).toBe('?port=Tigre&min_capacity=4&page=2');
    await user.click(screen.getByRole('button', { name: 'Limpiar filtros' }));
    expect(window.location.search).toBe('');
    expect(screen.getByLabelText('Puerto')).toHaveValue('');
  });

  it('distinguishes empty search results from an empty catalog', async () => {
    fetchMock.mockImplementation(async () => response({ data: [], meta: { total: 0, per_page: 12 } }));
    mount('/boats?port=Nowhere');
    expect(await screen.findByText('No encontramos botes con esos filtros.')).toBeInTheDocument();
    expect(screen.queryByText('Publicá el primero')).not.toBeInTheDocument();
  });

  it('uploads multipart with CSRF and renders only the photo returned by the API', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation(async (url, options) => {
      if (url === '/api/v1/boats/1/photos' && options.method === 'POST') return response({ data: { ...boat, photos: [photo] } }, 201);
      return defaults(url, options);
    });
    mount('/my-boats/1/edit');
    const user = userEvent.setup();
    const file = new File(['test image bytes'], 'boat.png', { type: 'image/png' });
    await user.upload(await screen.findByLabelText('Agregar foto'), file);
    fireEvent.submit(screen.getByLabelText('Agregar foto').form);
    expect(await screen.findByText('Foto agregada.')).toBeInTheDocument();
    expect(screen.getByRole('img', { name: 'Aurora · foto 1' })).toHaveAttribute('src', photo.url);
    const [, options] = fetchMock.mock.calls.find(([url]) => url === '/api/v1/boats/1/photos');
    expect(options.body).toBeInstanceOf(FormData);
    expect(options.body.get('photo')).toBe(file);
    expect(options.headers['X-CSRF-Token']).toBe('token');
    expect(options.headers).not.toHaveProperty('Content-Type');
    expect(screen.getByLabelText('Agregar foto').files).toHaveLength(0);
  });

  it('preserves the selected file after a failed upload and never reports success', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation(async (url, options) => url === '/api/v1/boats/1/photos'
      ? response({ error: { message: 'Almacenamiento no disponible.' } }, 503) : defaults(url, options));
    mount('/my-boats/1/edit');
    const user = userEvent.setup();
    const input = await screen.findByLabelText('Agregar foto');
    await user.upload(input, new File(['test'], 'boat.png', { type: 'image/png' }));
    fireEvent.submit(input.form);
    expect(await screen.findByRole('alert')).toHaveTextContent('Almacenamiento no disponible');
    expect(input.files).toHaveLength(1);
    expect(screen.queryByText('Foto agregada.')).not.toBeInTheDocument();
  });

  it('does not remove a photo from the screen when deletion fails', async () => {
    const defaults = fetchMock.getMockImplementation();
    fetchMock.mockImplementation(async (url, options) => {
      if (url === '/api/v1/me/boats/1') return response({ data: { ...boat, photos: [photo] } });
      if (options.method === 'DELETE') throw new Error('Sin conexión');
      return defaults(url, options);
    });
    mount('/my-boats/1/edit');
    await userEvent.click(await screen.findByRole('button', { name: 'Eliminar foto 1' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Sin conexión');
    expect(screen.getByRole('img', { name: 'Aurora · foto 1' })).toBeInTheDocument();
    await waitFor(() => expect(screen.getByRole('button', { name: 'Eliminar foto 1' })).toBeEnabled());
  });
});
