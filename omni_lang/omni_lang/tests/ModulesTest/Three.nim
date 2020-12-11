import ../../../omni_lang
import macros

#macro t(body : typed) =
#    error astGenRepr body

expandMacros:
    use One:
        someFunc as someFunc1
        Something as Something1

    use Two:
        Something as Something2
        someFunc as someFunc2

init:
    one = Something1()
    two = Something2()

sample:
    out1 = someFunc1() + someFunc2()