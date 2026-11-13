import { Link, useParams } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { selectUser } from '../../redux/usersession/usersessionsSlice';
import ReservationForm from './ReservationForm';
import useResource from '../../lib/useResource';
import BoatCover from '../BoatCover';

export default function BoatDetails() {
  const { id } = useParams();
  const user = useSelector(selectUser);
  const { data: boat, loading, error, reload } = useResource('/boats/' + id);
  if (loading) return <p role="status">Cargando bote…</p>;
  if (error) return <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button><Link to="/boats">Volver al catálogo</Link></div>;
  return <article><Link to="/boats">← Explorar botes</Link><p className="eyebrow detail-eyebrow">{boat.port} · Bote completo</p><h1>{boat.name}</h1>
    <div className="boat-detail"><div className="boat-overview">
    {!boat.photos?.length && <BoatCover boat={boat} eager />}
    {boat.photos?.length > 0 && <div className="photo-gallery">{boat.photos.map((photo, index) => <img key={photo.id} src={photo.url} alt={boat.name + ' · foto ' + (index + 1)} loading={index === 0 ? 'eager' : 'lazy'} />)}</div>}
    <p>{boat.description}</p><dl className="facts-grid"><div><dt>Puerto</dt><dd>{boat.port}</dd></div>
      <div><dt>Capacidad</dt><dd>{boat.capacity} personas</dd></div><div><dt>Tarifa diaria</dt><dd>{(boat.daily_rate_cents / 100).toFixed(2)} {boat.currency}</dd></div>
      <div><dt>Zona horaria</dt><dd>UTC−3</dd></div></dl></div>
    <ReservationForm boat={boat} user={user} key={boat.id + ':' + (user?.id || 'guest')} />
    </div>
  </article>;
}
