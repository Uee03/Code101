type UserToken = { access_token: string; expired?: boolean };
let read: () => Promise<UserToken | null> = async () => null;
let refresh: () => Promise<UserToken | null> = async () => null;
let failed: () => Promise<void> = async () => {};
let flight: Promise<string> | undefined;
export function bindTokenGate(callbacks: { read: typeof read; refresh: typeof refresh; failed: typeof failed }) {
  read = callbacks.read; refresh = callbacks.refresh; failed = callbacks.failed;
}
export async function renew(): Promise<string> {
  if (!flight) {
    flight = refresh().then(user => {
      if (!user || user.expired) throw new Error('Please sign in again.');
      return user.access_token;
    }).catch(async error => { await failed(); throw error; }).finally(() => { flight = undefined; });
  }
  return flight;
}
export async function getAccessToken() {
  const user = await read();
  return user?.expired ? renew() : user?.access_token;
}
export async function endSession() { await failed(); }
