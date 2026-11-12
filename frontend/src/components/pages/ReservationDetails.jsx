import { useState } from 'react';
import { Link, useLocation, useParams } from 'react-router-dom';
import useResource from '../../lib/useResource';
import { apiRequest, errorMessage } from '../../lib/api';
import { dateLabel, deadlineLabel, money } from '../../lib/reservations';

export default function ReservationDetails() {
  const { id } = useParams();
  const { state } = useLocation();
  const { data, loading, error, reload } = useResource('/me/reservations/' + id);
  const [notice, setNotice] = useState(state?.message || '');
  const [failure, setFailure] = useState('');
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);
  async function cancel() {
    if (busy) return;
    setBusy(true); setFailure(''); setNotice('');
    try {
      await apiRequest('/me/reservations/' + id + '/cancellation', { method: 'POST' });
      setConfirming(false); setNotice('Reserva cancelada. Las fechas volvieron a quedar disponibles.'); reload();
    } catch (err) { setFailure(errorMessage(err)); }
    finally { setBusy(false); }
  }
  if (loading) return <p role="status">Cargando reserva…</p>;
  if (error) return <div><p role="alert">{error}</p><button onClick={reload}>Reintentar</button><Link to="/my-reservations">Volver a Mis reservas</Link></div>;
  return <article><Link to="/my-reservations">← Mis reservas</Link><h1>Reserva #{data.id}</h1>
    {notice && <p role="status">{notice}</p>}{failure && <p role="alert">{failure}</p>}
    <h2>{data.boat.name}</h2><p>{data.status === 'confirmed' ? 'Confirmada' : 'Cancelada'} · {data.boat.port}</p>
    <dl><dt>Primer día de uso</dt><dd>{dateLabel(data.starts_on)} · 00:00 UTC−3</dd>
      <dt>Disponible nuevamente desde</dt><dd>{dateLabel(data.ends_on)} · 00:00 UTC−3 (no incluido)</dd>
      <dt>Duración y pasajeros</dt><dd>{data.days} días · {data.passengers} personas</dd>
      <dt>Tarifa acordada</dt><dd>{money(data.daily_rate_cents, data.currency)} / día</dd>
      <dt>Total acordado</dt><dd>{money(data.total_cents, data.currency)}</dd>
      <dt>Límite de cancelación</dt><dd>{deadlineLabel(data.cancellation_deadline)}, inclusive</dd></dl>
    <p>Esta reserva no incluye un cobro en la plataforma.</p>
    {!data.boat.active && <p className="notice">La publicación está inactiva. Tu reserva y su historial se conservan.</p>}
    {data.status === 'confirmed' && (data.can_cancel ? <div className="reservation-actions">
      {confirming ? <><p>¿Querés cancelar esta reserva? Se liberarán sus fechas y conservaremos el historial.</p>
        <button disabled={busy} onClick={cancel}>{busy ? 'Cancelando…' : 'Confirmar cancelación'}</button>
        <button disabled={busy} onClick={() => setConfirming(false)}>Conservar reserva</button></>
        : <button onClick={() => { setConfirming(true); setNotice(''); }}>Cancelar reserva</button>}
    </div> : <p>El plazo de cancelación terminó.</p>)}
  </article>;
}
