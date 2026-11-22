const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..", "..");
const PROTECTED_FILES = [
	"gdlintrc",
	".claude/settings.json",
	".agents/hooks.json",
];
const PROTECTED_DIRS = [
	".claude/hooks/",
	".agents/hooks/",
];

function readInput() {
	try {
		return JSON.parse(fs.readFileSync(0, "utf8") || "{}");
	} catch (error) {
		return {};
	}
}

function normalizeRelative(filePath, rootDir) {
	const resolved = path.resolve(rootDir, filePath);
	const relative = path.relative(rootDir, resolved).replace(/\\/g, "/");
	return process.platform === "win32" ? relative.toLowerCase() : relative;
}

function isProtected(relativePath) {
	if (PROTECTED_FILES.includes(relativePath)) return true;
	return PROTECTED_DIRS.some((dir) => relativePath.startsWith(dir));
}

const input = readInput();
const args = (input.toolCall && input.toolCall.args) || {};
const filePath = args.Path || args.TargetFile || args.file_path || "";

if (!filePath) {
	process.stdout.write(JSON.stringify({ decision: "allow" }));
	process.exit(0);
}

const rootDir = input.cwd || ROOT;
const relativePath = normalizeRelative(filePath, rootDir);

if (isProtected(relativePath)) {
	process.stdout.write(
		JSON.stringify({
			decision: "deny",
			reason: `Arquivo protegido (${relativePath}): somente o dono do projeto pode alterar.`,
		})
	);
	process.exit(0);
}

process.stdout.write(JSON.stringify({ decision: "allow" }));
