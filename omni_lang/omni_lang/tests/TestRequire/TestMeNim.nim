import ../../../omni_lang

require:
    "ImportMe.nim" as im
    "ImportMeToo.nim" as imt

let a = when declared(im_module_inner):
        im_module_inner.ImportMe()
    else:
        -1

let b = when declared(imt_module_inner):
        imt_module_inner.ImportMe()
    else:
        -1

echo (a, b)

require "ImportMe.nim", "ImportMeToo.nim"

let c = when declared(ImportMe_module_inner):
        ImportMe_module_inner.ImportMe()
    else:
        -1

let d = when declared(ImportMeToo_module_inner):
        ImportMeToo_module_inner.ImportMe()
    else:
        -1

echo (c, d)