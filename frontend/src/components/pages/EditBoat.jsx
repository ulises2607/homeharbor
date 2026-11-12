import { useParams } from 'react-router-dom';
import BoatForm from './BoatForm';
import useResource from '../../lib/useResource';
export default function EditBoat() {
  const { id } = useParams();
  const { data, loading, error, reload } = useResource('/me/boats/' + id);
  if (loading) return <p role="status">Cargando publicación…</p>;
  if (error) return <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button></div>;
  return <section><h1>Editar bote</h1><BoatForm boat={data} /></section>;
}
