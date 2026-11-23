import Board from './components/Board';
import Toast from './components/Toast';
import Toolbar from './components/Toolbar';
import { ViewProvider } from './ui/view-context';

export default function App() {
  return (
    <ViewProvider>
      <main>
        <h1>State lab</h1>
        <Toolbar />
        <Toast />
        <Board />
      </main>
    </ViewProvider>
  );
}
