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

export default function Toolbar() {
  return (
    <div className="toolbar">
      <ViewToggle />
      <SearchBox />
    </div>
  );
}
