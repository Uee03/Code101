import type { HostContext, RemoteEntry, RemoteModule } from './contract.js';
import { HOST_CONTRACT } from './contract.js';
import { loadRemote, type Importer } from './loader.js';
import { isEnabled, type FlagConfig } from './rollout.js';

interface FakeTarget {
  text: string;
}

const tasksModule: RemoteModule<FakeTarget> = {
  mount(target: FakeTarget, context: HostContext) {
    target.text = `Tasks board for team ${context.teamId}`;
    return () => {
      target.text = '';
    };
  },
};

const importer: Importer = async (url) => {
  switch (url) {
    case '/remotes/tasks.js':
      return tasksModule;
    case '/remotes/reports.js':
      return new Promise<never>(() => {});
    case '/remotes/search.js':
      throw new Error('network down');
    case '/remotes/profile.js':
      return { mount: 'not a function' };
    default:
      throw new Error(`unexpected url ${url}`);
  }
};

const entries: RemoteEntry[] = [
  { name: 'tasks', url: '/remotes/tasks.js', contract: 2 },
  { name: 'billing', url: '/remotes/billing.js', contract: 1 },
  { name: 'reports', url: '/remotes/reports.js', contract: 2 },
  { name: 'search', url: '/remotes/search.js', contract: 2 },
  { name: 'profile', url: '/remotes/profile.js', contract: 2 },
];

const options = { timeoutMs: 50, hostContract: HOST_CONTRACT };

for (const entry of entries) {
  const result = await loadRemote<FakeTarget>(entry, importer, options);
  if (result.status === 'loaded') {
    const target: FakeTarget = { text: '' };
    const unmount = result.module.mount(target, { teamId: 'core', navigate: () => {} });
    console.log(`${entry.name}: loaded`);
    console.log(`mounted: ${target.text}`);
    unmount();
    console.log(`unmounted: ${target.text === ''}`);
  } else {
    console.log(`${entry.name}: failed ${result.reason} (${result.detail})`);
  }
}

const users = Array.from({ length: 1000 }, (_, index) => `user-${index}`);
const flag = (percent: number, extra: Partial<FlagConfig> = {}): FlagConfig => ({
  name: 'board-v2',
  percent,
  killSwitch: false,
  allowList: [],
  ...extra,
});
const count = (config: FlagConfig): number => users.filter((user) => isEnabled(config, user)).length;

console.log(`rollout 0%: ${count(flag(0))} of 1000`);
console.log(`rollout 100%: ${count(flag(100))} of 1000`);
console.log(`rollout 50% within tolerance: ${Math.abs(count(flag(50)) - 500) <= 150}`);
console.log(`sticky: ${isEnabled(flag(30), 'user-7') === isEnabled(flag(30), 'user-7')}`);
console.log(`ramp is a subset: ${users.every((user) => !isEnabled(flag(10), user) || isEnabled(flag(20), user))}`);
console.log(`kill switch: ${count(flag(100, { killSwitch: true }))} of 1000`);
console.log(`allow list at 0%: ${isEnabled(flag(0, { allowList: ['user-7'] }), 'user-7')}`);
