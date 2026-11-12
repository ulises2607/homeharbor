let csrfToken;
let csrfRequest;
let onUnauthorized = () => {};

export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler;
}
export function clearCsrfToken() {
  csrfToken = undefined;
  csrfRequest = undefined;
}
export class ApiError extends Error {
  constructor(status, error = {}) {
    super(error.message || 'No pudimos completar la solicitud.');
    this.status = status;
    this.code = error.code;
    this.fields = error.fields;
  }
}
async function readResponse(response) {
  if (response.status === 204) return {};
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new ApiError(response.status, body.error);
  if (body.data?.csrf_token) csrfToken = body.data.csrf_token;
  return body;
}
export async function ensureCsrf() {
  if (csrfToken) return csrfToken;
  if (!csrfRequest) {
    csrfRequest = fetch('/api/v1/session/csrf', { credentials: 'same-origin', headers: { Accept: 'application/json' } })
      .then(readResponse).then(() => csrfToken).finally(() => { csrfRequest = undefined; });
  }
  return csrfRequest;
}
export async function apiRequest(path, { method = 'GET', body, signal, notifyUnauthorized = true } = {}) {
  const headers = { Accept: 'application/json' };
  const multipart = body instanceof FormData;
  if (method !== 'GET') {
    headers['X-CSRF-Token'] = await ensureCsrf();
    if (!multipart) headers['Content-Type'] = 'application/json';
  }
  try {
    return await readResponse(await fetch('/api/v1' + path, {
      method, headers, credentials: 'same-origin', signal,
      ...(body === undefined ? {} : { body: multipart ? body : JSON.stringify(body) }),
    }));
  } catch (error) {
    if (error.code === 'invalid_csrf') clearCsrfToken();
    if (error.status === 401 && notifyUnauthorized) {
      clearCsrfToken();
      onUnauthorized();
    }
    throw error;
  }
}
export function errorMessage(error) {
  const fields = error.fields ? Object.entries(error.fields).flatMap(([field, messages]) => messages.map(message => field + ': ' + message)).join(' · ') : '';
  return fields || error.message || 'No se pudo conectar. Revisá tu conexión e intentá de nuevo.';
}
