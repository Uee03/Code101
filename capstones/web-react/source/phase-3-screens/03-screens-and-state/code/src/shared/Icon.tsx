export type IconName = 'search' | 'filter' | 'plus' | 'x' | 'check-circle' | 'alert-triangle' | 'list' | 'columns'
  | 'log-in' | 'log-out' | 'refresh-cw' | 'users' | 'cloud-off' | 'calendar-days';
export function Icon({ name }: { name: IconName }) {
  return <span className={`icon icon-${name}`} aria-hidden="true" />;
}
