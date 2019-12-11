ins 1:
    "freq"

outs 1:
    "sine_out"
 
constructor:
    var phase = 0.0
    
    new phase

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

        phase += abs(frequency) / (samplerate - 1) #phase equals to phase_var[]