import { onCLS, onINP, onLCP, type Metric } from 'web-vitals';

export interface VitalReport {
  name: string;
  value: number;
  rating: string;
}

// Real-user measurement: the numbers come from your visitors' browsers, not from your laptop.
export function reportVitals(send: (report: VitalReport) => void): void {
  const forward = (metric: Metric): void => {
    send({ name: metric.name, value: metric.value, rating: metric.rating });
  };
  onCLS(forward);
  onINP(forward);
  onLCP(forward);
}
