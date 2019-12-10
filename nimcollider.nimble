version       = "0.1.0"
author        = "Francesco Cameli"
description   = "nimcollider is a DSL to generate audio algorithms at the lowest level."
license       = "MIT"

installDirs = @["SC", "src", "tests"]

#This is a CLI to build UGens out of nimcollider code.
bin = @["buildUGen"]