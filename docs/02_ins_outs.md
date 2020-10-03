---
layout: page
title: ins and outs
---

The `ins` and `outs` blocks express the number of inputs and outputs channels of the algorithm implemented. They always must be expressed at the top of the omni file.

There are different ways to express them:

1. `ins` and `outs` must be expressed with an integer literal value. The colon is optional when not defining any input/output names.

   ```nim
   ins:  3
   outs: 3
   ```

   ```nim
   ins  3
   outs 3
   ```

2. Optionally, it's possible to define names for each of the `ins` or `outs` with either identifiers orliteral string values. These will then have two roles: they will be used in the algorithm to refer to that specific `in`, and they will also be used in whatever wrapper of your choice (SuperCollider, Max) to determine the name of the inputs of the created objects. If no names are specified (like in case number 1), omni will export the "in1", "in2", "out1", "out2", etc... names.

   ```nim
   ins 3:
      freq
      phase
      amp
   
   #Can also be string literals
   outs 3:
      "outFreq"
      "outPhase"
      "outAmp"

   #freq, phase, amp can be accessed in both the init and perform/sample blocks.
   #They will be analogous to in1, in2, in3.
   init:
      print(freq)    # == print(in1)
      print(phase)   # == print(in2)
      print(amp)     # == print(in3)

   sample:
      out1 = freq    # == out1 = in1
      out2 = phase   # == out2 = in2
      out3 = amp     # == out3 = in3
   ```

   #### **_NOTE:_**
   Named `outs` are not supported yet as replacement for `out1`, `out2`, `out[n]`. (You can't do `outFreq = freq` yet)


3. Also, default values, together with minimum and maximum ranges can be specified for each `in`.

   ```nim
   ins 3:
      freq  {440, 1, 22000} #3 values = default / min / max
      phase {0, 1}          #2 values = min / max
      amp   {0.5}           #1 value  = default
   
   outs 3:
      "outFreq"
      "outPhase"
      "outAmp"
   ```

#### **_NOTE:_**
If no `ins` or `outs` are defined, they are defaulted to `ins 1` and `outs 1`.

<br>

## [Next: 03 - The init block](03_init.md)