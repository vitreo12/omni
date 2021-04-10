---
layout: page
title: Syntax
---

## Code structure

*Omni* files can have two different extensions: `.omni` or `.oi`.

*Omni* files are divided into different *block* statements. A simple sinusoidal oscillator can be expressed as simply as this:

```
init:
    phase = 0

sample:
    freq_incr = in1 / samplerate
    out1 = sin(phase * TWOPI)
    phase = (phase + freq_incr) % 1
```

The `init` block defines the initialization of variables whose state is store and preserved in the `sample` block, which implement the algorithm sample by sample. The `in1` and `out1` variables are dynamically created by *Omni* to represent the input and output values at the current audio sample.

More information on all the block types follows in the next sections.

**_NOTE:_**

In *Omni*, indentation is mandatory to specify each different block section.

## Variable declaration

As you might have noticed, declaration of variables in *Omni* doesn't need any keyword. Despite being a strictly statically typed language, types are inferred by the return type of a given statement. Optionally, types can be explicitly set with this syntax:

```
init:
    phase float = 0.0
```

For number types, if not specified otherwise, all variables are declared as `float`. In this regards, `int` types are considered 'second class citizens', and need to be explicitly declared.

```
init:
    phase      = 0      #float
    phase2 int = 0      #int
    phase3     = int(0) #int, explicit conversion
    test       = true   #bool, booleans are not affected by this mechanism
```

All variables of standard types, excluding the ones assigned to an instantiation of a `struct` (more on them later), are modifiable. To declare a constant variable, declare it with all upper cases:


```
init:
    PHASE = 0.0
    PHASE = 1.0  # <-- This will error out, trying to modify a constant variable
```

The `:=` operator can be used to declare aliases. This will be more useful later when talking about `structs`:

```
init:
    a = 100
    b := a  #b will be an alias to a
```

## Function calls

The syntax to call functions, `defs` (more on them later), can be either of the following:

```
def mySum(a, b):
    return a + b

def myTanh(a):
    return tanh(a)

init:
    a = 1; b = 2    #; merges multiple statements in one liners
    x = mySum(a, b) #standard calling syntax
    y = a.mySum(b)  #alternative "method" calling syntax
    z = myTanh x    #for single argument defs, the command syntax can be used
    print z
```

## Flow control

There are three options for loops in omni: `loop`, `for` or `while` statements:

**_NOTE:_**
The `loop` statement is the preferred way of doing loops in omni, as it's more optimized. When used with integer literals, it automatically unrolls the loops.

```
init:
    #This counts from 0 to 9
    i = 0
    loop 10:
        print(i)
        i += 1

    #This counts from 0 to 9
    loop i 10:
        print(i)  
    
    #Same as before
    loop(i, 10):
        print(i) 

    #This counts from 0 to 10
    loop i 0..10:
        print(i)

    #Same as before
    loop(i, 0..10):
        print(i)
    
    #This counts from 0 to 9
    loop i 0..<10:
        print(i)

    #Same as before
    loop(i, 0..<10):
        print(i)

    #This counts from 0 to 10
    for i in 0..10:
        print(i)

    #This counts from 0 to 9
    for i in 0..<10:
        print(i)

    #This counts from 0 to 9
    i = 0
    while i < 10:
        print(i)
        i += 1
```

As for conditionals, the standard `if` / `elif` / `else` are provided. Note also that, just as in the *Nim* programming language, it is possible to assign the result of a conditional statement to a variable:

```
params:
    a; b

init:
    if a < b:
        print("a less than b")
    elif a > b:
        print("a more than b")
    else:
        print("equal")

    c = if a < b: a else: b
```

## Keywords

```if, elif, else, case, loop, for, while, mod, and, or, of, not, float, float32, float64, int, int32, int64, def, struct, samplerate, bufsize, ins, outs, in[1..32], out[1..32], params, buffers, init, build, perform, sample, Data, Delay, Buffer, signal, signal32, signal64, sig, sig32, sig64```

**_NOTES:_** 

1. `float` defaults to the bits of your machine. So, on a 64 bit computer, `float` is equal to `float64`
2. `signal` and `sig` are aliases to `float` (`signal32` and `sig32` are aliases to `float32`, `signal64` / `sig64` to `float64`)

<br>

## [Next: 02 - The ins, outs and params blocks](02_ins_outs_params.md)