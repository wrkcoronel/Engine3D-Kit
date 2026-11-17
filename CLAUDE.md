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
1. `C:\Users\pc\Desktop\env\Scripts\gdformat.exe .`
2. `C:\Users\pc\Desktop\env\Scripts\gdlint.exe .`
3. `"C:\Program Files\Godot\godot_console.exe" --headless --path . --quit-after 60`
4. Testes: `"C:\Program Files\Godot\godot_console.exe" --headless --path . --script res://tests/run_tests.gd`
   (codigo de saida 1 = algum teste falhou). Codigo novo com logica pura ganha teste em `tests/`.
Se criar `class_name` novo, rodar antes `godot_console.exe --headless --path . --import`.
Dizer o que NAO foi testado jogando.
