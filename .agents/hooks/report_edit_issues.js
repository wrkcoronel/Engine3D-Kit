const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..", "..");
const PENDING_FILE = path.join(ROOT, ".agents", ".pending_lint.txt");
const MAX_LINES = 40;

if (!fs.existsSync(PENDING_FILE)) {
	process.stdout.write("{}");
	process.exit(0);
}

const raw = fs.readFileSync(PENDING_FILE, "utf8").trim();
fs.unlinkSync(PENDING_FILE);

if (!raw) {
	process.stdout.write("{}");
	process.exit(0);
}

const message = raw.split("\n").slice(0, MAX_LINES).join("\n");
process.stdout.write(
	JSON.stringify({
		injectSteps: [
			{
				systemMessage: {
					systemMessage: `Hook de edicao encontrou problemas no GDScript:\n${message}`,
				},
			},
		],
		terminationBehavior: "force_continue",
	})
);
