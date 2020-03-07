### Buffer implementation spec ###

# Buffer.innerInit*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S, omni_inputs : int) : Buffer

# template new*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S) : untyped =
#     innerInit(Buffer, input_num, omni_inputs) #omni_inputs belongs to the scope of the dsp module

# Buffer.destructor*(obj : Buffer) : void

# Buffer.get_buffer(buffer : Buffer, fbufnum : float32)
# when defined(multithread_buffer):
#   Buffer.unlock_buffer(buffer : Buffer)

# []
# []=

# Buffer.len()
# Buffer.size()
# Buffer.nchans()
# Buffer.samplerate()