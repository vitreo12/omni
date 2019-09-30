#nim c --app:lib --gc:none --noMain:on -d:supercollider -d:release -d:danger --checks:off --assertions:off --opt:speed Sine.nim

#The problem with this approach is that it actually imports the modules on every module called..
#nim c --import:math --import:/home/francesco/Sources/NimCollider/dsp_macros.nim --import:/home/francesco/Sources/NimCollider/sc_types.nim --import:/home/francesco/Sources/NimCollider/SC/sc_data.nim  --import:/home/francesco/Sources/NimCollider/SC/sc_buffer.nim --import:/home/francesco/Sources/NimCollider/SC/RTAlloc/rt_alloc.nim --import:/home/francesco/Sources/NimCollider/dsp_print.nim --app:lib --gc:none --noMain -d:supercollider -d:release -d:danger --checks:off --assertions:off --opt:speed --deadCodeElim:on --warning[UnusedImport]:off Sine.nim

#[ import macros
import math
import ../dsp_macros
import ../dsp_print
import ../sc_types

#For rt_alloc/rt_alloc0/rt_realloc/rt_free
import ../SC/RTAlloc/rt_alloc

import ../SC/sc_data
import ../SC/sc_buffer ]#
    
ins 1:
    "freq"

outs 1:
    "sine_out"
 
#expandMacros:
constructor:
    let 
        sampleRate = 48000.0
        #mydata = Data.init(48000)

    var phase = 0.0
    
    new phase, sampleRate#, mydata

perform:
    var 
        frequency : float
        sine_out : float

    sample:
        frequency = in1

        if phase >= 1.0:
            phase = 0.0

        sine_out = cos(phase * 2 * PI) #phase equals to phase_var[]
        
        out1 = sine_out

        phase += abs(frequency) / (sampleRate - 1) #phase equals to phase_var[]