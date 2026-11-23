import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ApiClient } from '../../api-client';
import { ApiProblem, isApiProblem } from '../../http/problem';
import { ProblemView } from '../../shared/problem-view';

interface Probe {
  label: string;
  path: string;
}

type Outcome = { kind: 'idle' } | { kind: 'loading'; label: string } | { kind: 'ok'; label: string; data: string } | { kind: 'problem'; label: string; problem: ApiProblem };

@Component({
  selector: 'app-demo',
  imports: [ProblemView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './demo.html',
  styleUrl: './demo.css'
})
export class Demo {
  private readonly api = inject(ApiClient);

  protected readonly probes: readonly Probe[] = [
    { label: 'Health check (200)', path: '/health' },
    { label: 'Not found (404)', path: '/v1/demo/error/404' },
    { label: 'Validation failed (422)', path: '/v1/demo/error/422' },
    { label: 'Too many requests, retried once (429 then 200)', path: '/v1/demo/limited' },
    { label: 'Server error (500)', path: '/v1/demo/error/500' },
    { label: 'Connection dropped (no answer)', path: '/v1/demo/drop' }
  ];
  protected readonly outcome = signal<Outcome>({ kind: 'idle' });

  protected async run(probe: Probe): Promise<void> {
    this.outcome.set({ kind: 'loading', label: probe.label });
    try {
      const data = await this.api.get<unknown>(probe.path);
      this.outcome.set({ kind: 'ok', label: probe.label, data: JSON.stringify(data) });
    } catch (error) {
      if (isApiProblem(error)) {
        this.outcome.set({ kind: 'problem', label: probe.label, problem: error });
      } else {
        throw error;
      }
    }
  }
}
