const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const ROOT = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const GDLINT = process.env.GDLINT || "gdlint";
const GDFORMAT = process.env.GDFORMAT || "gdformat";
const GODOT = process.env.GODOT || (process.platform === "win32" ? "godot_console" : "godot");
const STAMP = path.join(ROOT, ".claude", ".last_check");
const WATCHED = ["app", "contexts", "shared", "tests"];
const WATCHED_FILES = ["project.godot", "gdlintrc"];
const MAX_LINES = 40;

function readInput() {
	try {
		return JSON.parse(fs.readFileSync(0, "utf8") || "{}");
	} catch (error) {
		return {};
	}
}

function newestChange(dir) {
	let newest = 0;
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) newest = Math.max(newest, newestChange(full));
		else if (/\.(gd|tscn|tres)$/.test(entry.name)) newest = Math.max(newest, fs.statSync(full).mtimeMs);
	}
	return newest;
}

function run(command, args) {
	const result = cp.spawnSync(command, args, { cwd: ROOT, encoding: "utf8" });
	if (result.error) {
		return { status: 1, output: `nao foi possivel rodar "${command}": ${result.error.message}. Coloque no PATH ou defina GDLINT, GDFORMAT ou GODOT com o caminho completo.` };
	}
	return { status: result.status, output: `${result.stdout || ""}${result.stderr || ""}` };
}

function errorLines(text) {
	return text.split("\n").filter((line) => /SCRIPT ERROR|^ERROR|Parse Error|Compile Error/.test(line));
}

const input = readInput();
if (input.stop_hook_active) process.exit(0);

let newest = 0;
for (const dir of WATCHED) newest = Math.max(newest, newestChange(path.join(ROOT, dir)));
for (const file of WATCHED_FILES) newest = Math.max(newest, fs.statSync(path.join(ROOT, file)).mtimeMs);
const lastRun = fs.existsSync(STAMP) ? Number(fs.readFileSync(STAMP, "utf8")) : 0;
if (newest <= lastRun) process.exit(0);

const problems = [];

run(GDFORMAT, ["."]);

const lint = run(GDLINT, ["."]);
if (lint.status !== 0) problems.push("gdlint:", lint.output.trim());

run(GODOT, ["--headless", "--path", ".", "--import"]);
const load = run(GODOT, ["--headless", "--path", ".", "--quit-after", "60"]);
const loadErrors = errorLines(load.output);
if (loadErrors.length > 0) problems.push("godot (carregar projeto):", ...loadErrors);

const tests = run(GODOT, ["--headless", "--path", ".", "--script", "res://tests/run_tests.gd"]);
if (tests.status !== 0) {
	const failing = tests.output.split("\n").filter((line) => /FAIL|^\s+- |testes,/.test(line));
	problems.push("testes:", ...failing);
}

if (problems.length > 0) {
	console.error(problems.join("\n").split("\n").slice(0, MAX_LINES).join("\n"));
	process.exit(2);
}

fs.writeFileSync(STAMP, String(Date.now()));
