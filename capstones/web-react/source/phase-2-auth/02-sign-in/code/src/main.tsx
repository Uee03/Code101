import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from 'react-oidc-context';
import { RouterProvider } from 'react-router/dom';
import { manager, onSigninCallback } from './auth/user-manager';
import { router } from './router';
import './styles.css';
const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
manager.events.addUserUnloaded(() => queryClient.clear());
manager.events.addUserLoaded(() => { queryClient.clear(); });
createRoot(document.getElementById('root')!).render(
  <StrictMode><AuthProvider userManager={manager} onSigninCallback={onSigninCallback}>
    <QueryClientProvider client={queryClient}><RouterProvider router={router} /></QueryClientProvider>
  </AuthProvider></StrictMode>,
);
