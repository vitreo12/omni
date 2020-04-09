# Code structure

Omni files are divided into different block statements. A simple sinusoidal oscillator can be expressed as simply as this:

```nim
ins:  1
outs: 1

init:
    phase = 0.0

sample:
    freq_incr = in1 / samplerate
    out1 = sin(phase * 2 * PI)
    phase = (phase + freq_incr) % 1.0
```

In the previous oscillator example, the ins and outs block define the number of inputs and outputs of the algorithm. The init block defines the initialization of variables whose state is store and preserved in the sample block, which implement the algorithm sample by sample. The in1 and out1 variables are dynamically created by omni to represent the input and output values at the current sample, as described by the ins and outs macros.

More information on all the block types follows in the next docs.


# Syntax

As you might have noticed, declaration of variables in omni doesn't need any keyword. Despite being a strictly statically typed language, all types are inferred by the return type of a given statement. Optionally, types can be explicitly set with this syntax:

```nim
init:
    phase float = 0.0

All variables of standard types, excluding the ones assigned to an instantiation of a struct (more on them later), are modifiable. To declare a non-modifiable variable, declare it with all upper cases:
```

```nim
init:
    PHASE = 0.0
    PHASE = 1.0  # <-- This will error out, trying to modify a constant variable
```

# Keywords

 ```if, elif, else, case, for, while, mod, and, or, not, isnot, is, float, float32, float64, int, int32, int64, def, struct, samplerate, bufsize, ins, outs, in[1..32], out[1..32], init, build, perform, sample, Data, Delay, Buffer, Signal, Signal32, Signal64```
 