params 3
#buffers 4

omni_debug_macros:
    def something:
        #omni_temp_result = 2
        return 0.5

    struct Something:
        samplerate 

    init:
        a = 23
        c = a + params[2] * a + a

        loop(params, i):
            d = params[i] * 2

        a = something() * samplerate
        
        buffer = Something()
        buffer.samplerate = 3

    sample:
        out1 = something()