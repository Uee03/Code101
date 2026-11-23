import ApiStatus from './components/ApiStatus';
import CrashDemo from './components/CrashDemo';
import Playground from './components/Playground';
import AppErrorBoundary from './shared/AppErrorBoundary';

export default function App() {
  return (
    <main>
      <h1>Error lab</h1>
      <AppErrorBoundary>
        <ApiStatus />
        <Playground />
        <CrashDemo />
      </AppErrorBoundary>
    </main>
  );
}
