ins 5, "input", "delay_length", "delay_time", "feedback", "damping"

outs 1

constructor:
    delay_length = int(in2 * samplerate)
    delay_length_pow = nextPowerOfTwo(delay_length)
    delay_mask = delay_length_pow - 1

    delay_data = Data.init(delay_length_pow)

    phase = 0
    prev_value = 0.0

    new delay_length, delay_length_pow, delay_mask, delay_data, phase, prev_value

def linear_interp(a, x1, x2):
    return x1 + (a * (x2 - x1))

perform:
    float_delay_time = in3 * samplerate
    float_delay_time = if float_delay_time < float(delay_length): float_delay_time else: float(delay_length)
     
    delay_time = int(float_delay_time)
    frac = float_delay_time - float(delay_time)

    feedback = in4
    feedback = if feedback < 0.98: feedback else: 0.98

    damping = in5
    damping = if damping > 0: damping else: 0
    damping = if damping < 0.98: damping else: 0.98

    sample:
        input = in1

        #Read
        index_value  = (phase - delay_time) and delay_mask
        delay_value1 = delay_data[(index_value and delay_mask)]
        delay_value2 = delay_data[((index_value + 1) and delay_mask)]
        delay_value  = linear_interp(frac, delay_value1, delay_value2)

        out1 = delay_value

        #Apply FB and damping
        feedback_value = delay_value * feedback
        write_value    = input + feedback_value
        write_value = ((1.0 - damping) * write_value) + (damping * prev_value)

        #Write
        delay_data[phase] = write_value 

        #Advance reading index and store it for next iteration
        phase = (phase + 1) and delay_mask

        #Store filter value for next iteration
        prev_value = write_value