version       = "0.1.0"
author        = "Francesco Cameli"
description   = "omni is a DSL for low-level audio programming."
license       = "MIT"

requires "nim >= 1.0.0"
requires "cligen >= 0.9.41"

#Compiler executable
bin = @["omni"]

#If using "nimble install" instead of "nimble installOmni", make sure omni-lang is still getting installed
before install:
    withDir(getPkgDir() & "/omni_lang"):
        exec "nimble install"

#before/after are BOTH needed for any of the two to work
after install:
    discard
    
#As nimble install, but with -d:release, -d:danger and --opt:speed. Also installs omni_lang.
task installOmni, "Install the omni-lang package and the omni compiler":
    #Build and install the omni compiler executable. This will also trigger the "before install" to install omni_lang
    exec "nimble install --passNim:-d:release --passNim:-d:danger --passNim:--opt:speed"