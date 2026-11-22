const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const ROOT = path.resolve(__dirname, "..", "..");
const GDLINT = process.env.GDLINT || "gdlint";
const GDFORMAT = process.env.GDFORMAT || "gdformat";
const GODOT = process.env.GODOT || (process.platform === "win32" ? "godot_console" : "godot");
const STAMP = path.join(ROOT, ".agents", ".last_check");
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
	if (!fs.existsSync(dir)) return 0;
	let newest = 0;
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) newest = Math.max(newest, newestChange(full));
		else if (/\.(gd|tscn|tres)$/.test(entry.name)) newest = Math.max(newest, fs.statSync(full).mtimeMs);
	}
	return newest;
}

function listScripts(dir) {
	if (!fs.existsSync(dir)) return [];
	const found = [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) found.push(...listScripts(full));
		else if (entry.name.endsWith(".gd")) found.push(full);
	}
	return found;
}

function findCommentLines(source) {
	const found = [];
	source.replace(/\r/g, "").split("\n").forEach((line, index) => {
		let quote = null;
		for (let i = 0; i < line.length; i++) {
			const c = line[i];
			if (quote) {
				if (c === "\\") i++;
				else if (c === quote) quote = null;
			} else if (c === '"' || c === "'") {
				quote = c;
			} else if (c === "#") {
				found.push(index + 1);
				break;
			}
		}
	});
	return found;
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

function allow() {
	process.stdout.write(JSON.stringify({ decision: "allow" }));
	process.exit(0);
}

const input = readInput();
if (input.continuationActive) allow();
if (input.terminationReason && input.terminationReason !== "NO_TOOL_CALL") allow();

let newest = 0;
for (const dir of WATCHED) newest = Math.max(newest, newestChange(path.join(ROOT, dir)));
for (const file of WATCHED_FILES) {
	const full = path.join(ROOT, file);
	if (fs.existsSync(full)) newest = Math.max(newest, fs.statSync(full).mtimeMs);
}
const lastRun = fs.existsSync(STAMP) ? Number(fs.readFileSync(STAMP, "utf8")) : 0;
if (newest <= lastRun) allow();

const problems = [];

run(GDFORMAT, ["."]);

const lint = run(GDLINT, ["."]);
if (lint.status !== 0) problems.push("gdlint:", lint.output.trim());

for (const dir of WATCHED) {
	for (const file of listScripts(path.join(ROOT, dir))) {
		for (const lineNumber of findCommentLines(fs.readFileSync(file, "utf8"))) {
			const rel = path.relative(ROOT, file);
			problems.push(`${rel}:${lineNumber}: comentario (regra do projeto: sem comentarios no codigo)`);
		}
	}
}

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
	const reason = problems.join("\n").split("\n").slice(0, MAX_LINES).join("\n");
	process.stdout.write(JSON.stringify({ decision: "continue", reason }));
	process.exit(0);
}

fs.writeFileSync(STAMP, String(Date.now()));
allow();
