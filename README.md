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

### **Linux**

Refer to your distribution's package manager and make sure you've got `nim` and `git` installed.

### **MacOS**

To install dependencies on MacOS it is suggested to use a package manager like [brew](https://brew.sh/). 

After `brew` has been installed, run the following command in the `Terminal` app to install `nim`:

    brew install nim

Then, make sure that the `~/.nimble/bin` directory is set in your shell `$PATH`.
If using bash (the default shell in MacOS), simply edit (or create if it doesn't exist) the `~/.bash_profile` file and add this line to it: 

    export PATH=$PATH:~/.nimble/bin

### **Windows:**

To install dependencies on Windows it is suggested to use a package manager like [chocolatey](https://community.chocolatey.org/).

After `chocolatey` has been installed, open `PowerShell` as administrator and run this command to install `nim` and `git`:

    choco install nim git -y

## **Installation**

To install `omni`, simply use the `nimble` package manager (it comes bundled with the `nim` installation):

    nimble install omni

## **Usage**

Once you've installed omni, the `omni` executable will be placed in your `~/.nimble/bin` folder.

Run `omni -h` to get help on all the available flags.

When running the `omni` compiler, the output is either a static or shared library (depending on the `--lib` flag). Along with it, an `omni.h` file (depending on the `--exportHeader` flag) containing all the callable functions in the shared/static library will be exported.

    omni ~/.nimble/pkgs/omni-0.3.0/examples/OmniSaw.omni -o:./

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
