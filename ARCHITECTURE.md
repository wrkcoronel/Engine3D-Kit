# Arquitetura do projeto

Organizado por **contextos** (estilo DDD): cada assunto do jogo mora na sua pasta, com suas cenas,
scripts e efeitos juntos. Nada de pasta global "scripts" ou "scenes".

```
app/                      Composicao: monta os contextos em cenas jogaveis
  main.tscn               mapa principal (mundo grande + carro)
  arena.tscn / arena.gd   arena de teste de tiro (muro + inimigo)

contexts/                 Um contexto por assunto
  world/                  mapa
    world.tscn            piso, ceu, luz, predios e rampas
    props/                building, ramp (pecas reutilizaveis)
  player/                 jogador
    player.tscn / .gd     corpo: movimento, pulo, correr, agachar, deslizar
    components/           mouse_look, head_lean (cada um faz uma coisa)
  weapons/                arma
    gun.tscn / .gd        orquestrador: atira e junta a pose
    components/           wall_avoid, cover_peek, aim, sway, recoil, sprint
    effects/              impact (marca do tiro)
  vehicles/               carro
    car.tscn / .gd        fisica arcade, camera, entrar/sair
    ui/                   speedometer (HUD do carro)
  enemy/                  inimigo
    enemy.tscn / .gd      corpo com partes destrutiveis
    effects/              blood, blood_stain, gib

shared/                   Usado por mais de um contexto
  physics/ray_util.gd
```

## Regras

- **Dependencia so desce:** `app` conhece `contexts`; `contexts` conhecem `shared`; `shared` nao conhece ninguem.
- **Um contexto nao mexe nos detalhes de outro.** Hoje as ligacoes sao:
  - `weapons` -> `enemy`: so chama `take_hit(hit, dir, damage)` (qualquer coisa que tenha esse metodo reage a tiro);
  - `weapons` -> `player`: a arma usa o `HeadLean` do jogador (peek do cover) e le `is_sprinting`;
  - `vehicles` -> `player`: acha o jogador pelo grupo `player` ao entrar.
- **Componente = uma responsabilidade.** O orquestrador (`gun.gd`, `car.gd`) chama `update()` de cada parte.
- Efeito visual de um contexto fica em `effects/` dele; HUD fica em `ui/`.
