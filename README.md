# **omni**

`omni` is a DSL for low-level audio programming.

## **Requirements**

1) [nim](https://nim-lang.org/)
2) [git](https://git-scm.com/)

### **Linux**

Refer to your distribution's package manager and make sure you've got installed `nim` and `git`.

### **MacOS**

To install dependencies on MacOS it is suggested to use a package manager like [brew](https://brew.sh/). 
To install `brew`, simply open the `Terminal` app and run this command :
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

After `brew` has been installed, run the following command in the `Terminal` app to install `nim`:

    brew install nim

Then, make sure that the `~/.nimble/bin` directory is set in your shell `$PATH`.
If using bash (the default shell in MacOS), simply edit (or create if it doesn't exist) the `~/.bash_profile` file and add this line to it: 

    export PATH=$PATH:~/.nimble/bin

### **Windows:**

To install dependencies on Windows it is suggested to use a package manager like [scoop](https://scoop.sh/). 
To install `scoop`, simply open `PowerShell` and run this command :
    
    iwr -useb get.scoop.sh | iex

After `scoop` has been installed, run the following command in `PowerShell` to install `nim` and `git`:

    scoop install nim git

## **Installation**

To install `omni` run these commands:

    git clone https://github.com/vitreo12/omni
    
    cd omni

    nimble installOmni

## **Sine oscillator example**

```nim
ins:  1
outs: 1

init:
    phase = 0.0

sample:
    freq_incr = in1 / samplerate
    out1 = sin(phase * 2 * PI)
    phase = (phase + freq_incr) % 1.0
```

## **Usage**

    omni ~/.nimble/pkgs/omni_lang-0.1.0/omni_lang/examples/OmniSaw.omni -o:./

This command will compile an antialiased sawtooth oscillator (part of the examples) to a shared library (`libOmniSaw.so/dylib/dll`), together with a header file (`omni.h`), in the current folder.