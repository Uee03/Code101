import type { Fetcher } from "./api";

export const SCENARIOS = ["normal", "slow", "server-error", "offline", "bad-data", "stalled"] as const;
export type Scenario = (typeof SCENARIOS)[number];

export function isScenario(value: string): value is Scenario {
  return SCENARIOS.some((scenario) => scenario === value);
}

function wait(ms: number, signal?: AbortSignal | null): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(signal.reason);
      return;
    }
    const timer = setTimeout(resolve, ms);
    signal?.addEventListener(
      "abort",
      () => {
        clearTimeout(timer);
        reject(signal?.reason);
      },
      { once: true },
    );
  });
}

export function fetcherFor(scenario: Scenario): Fetcher {
  return async (input, init): Promise<Response> => {
    switch (scenario) {
      case "normal":
        return fetch(input, init);
      case "slow":
        await wait(2500, init?.signal);
        return fetch(input, init);
      case "server-error":
        await wait(300, init?.signal);
        return new Response("Internal Server Error", { status: 500 });
      case "offline":
        await wait(300, init?.signal);
        throw new TypeError("Failed to fetch");
      case "bad-data":
        await wait(300, init?.signal);
        return new Response(JSON.stringify({ message: "this is not a task list" }), {
          headers: { "Content-Type": "application/json" },
        });
      case "stalled":
        await wait(60_000, init?.signal);
        return fetch(input, init);
    }
  };
}
