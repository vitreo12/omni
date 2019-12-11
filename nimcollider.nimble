version       = "0.1.0"
author        = "Francesco Cameli"
description   = "nimcollider is a DSL for SuperCollider. It allows to code audio algorithms at the lowest level."
license       = "MIT"

requires "nim >= 1.0.0"
requires "cligen >= 0.9.41"

installDirs = @["SC", "src", "tests", "deps", "examples"]

#This is a CLI to build UGens out of nimcollider code.
bin = @["supernim"]

#Task to build the Nim UGen for SuperCollider, allowing for JIT compilation of nimcollider code
