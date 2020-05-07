---
layout: page
title: perform and sample
---

So far, the `sample` block has been used to specify the output of the implemented algorithms. There is one more block, the `perform` block, that can be used around the `sample` block. The `perform` block does not operate at the sample level, but at the block level (determined by the vector size of your system). This allows for optimizations in variable declarations and input unpacking (given that, however, the `in1, in2 etc...` constructs, when used in `perform`, will not retrieve values at the sample level, but at the block level). The `out1, out2, etc..` constructs are not available in the perform block.

Here the `in1` and `in2` are unpacked in the sample block. This means that their values are polled once per sample. `in3`, which is unpacked in the `perform` section, on the other hand, is polled once per block.

```nim
ins  3:
    "in1"
    "in2"
    "mix" {0.5, 0, 1}

outs 1

perform:
    mix = in3

    sample:
        out1 = (in1 * (1.0 - mix)) + (in2 * mix)
```

#### _**NOTE:**_ 
The `perform` block is optional. `sample` can be defined on its own. However, if `perform` is defined, the `sample` block must be contained in it.

<br>

## [Next: 05 - Functions: def](05_def.md)