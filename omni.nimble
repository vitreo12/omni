version       = "0.1.0"
author        = "Francesco Cameli"
description   = "omni is a DSL for low-level audio programming."
license       = "MIT"

requires "nim >= 1.0.0"
requires "cligen >= 0.9.41"

#Install the whole dir (perhaps ideas and tests should be ignored)
installDirs = @["omnipkg"]

#Compiler executable
bin = @["omni"]

#As nimble install, but with -d:release, -d:danger and --opt:speed
task installRelease, "Install Omni with -d:release, d:danger and --opt:speed":
    exec "nimble install --passNim:-d:release --passNim:-d:danger --passNim:--opt:speed"