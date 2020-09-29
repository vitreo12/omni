import ../../../omni_lang, macros

struct Dummy:
    a

expandMacros:
    def something(a):
        print("Mh")
    
    def something(a Dummy):
        print("Mhmh")

    def something[T](a T):
        print("Mhmhmh")