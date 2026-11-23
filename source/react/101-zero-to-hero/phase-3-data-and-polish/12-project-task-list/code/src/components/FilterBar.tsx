import type { Filter } from '../types';

type FilterBarProps = {
  filter: Filter;
  onChange: (filter: Filter) => void;
};

const options: { value: Filter; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'active', label: 'Active' },
  { value: 'done', label: 'Done' },
];

export default function FilterBar({ filter, onChange }: FilterBarProps) {
  return (
    <div role="group" aria-label="Show tasks" className="filters">
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          aria-pressed={filter === option.value}
          onClick={() => onChange(option.value)}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}
