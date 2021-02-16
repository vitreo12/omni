ins 1
outs 1

omni_debug_macros:
    init:
        a = 4
        
        loop(i, 4):
            print i
        
        loop(i, 3..4): 
            print i
        
        loop i 0 ..< a:
            print i
        
        loop i 0..4:
            print i

        loop i, 4:
            print i

        loop i, 3..4:
            print i
        
        loop 4:
            print _

        loop a:
            b = _
            loop 4:
                print _ + a
            print _