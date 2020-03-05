### Buffer implementation spec ###

# Buffer.innerInit*[S : SomeInteger](obj_type : typedesc[Buffer], input_num : S, ugen_inputs : int) : Buffer

# Buffer.get_buffer(buffer : Buffer, fbufnum : float32)
# when defined(multithread_buffer):
#   Buffer.unlock_buffer(buffer : Buffer)

# []
# []=

# Buffer.len()
# Buffer.size()
# Buffer.nchans()
# Buffer.samplerate()