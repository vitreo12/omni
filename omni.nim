#SuperCollider related code
when defined(supercollider):
    import src/sc/sc_alloc/sc_alloc
    export sc_alloc

    import src/sc/sc_data
    export sc_data

    import src/sc/sc_buffer
    export sc_buffer

when defined(puredata):
    discard

when defined(maxmsp):
    discard

#DSL macros
import src/omni_macros
export omni_macros

#print helper
import src/omni_print
export omni_print

#types
import src/omni_types
export omni_types

#math
import math
export math