#[
#SuperCollider related code
when defined(supercollider):
    discard

#PD related code
when defined(puredata):
    discard

#Max related code
when defined(maxmsp):
    discard
]#

#This imports here are only SuperCollider related. 
#As of now, keep it like this in order to have syntax highlighting 
#on Data and Buffer when doing "import omni".
import src/sc/sc_alloc/sc_alloc
export sc_alloc

import src/sc/sc_data
export sc_data

import src/sc/sc_buffer
export sc_buffer

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