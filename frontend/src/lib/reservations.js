export const money = (cents, currency = 'USD') => (cents / 100).toFixed(2) + ' ' + currency;
export const dateLabel = value => new Intl.DateTimeFormat('es-AR', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' }).format(new Date(value + 'T00:00:00Z'));
export const deadlineLabel = value => new Intl.DateTimeFormat('es-AR', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Etc/GMT+3', hourCycle: 'h23' }).format(new Date(value)) + ' UTC−3';
export function tomorrow() {
  return new Date(Date.now() - 3 * 3600000 + 86400000).toISOString().slice(0, 10);
}

const pendingKey = (userId, boatId) => 'homeharbor:pending-reservation:' + userId + ':' + boatId;
export function readPending(userId, boatId) {
  if (!userId) return null;
  try {
    const value = JSON.parse(sessionStorage.getItem(pendingKey(userId, boatId)));
    return typeof value?.key === 'string' && value.payload?.boat_id === boatId ? value : null;
  } catch { return null; }
}
export function savePending(userId, boatId, value) {
  try {
    if (value) sessionStorage.setItem(pendingKey(userId, boatId), JSON.stringify(value));
    else sessionStorage.removeItem(pendingKey(userId, boatId));
  } catch { /* An in-memory retry still works if browser storage is unavailable. */ }
}
