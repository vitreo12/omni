import omni

ins 2, "bufnum", "speed"

outs 1

constructor:
    buffer = Buffer.init(input_num = 1)
    phase = 0.0

    #new buffer, phase

perform:
    scaled_rate = buffer.samplerate / samplerate
    
    sample:
        out1 = buffer[phase]
        phase += (in2 * scaled_rate)
        phase = phase mod float(buffer.len)