import { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { apiRequest, errorMessage } from '../../lib/api';

export default function AccountRecovery({ mode }) {
  const [params] = useSearchParams();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const confirm = mode === 'confirm';
  const reset = mode === 'reset';
  const resend = mode === 'resend';
  const token = params.get(confirm ? 'confirmation_token' : 'reset_password_token');
  const title = confirm ? 'Confirmar correo' : reset ? 'Elegir nueva contraseña' : resend ? 'Reenviar confirmación' : 'Recuperar contraseña';
  async function submit(event) {
    event.preventDefault(); setBusy(true); setError('');
    const fields = Object.fromEntries(new FormData(event.currentTarget));
    if (reset && fields.password !== fields.password_confirmation) { setError('Las contraseñas no coinciden.'); setBusy(false); return; }
    const path = confirm || resend ? '/confirmations' : '/passwords';
    const body = confirm ? { confirmation_token: token } : reset ? { ...fields, reset_password_token: token } : fields;
    try { setMessage((await apiRequest(path, { method: confirm || reset ? 'PATCH' : 'POST', body })).data.message); }
    catch (failure) { setError(errorMessage(failure)); }
    finally { setBusy(false); }
  }
  return <section className="auth-card"><h1>{title}</h1>
    {message ? <p role="status">{message}</p> : (confirm || reset) && !token ? <p role="alert">Falta el enlace del correo. Solicitá uno nuevo.</p> :
      <form onSubmit={submit}>
        {confirm ? <p>Confirmá que querés activar tu cuenta de Homeharbor.</p> : reset ? <>
          <label htmlFor="password">Nueva contraseña</label><input id="password" name="password" type="password" autoComplete="new-password" minLength={12} maxLength={128} required />
          <label htmlFor="password_confirmation">Repetir contraseña</label><input id="password_confirmation" name="password_confirmation" type="password" autoComplete="new-password" minLength={12} maxLength={128} required />
        </> : <><label htmlFor="email">Correo electrónico</label><input id="email" name="email" type="email" autoComplete="email" required /></>}
        {error && <p role="alert">{error}</p>}
        <button className="primary" disabled={busy}>{busy ? 'Enviando…' : title}</button>
      </form>}
    <Link to="/login">Volver a ingresar</Link>
    {(confirm || resend) && <Link to="/resend-confirmation">Pedir un nuevo enlace</Link>}
    {reset && <Link to="/forgot-password">Pedir un nuevo enlace</Link>}
  </section>;
}
