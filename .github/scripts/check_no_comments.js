const fs = require("fs");
const path = require("path");

const ROOT = process.cwd();
const FOLDERS = ["app", "contexts", "shared", "tests"];

function listScripts(dir) {
	const found = [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) found.push(...listScripts(full));
		else if (entry.name.endsWith(".gd")) found.push(full);
	}
	return found;
}

function commentLines(source) {
	const lines = [];
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
				lines.push(index + 1);
				break;
			}
		}
	});
	return lines;
}

const problems = [];
for (const folder of FOLDERS) {
	for (const file of listScripts(path.join(ROOT, folder))) {
		for (const line of commentLines(fs.readFileSync(file, "utf8"))) {
			problems.push(`${path.relative(ROOT, file)}:${line}: comentario (regra: sem comentarios)`);
		}
	}
}

if (problems.length > 0) {
	console.error(problems.join("\n"));
	process.exit(1);
}
console.log("sem comentarios nos .gd");
