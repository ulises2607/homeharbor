import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiRequest, errorMessage } from '../../lib/api';

export default function BoatForm({ boat }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  async function submit(event) {
    event.preventDefault(); setBusy(true); setError('');
    const values = Object.fromEntries(new FormData(event.currentTarget));
    const payload = { ...values, capacity: Number(values.capacity), daily_rate_cents: Math.round(Number(values.daily_rate) * 100), currency: 'USD', time_zone: 'Etc/GMT+3' };
    delete payload.daily_rate;
    try {
      const result = await apiRequest(boat ? '/boats/' + boat.id : '/boats', { method: boat ? 'PATCH' : 'POST', body: { boat: payload } });
      navigate(boat ? '/my-boats' : '/my-boats/' + result.data.id + '/edit', { state: { message: boat ? 'Cambios guardados.' : 'Bote publicado. Ya podés agregar fotos.' } });
    } catch (failure) { setError(errorMessage(failure)); }
    finally { setBusy(false); }
  }
  return <form onSubmit={submit} className="auth-card">
    <label htmlFor="name">Nombre del bote</label><input id="name" name="name" defaultValue={boat?.name} required maxLength={150} />
    <label htmlFor="description">Descripción</label><textarea id="description" name="description" defaultValue={boat?.description} required maxLength={5000} />
    <label htmlFor="port">Puerto</label><input id="port" name="port" defaultValue={boat?.port} required maxLength={150} />
    <label htmlFor="capacity">Capacidad de personas</label><input id="capacity" name="capacity" type="number" min="1" max="500" step="1" defaultValue={boat?.capacity} required />
    <label htmlFor="daily_rate">Tarifa por día (USD)</label><input id="daily_rate" name="daily_rate" type="number" min="0.01" max="1000000" step="0.01" defaultValue={boat ? (boat.daily_rate_cents / 100).toFixed(2) : undefined} required />
    <p>Tarifas en dólares estadounidenses. Zona horaria UTC−3.</p>
    {error && <p role="alert">{error}</p>}
    <button className="primary" disabled={busy}>{busy ? 'Guardando…' : boat ? 'Guardar cambios' : 'Publicar bote'}</button>
  </form>;
}
