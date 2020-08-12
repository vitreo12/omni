import ../../omni_lang, macros

ins 1

expandMacros:
    def process():
        sample_out = 0
        sample_out += 1.0
        #result = sample_out
        #return Data(10)
        return sample_out

expandMacros:
    sample:
        out1 = process()
        a = 120