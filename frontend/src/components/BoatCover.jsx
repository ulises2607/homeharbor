export default function BoatCover({ boat, eager = false }) {
  const photo = boat.photos?.[0];
  return <div className={'boat-visual' + (photo ? '' : ' illustrated tone-' + (Number(boat.id) % 3))}>
    <img className="boat-cover" src={photo?.url || '/illustrations/harbor.svg'} alt={photo ? boat.name : 'Ilustración náutica; este bote todavía no tiene fotos'} loading={eager ? 'eager' : 'lazy'} width="1000" height="650" />
    {!photo && <span className="image-caption">Ilustración · sin fotos</span>}
  </div>;
}
