import Panel from '../components/Panel';
import Counter from '../components/Counter';

export default function About() {
  return (
    <Panel title="About">
      <p>A small app that grows lesson by lesson.</p>
      <Counter />
    </Panel>
  );
}
