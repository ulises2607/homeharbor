import { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { login } from '../../redux/usersession/usersessionsSlice';

export default function Login() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const location = useLocation();
  const sessionError = useSelector(state => state.usersession.error);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  async function submit(event) {
    event.preventDefault(); setError(''); setBusy(true);
    const form = new FormData(event.currentTarget);
    try {
      await dispatch(login({ email: form.get('email'), password: form.get('password') })).unwrap();
      const from = location.state?.from;
      navigate(typeof from === 'string' && from.startsWith('/') && !from.startsWith('//') ? from : '/my-boats', { replace: true });
    } catch (failure) { setError(typeof failure === 'string' ? failure : 'No pudimos ingresar. Intentá de nuevo.'); }
    finally { setBusy(false); }
  }
  return <section className="auth-card"><h1>Ingresar a Homeharbor</h1>
    <p>Tu próximo día en el agua empieza acá.</p>
    <form onSubmit={submit}>
      <label htmlFor="email">Correo electrónico</label><input id="email" name="email" type="email" autoComplete="email" required />
      <label htmlFor="password">Contraseña</label><input id="password" name="password" type="password" autoComplete="current-password" required />
      {(error || sessionError) && <p role="alert">{error || sessionError}</p>}
      <button className="primary" disabled={busy}>{busy ? 'Ingresando…' : 'Ingresar'}</button>
    </form>
    <Link to="/forgot-password">Olvidé mi contraseña</Link>
    <Link to="/resend-confirmation">Reenviar confirmación</Link>
    <p>¿Todavía no tenés cuenta? <Link to="/signup">Crear cuenta</Link></p>
  </section>;
}
