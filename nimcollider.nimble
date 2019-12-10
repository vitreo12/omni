version       = "0.1.0"
author        = "Francesco Cameli"
description   = "nimcollider is a DSL for SuperCollider. It allows to code audio algorithms at the lowest level."
license       = "MIT"

installDirs = @["SC", "src", "tests"]

#This is a CLI to build UGens out of nimcollider code.
bin = @["buildUGen"]

#Task to build the Nim UGen for SuperCollider, allowing for JIT compilation of nimcollider code
