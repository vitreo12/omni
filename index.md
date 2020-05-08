---
layout: page
---

<div align="center">
    <img src="/images/omni_logo_text_transparent.png" alt="Omni logo" width="30%" height="30%">
</div>

Omni is a cross-platform DSL (Domain Specific Language) for low level audio programming. 
It aims to be a new, expressive and easy to use programming language to code audio algorithms in.

Omni leverages on nim and C to compile self-contained static or shared libraries that can then be loaded and used anywhere. So far, two wrappers have already been written to compile omni code to [SuperCollider](https://supercollider.github.io/) UGens ([omnicollider](https://github.com/vitreo12/omnicollider)), or [Max 8](https://cycling74.com/) objects ([omnimax](https://github.com/vitreo12/omnimax)).

Also, a basic syntax highlighting [VSCode](https://code.visualstudio.com/) plugin is available by simply looking for [omni](https://github.com/vitreo12/vscode-omni) in the Extensions Marketplace.

## The omni CLI 

Once you've installed omni, the `omni` executable will be placed in your `~/.nimble/bin` folder.

The `omni` executable has one positional argument: the `.omni` or `.oi` file to compile. The argument can also be a list of multiple `omni` files, or a directory. In this latter case, all `.omni` or `.oi` files in the directory will be compiled.

Run `omni -h` to get help on all the available flags.

```
Usage:
    omni [optional-params] [omniFiles: string...]
Options(opt-arg sep :|=|spc):
    -h, --help                               print this cligen-erated help
    --help-syntax                            advanced: prepend,plurals,..
    -n=, --outName=       string   ""        Name for the output library. Defaults to the name of the input file(s) with "lib"      prepended (e.g. "OmniSaw.omni" -> "libOmniSaw.so"). This flag doesn't work for multiple files or directories.
    -o=, --outDir=        string   ""        Output folder. Defaults to the one in of the omni file(s).
    -l=, --lib=           string   "shared"  Build a shared or static library.
    -a=, --architecture=  string   "native"  Build architecture.
    -c=, --compiler=      string   "gcc"     Specify a different C backend compiler to use. Omni supports all of nim's C supported compilers.
    -d=, --define=        strings  {}        Define additional symbols for the intermediate nim compiler.
    -i=, --importModule=  strings  {}        Import additional nim modules to be compiled with the omni file(s).
    -b=, --performBits=   string   "32/64"   Specify precision for ins and outs in the init and perform blocks. Accepted values are "32", "64" or "32/64".
    -e, --exportHeader    bool     true      Export the "omni.h" header file together with the compiled lib.
```

When running the `omni` compiler, the output is either a static or shared library (depending on the `--lib` flag). Along with it, an `omni.h` file (depending on the `--exportHeader` flag) containing all the callable functions in the shared/static library will be exported.

## Documentation

### [01 - Syntax](/docs/01_syntax.md)

### [02 - The ins and outs blocks](/docs/02_ins_outs.md)

### [03 - The init block](/docs/03_init.md)

### [04 - The perform and sample blocks](/docs/04_perform_sample.md)

### [05 - Functions: def](/docs/05_def.md)

### [06 - Custom types: struct](/docs/06_struct.md)

### [07 - Memory allocation: Data](/docs/07_data.md)

### [08 - External memory: Buffer](/docs/08_buffer.md)

### [09 - Stdlib: Delay](/docs/09_delay.md)

### [10 - Code composition](/docs/10_code_composition.md)

### [11 - Writing wrappers](/docs/11_writing_wrappers.md)

### [12 - Nim interoperability](/docs/12_nim_interop.md)