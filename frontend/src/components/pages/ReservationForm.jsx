import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { apiRequest, errorMessage } from '../../lib/api';
import { dateLabel, money, readPending, savePending, tomorrow } from '../../lib/reservations';

export default function ReservationForm({ boat, user }) {
  const [search] = useSearchParams();
  const [pending, setPending] = useState(() => readPending(user?.id, boat.id));
  const [values, setValues] = useState(() => ({
    starts_on: pending?.payload.starts_on || search.get('starts_on') || '',
    ends_on: pending?.payload.ends_on || search.get('ends_on') || '',
    passengers: String(pending?.payload.passengers || search.get('passengers') || 1),
  }));
  const [quote, setQuote] = useState(null);
  const [busy, setBusy] = useState('');
  const [error, setError] = useState('');
  const active = useRef(false);
  const request = useRef(null);
  const sending = useRef(false);
  const navigate = useNavigate();
  useEffect(() => {
    active.current = true;
    return () => { active.current = false; request.current?.abort(); };
  }, []);

  function change(event) {
    setValues(current => ({ ...current, [event.target.name]: event.target.value }));
    setQuote(null); setError('');
  }
  async function check(event) {
    event.preventDefault();
    if (sending.current) return;
    sending.current = true; setBusy('quote'); setError(''); setQuote(null);
    request.current?.abort();
    const controller = new AbortController();
    request.current = controller;
    try {
      const result = await apiRequest('/boats/' + boat.id + '/availability?' + new URLSearchParams(values), { signal: controller.signal });
      if (active.current && !controller.signal.aborted) setQuote(result.data);
    } catch (failure) {
      if (active.current && !controller.signal.aborted) setError(errorMessage(failure));
    } finally {
      sending.current = false;
      if (active.current) setBusy('');
    }
  }
  async function confirm() {
    if (sending.current || !user || (!pending && !quote?.available)) return;
    const operation = pending || { key: crypto.randomUUID(), payload: {
      boat_id: boat.id, ...values, passengers: Number(values.passengers),
      expected_total_cents: quote.total_cents, expected_currency: quote.currency,
    } };
    // Persist before sending: a reload or lost response can replay the same operation.
    savePending(user.id, boat.id, operation); setPending(operation);
    sending.current = true; setBusy('book'); setError('');
    try {
      const result = await apiRequest('/reservations', { method: 'POST', body: { reservation: operation.payload }, idempotencyKey: operation.key });
      savePending(user.id, boat.id, null);
      if (active.current) navigate('/my-reservations/' + result.data.id, { state: { message: result.data.status === 'confirmed' ? 'Reserva confirmada.' : 'La reserva ya estaba cancelada.' } });
    } catch (failure) {
      if (active.current) {
        // A 5xx or network failure can arrive after commit: keep the key and payload.
        if (failure.status >= 400 && failure.status < 500 && failure.status !== 401 && failure.code !== 'invalid_csrf') {
          savePending(user.id, boat.id, null); setPending(null); setQuote(null);
          setError(errorMessage(failure));
        } else {
          setError('No pudimos confirmar el resultado. Reintentá la misma operación o revisá Mis reservas.');
        }
      }
    } finally {
      sending.current = false;
      if (active.current) setBusy('');
    }
  }

  const returnTo = '/boats/' + boat.id + '?' + new URLSearchParams(values);
  return <section className="reservation-panel" aria-labelledby="reserve-title">
    <h2 id="reserve-title">Reservar este bote</h2>
    <p>Uso por días completos, desde las 00:00 UTC−3. La fecha final queda libre: del 10 al 12 incluye los días 10 y 11.</p>
    <form onSubmit={check} className="reservation-fields">
      <div><label htmlFor="starts_on">Primer día de uso</label><input id="starts_on" name="starts_on" type="date" min={tomorrow()} required value={values.starts_on} onChange={change} disabled={Boolean(busy || pending)} /></div>
      <div><label htmlFor="ends_on">Disponible nuevamente desde</label><input id="ends_on" name="ends_on" type="date" min={values.starts_on || tomorrow()} required value={values.ends_on} onChange={change} disabled={Boolean(busy || pending)} /></div>
      <div><label htmlFor="passengers">Pasajeros</label><input id="passengers" name="passengers" type="number" min="1" max={boat.capacity} step="1" required value={values.passengers} onChange={change} disabled={Boolean(busy || pending)} /></div>
      {!pending && <button disabled={Boolean(busy)}>{busy === 'quote' ? 'Consultando…' : 'Consultar disponibilidad'}</button>}
    </form>
    {error && <p role="alert">{error}</p>}
    {quote && <div aria-live="polite">
      <p>{quote.days} {quote.days === 1 ? 'día' : 'días'} de uso · {money(quote.daily_rate_cents, quote.currency)} por día.</p>
      <p><strong>Total: {money(quote.total_cents, quote.currency)}</strong></p>
      {!quote.available && <><p role="status">Hay fechas ocupadas. Probá otro intervalo.</p>
        <ul>{quote.occupied_intervals.map((interval, index) => <li key={index}>{dateLabel(interval.starts_on)} → {dateLabel(interval.ends_on)} (fin no incluido)</li>)}</ul>
        {quote.more_occupied_intervals && <p>Hay más períodos ocupados. Consultá un intervalo más corto.</p>}</>}
    </div>}
    {(quote?.available || pending) && <>
      {pending && <p className="notice">Hay una operación pendiente de verificar por {money(pending.payload.expected_total_cents, pending.payload.expected_currency)}. Reintentar recupera la misma reserva.</p>}
      <p>Confirmación automática, sin pagos en esta versión. Podés cancelar hasta 24 horas antes del inicio, inclusive.</p>
      {user ? <button className="primary" type="button" onClick={confirm} disabled={Boolean(busy)}>{busy === 'book' ? 'Confirmando…' : pending ? 'Verificar confirmación' : 'Confirmar reserva'}</button>
        : <Link to="/login" state={{ from: returnTo }}>Ingresar para reservar</Link>}
      {pending && <p><Link to="/my-reservations">Revisar Mis reservas</Link></p>}
    </>}
  </section>;
}
