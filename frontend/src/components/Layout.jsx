import { Outlet } from 'react-router-dom';
import Header from './Header';
export default function Layout() {
  return <><Header /><main className="page"><Outlet /></main>
    <footer>Homeharbor · Evolución de Reserve Boats / Microverse</footer></>;
}
