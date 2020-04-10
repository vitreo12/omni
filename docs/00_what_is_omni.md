Omni is a cross-platform DSL (Domain Specific Language) for low level audio programming. 
It aims to be a new, expressive and easy to use programming language to code audio algorithms in.

Omni leverages nim and C to  compile code to self-contained static or shared libraries that can then be loaded and used anywhere. So far, two wrappers have already been written to compile Omni code to [SuperCollider](https://supercollider.github.io/) UGens ([omnicollider](https://github.com/vitreo12/omnicollider)), or [Max 8](https://cycling74.com/) objects ([omnimax](https://github.com/vitreo12/omnimax)).

Also, a basic syntax highlighting [VSCode](https://code.visualstudio.com/) plugin is available by simply looking for [omni](https://github.com/vitreo12/vscode-omni) in the Extensions Marketplace.

# The omni CLI 

Once you've installed omni, the `omni` executable will be placed in your `~/.nimble/bin` folder.

Run `omni -h` to get help on all the available flags.

When running the `omni` compiler, the output is either a static or shared library (depending on the `--lib` flag). Along with it, an `omni.h` file (depending on the `--exportHeader` flag) containing all the callable functions in the shared/static library will be exported.