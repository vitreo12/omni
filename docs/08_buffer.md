---
layout: page
title: Buffer
---

`Buffer` is a special construct that is implemented on a per-wrapper basis. While it doesn't exist as a standalone omni `struct`, the omni parser knows about its existence. However, the code will only compile if the wrapper around omni (like [omnicollider](https://github.com/vitreo12/omnicollider) and [omnimax](https://github.com/vitreo12/omnimax)) implements it. Its purpose is to deal with memory allocated from outside of omni, as it's the case with SuperCollider's or Max's own buffers. Check [here](11_writing_wrappers.md) for a description on how to write an omni wrapper (including the `Buffer` interface).

## Buffer methods

These are methods that only work in the `perform` or `sample` blocks. If used in the `init` block, they will yield 0:

1. `len` / `length` : returns the length of the `Buffer`.
2. `size`           : returns the total size of the `Buffer` (length * channels).
3. `chans`          : returns the number of channels of the `Buffer`.
4. `samplerate`     : returns the samplerate of the `Buffer`.

## Example

To access a `Buffer`, one of the `ins` has to be used in order for omni to point at the specified external buffer. In the example below, the first `in`, named `buffer`, is declared as a `Buffer`. This makes the `buffer` variable available in the `sample` block to be accessed and used.

### *MyBuffer.omni*:
```nim
ins 2:
    buffer Buffer
    speed  {1, 0.1, 10}

outs: 1

init:
    phase = 0.0

perform:
    scaled_rate = buffer.samplerate / samplerate
    
    sample:
        out1 = buffer[phase]
        phase += (speed * scaled_rate)
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