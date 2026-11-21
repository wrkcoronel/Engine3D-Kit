# Arquitetura

O codigo e organizado por **contexto**: cada assunto do jogo mora na sua pasta, com cenas, scripts e
efeitos juntos. Nao existe pasta global de scripts ou de cenas.

O codigo nao tem comentarios. Quem explica e o nome do arquivo, da funcao e da variavel. Este
documento explica o resto: onde cada coisa mora e por que.

## Mapa

```
app/            monta os contextos em cenas jogaveis
  main.tscn       mundo + jogador + carro
  arena.tscn      piso, muro e jogador, para testar tiro (F5 recarrega)

contexts/       um contexto por assunto
  world/          mapa: piso, ceu, luz, predios e rampas (props/; a rampa tem transicao de 9 graus na base)
  player/         corpo do jogador: movimento, pulo, correr, agachar, deslizar
    components/     mouse_look, head_lean
  weapons/        as quatro armas que o jogador carrega (1911, Boito Pump, carabina .22, rifle de caca)
    gun.gd          orquestra: le o teclado, junta a pose final e decide tiro, recarga e conferencia
    components/     separados por assunto
      arsenal/        stats e catalogo das armas, municao, troca de arma (1-4, roda, Q), teclas
      pose/           wall_avoid, cover_peek, aim, sway, recoil, sprint, holster (coldre/costas),
                      sight (mira pelas miras da arma), pose_builder
      firing/         gatilho (semi e automatico), dispersao, dano por distancia, tiro (raio),
                      clarao, rastro, estojo ejetado, sons
      reload/         recarga de pente e da Boito cartucho por cartucho
      check/          conferencia da municao (V segurado: pente na mao, tubo ou acao; R com a arma
                      cheia: camara), furos do pente
      action/         pecas que se mexem: corredica e cao da 1911, telha da Boito, ferrolho da .22
                      e do rifle (recuam no tiro e na conferencia e ejetam o estojo)
      scope/          a lente da luneta do rifle
    models/         cenas das armas e cartuchos (malhas OBJ, materiais, sons). Os nomes dos nos
                    ficam em portugues porque o codigo os acha pelo nome (ex.: Visual/Corpo)
    ui/             shader da mira da luneta
    effects/        impact (furo de bala, um Decal) e tracer (rastro)
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
    ui/             speedometer (HUD), speed_readout (velocidade), gear_badge (caixa da marcha), rpm_bar (barra de rpm), italic_font

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
  weapons/            municao, dano, gatilho, conferencia, troca e as quatro armas atirando

tools/           ferramentas fora do jogo, uma pasta por assunto (tem .gdignore: o Godot nao enxerga)
  car/              gol_gti.blend e build_gol_gti.py, que monta o carro e exporta o gol_gti.glb
  weapons/
    blends/           <arma>.blend: as quatro armas, peca por peca, com os mesmos nomes dos nos
                      do Godot e um esqueleto com uma animacao (Action) para cada coisa que a arma faz
    animations/       <arma>_animations.json: as animacoes gravadas do jogo, quadro a quadro
    blender/          scripts que rodam dentro do Blender (montar os .blend, exportar as malhas)
    godot/            script que roda no Godot (gravar as animacoes)
```

## Armas no Blender

As armas existem nos dois lugares: as cenas `.tscn` (o jogo usa) e os `.blend` (para editar). O
caminho de ida e volta:

1. `build_weapon_blends.py` le as cenas das armas e monta um `.blend` por arma: importa cada malha
   OBJ, recria os cartuchos e o clarao, copia os materiais e guarda em cada objeto o caminho do no
   no Godot (`godot_path`) e o arquivo da malha (`godot_mesh`). Se existir
   `animations/<arma>_animations.json`, cria o objeto `Esqueleto`: um osso para cada peca que se mexe
   (a peca fica presa no osso) e uma Action separada para cada animacao: `tiro`, `recarga` (falta
   uma bala), `recarga_vazia`, `conferir_camara`, `conferir_pente`, `guardar` e `sacar`. Para ver
   uma, selecione o `Esqueleto`, abra o Action Editor e escolha a Action. Peca que some (cartucho na
   camara, arma guardada) tem a escala do osso zerada naquele quadro.
2. `record_weapon_animations.gd` roda o jogo sem janela, faz cada arma atirar, recarregar e conferir
   e grava a pose de cada peca quadro a quadro nesse `.json`. A animacao no Blender e a mesma do
   jogo, porque vem do proprio codigo.
3. Depois de editar uma peca no Blender, `export_weapon_meshes.py` grava a malha de volta no OBJ que
   a cena usa (so a malha; posicao e animacao continuam no Godot).

```powershell
$blender = "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"
godot_console --headless --path . --fixed-fps 30 --script res://tools/weapons/godot/record_weapon_animations.gd
& $blender -b --factory-startup --python tools/weapons/blender/build_weapon_blends.py -- .
& $blender -b tools/weapons/blends/pistol_1911.blend --python tools/weapons/blender/export_weapon_meshes.py -- .
```

As animacoes no Blender sao para ver e estudar. Quem anima no jogo e o codigo de
`contexts/weapons/components/action/`, `reload/` e `check/`: mudar a animacao no Blender nao muda o
jogo.

## Regras

- **A dependencia so desce:** `app` conhece `contexts`, `contexts` conhecem `shared`, e `shared`
  nao conhece ninguem.
- **Um contexto nao mexe nos detalhes de outro.** As ligacoes que existem hoje:
  - `weapons` chama `take_hit(hit, dir, damage)` em quem tiver esse metodo. Hoje nada tem.
  - `weapons` usa o `HeadLean` do jogador (inclinar a cabeca no cover), le `is_sprinting` e muda
    `MouseLook.sensitivity_scale` (mira e luneta deixam o mouse mais lento).
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
