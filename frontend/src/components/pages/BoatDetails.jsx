import { Link, useParams } from 'react-router-dom';
import useResource from '../../lib/useResource';

export default function BoatDetails() {
  const { id } = useParams();
  const { data: boat, loading, error, reload } = useResource('/boats/' + id);
  if (loading) return <p role="status">Cargando bote…</p>;
  if (error) return <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button><Link to="/boats">Volver al catálogo</Link></div>;
  return <article><Link to="/boats">← Explorar botes</Link><h1>{boat.name}</h1>
    {boat.photos?.length > 0 && <div className="photo-gallery">{boat.photos.map((photo, index) => <img key={photo.id} src={photo.url} alt={boat.name + ' · foto ' + (index + 1)} loading={index === 0 ? 'eager' : 'lazy'} />)}</div>}
    <p>{boat.description}</p><dl><dt>Puerto</dt><dd>{boat.port}</dd>
      <dt>Capacidad</dt><dd>{boat.capacity} personas</dd><dt>Tarifa diaria</dt><dd>{(boat.daily_rate_cents / 100).toFixed(2)} {boat.currency}</dd>
      <dt>Zona horaria</dt><dd>UTC−3</dd></dl>
    <p className="notice">Las reservas estarán disponibles próximamente.</p>
  </article>;
}
