#Flags to cpp compiler
{.passC: "-O3".}

#If supernova defined, also pass the supernova flag to cpp
when defined(supernova):
    {.passC: "-D SUPERNOVA".}

#cpp file to compile together. Should I compile it ahead and use the link pragma on the .o instead?
{.compile: "SCBuffer.cpp".}

#Wrapping of cpp functions
proc get_buffer_SC(buffer_SCWorld : pointer, fbufnum : cfloat) : pointer {.importc, cdecl.}

when defined(supernova):
    proc unlock_buffer_SC(buf : pointer) : void {.importc, cdecl.}

proc get_float_value_buffer_SC(buf : pointer, index : clong, channel : clong) : cfloat {.importc, cdecl.}

proc set_float_value_buffer_SC(buf : pointer, value : cfloat, index : clong, channel : clong) : void {.importc, cdecl.}

proc get_frames_buffer_SC(buf : pointer) : cint {.importc, cdecl.}

proc get_samples_buffer_SC(buf : pointer) : cint {.importc, cdecl.}

proc get_channels_buffer_SC(buf : pointer) : cint {.importc, cdecl.}

proc get_samplerate_buffer_SC(buf : pointer) : cdouble {.importc, cdecl.}

proc get_sampledur_buffer_SC(buf : pointer) : cdouble {.importc, cdecl.}

import sc_alloc/sc_alloc
import ../lang/omni_print

type
    Buffer_obj = object
        sc_world   : pointer
        snd_buf    : pointer
        bufnum     : float32
        input_num* : int       #need to export it in order to be retrieved with the ins_Nim[buffer.input_num][0] syntax for get_buffer.

    Buffer* = ptr Buffer_obj

const
    exceeding_max_ugen_inputs = "ERROR: Buffer: exceeding maximum number of inputs: %d\n"
    upper_exceed_input_error  = "ERROR: Buffer: input %d out of bounds. Maximum input number is 32.\n"
    lower_exceed_input_error  = "ERROR: Buffer: input %d out of bounds. Minimum input number is 1.\n"

proc innerInit*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S, ugen_inputs : int) : Buffer =
    result = cast[Buffer](rt_alloc(cast[culong](sizeof(Buffer_obj))))
    
    result.sc_world  = get_sc_world()
    result.bufnum    = float32(-1e9)

    #1 should be 0, 2 1, 3 2, etc... 32 31
    result.input_num = int(input_num) - int(1)

    #If these checks fail set to sc_world to nil, which will invalidate the Buffer (the get_buffer_SC would just return null)
    if input_num > ugen_inputs:
        discard printf(exceeding_max_ugen_inputs, ugen_inputs)
        result.sc_world = nil

    elif input_num > 32:
        discard printf(upper_exceed_input_error, input_num)
        result.sc_world = nil

    elif input_num < 1:
        discard printf(lower_exceed_input_error, input_num)
        result.sc_world = nil

#Template which also uses the const ugen_inputs, which belongs to the nim dsp new module. It will string substitute Buffer.init(1) with initInner(Buffer, 1, ugen_inputs)
template new*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S) : untyped =
    innerInit(Buffer, input_num, ugen_inputs) #ugen_inputs belongs to the scope of the dsp module

proc destructor*(obj : Buffer) : void =
    print("Calling Buffer's destructor\n")

    let obj_void = cast[pointer](obj)

    rt_free(obj_void)

#Called at start of perform. If supernova is active, this will also lock the buffer.
proc get_buffer*(buffer : Buffer, fbufnum : float32) : void =
    var bufnum = fbufnum
    if bufnum < 0.0:
        bufnum = 0.0

    #Update buffer pointer only with a new buffer number as input
    if buffer.bufnum != bufnum:
        buffer.bufnum  = bufnum
        buffer.snd_buf = get_buffer_SC(buffer.sc_world, cfloat(bufnum))

#Supernova unlocking
when defined(supernova):
    proc unlock_buffer*(buffer : Buffer) : void =
        unlock_buffer_SC(cast[pointer](buffer.snd_buf))

##########
# GETTER #
##########

#1 channel
proc `[]`*[I : SomeNumber](a : Buffer, i : I) : float32 =
    return get_float_value_buffer_SC(a.snd_buf, clong(i), clong(0))

#more than 1 channel
proc `[]`*[I1 : SomeNumber, I2 : SomeNumber](a : Buffer, i1 : I1, i2 : I2) : float32 =
    return get_float_value_buffer_SC(a.snd_buf, clong(i1), clong(i2))

##########
# SETTER #
##########

#1 channel
proc `[]=`*[I : SomeNumber, S : SomeNumber](a : Buffer, i : I, x : S) : void =
    set_float_value_buffer_SC(a.snd_buf, cfloat(x), clong(i), clong(0))

#more than 1 channel
proc `[]=`*[I1 : SomeNumber, I2 : SomeNumber, S : SomeNumber](a : Buffer, i1 : I1, i2 : I2, x : S) : void =
    set_float_value_buffer_SC(a.snd_buf, cfloat(x), clong(i1), clong(i2))

#########
# INFOS #
#########

#length of each frame in buffer
proc len*(buffer : Buffer) : cint =
    return get_frames_buffer_SC(buffer.snd_buf)

#Returns total size (snd_buf->samples)
proc size*(buffer : Buffer) : cint =
    return get_samples_buffer_SC(buffer.snd_buf)

#Number of channels
proc nchans*(buffer : Buffer) : cint =
    return get_channels_buffer_SC(buffer.snd_buf)

#Samplerate (float64)
proc samplerate*(buffer : Buffer) : cdouble =
    return get_samplerate_buffer_SC(buffer.snd_buf)

#Sampledur (Float64)
proc sampledur*(buffer : Buffer) : cdouble =
    return get_sampledur_buffer_SC(buffer.snd_buf)