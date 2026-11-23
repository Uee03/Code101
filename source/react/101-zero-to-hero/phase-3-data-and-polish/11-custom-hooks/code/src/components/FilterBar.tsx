type FilterBarProps = {
  unreadOnly: boolean;
  onChange: (value: boolean) => void;
};

export default function FilterBar({ unreadOnly, onChange }: FilterBarProps) {
  return (
    <label className="filter">
      <input type="checkbox" checked={unreadOnly} onChange={(event) => onChange(event.target.checked)} /> Show
      unread only
    </label>
  );
}
