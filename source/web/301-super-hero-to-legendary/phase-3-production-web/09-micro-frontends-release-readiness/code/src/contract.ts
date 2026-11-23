// The agreement between the shell (host) and a remote. Change it with the same care as a public API.
export const HOST_CONTRACT = 2;

export interface HostContext {
  teamId: string;
  navigate: (path: string) => void;
}

export type Unmount = () => void;

// Target is the thing a remote draws into: an HTMLElement in a browser, a plain object in tests.
export interface RemoteModule<Target> {
  mount: (target: Target, context: HostContext) => Unmount;
}

export interface RemoteEntry {
  name: string;
  url: string;
  contract: number;
}
