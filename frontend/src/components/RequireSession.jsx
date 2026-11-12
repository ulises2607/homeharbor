import { useDispatch, useSelector } from 'react-redux';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { restoreSession } from '../redux/usersession/usersessionsSlice';

export default function RequireSession() {
  const { user, status, error } = useSelector(state => state.usersession);
  const dispatch = useDispatch();
  const location = useLocation();
  if (status === 'idle' || status === 'loading') return <p role="status">Comprobando sesión…</p>;
  if (status === 'error') return <div><p role="alert">{error}</p><button onClick={() => dispatch(restoreSession())}>Reintentar</button></div>;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  return <Outlet />;
}
