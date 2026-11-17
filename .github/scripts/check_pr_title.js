const TYPES = ["feat", "fix", "refactor", "test", "docs", "ci", "chore", "style", "perf", "revert"];
const MAX_LENGTH = 72;

const title = process.env.PR_TITLE || "";
const pattern = new RegExp(`^(${TYPES.join("|")})(\\([a-z0-9-]+\\))?!?: [a-z0-9]`);

const problems = [];
if (!pattern.test(title)) {
	problems.push(`formato esperado: tipo(escopo): descricao. Tipos: ${TYPES.join(", ")}.`);
	problems.push("a descricao comeca em minusculo (ou numero), depois de ': '.");
}
if (title.length > MAX_LENGTH) {
	problems.push(`o titulo tem ${title.length} caracteres; o maximo e ${MAX_LENGTH}.`);
}
if (title.endsWith(".")) {
	problems.push("o titulo nao termina com ponto final.");
}

if (problems.length > 0) {
	console.error(`Titulo fora do padrao: "${title}"`);
	console.error(problems.join("\n"));
	console.error('Exemplo: refactor(car): divide o carro em componentes');
	process.exit(1);
}
console.log(`titulo ok: "${title}"`);
