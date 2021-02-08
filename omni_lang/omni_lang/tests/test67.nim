params:
    freq {0, 1, 2}
    something

omni_debug_macros:
    init:
        a = 0

    sample:
        loop:
            loop:
                for i in 0..10:
                    if i < 3:
                        a = 10
                        in1 = 3