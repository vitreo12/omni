# MIT License
# 
# Copyright (c) 2020 Francesco Cameli
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

##########
## LANG ##
##########

import omni_lang/core/lang/omni_macros
export omni_macros

#########
## LIB ##
#########

#Allocation
import omni_lang/core/lib/alloc/omni_alloc
export omni_alloc

#Automatic memory management
import omni_lang/core/lib/auto_mem/omni_auto_mem
export omni_auto_mem

#Buffer
import omni_lang/core/lib/buffer/omni_buffer
export omni_buffer

#Data
import omni_lang/core/lib/data/omni_data
export omni_data

#Delay
import omni_lang/core/lib/delay/omni_delay
export omni_delay

#Print
import omni_lang/core/lib/print/omni_print
export omni_print

#Utilities (get samplerate/bufsize)
import omni_lang/core/lib/utilities/omni_utilities
export omni_utilities

#Global init of C functions for Alloc/Print/GetSamplerate/Bufsize
import omni_lang/core/lib/init/omni_init_global
export omni_init_global

#math
import omni_lang/core/lib/math/omni_math
export omni_math

import omni_lang/core/lib/math/omni_tables
export omni_tables

#stdlib
import omni_lang/core/lib/stdlib/omni_stdlib
export omni_stdlib
