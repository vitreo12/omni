#Cpp file to compile together. Should I compile it ahead and use the link pragma on the .o instead?
{.compile: "SCBuffer.cpp".}

#Flags to cpp compiler
{.passC: "-O3".}

#If supernova defined, also pass the supernova flag to cpp
when defined(supernova):
    {.passC: "-D SUPERNOVA".}

#Wrapping of cpp functions
proc get_buffer_SC(buffer_SCWorld : pointer, fbufnum : cfloat) : pointer {.importc.}

when defined(supernova):
    proc unlock_buffer_SC(buf : pointer) : void {.importc.}

proc get_float_value_buffer_SC(buf : pointer, index : clong, channel : clong) : cfloat {.importc.}

proc set_float_value_buffer_SC(buf : pointer, value : cfloat, index : clong, channel : clong) : void {.importc.}

proc get_frames_buffer_SC(buf : pointer) : cint {.importc.}

proc get_samples_buffer_SC(buf : pointer) : cint {.importc.}

proc get_channels_buffer_SC(buf : pointer) : cint {.importc.}

proc get_samplerate_buffer_SC(buf : pointer) : cdouble {.importc.}

proc get_sampledur_buffer_SC(buf : pointer) : cdouble {.importc.}

import RTAlloc/rt_alloc
import ../dsp_print

type
    Buffer_obj = object
        sc_world  : pointer
        snd_buf   : pointer
        bufnum    : float32
        input_num : int

    Buffer = ptr Buffer_obj

const
    upper_exceed_input_error = "ERROR: Buffer: input number out of bounds. Maximum input number is 32.\n"
    lower_exceed_input_error = "ERROR: Buffer: input number out of bounds. Minimum input number is 1.\n"

proc init*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S) : Buffer =
    result = cast[Buffer](rt_alloc(cast[clong](sizeof(Buffer_obj))))
    
    result.sc_world  = get_sc_world()
    result.bufnum    = float32(-1e9)
    result.input_num = int(input_num)

    #Test if world is still same even with buffers..
    print_world()

    #If these checks fail set to sc_world to nil, which will invalidate the Buffer (the get_buffer_SC would just return null)
    if input_num > 32:
        print(upper_exceed_input_error)
        result.sc_world = nil

    elif input_num < 1:
        print(lower_exceed_input_error)
        result.sc_world = nil

#Called at start of perform
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
        unlock_buffer_SC(cast[pointer](buffer))

##########
# GETTER #
##########

#1 channel
proc `[]`*[I : SomeInteger](a : Buffer, i : I) : float32 =
    return get_float_value_buffer_SC(a.snd_buf, cast[clong](i), cast[clong](0))

#more than 1 channel
proc `[]`*[I1 : SomeInteger, I2 : SomeInteger](a : Buffer, i1 : I1, i2 : I2) : float32 =
    return get_float_value_buffer_SC(a.snd_buf, cast[clong](i1), cast[clong](i2))

##########
# SETTER #
##########

#1 channel
proc `[]=`*[I : SomeInteger, S : SomeFloat](a : Buffer, i : I, x : S) : void =
    set_float_value_buffer_SC(a.snd_buf, cast[cfloat](x), cast[clong](i), cast[clong](0))

#more than 1 channel
proc `[]=`*[I1 : SomeInteger, I2 : SomeInteger, S : SomeFloat](a : Buffer, i1 : I1, i2 : I2, x : S) : void =
    set_float_value_buffer_SC(a.snd_buf, cast[cfloat](x), cast[clong](i1), cast[clong](i2))

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