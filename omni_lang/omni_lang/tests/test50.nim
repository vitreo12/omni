import ../../omni_lang, macros

expandMacros:
    ins 2

    def blah(one, two):
        c = (one, (one, two)) #c = (float(one), (float(one), float(two)))
        return c
        #return (one, two)  #(float(one), float(two))

    init:
        a = blah(in1 * 2, in2)
        #BUBU = (1, 2)              #(float(1), float(2))
        #ahah (int, float) = (1, 2) #(1, float(2))