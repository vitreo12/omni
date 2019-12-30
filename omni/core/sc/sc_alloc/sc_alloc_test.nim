import rt_alloc

#To use toHex()
import strutils

################
# TEST SCWORLD #
################

#Should be nil, empty pointer
print_world()

#Emulate some sort of pointer from C, representing SCWorld*
let c = rt_alloc(cast[culong](sizeof(float)))

init_world(c)

#Test if the assignment actually worked
echo cast[int](c).toHex()
print_world()

rt_free(c)

################
# TEST RTALLOC #
################

let a = rt_alloc(cast[culong](sizeof(float)))

rt_free(a)