import { useEffect, useRef } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Header from './Header';
export default function Layout() {
  const main = useRef(null);
  const { pathname } = useLocation();
  useEffect(() => { main.current?.focus({ preventScroll: true }); }, [pathname]);
  return <><a className="skip-link" href="#main-content">Saltar al contenido</a><Header />
    <main id="main-content" className="page" ref={main} tabIndex={-1}><Outlet /></main>
    <footer><strong>Homeharbor</strong><span>Un puerto para tu próxima aventura.</span><small>Evolución de Reserve Boats / Microverse · Proyecto de portfolio</small></footer></>;
}
