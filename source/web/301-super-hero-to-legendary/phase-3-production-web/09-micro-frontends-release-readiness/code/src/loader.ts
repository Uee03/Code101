import type { RemoteEntry, RemoteModule } from './contract.js';

export type Importer = (url: string) => Promise<unknown>;

export type LoadFailure = 'timeout' | 'import-error' | 'contract-mismatch' | 'invalid-module';

export type LoadResult<Target> =
  | { status: 'loaded'; module: RemoteModule<Target> }
  | { status: 'failed'; reason: LoadFailure; detail: string };

export interface LoadOptions {
  timeoutMs: number;
  hostContract: number;
}

function failed<Target>(reason: LoadFailure, detail: string): LoadResult<Target> {
  return { status: 'failed', reason, detail };
}

function isRemoteModule<Target>(value: unknown): value is RemoteModule<Target> {
  return typeof value === 'object' && value !== null && typeof (value as { mount?: unknown }).mount === 'function';
}

// In a browser the importer is (url) => import(url). Here it is injected, so every failure can be rehearsed.
export async function loadRemote<Target>(
  entry: RemoteEntry,
  importer: Importer,
  options: LoadOptions,
): Promise<LoadResult<Target>> {
  // Cheap check first: do not even download a remote that speaks another contract.
  if (entry.contract !== options.hostContract) {
    return failed('contract-mismatch', `remote speaks contract ${entry.contract}, host needs ${options.hostContract}`);
  }

  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<'timeout'>((resolve) => {
    timer = setTimeout(() => resolve('timeout'), options.timeoutMs);
  });

  try {
    const outcome = await Promise.race([importer(entry.url), timeout]);
    if (outcome === 'timeout') {
      return failed('timeout', `no answer within ${options.timeoutMs} ms`);
    }
    if (!isRemoteModule<Target>(outcome)) {
      return failed('invalid-module', 'mount is not a function');
    }
    return { status: 'loaded', module: outcome };
  } catch (error) {
    return failed('import-error', error instanceof Error ? error.message : String(error));
  } finally {
    clearTimeout(timer);
  }
}
