version       = "0.1.0"
author        = "Francesco Cameli"
description   = "omni is a DSL for low-level audio programming."
license       = "MIT"

requires "nim >= 1.0.0"
requires "cligen >= 0.9.41"

#Install the whole dir
installDirs = @["omnipkg"]

#If using omni_lang as name, have a single "src" folder with both omni_lang.nim and omni.nim in src/
#srcDir = "src"

#Exec compiler
bin = @["omni"]