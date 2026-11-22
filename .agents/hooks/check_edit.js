const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const ROOT = path.resolve(__dirname, "..", "..");
const PENDING_FILE = path.join(ROOT, ".agents", ".pending_lint.txt");
const GDLINT = process.env.GDLINT || "gdlint";
const MAX_LINES = 30;

function readInput() {
	try {
		return JSON.parse(fs.readFileSync(0, "utf8") || "{}");
	} catch (error) {
		return {};
	}
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

const input = readInput();
const args = (input.toolCall && input.toolCall.args) || {};
const rawFile = args.Path || args.TargetFile || args.file_path || "";
const file = rawFile ? path.resolve(input.cwd || ROOT, rawFile) : "";

if (!file || !file.endsWith(".gd") || !fs.existsSync(file)) {
	process.stdout.write("{}");
	process.exit(0);
}

const problems = [];
for (const lineNumber of findCommentLines(fs.readFileSync(file, "utf8"))) {
	problems.push(`${file}:${lineNumber}: comentario (regra do projeto: sem comentarios no codigo)`);
}

const lint = cp.spawnSync(GDLINT, [file], { cwd: ROOT, encoding: "utf8" });
if (lint.error) {
	problems.push(`nao foi possivel rodar "${GDLINT}": ${lint.error.message}. Coloque no PATH ou defina GDLINT com o caminho completo.`);
} else if (lint.status !== 0) {
	const output = `${lint.stdout || ""}${lint.stderr || ""}`.trim();
	problems.push(...output.split("\n"));
}

if (problems.length > 0) {
	const summary = problems.slice(0, MAX_LINES).join("\n");
	fs.appendFileSync(PENDING_FILE, `${summary}\n`, "utf8");
}

process.stdout.write("{}");
