import ../../omni_lang
import macros

expandMacros:
    struct Delay[T, Y]:
        mask Y
        increment Y
        data Data[T]

    def newDelay(len int):
        delay_length = nextPowerOfTwo(len)
        data  = Data.new(delay_length)
        mask  = delay_length - 1
        return Delay.new(mask, 0, data)
        
    def read[T, Y](delay Delay[T, Y], delay_time float):
        index = (delay.increment - int(delay_time)) and delay.mask
        return delay.data[index]

    def write[T](delay Delay[T, int], val float):
        delay.data[delay.increment] = val
        delay.increment = (delay.increment + 1) and delay.mask

    def someComplicatedFunc[T, Y](a T, b Y):
        return a * b

    ins 5:
        "in"
        "delay_length"
        "delay_time"
        "fb"
        "mix"

    outs 1

    init:
        delay = newDelay(int(samplerate))

    sample:
        val = in1
        
        delay_val = delay.read(in3)

        something = someComplicatedFunc(10, 231231)

        out1 = (val * (1 - in5)) + (in5 * delay_val)
        
        fb_val = delay_val * in4
        write_val = val + fb_val

        delay.write(write_val)