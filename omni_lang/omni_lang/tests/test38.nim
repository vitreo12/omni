import ../../omni_lang, macros

struct Bubu:
    a

expandMacros:
    init:
        data = Data[Bubu](10)

        l = Data(10)

        for num in l:
            num = 0.23

        for bubu in data:
            bubu = Bubu()

        for i in 0..data.len-1:
            data[i] = Bubu()

        for i, entry in data:
            entry = Bubu(i)

        #for i, bubu in data:
        #    bubu = Bubu()
            
    sample:
        a = data[0]
        for bubu in data:
            for hah in data:
                bubu = a
                hah = a

        for num in l:
            num = 0.23