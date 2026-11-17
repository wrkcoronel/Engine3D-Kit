# Arquitetura

O codigo e organizado por **contexto**: cada assunto do jogo mora na sua pasta, com cenas, scripts e
efeitos juntos. Nao existe pasta global de scripts ou de cenas.

O codigo nao tem comentarios. Quem explica e o nome do arquivo, da funcao e da variavel. Este
documento explica o resto: onde cada coisa mora e por que.

## Mapa

```
app/            monta os contextos em cenas jogaveis
  main.tscn       mundo + jogador + carro
  arena.tscn      piso, muro e jogador, para testar tiro (R recarrega)

contexts/       um contexto por assunto
  world/          mapa: piso, ceu, luz, predios e rampas (props/)
  player/         corpo do jogador: movimento, pulo, correr, agachar, deslizar
    components/     mouse_look, head_lean
  weapons/        arma
    gun.gd          orquestra: atira e junta a pose final
    components/     wall_avoid, cover_peek, aim, sway, recoil, sprint
    effects/        impact (marca do tiro)
  vehicles/       carro
    car.gd          orquestra: fisica de direcao, aceleracao e entrar/sair
    components/     camera, tire_fx (fumaca e marcas), tilt, grip (aderencia)
    ui/             speedometer (HUD: km/h, marcha, rotacao, freio de mao)

shared/         usado por mais de um contexto
  physics/ray_util.gd   distancia de um raio ate o primeiro obstaculo

tests/          testes que rodam sem abrir o jogo
```

## Regras

- **A dependencia so desce:** `app` conhece `contexts`, `contexts` conhecem `shared`, e `shared`
  nao conhece ninguem.
- **Um contexto nao mexe nos detalhes de outro.** As ligacoes que existem hoje:
  - `weapons` chama `take_hit(hit, dir, damage)` em quem tiver esse metodo. Hoje nada tem.
  - `weapons` usa o `HeadLean` do jogador (inclinar a cabeca no cover) e le `is_sprinting`.
  - `vehicles` acha o jogador pelo grupo `player` ao entrar no carro.
- **Orquestrador e componente.** O `.gd` principal (`gun.gd`, `car.gd`) decide a ordem e chama cada
  parte. Cada componente faz uma coisa so e **nao le o estado do dono**: recebe tudo por argumento
  tipado em `update(...)`.
- **Um arquivo nao passa de 300 linhas.** Passou: dividir em componente novo, nunca subir o limite.
- **Tudo tipado.** Os avisos `untyped_declaration` e `unsafe_property_access` do Godot sao erro.
  Eventos de input sao convertidos antes de ler propriedades (`event as InputEventKey`).

## Como o carro funciona (o maior contexto)

Todo frame de fisica, o `car.gd` segue estes passos, cada um numa funcao com nome:

1. le o teclado (W/S, A/D, espaco);
2. suaviza o volante (`_smooth_steering`);
3. gira o carro (`_turn`) e calcula quanta tracao sobra para acelerar;
4. acelera ou freia (`_apply_throttle`) e aplica a gravidade da rampa (`_apply_slope`);
5. deixa o `CarGrip` remover a velocidade lateral e aplicar o freio de mao;
6. move o corpo (`_move`);
7. manda os numeros do frame para os efeitos dos pneus (`CarTireFx`).

Fora da fisica, a cada frame: `CarTilt` inclina o visual, `CarCamera` segue o carro e o
`Speedometer` mostra os dados.

## Qualidade automatica

- `gdformat .` e `gdlint .` (regras em `gdlintrc`).
- Godot carregando o projeto: `godot_console.exe --headless --path . --quit-after 60`.
- Testes: `godot_console.exe --headless --path . --script res://tests/run_tests.gd`.
- Dentro do Claude Code, os hooks de `.claude/` rodam isso sozinhos. O `CLAUDE.md` tem as regras
  que a IA segue.

- No GitHub, `.github/workflows/ci.yml` roda tudo isso (mais a checagem de comentarios) em todo
  pull request. O job se chama `qualidade` e pode ser exigido antes de aprovar.

`gdlintrc`, os avisos em `project.godot` e `.claude/` definem o que conta como erro e sao
protegidos: so o dono muda.
