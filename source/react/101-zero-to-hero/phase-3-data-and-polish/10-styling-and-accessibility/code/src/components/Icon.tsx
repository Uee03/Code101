export type IconName = 'plus' | 'x' | 'check-circle';

type IconProps = {
  name: IconName;
};

export default function Icon({ name }: IconProps) {
  return <span className={`icon icon-${name}`} aria-hidden="true" />;
}
