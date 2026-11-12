import { BrowserRouter, Routes, Route, Navigate, Link } from 'react-router-dom';
import Layout from './components/Layout';
import SessionBoundary from './components/SessionBoundary';
import RequireSession from './components/RequireSession';
import Boats from './components/pages/Boats';
import BoatDetails from './components/pages/BoatDetails';
import Login from './components/pages/Login';
import Signup from './components/pages/Signup';
import AccountRecovery from './components/pages/AccountRecovery';
import AddBoat from './components/pages/AddBoat';
import MyBoats from './components/pages/MyBoats';
import EditBoat from './components/pages/EditBoat';
import MyReservations from './components/pages/MyReservations';
import ReservationDetails from './components/pages/ReservationDetails';

export default function App() {
  return <BrowserRouter><SessionBoundary><Routes><Route path="/" element={<Layout />}>
    <Route index element={<Navigate to="/boats" replace />} />
    <Route path="boats" element={<Boats />} /><Route path="boats/:id" element={<BoatDetails />} />
    <Route path="login" element={<Login />} /><Route path="signup" element={<Signup />} />
    <Route path="confirm-email" element={<AccountRecovery key="confirm" mode="confirm" />} />
    <Route path="resend-confirmation" element={<AccountRecovery key="resend" mode="resend" />} />
    <Route path="forgot-password" element={<AccountRecovery key="forgot" mode="forgot" />} />
    <Route path="reset-password" element={<AccountRecovery key="reset" mode="reset" />} />
    <Route element={<RequireSession />}>
      <Route path="add-boat" element={<AddBoat />} /><Route path="my-boats" element={<MyBoats />} />
      <Route path="my-boats/:id/edit" element={<EditBoat />} />
      <Route path="delete-boat" element={<Navigate to="/my-boats" replace />} />
      <Route path="reserve" element={<Navigate to="/boats" replace />} />
      <Route path="my-reservations" element={<MyReservations />} />
      <Route path="my-reservations/:id" element={<ReservationDetails />} />
      <Route path="my-boats/:boatId/reservations" element={<MyReservations ownerView />} />
    </Route>
    <Route path="*" element={<section><h1>Página no encontrada</h1><Link to="/boats">Volver al catálogo</Link></section>} />
  </Route></Routes></SessionBoundary></BrowserRouter>;
}
