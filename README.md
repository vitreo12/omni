# NimCollider

nimcollider is a DSL for SuperCollider. It allows to code audio algorithms at the lowest level.

## Installation

    git clone --recursive https://github.com/vitreo12/NimCollider
    
    cd NimCollider

    nimble install

## CLI: supernim

If you have the .nimble folder in your path, run this:

    supernim ~/.nimble/pkgs/nimcollider-0.1.0/examples/NimSaw.nim -s=true

Otherwise

     ~/.nimble/bin/supernim ~/.nimble/pkgs/nimcollider-0.1.0/examples/NimSaw.nim -s=true