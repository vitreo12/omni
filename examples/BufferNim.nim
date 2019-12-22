import omni

ins 2, "bufnum", "speed"

outs 1

constructor:
    buffer = Buffer.init(input_num = 1)
    phase = 0.0

    print(phase)

    new buffer, phase

perform:
    sample:
        out1 = buffer[phase]
        phase += in2
        phase = phase mod float(buffer.len)