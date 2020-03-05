import RTAlloc/omni_alloc
import macros

type 
    Phasor_obj*[T : SomeFloat, Y] = object
        phase : T
        somethingElse : Y

    Phasor*[T : SomeFloat, Y] = ptr Phasor_obj[T, Y]
    
proc init*[T : SomeFloat, Y](obj_type : typedesc[Phasor[T, Y]], phase : T, somethingElse : Y) : Phasor[T, Y] = 
    result = cast[Phasor[T, Y]](omni_alloc(cast[culong](sizeof(Phasor_obj[T, Y]))))
    result.phase = phase  
    result.somethingElse = somethingElse 

proc destructor*[T : SomeFloat, Y](obj : Phasor[T, Y]) : void =
    echo "calling Phasor's destructor"

    let obj_cast = cast[pointer](obj)
    if not obj_cast.isNil():
        omni_free(obj_cast)

type 
    PhasorWrap_obj*[T, Y] = object
        phasor : Phasor[T, Y]

    PhasorWrap*[T, Y] = ptr PhasorWrap_obj[T, Y]

proc init*[T, Y](obj_type : typedesc[PhasorWrap[T, Y]], phasor : Phasor[T, Y]) : PhasorWrap[T, Y] = 
    result = cast[PhasorWrap[T, Y]](omni_alloc(cast[culong](sizeof(PhasorWrap_obj[T, Y]))))
    result.phasor = phasor

dumpAstGen:
    proc destructor*[T, Y](obj : PhasorWrap[T, Y]) : void =
        echo "calling PhasorWrap's destructor"

        destructor(obj.phasor)

        let obj_cast = cast[pointer](obj)
        if not obj_cast.isNil():
            omni_free(obj_cast)

dumpAstGen:
    proc OmniDestructor*(ugen : ptr UGen) : void {.exportc: "OmniDestructor".} =
        let ugen_void_cast = cast[pointer](ugen)
        if not ugen_void_cast.isNil():
            omni_free(ugen_void_cast)     

#[ let a = PhasorWrap.init(Phasor.init(0.0, 0.5))

echo a[]

destructor(a) ]#