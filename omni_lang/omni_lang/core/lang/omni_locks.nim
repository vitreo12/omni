# MIT License
# 
# Copyright (c) 2020-2021 Francesco Cameli
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

import atomics
export atomics

#-d:omni_locks_disable can be defined to not use any locks around setting and getting params / buffers.

#This option is particularly useful in cases like SuperCollider, where everything happens on the same audio thread, 
#as the interface comes directly from UGen inputs (in supernova too).

#If you're sure that your Omni_UGenSetParam / Omni_UGenSetBuffer calls will happen in the same thread as your
#Omni_UGenInit / Omni_UGenPerform ones, this option will remove locks, gaining a little bit of performance.

#param
template acquireParamLock*(lock : var AtomicFlag) : bool =
    when defined(omni_locks_disable_param_lock) or defined(omni_locks_disable):
        true
    else:
        not(lock.testAndSet(moAcquire))

template releaseParamLock*(lock : var AtomicFlag) : void =
    when defined(omni_locks_disable_param_lock) or defined(omni_locks_disable):
        discard
    else:
        lock.clear(moRelease)

template spinParamLock*(lock: var AtomicFlag, body: untyped) : untyped =
    when defined(omni_locks_disable_param_lock) or defined(omni_locks_disable):
        body
    else:
        while acquireParamLock(lock) : discard
        body
        lock.clear(moRelease)

#buffer
template acquireBufferLock*(lock : var AtomicFlag) : bool =
    when defined(omni_locks_disable_buffer_lock) or defined(omni_locks_disable):
        true
    else:
        not(lock.testAndSet(moAcquire))

template releaseBufferLock*(lock : var AtomicFlag) : void =
    when defined(omni_locks_disable_buffer_lock) or defined(omni_locks_disable):
        discard
    else:
        lock.clear(moRelease)

template spinBufferLock*(lock: var AtomicFlag, body: untyped) : untyped =
    when defined(omni_locks_disable_buffer_lock) or defined(omni_locks_disable):
        body
    else:
        while acquireBufferLock(lock) : discard
        body
        lock.clear(moRelease)