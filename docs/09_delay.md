---
layout: page
title: Delay
---

`Delay` is a convenient implementation of a linearly interpolated delay line. It provides two methods to be used in the `sample` block: `read` and `write`.

```nim
ins 2:
    "input"
    "delayTime" {0.5, 0, 1}

outs 1

init:
    delayLength = samplerate
    myDelay = Delay(delayLength) #length is expressed in samples

sample:
    input = in1
    delayVal = myDelay.read(in2 * samplerate) #delay time is expressed in samples
    out1 = input + delayVal
    myDelay.write(input)
```

<br>

## [Next: 10 - Code composition](10_code_composition.md)