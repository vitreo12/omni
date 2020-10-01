import ../../omni_lang, macros

expandMacros:
    init:
        b = 0

        a = 1

        loop 3 i:
            b = i
            c = 0
            loop 1 y:
                c = y
            
            if b == 0:
                c = 0.23
            
        loop(4, i):
            loop(2, y):
                print i
                print y

        loop(4):
            print 0

        loop 4 i:
            print i

        loop 4:
            print 0

        a = 4

        loop a i:
            print i

        loop a:
            print 0

        loop(a, i):
            print i
        
        loop(a):
            print 0