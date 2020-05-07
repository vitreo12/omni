---
layout: page
title: ins and outs
---

The `ins` and `outs` blocks express the number of inputs and outputs channels of the algorithm implemented. They always must be expressed at the top of the omni file.

There are different ways to express them:

1. `ins` and `outs` must be expressed with an integer literal value. The colon is optional when not defining any input/output names.

   ```nim
   ins:  3
   outs: 2
   ```

   ```nim
   ins  3
   outs 2
   ```

2. Optionally, it's possible to define names for each of the `ins` or `outs` with literal string values. These will then be used in whatever wrapper of your choice (SuperCollider, Max) to determine the name of the inputs of the created objects. If no names are specified (like in case number 1), omni will export the "in1", "in2", "out1", "out2", etc... names.

   ```nim
   ins 3:
       "freq"
       "phase"
       "amp"
    
   outs 2:
       "firstOutput"
       "secondOutput"
   ```


3. Also, default values, together with minimum and maximum ranges can be specified for each `in`.

   ```nim
   ins 3:
       "freq"  {440, 1, 22000} #3 values = default / min / max
       "phase" {0, 1}          #2 values = min / max
       "amp"   {0.5}           #1 value  = default
   
   outs 2:
       "firstOutput"
       "secondOutput"
   ```

#### _**NOTE:**_ 
If no `ins` or `outs` are defined, they are defaulted to `ins 1` and `outs 1`.

<br>

## [Next: 03 - The init block](03_init.md)