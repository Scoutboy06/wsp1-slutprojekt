import { build } from "esbuild";

build({
	entryPoints: ["./src/fields/index.js"],
	outfile: "../public/lit/fields.js",
	bundle: true,
	platform: "browser",
	format: "esm",
	treeShaking: true,
	sourcemap: "linked",
});
