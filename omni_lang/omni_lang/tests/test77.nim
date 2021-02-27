omni_debug_macros:
    ins:
        freq {default: 440, min: 10, max: 20}

    #[ params:
        freq {default: 440, min: 10, max: 20} ]#

    perform:
        a = freq
        sample:
            out1 = freq