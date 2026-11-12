import { useState } from 'react';
import { apiRequest, errorMessage } from '../../lib/api';

export default function BoatPhotos({ boat }) {
  const [photos, setPhotos] = useState(boat.photos || []);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  async function upload(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const file = form.elements.photo.files[0];
    setError(''); setMessage('');
    if (!file?.size || file.size > 5 * 1024 * 1024 || !['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      setError('Elegí una imagen JPEG, PNG o WebP de hasta 5 MB.'); return;
    }
    setBusy(true);
    try {
      const body = new FormData();
      body.append('photo', file);
      const result = await apiRequest('/boats/' + boat.id + '/photos', { method: 'POST', body });
      setPhotos(result.data.photos); form.elements.photo.value = ''; setMessage('Foto agregada.');
    } catch (failure) { setError(errorMessage(failure)); }
    finally { setBusy(false); }
  }

  async function remove(photo) {
    setBusy(true); setError(''); setMessage('');
    try {
      await apiRequest('/boats/' + boat.id + '/photos/' + photo.id, { method: 'DELETE' });
      setPhotos(current => current.filter(item => item.id !== photo.id)); setMessage('Foto eliminada.');
    } catch (failure) { setError(errorMessage(failure)); }
    finally { setBusy(false); }
  }

  return <section aria-labelledby="photos-title" className="photo-manager">
    <h2 id="photos-title">Fotos del bote</h2>
    <p>Hasta 5 fotos JPEG, PNG o WebP de 5 MB cada una. La primera aparece en el catálogo.</p>
    <p>{photos.length} de 5 fotos</p>
    <div className="photo-gallery">{photos.map((photo, index) => <figure key={photo.id}>
      <img src={photo.url} alt={boat.name + ' · foto ' + (index + 1)} loading="lazy" />
      <button type="button" disabled={busy} onClick={() => remove(photo)}>Eliminar foto {index + 1}</button>
    </figure>)}</div>
    <form onSubmit={upload}>
      <label htmlFor="photo">Agregar foto</label>
      <input id="photo" name="photo" type="file" accept="image/jpeg,image/png,image/webp" required disabled={busy || photos.length >= 5} aria-describedby="photos-title" />
      <button type="submit" disabled={busy || photos.length >= 5}>{busy ? 'Procesando…' : 'Subir foto'}</button>
    </form>
    {message && <p role="status">{message}</p>}{error && <p role="alert">{error}</p>}
  </section>;
}
