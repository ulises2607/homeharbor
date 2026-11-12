import { useState } from 'react';
import { useDispatch } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { logout } from '../redux/usersession/usersessionsSlice';

export default function Logout() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const dispatch = useDispatch();
  const navigate = useNavigate();
  async function submit() {
    setBusy(true); setError('');
    try { await dispatch(logout()).unwrap(); navigate('/login'); }
    catch (failure) { setError(typeof failure === 'string' ? failure : 'No pudimos cerrar la sesión. Intentá de nuevo.'); }
    finally { setBusy(false); }
  }
  return <span><button type="button" disabled={busy} onClick={submit}>{busy ? 'Cerrando…' : 'Cerrar sesión'}</button>{error && <span role="alert">{error}</span>}</span>;
}
