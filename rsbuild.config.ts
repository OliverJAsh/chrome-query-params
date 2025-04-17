import { defineConfig } from "@rsbuild/core";
import { pluginReact } from "@rsbuild/plugin-react";

export default defineConfig({
  mode: "development",
  source: {
    entry: {
      popup: "./src/popup.tsx",
    },
  },
  output: {
    filenameHash: false,
  },
  plugins: [pluginReact({ fastRefresh: false })],
});
