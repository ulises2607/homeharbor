import { useState } from 'react';
import { Link } from 'react-router-dom';
import { apiRequest, errorMessage } from '../../lib/api';

export default function Signup() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  async function submit(event) {
    event.preventDefault(); setError(''); setBusy(true);
    const user = Object.fromEntries(new FormData(event.currentTarget));
    if (user.password !== user.password_confirmation) { setError('Las contraseñas no coinciden.'); setBusy(false); return; }
    try {
      const response = await apiRequest('/registrations', { method: 'POST', body: { user } });
      setMessage(response.data.message);
    } catch (failure) { setError(errorMessage(failure)); }
    finally { setBusy(false); }
  }
  return <section className="auth-card"><h1>Crear tu cuenta</h1>
    {message ? <><p role="status">{message}</p><Link to="/login">Ir a ingresar</Link></> :
      <form onSubmit={submit}>
        <label htmlFor="name">Nombre</label><input id="name" name="name" autoComplete="name" maxLength={100} required />
        <label htmlFor="email">Correo electrónico</label><input id="email" name="email" type="email" autoComplete="email" required />
        <label htmlFor="password">Contraseña</label><input id="password" name="password" type="password" autoComplete="new-password" minLength={12} maxLength={128} required aria-describedby="password-hint" />
        <small id="password-hint">Usá al menos 12 caracteres.</small>
        <label htmlFor="password_confirmation">Repetir contraseña</label><input id="password_confirmation" name="password_confirmation" type="password" autoComplete="new-password" minLength={12} maxLength={128} required />
        {error && <p role="alert">{error}</p>}
        <button className="primary" disabled={busy}>{busy ? 'Creando cuenta…' : 'Crear cuenta'}</button>
      </form>}
    <p>¿Ya tenés cuenta? <Link to="/login">Ingresar</Link></p>
  </section>;
}
