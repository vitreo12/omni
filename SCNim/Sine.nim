ins 1:
    "freq"

outs 1:
    "sine_out"
 
constructor:
    let sampleRate = 48000.0

    var phase = 0.0
    
    new phase, sampleRate

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