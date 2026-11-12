import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import useResource from '../../lib/useResource';
import { dateLabel, money } from '../../lib/reservations';

export default function MyReservations({ ownerView = false }) {
  const { boatId } = useParams();
  const [page, setPage] = useState(1);
  const path = ownerView ? '/me/boats/' + boatId + '/reservations' : '/me/reservations';
  const { data, meta, loading, error, reload } = useResource(path + '?page=' + page);
  return <section><h1>{ownerView ? 'Reservas de mi bote' : 'Mis reservas'}</h1>
    <Link to={ownerView ? '/my-boats' : '/boats'}>{ownerView ? '← Mis botes' : 'Explorar botes'}</Link>
    {loading && <p role="status">Cargando reservas…</p>}
    {error && <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button></div>}
    {data?.length === 0 && <p>{ownerView ? 'Este bote todavía no tiene reservas.' : 'Todavía no hiciste reservas.'}</p>}
    <div className="boat-grid">{data?.map(reservation => <article className="boat-card" key={reservation.id}>
      <h2>{reservation.boat.name}</h2><p>Reserva #{reservation.id} · {reservation.status === 'confirmed' ? 'Confirmada' : 'Cancelada'}</p>
      {ownerView && <p>Cliente: {reservation.customer.name}</p>}
      <p>{dateLabel(reservation.starts_on)} → {dateLabel(reservation.ends_on)} (fin no incluido)</p>
      <p>{reservation.days} días · {reservation.passengers} pasajeros · UTC−3</p>
      <p><strong>{money(reservation.total_cents, reservation.currency)}</strong></p>
      {!ownerView && <Link to={'/my-reservations/' + reservation.id}>Ver reserva</Link>}
    </article>)}</div>
    {meta && meta.total > meta.per_page && <nav aria-label="Paginación de reservas">
      <button disabled={page === 1} onClick={() => setPage(page - 1)}>Anterior</button><span>Página {page}</span>
      <button disabled={page * meta.per_page >= meta.total} onClick={() => setPage(page + 1)}>Siguiente</button>
    </nav>}
  </section>;
}
