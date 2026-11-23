import { createBrowserRouter } from 'react-router';
import Shell from './Shell';
import Help from './pages/Help';
import NotFound from './pages/NotFound';
import Tasks from './pages/Tasks';

export const router = createBrowserRouter([
  {
    element: <Shell />,
    children: [
      { index: true, element: <Tasks /> },
      { path: 'help', element: <Help /> },
      { path: '*', element: <NotFound /> },
    ],
  },
]);
