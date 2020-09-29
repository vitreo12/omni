import ../../omni_lang, macros

expandMacros:
    ins 2

    def some(a, b):
        if a > 0:
            return a * b
        if b < 0:
            return a + b

    def blah(one, two): 
        #Untyped:
        #c (int, (int, float)) = (1, (1, 2)) #(int(1), (int(1), float(2)))

        #Typed:
        d = (one, (one, float(two) + int(one))) #(float(one), (float(one), float(two) + int(one)))
        
        #return (c, d)

        h = Data(1)

        #Fix this too, should be typeof (or overload tuple's `[]=` func ??)
        h[0] = int(0)

        d[0] = int(0)
        d[1][0] = int(0)
        
        return d

        #Explicit return!!
        #Convert only if it's some kind of weird float?
        #return (one, int(two))  #(float(one), float(two))
        #return (one, two)

    init:
        a = blah(in1 * 2, in2)

        a[0] = 0.23
       
        z = some(10, int(12))
        j = 123

        d = int(123.12313)
        
        BUBU = (1, 2)              #(float(1), float(2))
        ahah (int, float) = (1, 2) #(int(1), float(2))