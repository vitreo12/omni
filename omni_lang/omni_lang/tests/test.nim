import macros
import ../../omni_lang

#expandMacros:  
ins 1, "freq"
        
#expandMacros:
outs 1:
    "sine_out"

expandMacros:
    struct Phasor[T]:
        phase T

expandMacros:
    struct Something[T, Y]:
        a T      
        b Data[Y]

expandMacros:
    struct SomeOtherStruct[T, Y]:
        phasor    Phasor[T]        
        something Something[T, Y] 

expandMacros:
    def phasorDefault():
        return Phasor.new(0.0)

expandMacros:
    def someProcForPhasor[T](p Phasor[T]):
        p.phase = 0.23

expandMacros:
    init:
        phasor   = phasorDefault()
        something = Something.new(0.0, Data.new(int(samplerate)))
        someOtherStruct = SomeOtherStruct.new(phasor, something)
        someData = Data.new(100, 2) 

        phase = 0.0

        anotherVar = phase

        #new phase, anotherVar

        #oneMore : float
        oneMore = 0.23

        A_CONSTANT float = 0.5

        #print(bufsize, "\n")
        #print(samplerate, "\n")
        
        #build someBuffer
        #build phase, phasor, something, someData, someOtherStruct, someBuffer, someBufferWrapper
        #build:
        #    phase


expandMacros:
    perform:
        frequency signal 
        sine_out  signal  

        sample:
            frequency = in1

            freq = 0.6

            if phase >= 1.0:
                phase = 0.0
            
            #Can still access the var inside the object, even if named the same as another "var" declared variable (which produces a template with same name)
            phasor.phase = 2.3

            i1 = 1
            i2 = 2
        
            somethingArray = something.b

            blabla = someData

            #c = PhasorDefault()

            somethingArray[i1] = phase
            blabla[i1, i2] = phase
            
            #Test fuctions aswell
            someProcForPhasor(phasor)

            #echo omni_ugen.someOtherStruct_let.something.c[0]

            sine_out = cos(phase * 2 * PI) #phase equals to phase_var[]
            
            #This will convert double to float... signal should just be float32 by default. signal64 should be used to assure 64 bits precision.
            out1 = sine_out

            phase += abs(frequency) / (samplerate - 1) #phase equals to phase_var[]

#################
# TESTING SUITE #
#################
#[
var 
    ins_ptr_void  = alloc0(sizeof(ptr cfloat) * 2)      #float**
    in_ptr1_void = alloc0(sizeof(cfloat) * 512)         #float*

    ins_ptr_SC = cast[ptr ptr cfloat](ins_ptr_void)
    ins_ptr = cast[CFloatPtrPtr](ins_ptr_void)
    in_ptr1 = cast[CFloatPtr](in_ptr1_void)

    outs_ptr_void  = alloc0(sizeof(ptr cfloat) * 2)     #float**
    out_ptr1_void = alloc0(sizeof(cfloat) * 512)        #float*
    
    outs_ptr_SC = cast[ptr ptr cfloat](outs_ptr_void)
    outs_ptr = cast[CFloatPtrPtr](outs_ptr_void)
    out_ptr1 = cast[CFloatPtr](out_ptr1_void)

#Dummy
let world = alloc0(sizeof(float))

init_world(world)

#Fill frequency input with 200hz
for i in 0 .. 511:
    in_ptr1[i] = 200.0

ins_ptr[0]  = in_ptr1
outs_ptr[0] = out_ptr1

var omni_ugen = Omni_UGenConstructor(ins_ptr_SC, 512, 48000.0)

Omni_UGenPerform(omni_ugen, cast[cint](512), ins_ptr_SC, outs_ptr_SC)

dealloc(ins_ptr_void)
dealloc(in_ptr1_void)
dealloc(outs_ptr_void)
dealloc(out_ptr1_void)

Omni_UGenFree(omni_ugen)
]#