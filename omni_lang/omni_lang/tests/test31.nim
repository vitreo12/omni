import ../../omni_lang
import macros

ins 5:
    "input"
    "delay_length" {1 0 2}
    "delay_time"   {0.5 0 2}
    "feedback"     {0.5 0 0.9}
    "damping"      {0.5 0 0.9}

outs 1

#expandMacros:
init:
    delay_length = in2 * samplerate
    delay = Delay(delay_length)
    prev_value = 0.0

    build:
        delay
        prev_value

perform:
    delay_time = in3 * samplerate
    feedback   = in4
    damping    = in5

    sample:
        input = in1

        #Read
        delay_value = delay.read(delay_time)

        out1 = delay_value

        #Apply FB and damping
        feedback_value = delay_value * feedback
        write_value = input + feedback_value
        write_value = ((1.0 - damping) * write_value) + (damping * prev_value)

        #Write
        delay.write(write_value)

        #Store filter value for next iteration
        prev_value = write_value