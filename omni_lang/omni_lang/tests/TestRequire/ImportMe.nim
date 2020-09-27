import ../../../omni_lang, macros

#[ use Ah:
    ImportMeImportMe as ImportMeImportMe1
    something as something2 ]#

#expandMacros:
struct Ah:
    a

struct Bubu[T]:
    a T

expandMacros:
    struct ImportMe[T, Y, Z]:
        t Y
        a T
        b Z
        h Bubu[int]
        c Data[Data[Data[int]]]

    #[ struct Normal:
        a ]#

#[ def something(a ImportMe):
    print("something - ImportMe")

def something(a):
    print("something - auto")

def something():
    print("something") ]#

#[ def something[T](a T):
    print("something - Generics") ]#

#[ expandMacros:
    def blah(a ImportMe[float]):
        print("blah - ImportMe") ]#
    
    #[ def blah(a):
        print("blah - auto") ]#

    #[ def blah(a):
        print("blah - ImportMe") ]#

    #[ def blah(a ImportMe[float]):
        print("blah - ImportMe") ]#

#[ def blah(a):
    print("blah - auto")

def blah():
    print("blah") ]#

#[ proc ImportMe_struct_new_inner_test(T : typedesc = typedesc[float], obj_type: typedesc[ImportMe_struct_export[T]], a: T = 0, ugen_auto_mem: ptr OmniAutoMem, ugen_call_type: typedesc[CallType] = InitCall): ImportMe[T] {.inline.} =
    when ugen_call_type is PerformCall:
        {.fatal: "attempting to allocate memory in the \'perform\' or \'sample\' blocks for \'struct ImportMe\'".}
    result = cast[ImportMe[T]](omni_alloc(culong(sizeof(ImportMe_struct_inner[T]))))
    registerChild(ugen_auto_mem, result)
    result.a = a

init:
    a = ImportMe(0)
    #a = ImportMe_struct_new_inner_test(typedesc[float], ImportMe_struct_export[float], 0, ugen_auto_mem, ugen_call_type)
    #a.blah() ]#

#[ init:
    c = Data[Data[Data[int]]](10, 20)
    a = ImportMe[float, int, signal](a=10, h=Bubu[int](), c=c) ]#