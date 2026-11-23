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
      <button type="button" onClick={toggle} aria-expanded={open}>
        {open ? 'Hide details' : 'Show details'}
      </button>
      {open && <p>Built with React, TypeScript and Vite.</p>}
      <Counter />
    </Panel>
  );
}
