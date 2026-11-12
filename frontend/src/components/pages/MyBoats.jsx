import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import useResource from '../../lib/useResource';
import { apiRequest, errorMessage } from '../../lib/api';

export default function MyBoats() {
  const [page, setPage] = useState(1);
  const { data, meta, loading, error, reload } = useResource('/me/boats?page=' + page);
  const location = useLocation();
  const [notice, setNotice] = useState(location.state?.message || '');
  const [actionError, setActionError] = useState('');
  const [busy, setBusy] = useState(null);
  async function toggle(boat) {
    setBusy(boat.id); setActionError(''); setNotice('');
    try {
      await apiRequest('/boats/' + boat.id + (boat.active ? '/deactivation' : '/activation'), { method: 'POST' });
      setNotice(boat.active ? 'Publicación desactivada. Conservamos sus datos.' : 'Publicación activada.');
      reload();
    } catch (failure) { setActionError(errorMessage(failure)); }
    finally { setBusy(null); }
  }
  return <section><h1>Mis botes</h1><Link to="/add-boat">Publicar un bote</Link>
    {notice && <p role="status">{notice}</p>}
    {loading && <p role="status">Cargando tus publicaciones…</p>}
    {(error || actionError) && <div><p role="alert">{error || actionError}</p><button onClick={reload}>Reintentar</button></div>}
    {data?.length === 0 && <p>Todavía no publicaste ningún bote.</p>}
    <div className="boat-grid">{data?.map(boat => <article className="boat-card" key={boat.id}><h2>{boat.name}</h2>
      <p>{boat.active ? 'Publicado' : 'Inactivo'} · {boat.port}</p>
      <Link to={'/my-boats/' + boat.id + '/edit'}>Editar</Link>
      {' · '}<Link to={'/my-boats/' + boat.id + '/reservations'}>Reservas</Link>
      <button disabled={busy !== null} onClick={() => toggle(boat)}>{busy === boat.id ? 'Guardando…' : boat.active ? 'Desactivar' : 'Activar'}</button>
    </article>)}</div>
    {meta && meta.total > meta.per_page && <nav aria-label="Paginación">
      <button disabled={page === 1} onClick={() => setPage(page - 1)}>Anterior</button>
      <span>Página {page}</span><button disabled={page * meta.per_page >= meta.total} onClick={() => setPage(page + 1)}>Siguiente</button>
    </nav>}
  </section>;
}
