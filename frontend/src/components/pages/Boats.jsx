import { Link, useSearchParams } from 'react-router-dom';
import useResource from '../../lib/useResource';

export default function Boats() {
  const [params, setParams] = useSearchParams();
  const page = Number(params.get('page') || 1);
  const hasFilters = Boolean(params.get('port') || params.get('min_capacity'));
  const { data, meta, loading, error, reload } = useResource('/boats?' + params.toString());
  function filter(event) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    const next = new URLSearchParams();
    for (const key of ['port', 'min_capacity']) {
      const value = values.get(key).trim();
      if (value) next.set(key, value);
    }
    setParams(next);
  }
  function setPage(nextPage) {
    const next = new URLSearchParams(params);
    next.set('page', String(nextPage));
    setParams(next);
  }
  return <section><p className="eyebrow">Encontrá tu próxima salida</p><h1>Explorar botes</h1>
    <p>Conocé los botes de nuestra comunidad y sus tarifas por día.</p>
    <form className="catalog-filters" onSubmit={filter} key={params.toString()} aria-label="Filtrar botes">
      <div><label htmlFor="filter-port">Puerto</label><input id="filter-port" name="port" maxLength={150} defaultValue={params.get('port') || ''} placeholder="Por ejemplo, Tigre" /></div>
      <div><label htmlFor="filter-capacity">Personas</label><input id="filter-capacity" name="min_capacity" type="number" min="1" max="500" step="1" defaultValue={params.get('min_capacity') || ''} placeholder="Capacidad mínima" /></div>
      <button type="submit">Buscar botes</button><button type="button" onClick={() => setParams({})}>Limpiar filtros</button>
    </form>
    {loading && <p role="status">Cargando botes…</p>}
    {error && <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button></div>}
    {data?.length === 0 && <p>{hasFilters ? 'No encontramos botes con esos filtros.' : page > 1 ? 'No hay botes en esta página.' : <>Todavía no hay botes publicados. <Link to="/add-boat">Publicá el primero</Link>.</>}</p>}
    <div className="boat-grid">{data?.map(boat => <article className="boat-card" key={boat.id}>
      {boat.photos?.[0] ? <img className="boat-cover" src={boat.photos[0].url} alt={boat.name} loading="lazy" /> : <span className="boat-mark" aria-hidden="true">⛵</span>}<h2><Link to={'/boats/' + boat.id}>{boat.name}</Link></h2>
      <p>{boat.port} · Hasta {boat.capacity} personas</p><p>{boat.description}</p>
      <strong>{(boat.daily_rate_cents / 100).toFixed(2)} {boat.currency} / día</strong>
    </article>)}</div>
    {meta && meta.total > meta.per_page && <nav aria-label="Paginación">
      <button disabled={page === 1} onClick={() => setPage(page - 1)}>Anterior</button>
      <span>Página {page}</span><button disabled={page * meta.per_page >= meta.total} onClick={() => setPage(page + 1)}>Siguiente</button>
    </nav>}
  </section>;
}
