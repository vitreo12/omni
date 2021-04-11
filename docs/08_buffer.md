---
layout: page
title: Buffer
---

A `Buffer` is a special construct that is implemented on a per-wrapper basis. While it doesn't exist as a standalone omni `struct`, the omni parser knows about its existence. However, the code will only compile if the wrapper around omni (like [omnicollider](https://github.com/vitreo12/omnicollider) and [omnimax](https://github.com/vitreo12/omnimax)) implements it. Its purpose is to deal with memory allocated from outside of *Omni*, as it's the case with SuperCollider's or Max's own buffers. Check [here](11_writing_wrappers.md) for a description on how to write an *Omni* wrapper (including the `Buffer` interface).

To declare `Buffers`, the `buffers` block must be used:

```
buffers:
    myBuffer

sample:
    out1 = myBuffer[0]
```

## Buffer methods

`Buffers` can only be accessed in the `perform` / `sample` blocks.

These methods are provided:

1. `len` / `length`     : returns the length of the `Buffer`.
2. `size`               : returns the total size of the `Buffer` (length * channels).
3. `chans` / `channels` : returns the number of channels of the `Buffer`.
4. `samplerate`         : returns the samplerate of the `Buffer`.
5. `read`               : read at index with linear interpolation
6. `[]` / `[]=`         : read / write at index

## Example

### *MyBuffer.omni*:
```
buffers:
    myBuffer

params:
    speed  {1, 0.1, 10}

init:
    phase = 0.0

perform:
    scaled_rate = myBuffer.samplerate / samplerate

    sample:
        out1  = myBuffer[phase]
        phase = (phase + (speed * scaled_rate)) % myBuffer.len
```

## SuperCollider
After compiling the omni code with

    omnicollider MyBuffer.omni

the `Buffer` interface will work as a regular *SuperCollider Buffer*. For example:

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
  <img width="710" height="472" src="/images/omnimax_buffer.png">
</p>

<br>

## [Next: 09 - Stdlib: Delay](09_delay.md)