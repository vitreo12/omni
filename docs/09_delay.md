---
layout: page
title: Delay
---

`Delay` is a convenient implementation of a linearly interpolated delay line. It provides two methods to be used in the `sample` block: `read` and `write`.

```
ins: input

params: delayTime {0.5, 0, 1}

init:
    myDelay = Delay(samplerate)

sample:
    myDelay.write(input)
    delayVal = myDelay.read(delayTime * samplerate)
    out1 = input + delayVal
```

<br>

## [Next: 10 - Code composition](10_code_composition.md)