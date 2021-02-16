ins 1
outs 1

struct Bubu:
    a float

omni_debug_macros:
    init:
        a = Data[Bubu](10)
        loop bubu, a:
            bubu = Bubu()

        loop a:
            _ = Bubu()