import ../../omni_lang, macros

ins 1

expandMacros:
    def process(variable):
        sample_out = variable
        sample_out += 1.0
        #result = sample_out
        #return Data(10)
        return sample_out


sample:
    out1 = process()