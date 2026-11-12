import { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { restoreSession, sessionExpired } from '../redux/usersession/usersessionsSlice';
import { setUnauthorizedHandler } from '../lib/api';

export default function SessionBoundary({ children }) {
  const dispatch = useDispatch();
  useEffect(() => {
    // Discard identities saved by the academic frontend; Rails is authoritative.
    localStorage.removeItem('user');
    setUnauthorizedHandler(() => dispatch(sessionExpired()));
    dispatch(restoreSession());
    const refresh = () => dispatch(restoreSession());
    window.addEventListener('focus', refresh);
    return () => { setUnauthorizedHandler(() => {}); window.removeEventListener('focus', refresh); };
  }, [dispatch]);
  return children;
}
