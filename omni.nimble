version       = "0.1.0"
author        = "Francesco Cameli"
description   = "omni(m) is a DSL to code audio algorithms at the lowest level."
license       = "MIT"

requires "nim >= 1.0.0"
requires "cligen >= 0.9.41"

installDirs = @["SC", "src", "tests", "deps", "examples"]

#This is a CLI to build SC UGens out of omni code.
bin = @["omnicollider"]

#Task to build the Omni UGen for SuperCollider, allowing for JIT compilation of omni code
