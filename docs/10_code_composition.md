---
layout: page
title: Code composition
---

Omni encourages the re-use of code. Portions of code, especially the declaration of `structs` and `defs`, can easily be packaged in individual source files that can be included into different projects thanks to the `use` / `require` statements (they are analogous, the choice of the final name will come at a later stage).

## Example 1

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
use "Vector.omni"

ins:  3
outs: 1

init:
    myVec = Vector()

sample:
    myVec.setValues(in1, in2, in3)
    out1 = myVec.x * myVec.y * myVec.z
```

## Example 2

Consider the case where you want to implement an oscillator engine with multiple waveforms. The project can be split up in different files to implement each algorithm, and have a single `Oscillator.omni` file to compile to bring everything together:

### *Sine.omni*

```nim
struct Sine:
    phase
    
def process(sine Sine, freq = 440.0):
    freq_increment = freq / samplerate
    out_value = sin(sine.phase * 2 * PI)
    sine.phase = (sine.phase + freq_increment) % 1.0
    return out_value
```

### *Saw.omni*

```nim
struct Saw:
    phase
    prev_value

def process(saw Saw, freq = 440.0):
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
#equivalent to -> use "Sine.omni", "Saw.omni"
use Sine, Saw

ins 1:
    sineOrSaw {0, 0, 1}
    freq {440, 0.01, 22000}

outs 1

init:
    sine = Sine()
    saw  = Saw()

sample:
    if sineOrSaw < 1:
        out1 = sine.process(freq)
    else:
        out1 = saw.process(freq)
```

## Example 3

In the case of name collisions across modules, this syntax will allow the import of specific `structs` and `defs` with specific names, allowing, for example, multiple implementations with same name of some algorithms to coexist in the same project:

### *One.omni*

```nim
struct Something:
    a

def someFunc():
    return 0.7
```

### *Two.omni*

```nim
struct Something:
    a

def someFunc():
    return 0.3
```

### *Three.omni*

```nim
#equivalent to -> use "One.omni":
use One:
    Something as Something1
    someFunc as someFunc1

#equivalent to -> use "Two.omni":
use Two:
    Something as Something2
    someFunc as someFunc2

init:
    one = Something1()
    two = Something2()

sample:
    out1 = someFunc1() + someFunc2()
```

<br>

## [Next: 11 - Writing wrappers](11_writing_wrappers.md)
