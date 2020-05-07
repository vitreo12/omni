---
layout: page
title: Code composition
---

Omni encourages the re-use of code. Portions of code, especially the declaration of `structs` and `defs`, can easily be packaged in individual source files that can be included into different projects thanks to the `import` statement.

### *Vector.omni*:
```nim
struct Vector[X, Y, Z]:
    x X
    y Y
    z Z

def setValues(vec Vector, x, y, z):
    vec.x = x
    vec.y = y
    vec.z = z
```

### *VecTest.omni*:
```nim
import "Vector.omni"

ins:  3
outs: 1

init:
    myVec = Vector(0.0, 0.0, 0.0)

sample:
    myVec.setValues(in1, in2, in3)
    out1 = myVec.x * myVec.y * myVec.z
```

Consider the case where you want to implement an oscillator engine with multiple waveforms. The project can be split up in different files to implement each algorithm, and have a single `Oscillator.omni` file to compile to bring everything together:

### *Sine.omni*

```nim
struct Sine:
    phase #no types specified for struct field, meaning it's defaulted to be `float`
    
def perform(sine Sine, freq_in = 440.0):
    freq_increment = freq_in / samplerate
    out_value = sin(sine.phase * 2 * PI)
    sine.phase = (sine.phase + freq_increment) % 1.0
    return out_value
```

### *Saw.omni*

```nim
struct Saw:
    phase #no types specified for struct fields, meaning they're defaulted to be `float`
    prev_value

def perform(saw Saw, freq_in = 440.0):
    freq = freq_in
    if freq == 0.0:
        freq = 0.01
    
    #0.0 would result in 0 / 0 -> NaN
    if saw.phase == 0.0:
        saw.phase = 1.0

    #BLIT
    n = trunc((samplerate * 0.5) / freq)
    phase_2pi = saw.phase * 2 * PI
    blit = 0.5 * (sin(phase_2pi * (n + 0.5)) / (sin(phase_2pi * 0.5)) - 1.0)

    #Leaky integrator
    freq_over_samplerate = (freq * 2 * PI) / samplerate * 0.25
    out_value = (freq_over_samplerate * (blit - saw.prev_value)) + saw.prev_value
    
    #Update entries in struct
    saw.phase += (freq / (samplerate - 1)) % 1.0
    saw.prev_value = out_value

    return out_value
```

### *Oscillator.omni*

```nim
import "Saw.omni", "Sine.omni"

ins 1:
    "sineOrSaw" {0, 0, 1}
    "freq" {440, 0, 22000}

outs 1

init:
    sine = Sine()  #all float fields are defaulted to 0 if not specifed otherwise
    saw  = Saw()

sample:
    if in1 < 1.0:
        out1 = sine.perform(in1)
    else:
        out1 = saw.perform(in1)
```

<br>

## [Next: 11 - Writing wrappers](11_writing_wrappers.md)