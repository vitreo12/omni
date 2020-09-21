import ../../../omni_lang, macros

expandMacros:
    def hello(a, b, c):
        return 0

    def hello[T](a T):
        return a