import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import { apiRequest, clearCsrfToken } from '../../lib/api';

export const restoreSession = createAsyncThunk('session/restore', async (_, { rejectWithValue }) => {
  try { return (await apiRequest('/session', { notifyUnauthorized: false })).data.user; }
  catch (error) {
    if (error.status === 401) return null;
    return rejectWithValue(error.message);
  }
}, { condition: (_, { getState }) => getState().usersession.status !== 'loading' });
export const login = createAsyncThunk('session/login', async (user, { rejectWithValue }) => {
  try { return (await apiRequest('/session', { method: 'POST', body: { user }, notifyUnauthorized: false })).data.user; }
  catch (error) { return rejectWithValue(error.message); }
});
export const logout = createAsyncThunk('session/logout', async (_, { rejectWithValue }) => {
  try {
    await apiRequest('/session', { method: 'DELETE' });
    clearCsrfToken();
  } catch (error) { return rejectWithValue(error.message); }
});
const slice = createSlice({
  name: 'usersession',
  initialState: { user: null, status: 'idle', error: null, restoreRequestId: null },
  reducers: {
    sessionExpired: (state) => { state.user = null; state.status = 'ready'; state.restoreRequestId = null; state.error = 'Tu sesión venció. Volvé a ingresar.'; },
  },
  extraReducers: (builder) => {
    builder.addCase(restoreSession.pending, (state, action) => { state.status = 'loading'; state.error = null; state.restoreRequestId = action.meta.requestId; });
    builder.addCase(restoreSession.fulfilled, (state, action) => {
      if (state.restoreRequestId !== action.meta.requestId) return;
      state.user = action.payload; state.status = 'ready'; state.restoreRequestId = null;
    });
    builder.addCase(restoreSession.rejected, (state, action) => {
      if (state.restoreRequestId !== action.meta.requestId) return;
      state.status = 'error'; state.error = action.payload || action.error.message; state.restoreRequestId = null;
    });
    builder.addCase(login.pending, (state) => { state.restoreRequestId = null; state.status = 'ready'; });
    builder.addCase(login.fulfilled, (state, action) => { state.user = action.payload; state.status = 'ready'; state.error = null; });
    builder.addCase(logout.fulfilled, (state) => { state.user = null; state.status = 'ready'; state.error = null; state.restoreRequestId = null; });
  },
});
export const { sessionExpired } = slice.actions;
export const selectUser = state => state.usersession.user;
export default slice.reducer;
