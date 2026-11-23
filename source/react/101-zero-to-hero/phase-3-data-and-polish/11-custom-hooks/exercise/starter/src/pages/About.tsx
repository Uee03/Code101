import Panel from '../components/Panel';
import Counter from '../components/Counter';
import usePageTitle from '../hooks/usePageTitle';
import useToggle from '../hooks/useToggle';

export default function About() {
  usePageTitle('About - Reading list');
  const [open, toggle] = useToggle(false);
  return (
    <Panel title="About">
      <p>A small app that grows lesson by lesson.</p>
      {/* TODO 2: a button that calls toggle; its text is "Show details" when closed and "Hide details" when open. */}
      {open && <p>Built with React, TypeScript and Vite.</p>}
      <Counter />
    </Panel>
  );
}
