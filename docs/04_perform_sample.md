## perform / sample

So far, the `sample` block has been responsible for determining the output of the implemented algorithms. There is one more block, the `perform` block, that can be used around the `sample` block. The `perform` block does not operate at the sample level, but at the block level (determined by the vector/buffer size of your system). This allows for optimizations in variable declarations and input unpacking (given that, however, the `in1, in2 etc...` constructs will not retrieve values at the sample level, but at the block level). The `out1, out2, etc..` constructs are not available in the perform block.

1. Here the `in1` and `in2` are unpacked in the sample block. This means that their values are polled once per sample. `in3`, which is unpacked in the `perform` section, on the other hand, is polled once per block.

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