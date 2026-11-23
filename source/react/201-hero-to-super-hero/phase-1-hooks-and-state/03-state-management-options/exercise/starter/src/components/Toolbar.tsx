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

// TODO 3: write CompactToggle: a checkbox labelled "Compact" that reads compact and toggleCompact from the store
// with two selectors, logs 'render CompactToggle', and shows the text "Compact mode is on" or "Compact mode is off".

export default function Toolbar() {
  return (
    <div className="toolbar">
      <ViewToggle />
      <SearchBox />
      {/* TODO 4: show <CompactToggle /> here. */}
    </div>
  );
}
