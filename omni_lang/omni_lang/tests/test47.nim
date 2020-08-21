import ../../omni_lang, macros

ins 1

expandMacros:
    def a[T](x T = 0.0) T:
        return a(x) + 1

    def process():
        sample_out = a(1.23) * a(1)
        sample_out += 1.0
        #result = sample_out
        #return Data(10)
        return sample_out

expandMacros:
    sample:
        out1 = process()
        a = 120