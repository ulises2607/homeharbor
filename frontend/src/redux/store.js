import { configureStore } from '@reduxjs/toolkit';
import usersession from './usersession/usersessionsSlice';
export const makeStore = () => configureStore({ reducer: { usersession } });
export default makeStore();
