const fs = require("fs");
const cp = require("child_process");

const GDLINT = process.env.GDLINT || "C:/Users/pc/Desktop/env/Scripts/gdlint.exe";
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
const file = input.tool_input && input.tool_input.file_path;
if (!file || !file.endsWith(".gd") || !fs.existsSync(file)) process.exit(0);

const problems = [];

for (const lineNumber of findCommentLines(fs.readFileSync(file, "utf8"))) {
	problems.push(`${file}:${lineNumber}: comentario (regra do projeto: sem comentarios no codigo)`);
}

const lint = cp.spawnSync(GDLINT, [file], { encoding: "utf8" });
if (lint.status !== 0) {
	const output = `${lint.stdout || ""}${lint.stderr || ""}`.trim();
	problems.push(...output.split("\n"));
}

if (problems.length > 0) {
	console.error(problems.slice(0, MAX_LINES).join("\n"));
	process.exit(2);
}
