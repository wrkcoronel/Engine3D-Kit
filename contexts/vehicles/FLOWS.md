# Fluxos do carro

Cada fluxo segue um valor do comeco (o teclado) ate o fim (o carro se mexendo). Le-se de cima
para baixo, uma seta por passo. Todo `car.gd:` esta em `contexts/vehicles/car.gd`.

## 1. Acelerar (W)

```
car_input.gd:read_keyboard        W vira throttle = 1.0
  -> car_input.gd:update          so le o teclado se ha motorista
  -> car.gd:_physics_process      var throttle := input.throttle
  -> car.gd:_apply_throttle       soma acceleration * taper * traction ao forward_speed
  -> car.gd:_physics_process      clampf limita ao max_speed
  -> car_grip.gd:apply_to_velocity  junta forward_speed e a velocidade lateral em _vel
  -> car.gd:_move                 _vel girada pela rampa vira velocity
  -> move_and_slide()             o Godot move o corpo
```

`traction` vem do fluxo 2: curva forte reduz a aceleracao.

## 2. Virar (A / D)

```
car_input.gd:read_keyboard        A/D viram steering = -1, 0 ou 1
  -> car.gd:_smooth_steering      _steer_wheel anda ate o teclado aos poucos
  -> car.gd:_turn                 formula da bicicleta, limitada por max_lat_accel
  -> rotate_y()                   o carro gira (so no chao)
  -> car.gd:_turn                 devolve traction para o fluxo 1
```

## 3. Freio de mao e derrapagem (Espaco)

```
car_input.gd:read_keyboard        Espaco vira handbraking = true
  -> car_grip.gd:update           o grip atual cai para drift_grip
  -> car_grip.gd:drift_amount     0 (agarrado) a 1 (derrapando)
  -> car.gd:_turn                 vira mais facil quanto maior o drift_amount
  -> car_grip.gd:apply_handbrake_or_rest   freia, ou fica parado se for burnout
```

## 4. Estar no chao

```
ground_probe.gd:sample            raios das 4 rodas e do centro
  -> car_edge_support.gd:update   centro sobre o vazio = hanging_off_edge
  -> car.gd:_physics_process      grounded = no chao e nao pendurado
  -> _apply_throttle, _turn, _move   tudo muda no ar (sem tracao, sem giro, com gravidade)
```

## 5. Entrar e sair (E)

```
car.gd:_unhandled_input           tecla E
  -> car.gd:_try_enter / _exit
  -> car_seat.gd                  acha, esconde e devolve o jogador
  -> _driver                      com motorista, o CarInput passa a ler o teclado
```

## Ainda para mapear

- Fluxo visual: o que alimenta `car_tilt`, `car_wheels`, `car_tire_fx` e `car_camera`.
- Fluxo da telemetria: `car_telemetry_frame` ate o painel F3.
