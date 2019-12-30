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
import omni/core/sc/sc_alloc/sc_alloc
export sc_alloc

import omni/core/sc/sc_data
export sc_data

import omni/core/sc/sc_buffer
export sc_buffer

#Language macros/parsing and utilities
import omni/core/lang/omni_lang
export omni_lang

#math
import math
export math