---
layout: page
title: ins and outs
---

## ins and outs

The `ins` and `outs` blocks express the number of audio inputs and outputs channels of the algorithm implemented. They can only be accessed in the `perform` / `sample` blocks.

There are different ways to express them:

1. `ins` and `outs` must be expressed with an integer literal value. The colon is optional when not defining any input/output names.

   ```
   ins:  3
   outs: 3
   ```

   ```
   ins  3
   outs 3
   ```

2. Optionally, it's possible to define names for each of the `ins` or `outs` with either identifiers or literal values. These will then have two roles: they will be used in the algorithm to refer to that specific `in`, and they will also be used in the exported  metadata file (`--exportIO` flag). If no names are specified (like in case number 1), *Omni* will export the `in1`, `in2`, `out1`, `out2`, etc... names.

   ```
   ins 3:
      freq
      phase
      amp
   
   #The number of ins or outs can be inferred by the number of the names
   outs:
      "outFreq"    #string literals are accepted too
      "outPhase"
      "outAmp"

   sample:
      out1 = freq    # == out1 = in1
      out2 = phase   # == out2 = in2
      out3 = amp     # == out3 = in3
   ```

   #### **_NOTE:_**
   Named `outs` are not supported yet as replacement for `out1`, `out2`, `outn`. (You can't do `outFreq = freq` yet)

3. Default values, together with minimum and maximum ranges can be specified for each `in`. While the minimum and maximum ranges are checked in *Omni*, the default value is exported as metadata (`--exportIO` flag).

   ```
   ins 3:
      freq  {440, 1, 22000} #3 values = default / min / max
      phase {0, 1}          #2 values = min / max
      amp   {0.5}           #1 value  = default
   
   outs 3:
      "outFreq"
      "outPhase"
      "outAmp"
   ```

   Explicit naming, can be rearranged in any order:

   ```
   ins:
      freq  {min: 1, max: 22000, default: 440}
   ```

#### **_NOTE:_**
If no `ins` or `outs` are defined, they are declared to highest count in the `perform` / `sample` blocks. More on this feature later.

## params

The `params` block is used to define control-rate parameters. The declaration syntax is similar to an `ins` block, including the possibility of defining default, minimum and maximum values. Contrairly to the `ins` and `outs` blocks, `params` can be also accessed in the `init` block:

```
params:
   freq  {440, 1, 22000} #3 values = default / min / max
   phase {0, 1}          #2 values = min / max
   amp   {0.5}           #1 value  = default  

init:
   print freq
   print phase
   print amp
```

#### **_NOTE:_**
`ins`, `outs` and `params` can also be dynamically accessed with array indexing:

```
   params 5
   ins 5   
   outs 5

   sample:
      loop(i, outs):
         outs[i] = ins[i] * params[i]
```

<br>

## [Next: 03 - The init block](03_init.md)