# Omni

Omni is a cross-platform DSL (Domain Specific Language) for low level audio programming. 
It aims to be a new, expressive and easy to use programming language to code audio algorithms in.

Omni, by leveraging on [nim]() and C, compiles code to self-contained static or shared libraries, which can then be laded and used anywhere. At the moment, two wrappers have already been written to compile Omni code to [SuperCollider]() UGens ([omnicollider]()), or [Max 8]() objects ([omnimax]()).

Also, a basic syntax highlighting [VSCode](https://code.visualstudio.com/) plugin is available by simply looking for [omni](https://github.com/vitreo12/vscode-omni) in the Extensions Marketplace.