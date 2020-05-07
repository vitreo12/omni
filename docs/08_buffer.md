---
layout: page
title: Buffer
---

`Buffer` is a special construct that is implemented on a per-wrapper basis. It doesn't exist as a standalone omni `struct`, but it only works if the wrapper around omni (like [omnicollider](https://github.com/vitreo12/omnicollider) and [omnimax](https://github.com/vitreo12/omnimax)) implement it. Its purpose is to deal with memory allocated from outside of omni, as it's the case with SuperCollider's or Max's own buffers. Check [here](11_writing_wrappers.md) for a description on how to write an omni wrapper (including the `Buffer` interface).

## Buffer methods

These are methods that only work in the `perform` or `sample` blocks. If used in the `init` block, they will yield 0:

1. `length`     : returns the length of the `Buffer`.
2. `size`       : returns the total length of the `Buffer` (length * channels).
3. `chans`      : returns the number of channels of the `Buffer`.
4. `samplerate` : returns the samplerate of the `Buffer`.

## Example

### *MyBuffer.omni*:
```nim
ins 2:
    "buffer"
    "speed" {1, 0.1, 10}

outs: 1

init:
    #One of the ins has to be used in order for omni to point 
    #at the specified external buffer.
    #Here it's been set to the first input, "buffer".
    buffer = Buffer(1)
    phase = 0.0

perform:
    scaled_rate = buffer.samplerate / samplerate
    
    sample:
        out1 = buffer[phase]
        phase += (in2 * scaled_rate)
        phase = phase % float(buffer.len)
```

## SuperCollider
After compiling the omni code with

    omnicollider MyBuffer.omni

the `Buffer` interface will work as a regular SuperCollider Buffer. For example:

```c++
s.waitForBoot({
    b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
    s.sync;
    {MyBuffer.ar(b, 1)}.play
})
```

## Max

**Check omnimax's [readme](https://github.com/vitreo12/omnimax) for more information on the calling syntax of Max objects compiled with omni.**

After compiling the omni code with

    omnimax MyBuffer.omni

the `Buffer` interface will look like so:

<p align="left">
  <img width="559" height="444" src="/images/max_buffer.png">
</p>

<br>

## [Next: 09 - Stdlib: Delay](09_delay.md)