import { useState } from 'react';
import { Link } from 'react-router-dom';
import useResource from '../../lib/useResource';

export default function Boats() {
  const [page, setPage] = useState(1);
  const { data, meta, loading, error, reload } = useResource('/boats?page=' + page);
  return <section><p className="eyebrow">Encontrá tu próxima salida</p><h1>Explorar botes</h1>
    <p>Conocé los botes de nuestra comunidad y sus tarifas por día.</p>
    {loading && <p role="status">Cargando botes…</p>}
    {error && <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button></div>}
    {data?.length === 0 && <p>Todavía no hay botes publicados. <Link to="/add-boat">Publicá el primero</Link>.</p>}
    <div className="boat-grid">{data?.map(boat => <article className="boat-card" key={boat.id}>
      <span className="boat-mark" aria-hidden="true">⛵</span><h2><Link to={'/boats/' + boat.id}>{boat.name}</Link></h2>
      <p>{boat.port} · Hasta {boat.capacity} personas</p><p>{boat.description}</p>
      <strong>{(boat.daily_rate_cents / 100).toFixed(2)} {boat.currency} / día</strong>
    </article>)}</div>
    {meta && meta.total > meta.per_page && <nav aria-label="Paginación">
      <button disabled={page === 1} onClick={() => setPage(page - 1)}>Anterior</button>
      <span>Página {page}</span><button disabled={page * meta.per_page >= meta.total} onClick={() => setPage(page + 1)}>Siguiente</button>
    </nav>}
  </section>;
}
