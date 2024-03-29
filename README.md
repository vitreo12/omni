<a name="logo" href = "https://vitreo12.github.io/omni">
    <div align="center">
        <img src="omni_logo_text_transparent.png" alt="Omni logo" width="30%" height="30%">
    </div>
</a>

![Build Status (master)](https://github.com/vitreo12/omni/actions/workflows/omni.yml/badge.svg?branch=master)

<a href="https://www.buymeacoffee.com/vitreo12" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Omni is a cross-platform DSL (Domain Specific Language) for low level audio programming. 
It aims to be a new, expressive and easy to use programming language to code audio algorithms in.

Omni leverages nim and C to  compile code to self-contained static or shared libraries that can then be loaded and used anywhere. So far, two wrappers have already been written to compile omni code to [SuperCollider](https://supercollider.github.io/) UGens ([omnicollider](https://github.com/vitreo12/omnicollider)), or [Max 8](https://cycling74.com/) objects ([omnimax](https://github.com/vitreo12/omnimax)).

Also, a basic syntax highlighting [VSCode](https://code.visualstudio.com/) plugin is available by simply looking for [omni](https://github.com/vitreo12/vscode-omni) in the Extensions Marketplace.

## **Requirements**

1) [nim](https://nim-lang.org/)
2) [git](https://git-scm.com/)

Note that `omni` only supports `nim` version 1.6.0. It is recommended to install it via [choosenim](https://github.com/dom96/choosenim).

## **Installation**

To install `omni`, simply use the `nimble` package manager (it comes bundled with the `nim` installation):

    nimble install omni -y

## **Usage**

Once you've installed omni, the `omni` executable will be placed in your `~/.nimble/bin` folder.

Run `omni -h` to get help on all the available flags.

When running the `omni` compiler, the output is either a static or shared library (depending on the `--lib` flag). Along with it, an `omni.h` file (depending on the `--exportHeader` flag) containing all the callable functions in the shared/static library will be exported.

    omni ~/.nimble/pkgs/omni-0.4.2/examples/OmniSaw.omni -o:./

This command will compile an antialiased sawtooth oscillator (part of the examples) to a shared library (`libOmniSaw.so/dylib/dll`), together with a header file (`omni.h`), in the current folder.

## **Sine oscillator example**

`Sine.omni`

```nim
ins:  1
outs: 1

init:
    phase = 0.0

sample:
    incr  = in1 / samplerate
    out1  = sin(phase * TWOPI)
    phase = (phase + incr) % 1.0
```

To compile it, simply run:

    omni Sine.omni

## **Website / Docs**

Check omni's [website](https://vitreo12.github.io/omni).
