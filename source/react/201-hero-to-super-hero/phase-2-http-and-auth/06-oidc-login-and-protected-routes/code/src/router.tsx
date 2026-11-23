import { createBrowserRouter } from 'react-router';
import RequireAuth from './auth/RequireAuth';
import Shell from './Shell';
import Callback from './pages/Callback';
import Home from './pages/Home';
import Login from './pages/Login';
import NotFound from './pages/NotFound';

export const router = createBrowserRouter([
  {
    element: <Shell />,
    children: [
      { path: '/login', element: <Login /> },
      { path: '/auth/callback', element: <Callback /> },
      { element: <RequireAuth />, children: [{ index: true, element: <Home /> }] },
      { path: '*', element: <NotFound /> },
    ],
  },
]);
