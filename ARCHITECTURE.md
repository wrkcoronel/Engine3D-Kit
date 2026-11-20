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
  world/          mapa: piso, ceu, luz, predios e rampas (props/; a rampa tem transicao de 9 graus na base)
  player/         corpo do jogador: movimento, pulo, correr, agachar, deslizar
    components/     mouse_look, head_lean
  weapons/        arma
    gun.gd          orquestra: atira e junta a pose final
    components/     wall_avoid, cover_peek, aim, sway, recoil, sprint
    effects/        impact (marca do tiro)
  vehicles/       carro
    car.gd          orquestra: fisica de direcao, aceleracao e entrar/sair
    components/     separados por assunto
      driving/        input, grip (aderencia), seat (entrar/sair)
      ground/         ground_probe, wheel_ground, edge_support (escorrega da borda),
                      fall (limite da velocidade de queda)
      visual/         tilt, body_lean, wheels, tire_fx (fumaca e marcas), camera, spring_value
      telemetry/      telemetry, telemetry_context, telemetry_frame (eventos e anomalias)
    ui/             speedometer (HUD: km/h, marcha, rotacao, freio de mao)

shared/         usado por mais de um contexto
  physics/ray_util.gd   distancia de um raio ate o primeiro obstaculo
  physics/box_edges.gd  cantos e arestas de uma caixa (usado pela telemetria)
  telemetry/            grava o que o carro e o jogador fazem (F3 mostra, F2 salva relatorio)
                        e imprime os eventos ao vivo na saida do Godot

tests/          testes que rodam sem abrir o jogo, uma pasta por contexto
  run_tests.gd        roda todos os testes rapidos
  run_scenarios.gd    roda so os cenarios (pastas scenarios/), com --fixed-fps 60
  support/            base dos testes (TestCase)
  vehicles/           testes do carro; scenarios/ dirige o carro nas rampas e confere a telemetria
  world/              geometria da rampa (a transicao encosta no chao e na rampa)
  shared/             testes do ray_util e do TelemetryLog
  player/             testes da telemetria do jogador
```

## Regras

- **A dependencia so desce:** `app` conhece `contexts`, `contexts` conhecem `shared`, e `shared`
  nao conhece ninguem.
- **Um contexto nao mexe nos detalhes de outro.** As ligacoes que existem hoje:
  - `weapons` chama `take_hit(hit, dir, damage)` em quem tiver esse metodo. Hoje nada tem.
  - `weapons` usa o `HeadLean` do jogador (inclinar a cabeca no cover) e le `is_sprinting`.
  - `vehicles` acha o jogador pelo grupo `player` ao entrar no carro.
  - `vehicles`, `player` e `weapons` mandam eventos e amostras para `Telemetry.record` e
    `Telemetry.sample` (em `shared/telemetry/`). Sem o no `Telemetry` na cena, nada acontece.
- **Orquestrador e componente.** O `.gd` principal (`gun.gd`, `car.gd`) decide a ordem e chama cada
  parte. Cada componente faz uma coisa so e **nao le o estado do dono**: recebe tudo por argumento
  tipado em `update(...)`.
- **Um arquivo nao passa de 300 linhas** (`max-file-lines` do `gdlintrc`). Passou: dividir em componente novo; so o dono muda o limite.
- **Tudo tipado.** Os avisos `untyped_declaration` e `unsafe_property_access` do Godot sao erro.
  Eventos de input sao convertidos antes de ler propriedades (`event as InputEventKey`).

## Como o carro funciona (o maior contexto)

Todo frame de fisica, o `car.gd` segue estes passos, cada um numa funcao com nome:

1. le o teclado (W/S, A/D, espaco) e pergunta ao `CarEdgeSupport` se o centro do carro esta
   sobre o vazio (ai ele escorrega da borda em modo flutuante, em vez de ficar equilibrado);
2. suaviza o volante (`_smooth_steering`);
3. gira o carro (`_turn`) e calcula quanta tracao sobra para acelerar;
4. acelera ou freia (`_apply_throttle`) e aplica a gravidade da rampa (`_apply_slope`);
5. deixa o `CarGrip` remover a velocidade lateral e aplicar o freio de mao;
6. move o corpo (`_move`); abaixo de ~71 km/h, se perder o chao com o centro ainda sobre a
   rampa, volta para o chao (`_snap_back_onto_ramp`), para nao dar pulinho antes do topo;
7. manda os numeros do frame para os efeitos dos pneus (`CarTireFx`) e para a telemetria.

O carro nao tem suspensao: a colisao e uma caixa de 1.66 x 1 x 4 m que so gira no eixo Y. As
rodas e a inclinacao sao so visuais. O `GroundProbe` lanca um raio por roda e um no centro.

Fora da fisica, a cada frame: `CarTilt` inclina o visual, `CarCamera` segue o carro e o
`Speedometer` mostra os dados.

## Qualidade automatica

- `gdformat .` e `gdlint .` (regras em `gdlintrc`).
- Godot carregando o projeto: `godot_console.exe --headless --path . --quit-after 60`.
- Testes: `godot_console.exe --headless --path . --script res://tests/run_tests.gd`.
- Cenarios do carro: `godot_console.exe --headless --path . --fixed-fps 60 --script res://tests/run_scenarios.gd`.
  - So alguns: `... run_scenarios.gd -- --cenario ramp5` (roda os testes cujo nome contem `ramp5`).
  - Com detalhe: acrescente `--telemetria-detalhada` (0.5 s antes e depois de cada anomalia).
  - Os cenarios de `test_car_ramp_telemetry.gd` falham se aparecer SOLAVANCO, PERDEU O CHAO
    RAPIDO, PENDURADO NA BORDA, FREOU DE REPENTE sem predio, ou se o carro nao chegar na rampa.
- Dentro do Claude Code, os hooks de `.claude/` rodam isso sozinhos. O `CLAUDE.md` tem as regras
  que a IA segue.

- No GitHub, `.github/workflows/ci.yml` roda tudo isso (mais a checagem de comentarios) em todo
  pull request. O job se chama `qualidade` e pode ser exigido antes de aprovar.

`gdlintrc`, os avisos em `project.godot` e `.claude/` definem o que conta como erro e sao
protegidos: so o dono muda.
