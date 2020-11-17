extensions [vid] ; Para grabar
breed [pasajeros pasajero]
breed [posibles posible]
breed [puertas puerta]

directed-link-breed [andando-con-bus-s andando-con-bus]

undirected-link-breed [chasis-buses chasis-bus]

breed [buses bus]
breed [vagones vagon]
breed [conexiones conexion]
breed [paradas parada]

breed [estaciones estacion]

globals [
  tiempo-promedio
]


patches-own[
  tipo ; Piso - Pared - Calle
  interesados
]
;-----------------------------------
; PASAJEROS
; ----------------------------------
pasajeros-own[
  ruta ; La ruta de bus que va a tomar (aun no se utiliza)
  puerta-destino ; Alguna de las puertas dondee para la ruta que va a usar
  decidido ; Si ya decidio a que baldosa se movera
  tiempo-destino
]

;----------------------------------
; BUSES
;----------------------------------
buses-own [
  ruta
  paradas-atendidas
  paradas-restantes
  cantidad-pasajeros
  velocidad
  estado
  tiempo-estado
  conexion-vagon
  union
  cantidad-vagones
  vagones-bus
]

vagones-own[
  velocidad
  conexion-vagon
  bus-correspondiente
]
conexiones-own [
  union
]

paradas-own [
  abierta
  ruta
  puertas-parada
  estacion-parada
  orientacion-p
]
;-----------------------------------
; ESTACIONES
; ----------------------------------
estaciones-own [
  paradas-estacion
]


;----------------------------------
; SETUP
;----------------------------------

to setup
  clear-all

  set-default-shape buses "bus"
  set-default-shape vagones "articulacion"
  set-default-shape conexiones "conexion"
  set-default-shape pasajeros "person"
  set-default-shape puertas "box"
  set-default-shape paradas "parada"
  ask patches [
    set pcolor green + random 2 - 1
    set interesados []
  ]
  crear-estacion patch -100 0
  crear-estacion patch 100 0
  ask patches with [ abs(pycor) > 5 and abs(pycor) < 19 ] [
    set tipo "calle"
    set pcolor black
  ]
  crear-bus (patch -250 9) 2 VelocidadBuses 90 sort paradas with [orientacion-parada = 1]
  crear-bus (patch 250 -9) 2 VelocidadBuses -90 sort paradas with [orientacion-parada = -1]
  ask patches with [tipo = "piso"] [
    set interesados []
    if random-float 1.0 < densidad / 100 [
      sprout-pasajeros 1 [
        set puerta-destino puerta-aleatoria
        set tiempo-destino 0
        ;direccionar
        set decidido false
      ]
    ]
  ]
  set tiempo-promedio (list 0 0)
  reset-ticks
end

;----------------------------------
; GO
;----------------------------------
to cosas-pasajeros
  ask pasajeros with [decidido = false and count my-links = 0] [
    (run (one-of (list [p -> regla-1 p] [p -> regla-2 p] [p -> regla-3 p] [p -> regla-4 p] [p -> regla-5 p] [p -> regla-6 p] [p -> regla-7 p] [p -> regla-8 p] [p -> regla-9 p])) (SeguridadPaso / 10))
  ]
  resolver-conflictos
  colorear
  mover-pasajeros
  colorear
  ask pasajeros [
    set tiempo-destino tiempo-destino + 1
  ]
end


to go
  tick
  cosas-pasajeros
  ask buses [
    conducir
  ]
end

;-----------------------------------
; ESTACIONES
; ----------------------------------
to crear-estacion [origen]
  let estacion-actual 0
  ask origen [
    sprout-estaciones 1 [
      set estacion-actual self
    ]
  ]
  let x [pxcor] of origen
  let y [pycor] of origen
  let ancho 10
  let largo 100
  ask patches with [
    pxcor > x - largo / 2 and
    pxcor < x + largo / 2 and
    pycor > y - ancho / 2 and
    pycor < y + ancho / 2] [
    set tipo "piso"
    set pcolor gray
  ]
  ask patches with [
    ((pxcor = x - largo / 2 or pxcor = x + largo / 2 ) and pycor > y - ancho / 2 and pycor < y + ancho / 2) or
    ((pycor = y - ancho / 2 or pycor = y + ancho / 2 ) and pxcor > x - largo / 2 and pxcor < x + largo / 2)
  ] [
    set tipo "pared"
    set pcolor gray - 1
  ]
  let parada-actual 0
  ask patches with [ (abs pycor) = 9 and (pxcor = x - 8 * orientacion-parada or pxcor = x + 42 * orientacion-parada) ] [
    sprout-paradas 1 [
      set size 5
      set parada-actual self
      set heading (ifelse-value (pycor < 0) [-1][1]) * 90
      set estacion-parada estacion-actual
      set puertas-parada []
      set orientacion-p orientacion-parada
    ]
    foreach [4 15 25 37] [d ->
      ask patches with [(pxcor = [xcor] of parada-actual - d * [orientacion-parada] of parada-actual ) and (pycor = [orientacion-parada] of parada-actual * ancho / 2)] [
        sprout-puertas 1 [
          set heading 90 * [orientacion-parada] of parada-actual
          ask parada-actual [
            set puertas-parada lput myself puertas-parada
          ]
        ]
      ]
    ]
  ]
  ask estacion-actual [
    set paradas-estacion paradas with [estacion-parada = myself]
  ]
end
to-report orientacion-parada
  report ifelse-value (pycor < 0) [-1][1]
end

to-report cuenta-pasajeros-estacion [estacion-actual]
  let x [xcor] of estacion-actual
  let y [ycor] of estacion-actual
  let ancho 10
  let largo 100
  report count pasajeros with [
    xcor > x - largo / 2 and
    xcor < x + largo / 2 and
    ycor > y - ancho / 2 and
    ycor < y + ancho / 2]
end
;-----------------------------------
; PUERTAS
; ----------------------------------
to abrir-puerta
  ask (patch-set patch-here patch-ahead 1 patch-ahead 2 patch-ahead 3) [
   set tipo "piso"
   set pcolor gray
  ]
  move-to patch-at-heading-and-distance (heading + -90) 7
end
to cerrar-puerta
  move-to patch-at-heading-and-distance (heading + 90) 7
  ask (patch-set patch-here patch-ahead 1  patch-ahead 2 patch-ahead 3) [
   set tipo "pared"
   set pcolor gray - 1
  ]
end
;-----------------------------------
; PATCHES
; ----------------------------------
to colorear
  ask patches with [tipo = "piso"] [
    set pcolor gray + length interesados
  ]
end

;-----------------------------------
; PASAJEROS
; ----------------------------------

to-report puerta-aleatoria []
  let estacion-cercana (min-one-of estaciones [distance myself])
  let orientacion-actual orientacion-parada
  report (one-of (turtle-set ([puertas-parada] of one-of [paradas-estacion with [orientacion-parada != orientacion-actual]] of estacion-cercana)))
end

to-report obstaculo [patches-en-cuenta]
  ; Retorna si hay obstaculos en todas las baldosas que se estan teniendo en cuenta
  ; Un obstaculo es otro pasajero o una baldosa que no sea piso
  report (count patches-en-cuenta with [tipo != "piso"]) + (count pasajeros-on (patches-en-cuenta with [tipo = "piso"])) >= (count patches-en-cuenta)
end

to direccionar
  ; Direcciona al pasajero respecto a su puerta-destino
  ; y ademas redondea el valor a un multiplo de 90
  face puerta-destino
  set heading (round (heading / 90)) * 90
end

; Las siguientes funciones (reporters) devuelven las baldosas correspondientes
; dependiendo de que pasajero los llame
to-report patch-enfrente
  report patch-ahead 1
end

to-report patch-derecha
  report patch-at-heading-and-distance (heading + 90) 1
end

to-report patch-izquierda
  report (patch-at-heading-and-distance (heading - 90) 1)
end

to-report patch-diagonal-derecha
  report patch-at-heading-and-distance (heading + 45) 1
end

to-report patch-diagonal-izquierda
  report patch-at-heading-and-distance (heading - 45) 1
end

to regla-1 [probabilidad]
  ;; Moverse hacia en frente
  let enfrente patch-enfrente
  let en-cuenta (patch-set enfrente)
  if (random-float 1 < probabilidad) and (not obstaculo en-cuenta) [
    ask (patch-set enfrente) with [tipo = "piso"] [
       set interesados lput myself interesados
      ]
  ]
  set decidido true
end

to regla-2 [probabilidad]
  ;; estan ocupados enfrente y derecha y se mueve a la izquierda que esta desocupada
  let enfrente patch-enfrente
  let izquierda patch-izquierda
  let derecha patch-derecha
  let en-cuenta (patch-set enfrente derecha)
  if (random-float 1 < probabilidad) and (obstaculo en-cuenta) and (not obstaculo (patch-set izquierda)) [
    ask (patch-set izquierda) with [tipo = "piso"] [
      set interesados lput myself interesados
    ]
  ]
  set decidido true
end

to regla-3 [probabilidad]
  ;; estan ocupados enfrente e izquierda, y se mueve a la derecha que esta desocupada
  let enfrente patch-enfrente
  let izquierda patch-izquierda
  let derecha patch-derecha
  let en-cuenta (patch-set enfrente izquierda)
  if (random-float 1 < probabilidad) and (obstaculo en-cuenta) and (not obstaculo (patch-set derecha)) [
    ask (patch-set derecha) with [tipo = "piso"] [
      set interesados lput myself interesados
    ]
  ]
  set decidido true
end

to regla-4 [probabilidad]
  ;; estan ocupados enfrente y diagonal derecha, y se mueve a diagonal izquierda que esta desocupada
  let enfrente patch-enfrente
  let diagonal-izquierda patch-diagonal-izquierda
  let diagonal-derecha patch-diagonal-derecha

  let en-cuenta (patch-set enfrente diagonal-derecha)
  if (random-float 1 < probabilidad) and (obstaculo en-cuenta) and (count pasajeros-on diagonal-izquierda) = 0 [
    ask (patch-set diagonal-izquierda) with [tipo = "piso"] [
      set interesados lput myself interesados
    ]
  ]
  set decidido true
end

to regla-5 [probabilidad]
  ;; estan ocupados enfrente y diagonal izquierda, y se mueve a diagonal derecha que esta desocupada
  let enfrente patch-enfrente
  let diagonal-izquierda patch-diagonal-izquierda
  let diagonal-derecha patch-diagonal-derecha
  let en-cuenta (patch-set enfrente diagonal-izquierda)
  if (random-float 1 < probabilidad) and (obstaculo en-cuenta) and (not obstaculo (patch-set diagonal-derecha)) [
    let paso (patch-set diagonal-derecha) with [tipo = "piso"]
    if (paso != nobody) [
      ask paso [
        set interesados lput myself interesados
      ]
    ]
  ]
  set decidido true
end

to regla-6 [probabilidad]
  ; Esta ocupado enfrente y desocupadas ambas diagonales, elige una aleatoria
  let enfrente patch-enfrente
  let diagonal-izquierda patch-diagonal-izquierda
  let diagonal-derecha patch-diagonal-derecha
  let en-cuenta (patch-set diagonal-izquierda diagonal-derecha)
  if en-cuenta != nobody [
    if (random-float 1 < probabilidad) and (not obstaculo en-cuenta) and (count pasajeros-on enfrente) = 1 [
      let paso en-cuenta with [tipo = "piso" and count pasajeros-here = 0 ]
      if paso != nobody [
        ask one-of en-cuenta [

          set interesados lput myself interesados
        ]
      ]
    ]
  ]
  set decidido true
end

to regla-7 [probabilidad]
  ; Esta ocupado enfrente y desocupados ambos lados, elige uno aleatorio
  let enfrente patch-enfrente
  let izquierda patch-izquierda
  let derecha patch-derecha
  let en-cuenta (patch-set izquierda derecha)
  if (random-float 1 < probabilidad) and (obstaculo en-cuenta) = 0 and (count pasajeros-on enfrente) = 1 [
    ask one-of en-cuenta [
      set interesados lput myself interesados
    ]
  ]
  set decidido true
end

to regla-8 [probabilidad]
  ; Todos estan ocupados, se elige entre cambiar con alguno o quedarse donde esta
  let enfrente patch-enfrente
  let izquierda patch-izquierda
  let derecha patch-derecha
  let diagonal-izquierda patch-diagonal-izquierda
  let diagonal-derecha patch-diagonal-derecha
  let en-cuenta (patch-set enfrente derecha izquierda diagonal-izquierda diagonal-derecha)
  ;show en-cuenta
  ;ask en-cuenta [show pasajeros-here]
  ;show (count pasajeros-on en-cuenta)
  if (random-float 1 < 0.5) and (obstaculo en-cuenta)  [
    let propio patch-here
    let paso one-of en-cuenta with [tipo = "piso" and count pasajeros-here > 0]
    if paso != nobody [
      ask paso [
        set interesados lput myself interesados
        let elegido one-of pasajeros-here
        ask elegido [
          set decidido true
        ]
        ask propio [
          set interesados lput elegido interesados
        ]
      ]
    ]
  ]
  set decidido true
end

to regla-9 [probabilidad]
  ; Se mueve a una posicion aleatoria vacia, si la hay
  let enfrente patch-enfrente
  let izquierda patch-izquierda
  let derecha patch-derecha
  let diagonal-izquierda patch-diagonal-izquierda
  let diagonal-derecha patch-diagonal-derecha
  let en-cuenta (patch-set enfrente derecha izquierda diagonal-izquierda diagonal-derecha) with [tipo = "piso" and count pasajeros-here = 0]
  if (count en-cuenta) > 1 [
    ask one-of en-cuenta  [
      set interesados lput myself interesados
    ]
  ]
  set decidido true
end

to resolver-conflictos
  ; Cuando hay más de un interesado en moverse a una baldosa se elige solo uno aleatorio
  ask patches with [tipo = "piso" and length interesados > 1] [
    set interesados (list one-of interesados)
  ]
end

to mover-pasajeros
  ; Mueve a los interesados a las respectivas baldosas
  ask patches with [tipo = "piso" and length interesados > 0][
    let pasajero-viniendo last interesados
    set interesados []
    ask pasajero-viniendo [
      move-to myself
    ]
  ]
  ask pasajeros [
    direccionar
    set decidido false
  ]
end


;----------------------------------
; BUSES
;----------------------------------

; importante
to crear-bus [origen numero-vagones velocidad-bus orientacion paradas-res]
 let bus-principal 0
 ask origen [
    sprout-buses 1 [
      set heading orientacion
      set velocidad velocidad-bus
      set conexion-vagon self
      set bus-principal self
      set cantidad-vagones numero-vagones
      set size 29
      set vagones-bus []
      set paradas-atendidas []
      set paradas-restantes paradas-res
    ]
  ]
  crear-vagones bus-principal numero-vagones bus-principal
end

; importante
to crear-vagones [padre numero-vagones bus-principal]
  let orientacion 90
  let nuevo-vagon 0
  ask [conexion-vagon] of padre [
      hatch-vagones 1 [
        set bus-correspondiente bus-principal
        set nuevo-vagon self
        set heading [heading] of padre
        set velocidad [velocidad] of padre
        set size 58
        let nueva-conexion 0
        hatch-conexiones 1 [
          set size 58
          create-chasis-bus-with myself
          set nueva-conexion self
          back 21
          if numero-vagones <= 1 [
          set hidden? true
        ]
          ask one-of my-links [
            tie
          ]
        ]
       set conexion-vagon nueva-conexion
      ]
    set union nuevo-vagon
  ]
  ask bus-principal [
    set vagones-bus lput nuevo-vagon vagones-bus
  ]
  if numero-vagones > 1 [
    crear-vagones nuevo-vagon (numero-vagones - 1) bus-principal
  ]
end

; importante
to mover [distancia]
  ifelse (is-agent? distancia)
  [move-to distancia][fd distancia]
  let conexion-actual conexion-vagon
  let otro-vagon [union] of conexion-actual
  if is-vagon? otro-vagon [
    ask otro-vagon [
      ask conexion-vagon [
        face conexion-actual
      ]
      mover conexion-actual
    ]
  ]
end
to cambiar-estado [estado-patches-bus]
  let p (patch-set (n-values 7 [v -> patch-at-heading-and-distance (heading - 90) (v - 3)]))
  let bus-actual bus-correspondiente
  ask p [
    let c 0
    while [c < 21] [
      ask patch-at-heading-and-distance [heading] of myself (- c) [
       set tipo estado-patches-bus
        ifelse estado-patches-bus = "calle" [set pcolor black][set pcolor [color] of bus-actual]
        set interesados []
        ifelse estado-patches-bus = "calle"
        [
          ask pasajeros-here [
            create-andando-con-bus-from bus-actual [
              tie
              set hidden? true
            ]
            set tiempo-promedio lput tiempo-destino tiempo-promedio
            set tiempo-destino 0
          ]
          ask bus-actual [
            set cantidad-pasajeros cantidad-pasajeros + [count pasajeros-here] of myself
          ]
        ]
        [
            ask pasajeros-here [
              set puerta-destino puerta-aleatoria
              ask my-links [
                die
              ]
            ]
            ask bus-actual [
            set cantidad-pasajeros cantidad-pasajeros - [count pasajeros-here] of myself
          ]
          ]
      ]
      set c c + 1
    ]
    ]
end

to estacionar
  cambiar-estado "piso"
end

to partir
  cambiar-estado "calle"
end

to conducir
  let proxima-parada last paradas-restantes

  ifelse (estado != "estacionado") [
    let distancia distance proxima-parada
    let ultimo-vagon last vagones-bus
    let distancia-vagones cantidad-vagones * 21
    ifelse distancia < 1.5 [
      set estado "estacionado"
      ask turtle-set vagones-bus [
        estacionar
      ]
      ask proxima-parada [
        set abierta true
        ask turtle-set puertas-parada [
          abrir-puerta
        ]
      ]
    ] [
      ifelse abs(ycor - [ycor] of proxima-parada) > 1 [
        girar towards min-one-of neighbors [distance proxima-parada]
      ][
        girar towards proxima-parada
      ]
      set velocidad velocidad - ( velocidad ^ 2 ) / ( 2 * distancia )
      mover velocidad
    ]
  ][
    set tiempo-estado tiempo-estado + 1
    if tiempo-estado > TiempoEsperaBus [
      set estado "andando"
      ask turtle-set vagones-bus [
        partir
      ]
      ask proxima-parada [
        set abierta false
        ask turtle-set puertas-parada [
          cerrar-puerta
        ]
      ]
      set velocidad VelocidadBuses
      set paradas-restantes fput proxima-parada but-last paradas-restantes
      set paradas-atendidas fput proxima-parada paradas-atendidas
      set tiempo-estado 0
    ]
  ]
end

to girar [angulo]
  let dif abs( angulo - heading)
  if dif <= 45[
    set heading angulo
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
20
16
2033
230
-1
-1
5.0
1
10
1
1
1
0
1
0
1
-200
200
-20
20
1
1
1
ticks
30.0

SLIDER
1242
296
1596
329
densidad
densidad
0
100
44.0
1
1
NIL
HORIZONTAL

BUTTON
1612
260
1750
294
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1612
300
1676
334
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1682
300
1752
334
grabar
;setup\nvid:start-recorder\nvid:record-interface ;; mostrar estado inicial\nrepeat 500\n[ go\n  vid:record-interface]\nvid:save-recording \"prototipo.mp4\"\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
572
256
1222
406
Cantidad de pasajeros en cada lugar
Pasajeros
tiempo
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Buses" 1.0 0 -2674135 true "" "plot (count pasajeros) - cuenta-pasajeros-estacion estacion 0 - cuenta-pasajeros-estacion estacion 21"
"Estacion 1" 1.0 0 -11033397 true "" "plot cuenta-pasajeros-estacion estacion 0"
"Estacion 2" 1.0 0 -13840069 true "" "plot cuenta-pasajeros-estacion estacion 21"

PLOT
272
256
549
406
Tiempo promedio hasta destino
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"promedio-espera" 1.0 0 -11221820 true "" "plot mean tiempo-promedio"

SLIDER
1242
260
1595
293
VelocidadBuses
VelocidadBuses
0
40
33.0
1
1
NIL
HORIZONTAL

SLIDER
1472
336
1594
369
SeguridadPaso
SeguridadPaso
0
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
1236
336
1440
369
TiempoEsperaBus
TiempoEsperaBus
0
100
72.0
1
1
Segundos
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

articulacion
true
1
Rectangle -2674135 false true 130 152 170 262

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

bus
true
1
Rectangle -1184463 true false 167 143 179 146
Rectangle -2674135 true true 120 145 180 150
Rectangle -1184463 true false 121 143 133 145

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

conexion
true
1
Circle -7500403 false false 135 135 30

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

parada
true
0
Circle -7500403 true true 59 59 182
Polygon -16777216 true false 135 195 165 195 165 135 195 135 195 105 105 105 105 135 135 135 135 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
