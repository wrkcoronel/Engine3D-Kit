shader_type spatial;
// Metal das armas com uma janela aberta de verdade (janela de ejecao): os fragmentos dentro da caixa
// janela_min..janela_max (no espaco do proprio mesh) sao descartados, e por ela se ve o interior da arma
// (uma caixa escura com as faces para dentro), o ferrolho e o cartucho na camara.
// O receptor das armas e uma caixa fechada; sem isso nada de dentro apareceria.
uniform vec4 cor : source_color = vec4(0.15, 0.16, 0.17, 1.0);
uniform float metalico = 0.6;
uniform float rugosidade = 0.4;
uniform vec3 janela_min = vec3(0.0);
uniform vec3 janela_max = vec3(0.0);
varying vec3 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	if (all(greaterThan(local, janela_min)) && all(lessThan(local, janela_max))) {
		discard;
	}
	ALBEDO = cor.rgb;
	METALLIC = metalico;
	ROUGHNESS = rugosidade;
}
