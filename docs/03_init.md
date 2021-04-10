---
layout: page
title: init
---

The `init` block is an optional block that takes care of initializing and storing all variables that might be needed in your algorithm. This is also where the creation of any `struct` (more on them later) should happen.

1. Here `myVariable` is created in the `init` block and passed over the `sample` block (more on it later). `myVariable` can then be accessed and modified in the `sample` block, creating an increasing ramp over one second that goes from 0 to `samplerate` (`samplerate` is a keyword to retrieve the current system samplerate).

    ```
    init:
        myVariable = 0

    sample:
        out1 = myVariable
        myVariable = (myVariable + 1) % samplerate
    ```

2. This is a slightly more complex example that shows the use of memory allocation via the creation of a `Delay` (more on it later). Here is also used the `build` block, which only passes specific variables to `sample`, as `init` passes by default all declared variables in its scope.

    ```
    ins: input
    
    params: delayTime {0.5, 0, 1}

    init:
        myDelay = Delay(samplerate)

        #the build block only passes specific variables to perform/sample
        build:
            myDelay

    sample:
        #write input to the delay line
        myDelay.write(input)

        #input + read of the delay line, using the delayTime param as a delay time control
        outVal = (input * 0.5) + (myDelay.read(delayTime * samplerate) * 0.5)
        
        out1 = outVal
    ```

<br>

## [Next: 04 - The perform and sample blocks](04_perform_sample.md)