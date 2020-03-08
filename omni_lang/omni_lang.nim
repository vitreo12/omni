##########
## LANG ##
##########

import omni_lang/core/lang/omni_macros
export omni_macros

#########
## LIB ##
#########

#Allocation AND Print... 
#Print should be moved to a different module (once no more alloc debug in omni_alloc.nim is needed anymore)
import omni_lang/core/lib/alloc/omni_alloc
export omni_alloc

#Data
import omni_lang/core/lib/data/omni_data
export omni_data

#math
import math
export math