# Fluxos do carro

Cada fluxo segue um valor do comeco (o teclado) ate o fim (o carro se mexendo). Le-se de cima
para baixo, uma seta por passo. Todo `car.gd:` esta em `contexts/vehicles/car.gd`.

O carro e um `RigidBody3D`: o codigo nunca muda a posicao dele direto. Ele so aplica forcas
(`apply_force`) e o motor de fisica faz o resto.

## 1. Acelerar (W)

```
car_input.gd:read_keyboard            W vira throttle = 1.0
  -> car_engine.gd:update             escolhe a marcha (sobe a 6400 rpm, desce a 2800 rpm)
                                      e calcula a rotacao pela velocidade das rodas
  -> car_engine.gd:drive_force        torque do motor naquela rotacao x relacao da marcha
                                      (durante a troca, 0.25 s sem forca)
  -> car.gd:_wheel_command            metade para cada roda da frente
  -> car_tires.gd:force_on_ground     limita pelo atrito: se passar, a roda patina
  -> car.gd:_apply_wheel_force        apply_force no ponto onde a roda toca o chao
```

No AUTO, S parado engata a re (`CarEngine.REVERSE`) e S andando freia.

## 1b. Trocar de marcha (M, Shift, Ctrl)

```
car_input.gd:_read_gear_keys          so o aperto (nao segurar) ou um giro do scroll vira shift_up/down_pressed
  -> car_engine.gd:handle_driver_shifts   M alterna AUTO/MANUAL; no MANUAL Shift sobe e Ctrl desce
  -> car_engine.gd:_manual_shift_down     parado na 1a, descer engata a re (como no Forza)
  -> car_engine.gd:wants_brake            no MANUAL, S e so freio
  -> speedometer.gd:update_hud            velocidade digital grande; caixa da marcha vermelha no MANUAL e branca no AUTO; barra de rpm enche e fica vermelha perto do corte
```

## 2. Virar (A / D)

```
car_input.gd:read_keyboard            A/D viram steering = -1, 0 ou 1
  -> car_steering.gd:smooth           o volante anda ate o teclado aos poucos
  -> car_steering.gd:wheel_angle      rapido, o angulo da roda diminui
  -> car.gd:_wheel_forward            gira a direcao das rodas da frente
  -> car_tires.gd:_lateral_force      o pneu empurra contra o deslize de lado: o carro vira
```

## 3. Freio de mao (Espaco)

```
car_input.gd:read_keyboard            Espaco vira handbraking = true
  -> car.gd:_wheel_command            rodas de tras com locked = true
  -> car_tires.gd:_locked_wheel_force roda travada desliza com atrito menor: a traseira escapa
```

## 4. Ficar em cima das rodas

```
car_suspension.gd:sample              um raio por roda, para baixo do carro
  -> wheel_ground.gd                  toca o chao? quanto a mola encolheu?
  -> car_suspension.gd:load_on        mola + batente + barra estabilizadora
  -> car.gd:_apply_wheel_force        empurra o carro para cima naquela roda
```

Sem chao embaixo de algumas rodas (borda da rampa), aquele canto perde a mola e o carro inclina
para la. Se o centro de massa passar da borda, ele tomba e cai.

## 5. Desvirar (R, ou A/D como no GTA)

```
car_input.gd:read_keyboard            R vira wants_upright = true
  -> car.gd:_request_upright          car_upright.gd:can_upright (capotado e quase parado?)
  -> car.gd:_integrate_forces         car_upright.gd:upright_transform: em pe, 1 m acima

capotado e encostando em algo, A/D:
  -> car.gd:_rock_when_flipped        car_upright.gd:rock_torque gira o carro de lado
```

## 6. Entrar e sair (E)

```
car.gd:_unhandled_input               tecla E
  -> car.gd:_try_enter / _exit
  -> car_seat.gd                      acha, esconde e devolve o jogador (sempre em pe)
  -> _driver                          com motorista, o CarInput passa a ler o teclado
```

## Ainda para mapear

- Fluxo visual: `car_wheels` (altura de cada roda), `car_tire_fx` e `car_camera`.
- Fluxo da telemetria: `car_telemetry_frame` ate o painel F3.
