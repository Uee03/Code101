import { UserManager, type User } from 'oidc-client-ts';
import { oidcSettings } from './oidc-config';
import { bindTokenGate, renew } from './token-gate';
import { safeRoute } from './safe-route';
export const manager = new UserManager(oidcSettings(window.location.origin, window.sessionStorage).settings);
export let callbackReturn = '/';
export function onSigninCallback(user?: User) {
  callbackReturn = safeRoute((user?.state as { returnTo?: string } | undefined)?.returnTo);
  localStorage.setItem('ts.hint', '1');
  history.replaceState({}, document.title, callbackReturn);
}
bindTokenGate({
  read: () => manager.getUser(), refresh: () => manager.signinSilent(),
  failed: async () => {
    await manager.removeUser(); localStorage.removeItem('ts.hint');
    const returnTo = safeRoute(location.pathname + location.search);
    history.replaceState({}, '', `/login?returnUrl=${encodeURIComponent(returnTo)}`);
    window.dispatchEvent(new PopStateEvent('popstate'));
  },
});
manager.events.addAccessTokenExpiring(() => { void renew().catch(() => {}); });
export async function signOut() {
  const user = await manager.getUser();
  await manager.removeUser(); localStorage.removeItem('ts.hint'); sessionStorage.removeItem('ts.stepup');
  await manager.signoutRedirect({ id_token_hint: user?.id_token });
}
