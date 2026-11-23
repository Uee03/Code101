import { useUiStore } from '../ui/ui-store';
import { useView } from '../ui/view-context';

function ViewToggle() {
  const { view, setView } = useView();
  console.log('render ViewToggle');
  return (
    <button type="button" onClick={() => setView(view === 'board' ? 'list' : 'board')}>
      Show {view === 'board' ? 'list' : 'board'}
    </button>
  );
}

function SearchBox() {
  const query = useUiStore((state) => state.query);
  const setQuery = useUiStore((state) => state.setQuery);
  console.log('render SearchBox');
  return (
    <label>
      Search <input value={query} onChange={(event) => setQuery(event.target.value)} />
    </label>
  );
}

function CompactToggle() {
  const compact = useUiStore((state) => state.compact);
  const toggleCompact = useUiStore((state) => state.toggleCompact);
  console.log('render CompactToggle');
  return (
    <label>
      <input type="checkbox" checked={compact} onChange={toggleCompact} /> Compact
      <span> (Compact mode is {compact ? 'on' : 'off'})</span>
    </label>
  );
}

export default function Toolbar() {
  return (
    <div className="toolbar">
      <ViewToggle />
      <SearchBox />
      <CompactToggle />
    </div>
  );
}
