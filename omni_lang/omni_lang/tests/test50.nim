import ../../omni_lang, macros

expandMacros:
    ins 2

    def some(a, b):
        return a * b

    def blah(one, two):     
        #Untyped:
        #c (int, (int, float)) = (1, (1, 2)) #(int(1), (int(1), float(2)))

        #Typed:
        c = (one, (one, float(two) + int(one))) #(float(one), (float(one), float(two)))
        
        return c
        
        #return (one, two)  #(float(one), float(two))

    init:
        a = blah(in1 * 2, in2)
        
        z = some(10, int(12))
        j = 123
        
        #BUBU = (1, 2)              #(float(1), float(2))
        #ahah (int, float) = (1, 2) #(int(1), float(2))