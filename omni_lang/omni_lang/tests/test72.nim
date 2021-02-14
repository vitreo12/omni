params 3
#buffers 4

omni_debug_macros:
    init:
        a = 23
        c = a + params[2] * a + a

        loop(params, i):
            d = params[i] * 2