---
layout: page
---

<div align="center">
    <img src="/images/omni_logo_text_transparent.png" alt="Omni logo" width="30%" height="30%">
</div>

*Omni* is a cross-platform *DSL* (Domain Specific Language) for low level audio programming. 
It aims to be a new, expressive and easy to use programming language to code audio algorithms in.

*Omni* leverages on *Nim* and *C* to compile self-contained static or shared libraries that can then be loaded and used anywhere. So far, two wrappers have already been written to compile omni code to *[SuperCollider](https://supercollider.github.io/) UGens* (*[OmniCollider](https://github.com/vitreo12/omnicollider)*), or *[Max](https://cycling74.com/) objects* (*[OmniMax](https://github.com/vitreo12/omnimax)*).

Also, a basic syntax highlighting *[VSCode](https://code.visualstudio.com/)* plugin is available by simply looking for *[omni](https://github.com/vitreo12/vscode-omni)* in the Extensions Marketplace.

## The omni CLI 

Once you've installed *Omni*, the `omni` executable will be placed in your `~/.nimble/bin` folder.

The `omni` executable has one positional argument: the `.omni` or `.oi` file to compile. The argument can also be a list of multiple `omni` files, or a directory. In this latter case, all `.omni` or `.oi` files in the directory will be compiled.

Run `omni -h` to get help on all the available flags.

```
Omni - version 0.4.0
(c) 2020-2021 Francesco Cameli

Arguments:
  Omni file(s) or folder.

Options:
  -n=, --outName=       ""        Name for the output library. Defaults to the name of the input file with 'lib'
                                  prepended to it (e.g. 'OmniSaw.omni' -> 'libOmniSaw.so'). This argument does not work
                                  for directories or multiple files.
  -o=, --outDir=        ""        Output folder. Defaults to the one of the Omni file(s) to compile.
  -l=, --lib=           "shared"  Build a 'shared' or 'static' library.
  -a=, --architecture=  "native"  Build architecture.
  -c=, --compiler=      "gcc"     Select a different C backend compiler to use. Omni supports all of Nim's C compilers.
  -b=, --performBits=   "32/64"   Set precision for 'ins' and 'outs' in the perform block. Accepted values are '32',
                                  '64' or '32/64'. Note that this option does not affect Omni's internal floating point
                                  precision.
  -w=, --wrapper=       ""        Specify an Omni wrapper to use.
  -d=, --define=        {}        Define additional symbols for the intermediate Nim compiler.
  -m=, --importModule=  {}        Import additional Nim modules to be compiled with the Omni file(s).
  -p=, --passNim=       {}        Pass additional flags to the intermediate Nim compiler.
  -e, --exportHeader    true      Export the 'omni.h' header file together with the compiled lib.
  -i, --exportIO        false     Export the 'omni_io.txt' file together with the compiled lib.
```

When running the `omni` compiler, the output is either a static or shared library (depending on the `--lib` flag). Along with it, an `omni.h` file (depending on the `--exportHeader` flag) containing all the callable functions in the shared/static library will be exported.

## Documentation

### [01 - Syntax](/docs/01_syntax.md)

### [02 - The ins, outs and params blocks](/docs/02_ins_outs_params.md)

### [03 - The init block](/docs/03_init.md)

### [04 - The perform and sample blocks](/docs/04_perform_sample.md)

### [05 - Functions: def](/docs/05_def.md)

### [06 - Custom types: struct](/docs/06_struct.md)

### [07 - Memory allocation: Data](/docs/07_data.md)

### [08 - External memory: buffers](/docs/08_buffer.md)

### [09 - Stdlib: Delay](/docs/09_delay.md)

### [10 - Code composition](/docs/10_code_composition.md)

### [11 - Writing wrappers](/docs/11_writing_wrappers.md)

### [12 - Nim interoperability](/docs/12_nim_interop.md)