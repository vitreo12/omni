struct Something: a

#struct Something: a = PI

#struct Something: a = PI * 2

#omni_debug_macros:
init:
    data = Data[Data[Something]](2)
    for entry in data:
        for hell in entry:
            hell = Something()

sample: discard