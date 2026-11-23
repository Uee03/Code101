import { memo } from 'react';
import type { Status } from '../tasks';

type SummaryProps = {
  counts: Record<Status, number>;
};

const Summary = memo(function Summary({ counts }: SummaryProps) {
  console.log('render Summary');
  return (
    <p role="status">
      {counts.todo} to do, {counts.doing} doing, {counts.done} done
    </p>
  );
});

export default Summary;
