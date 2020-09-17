import ../../../omni_lang, macros

#[
require:
    "ImportMe.nim" as im
    "ImportMeToo.nim" as imt

let a = when declared(im):
        im.ImportMe()
    else:
        -1

let b = when declared(imt):
        imt.ImportMe()
    else:
        -1

echo (a, b)

require "ImportMe.nim", "ImportMeToo.nim"

let c = when declared(ImportMe):
        ImportMe.ImportMe()
    else:
        -1

let d = when declared(ImportMeToo):
        ImportMeToo.ImportMe()
    else:
        -1

echo (c, d)

let e = when declared(ImportMeToo.ImportMe):
        (ImportMeToo.ImportMe())
    else:
        -1

echo e

dumpAstGen:
    ImportMeToo.ImportMe()
]#

import ImportMe, ImportMeToo

let a = ImportMe.ImportMe()

echo a