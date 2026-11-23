import Panel from '../components/Panel';
import Counter from '../components/Counter';
import usePageTitle from '../hooks/usePageTitle';

export default function About() {
  usePageTitle('About - Reading list');
  return (
    <Panel title="About">
      <p>A small app that grows lesson by lesson.</p>
      <Counter />
    </Panel>
  );
}
