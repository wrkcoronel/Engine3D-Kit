# Regras do projeto (Godot 4.8, GDScript)

O dono do projeto esta aprendendo e precisa LER e ENTENDER o codigo. Legibilidade vale mais que
brevidade. Isto vale para qualquer codigo que a IA escrever ou alterar.

## Legibilidade
- Uma coisa por linha. Nada de expressao comprimida: evitar `a if c else b` aninhado, `and`/`or`
  encadeados em uma linha, e varias chamadas dentro de uma so linha.
- Quebrar conta longa em variaveis com nome que diz o que o valor e
  (`var end_point := from + dir * length`, e nao so `from + dir * length` dentro da chamada).
- Preferir `if ...: return` com varias linhas a um `return x if y else z`.
- Nomes completos e descritivos. Nada de abreviacao que precise adivinhar (`v`, `h`, `fs0`).
  Formula fisica tambem: nome completo em vez de letra (`steering_speed`, nao `v_yaw`).
- Funcao curta e com um objetivo. Funcao com mais de ~40 linhas deve ser dividida em funcoes
  menores, cada uma com nome que explica o passo.
- SEM COMENTARIOS no codigo. Nem `#` nem `##`, em nenhum `.gd` (inclusive `tests/`). Quem
  explica e o nome da variavel, da funcao e do arquivo. Se algo precisa de comentario para ser
  entendido, renomear ou dividir em funcoes menores. Nunca deixar codigo comentado.

## Tamanho e estrutura
- Arquivo com no maximo 300 linhas (regra `max-file-lines` do `gdlintrc`). Passou disso: dividir
  em componentes, como `contexts/weapons/` e `contexts/vehicles/components/`.
- Cada contexto mora na sua pasta em `contexts/`. O `.gd` principal orquestra; as partes ficam
  em `components/`.
- Componente nao le o estado do dono: recebe tudo por argumento tipado.

## Tipos (o projeto trata aviso como erro)
- `untyped_declaration` e `unsafe_property_access` estao como ERRO no `project.godot`.
- Sempre tipar variaveis, parametros e retornos. `for x: Tipo in lista`.
- Nao acessar propriedade de tipo generico: fazer cast antes (`var key := event as InputEventKey`).

## Commits e pull requests
- Titulo no formato `tipo(escopo): descricao`, em minusculo, no imperativo, sem ponto final, ate 72
  caracteres. O titulo do pull request segue o mesmo formato (o CI reprova se nao seguir) e vira o
  titulo do commit no Squash and merge.
- Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `ci`, `chore`, `style`, `perf`, `revert`.
- Escopos usuais: `car`, `player`, `gun`, `world`, `arena`, `tests`, `lint`, `ci`. Sem escopo, se a
  mudanca nao for de um contexto so.
- `!` antes dos dois pontos marca quebra de compatibilidade (`refactor(car)!: renomeia export`).
- Uma mudanca por commit. O corpo, se houver, explica o PORQUE.
- Exemplos: `refactor(car): divide o carro em componentes`, `fix(tests): falha sem testes`,
  `ci: atualiza as acoes`, `docs: reescreve o ARCHITECTURE.md`.
- Terminar com a linha `Co-Authored-By` quando a IA escreveu o commit.

## Arquivos protegidos (so o dono muda)
- `gdlintrc`, os avisos em `[debug]` do `project.godot` e `.claude/settings.json` definem o que
  conta como erro. Nunca mudar esses valores para fazer lint, aviso ou teste passar.
- Se um limite estiver atrapalhando (ex: `max-file-lines`), a resposta e corrigir o codigo. Se
  achar que o limite deve mudar, explicar o motivo ao dono e esperar ele decidir.
- Nunca afrouxar nem apagar um teste para ele passar. Teste que falha e para ser investigado.

## Hooks automaticos (`.claude/settings.json`, scripts em `.claude/hooks/`)
- Depois de cada edicao de `.gd`: confere comentario e roda o `gdlint` no arquivo.
- Ao fim de cada resposta que mudou codigo: gdformat, gdlint, Godot e os testes.
- Se um hook falhar, corrigir o codigo. Nao tentar desligar nem editar o hook.

## Antes de terminar qualquer mudanca
Rodar, nesta ordem, e deixar tudo limpo:
1. `gdformat .`
2. `gdlint .`
3. `godot --headless --path . --quit-after 60`
4. Testes: `godot --headless --path . --script res://tests/run_tests.gd`
   (codigo de saida 1 = algum teste falhou). Codigo novo com logica pura ganha teste em `tests/`.
5. Se mexeu na fisica ou no visual do carro, os cenarios:
   `godot --headless --path . --fixed-fps 60 --script res://tests/run_scenarios.gd`
   (`--fixed-fps 60` faz a fisica rodar mais rapido que o tempo real; sem ele demora minutos).

## Organizacao dos testes
- Uma pasta por contexto, sem subpastas do codigo: o teste de
  `contexts/vehicles/components/car_grip.gd` fica em `tests/vehicles/test_car_grip.gd`. Codigo de
  `shared/` testa em `tests/shared/`. O nome e o do arquivo testado com `test_` na frente.
- Cenarios (o jogo rodando com o carro sendo dirigido por codigo) ficam em `scenarios/` dentro da
  pasta do contexto, como `tests/vehicles/scenarios/`. Eles nao rodam no `run_tests.gd`, so no
  `run_scenarios.gd`.
- Novo cenario do carro: um metodo `test_` usando `CarScenario`, que posiciona o carro, dirige
  pelo `car.input` e mede rodas, trocas de chao e decolagem. Nao escrever script solto para testar.
- `tests/support/` guarda o que e base dos testes (`TestCase`).
Se criar `class_name` novo, rodar antes `godot --headless --path . --import`.

Esses comandos precisam estar no PATH (no Windows, o Godot e `godot_console.exe`). Se algum nao
estiver, definir a variavel de ambiente `GDLINT`, `GDFORMAT` ou `GODOT` com o caminho completo; os
hooks usam essas variaveis primeiro. Nunca escrever caminho absoluto de maquina em arquivo
versionado.
Dizer o que NAO foi testado jogando.
