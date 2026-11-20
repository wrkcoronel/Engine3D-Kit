# Engine

Jogo 3D em primeira pessoa feito no **Godot 4.8** com GDScript. Tem um jogador a pe, uma arma e um
carro (Gol GTI) com fisica propria, para andar numa arena com predios e rampas.

O projeto tambem e um jeito de aprender: o codigo e escrito para ser lido. Nomes completos, uma
coisa por linha e nenhum comentario.

## Como jogar

Abra a pasta no Godot 4.8 e rode. A cena principal e `app/main.tscn` (mundo, jogador e carro).
`app/arena.tscn` e uma arena menor para testar tiro.

| Tecla | A pe | Dirigindo |
|---|---|---|
| W A S D | andar | acelerar, frear e direcao (setas tambem) |
| Mouse | olhar | olhar em volta |
| Botao esquerdo | atirar | |
| Botao direito | mirar | |
| Shift | correr | |
| Ctrl ou C | agachar | |
| Espaco | pular | freio de mao |
| E | entrar no carro (perto dele) | sair do carro |
| Esc | soltar o mouse | soltar o mouse |
| F3 | mostrar a telemetria | mostrar a telemetria |
| F2 | salvar relatorio da telemetria | salvar relatorio da telemetria |
| R | recarregar a cena (arena) | |

## Como o codigo e organizado

Cada assunto do jogo mora numa pasta em `contexts/` (`player`, `weapons`, `vehicles`, `world`). O
arquivo `.gd` principal orquestra e as partes ficam em `components/`. O que mais de um contexto
usa fica em `shared/`. O mapa completo, com o motivo de cada decisao, esta em
[ARCHITECTURE.md](ARCHITECTURE.md).

## Qualidade

Precisa do [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) (`gdformat` e `gdlint`) e do
Godot no PATH. No Windows o Godot e `godot_console.exe`.

```bash
gdformat .
gdlint .
godot --headless --path . --quit-after 60
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --fixed-fps 60 --script res://tests/run_scenarios.gd
```

- Os testes rapidos rodam sem abrir o jogo. Os cenarios dirigem o carro por codigo nas rampas e
  conferem a telemetria.
- Para rodar um teste so, acrescente `-- --cenario parte_do_nome` ao comando.
- Se criar um `class_name` novo, rode antes `godot --headless --path . --import`.
- O CI repete esses passos em todo pull request.

## Contribuindo

As regras de codigo, de commits e de pull requests estao em [CLAUDE.md](CLAUDE.md). Resumo:
titulo no formato `tipo(escopo): descricao`, em minusculo e no imperativo.
