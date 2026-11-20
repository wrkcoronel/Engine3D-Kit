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
  vehicles/       carro (corpo rigido com suspensao, tracao dianteira)
    car.gd          orquestra: forcas das rodas, entrar/sair, desvirar
    components/     separados por assunto
      driving/        input, engine (motor e cambio de 5 marchas, AUTO ou MANUAL), steering (volante),
                      tires (atrito do pneu), wheel_command, upright (desvirar com R ou A/D),
                      seat (entrar/sair)
      suspension/     suspension (raios e molas das 4 rodas), wheel_ground (o que cada roda ve)
      visual/         wheels (rodas na altura da mola), tire_fx (fumaca e marcas), camera
      telemetry/      telemetry, telemetry_context, telemetry_frame, body_contact
                      (eventos e anomalias)
    ui/             speedometer (HUD) e tachometer_dial (conta-giros redondo desenhado em _draw)

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

O carro e um `RigidBody3D` de 1000 kg: o motor de fisica (Jolt) move e gira o corpo nos 3 eixos.
O `car.gd` so calcula forcas. A caixa de colisao e a carroceria e fica 0.3 m acima do chao; quem
segura o carro sao 4 molas, uma por roda. Por isso ele tomba de verdade quando o centro de massa
passa da borda de uma rampa, inclina nas curvas e mergulha na freada.

Todo frame de fisica, o `car.gd` segue estes passos, cada um numa funcao com nome:

1. le o teclado (W/S, A/D, espaco, R, Shift/Ctrl/M do cambio) e suaviza o volante (`CarSteering`);
2. o `CarSuspension` lanca um raio para baixo em cada roda e mede quanto a mola encolheu;
3. o `CarEngine` escolhe a marcha e calcula a forca do motor pela rotacao (torque x relacao);
4. para cada roda no chao (`_apply_wheel_force`): forca da mola para cima (com batente no fim do
   curso e barra estabilizadora) e forca do pneu (`CarTires`): motor so nas rodas da frente,
   freio, deslize lateral e o limite do atrito (circulo de atrito). Freio de mao trava as de tras;
5. arrasto do ar (`_apply_air_drag`); o amortecimento padrao do Godot fica desligado no
   `car.tscn` (`linear_damp_mode`), senao ele freia o carro como um paraquedas;
6. capotado: R desvira no proximo `_integrate_forces`, A/D balancam o carro (`_rock_when_flipped`);
7. coloca cada roda desenhada na altura da mola e manda os numeros para a fumaca dos pneus e a
   telemetria.

Os numeros do carro ficam como `@export` em `car.gd` (freio, volante, arrasto), no no `Engine`
(torque, rotacoes, marchas; hoje perto de um Gol GTI 16v: 0-100 em ~7 s, ~200 km/h), no no `Suspension`
(molas) e no no `Tires` (atrito). O centro de massa (baixo e mais para a frente, como o motor do
Gol) fica no `car.tscn`.

Fora da fisica, a cada frame: `CarCamera` segue o carro e o `Speedometer` mostra os dados.

## Qualidade automatica

- `gdformat .` e `gdlint .` (regras em `gdlintrc`).
- Godot carregando o projeto: `godot_console.exe --headless --path . --quit-after 60`.
- Testes: `godot_console.exe --headless --path . --script res://tests/run_tests.gd`.
- Cenarios do carro: `godot_console.exe --headless --path . --fixed-fps 60 --script res://tests/run_scenarios.gd`.
  - So alguns: `... run_scenarios.gd -- --cenario ramp5` (roda os testes cujo nome contem `ramp5`).
  - Com detalhe: acrescente `--telemetria-detalhada` (0.5 s antes e depois de cada anomalia).
  - Os cenarios de `test_car_ramp_telemetry.gd` falham se aparecer SOLAVANCO, PERDEU O CHAO
    RAPIDO ou FREOU DE REPENTE sem predio ate o carro decolar do topo, ou se ele nao chegar na
    rampa. O pouso depois do salto nao conta: cair de ~10 m bate o fundo de qualquer carro.
  - `test_car_ramp_edges.gd` confere as bordas: centro fora tomba e cai, carroceria fora com as
    rodas em cima anda normal, nada fica preso na quina nem flutua.
- Dentro do Claude Code, os hooks de `.claude/` rodam isso sozinhos. O `CLAUDE.md` tem as regras
  que a IA segue.

- No GitHub, `.github/workflows/ci.yml` roda tudo isso (mais a checagem de comentarios) em todo
  pull request. O job se chama `qualidade` e pode ser exigido antes de aprovar.

`gdlintrc`, os avisos em `project.godot` e `.claude/` definem o que conta como erro e sao
protegidos: so o dono muda.
