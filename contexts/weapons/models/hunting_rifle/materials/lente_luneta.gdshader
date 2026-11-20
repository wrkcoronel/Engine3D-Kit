shader_type spatial;
// Lentes da luneta (meshes/lentes.obj, as duas no mesmo mesh; z > 0 e a ocular, virada para o olho).
// Objetiva: vidro com tratamento multicamada. Reflete o ambiente e as luzes de verdade (sol, postes,
// lanterna): um brilho forte e pequeno (a "piscada" da luneta) e um brilho largo na cor do tratamento.
// O vidro reflete o ceu do mapa (ceu): uma faixa mais clara para o lado de cima, mais forte na beirada.
// Dentro dela aparecem, fracos, os aneis das lentes internas, que escorregam com o angulo de quem olha (cada
// lente mais funda escorrega mais), como numa luneta real. No escuro, sem luz, ela fica escura.
// Ocular: a imagem viva da luneta (luneta.gd, camera na objetiva, com o zoom da mira), com reticulo duplex.
// A pedido do usuario ela aparece na ocular inteira mesmo vista de lado (com a arma na cintura), so com
// uma vinheta suave na borda que escorrega um pouco com o angulo do olho.
uniform sampler2D imagem : source_color, filter_linear;
uniform float centro_y = 0.065;
uniform float raio = 0.0179;
uniform vec3 revestimento : source_color = vec3(0.32, 0.5, 0.42);
uniform vec3 brilho_tratamento : source_color = vec3(0.55, 0.35, 0.85);
// Cor do ceu do mapa (luneta.gd copia o fundo do ambiente): o reflexo do vidro some no escuro.
uniform vec3 ceu : source_color = vec3(0.36, 0.4, 0.46);
varying vec3 local;
varying float objetiva;

void vertex() {
	local = VERTEX;
	objetiva = local.z > 0.0 ? 0.0 : 1.0;
}

float anel(float r, float centro, float largura) {
	return 1.0 - smoothstep(0.0, largura, abs(r - centro));
}

void fragment() {
	vec2 p = (local.xy - vec2(0.0, centro_y)) / raio;
	vec3 olhar = normalize((inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	if (objetiva < 0.5) {
		vec2 desvio = clamp(olhar.xy / max(olhar.z, 0.15), vec2(-1.0), vec2(1.0)) * 0.12;
		float disco = 1.0 - smoothstep(0.72, 1.0, length(p + desvio));
		vec3 cor = texture(imagem, vec2(0.5 + p.x * 0.5, 0.5 - p.y * 0.5)).rgb;
		float fino = step(abs(p.x), 0.012) + step(abs(p.y), 0.012);
		float grosso = (step(abs(p.x), 0.04) * step(0.45, abs(p.y))) + (step(abs(p.y), 0.04) * step(0.45, abs(p.x)));
		float reticulo = clamp(fino + grosso, 0.0, 1.0);
		ALBEDO = vec3(0.01);
		METALLIC = 0.0;
		ROUGHNESS = 0.05;
		SPECULAR = 0.6;
		EMISSION = cor * disco * (1.0 - reticulo);
	} else {
		// A objetiva olha para -Z: o desvio usa o olhar visto da frente.
		vec2 desvio = olhar.xy / max(-olhar.z, 0.15);
		float r1 = length(p - desvio * 0.12);
		float r2 = length(p - desvio * 0.28);
		float r3 = length(p - desvio * 0.45);
		float aneis = anel(r1, 0.86, 0.03) * 0.5 + anel(r2, 0.6, 0.03) * 0.35 + anel(r3, 0.32, 0.04) * 0.25;
		ALBEDO = mix(revestimento * 0.12, brilho_tratamento * 0.5, aneis * 0.35);
		METALLIC = 0.85;
		ROUGHNESS = 0.05;
		SPECULAR = 1.0;
		// Reflexo do ceu: o vidro e curvo, entao o reflexo vira para cima conforme sobe na lente.
		vec3 normal_mundo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 olhar_mundo = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
		vec3 reflexo = reflect(-olhar_mundo, normal_mundo);
		float para_cima = clamp(reflexo.y + p.y * 0.45, -1.0, 1.0);
		float faixa = smoothstep(-0.15, 0.55, para_cima);
		float beirada = 0.35 + 0.65 * pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 2.0) + smoothstep(0.6, 1.0, length(p)) * 0.4;
		EMISSION = ceu * mix(vec3(0.55, 0.75, 0.7), vec3(0.9, 0.95, 1.0), faixa) * (0.08 + 0.55 * faixa) * beirada;
	}
}

void light() {
	float luz = ATTENUATION * max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * luz * ALBEDO * 0.08;
	vec3 metade = normalize(LIGHT + VIEW);
	float ndh = max(dot(NORMAL, metade), 0.0);
	// Piscada: o reflexo pequeno e forte da luz no vidro.
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * pow(ndh, 900.0) * 14.0;
	// Brilho largo do tratamento das lentes, so na objetiva.
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * pow(ndh, 18.0) * brilho_tratamento * 0.9 * objetiva;
}
