import omni

ins 2, "bufnum", "speed"

outs 1

init:
    buffer = Buffer.new(input_num = 1)
    phase = 0.0

    #build buffer, phase

perform:
    scaled_rate = buffer.samplerate / samplerate
    
    sample:
        out1 = buffer[phase]
        phase += (in2 * scaled_rate)
        phase = phase mod float(buffer.len)