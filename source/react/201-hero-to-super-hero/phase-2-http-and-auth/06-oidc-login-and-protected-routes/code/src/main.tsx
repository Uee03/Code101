import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from 'react-oidc-context';
import { RouterProvider } from 'react-router/dom';
import { ApiProblem } from './api/problem';
import { manager, onSigninCallback } from './auth/user-manager';
import { router } from './router';
import './styles.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (count, error) => count < 2 && (!(error instanceof ApiProblem) || error.status >= 500),
    },
    mutations: { retry: false },
  },
});

// A different user must never see the previous user's cached data.
manager.events.addUserUnloaded(() => queryClient.clear());
manager.events.addUserLoaded(() => queryClient.clear());

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider userManager={manager} onSigninCallback={onSigninCallback}>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </AuthProvider>
  </StrictMode>,
);
