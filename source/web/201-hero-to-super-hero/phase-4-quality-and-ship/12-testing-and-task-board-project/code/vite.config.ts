import { defineConfig } from "vitest/config";

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
  },
  preview: {
    port: 4173,
    strictPort: true,
  },
  build: {
    outDir: "dist",
    sourcemap: false,
    target: "baseline-widely-available",
  },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
