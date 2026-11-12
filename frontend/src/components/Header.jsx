import { NavLink } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { selectUser } from '../redux/usersession/usersessionsSlice';
import Logout from './Logout';
import boatLogo from '../Assets/Images/logo/boat-logo-3.png';

export default function Header() {
  const user = useSelector(selectUser);
  return <header className="site-header">
    <NavLink to="/boats" className="brand"><img src={boatLogo} alt="" /><span>Homeharbor</span></NavLink>
    <nav aria-label="Navegación principal">
      <NavLink to="/boats">Explorar botes</NavLink>
      {user ? <>
        <NavLink to="/my-reservations">Mis reservas</NavLink>
        <NavLink to="/my-boats">Mis botes</NavLink>
        <NavLink to="/add-boat">Publicar bote</NavLink>
        <span>Hola, {user.name}</span><Logout />
      </> : <><NavLink to="/login">Ingresar</NavLink><NavLink to="/signup">Crear cuenta</NavLink></>}
    </nav>
  </header>;
}
