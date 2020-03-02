import sc_alloc

#To use toHex()
import strutils

################
# TEST SCWORLD #
################

#Should be nil, empty pointer
print_world()

#Emulate some sort of pointer from C, representing SCWorld*
let c = omni_alloc(cast[culong](sizeof(float)))

init_world(c)

#Test if the assignment actually worked
echo cast[int](c).toHex()
print_world()

omni_free(c)

################
# TEST RTALLOC #
################

let a = omni_alloc(cast[culong](sizeof(float)))

omni_free(a)