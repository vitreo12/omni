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

template omni_export_io*() : untyped {.dirty.} =
    when defined(omni_export_io):
        import os
        
        #static == compile time block
        static:
            const omni_io_name {.strdefine.} = ""

            #ins
            var text = $omni_inputs & "\n" & $omni_inputs_names_const & "\n" 
            for index, default_val in omni_inputs_defaults_const:
                if omni_inputs == 0 or index == (omni_inputs - 1):
                    text.add($default_val & "\n") 
                    break
                text.add($default_val & ",")

            #params
            text.add($omni_params & "\n" & $omni_params_names_const & "\n")
            for index, default_val in omni_params_defaults_const:
                if omni_params == 0 or index == (omni_params - 1):
                    text.add($default_val & "\n") 
                    break
                text.add($default_val & ",")

            #buffers
            text.add($omni_buffers & "\n" & $omni_buffers_names_const & "\n")
            for index, default_val in omni_buffers_defaults_const:
                if omni_buffers == 0 or index == (omni_buffers - 1):
                    text.add($default_val & "\n") 
                    break
                text.add($default_val & ",")

            #outs
            text.add($omni_outputs & "\n" & omni_outputs_names_const)

            #this has been passed in as command argument with -d:tempDir
            let fullPathToNewFolder = getTempDir()
            if dirExists(fullPathToNewFolder):
                writeFile($fullPathToNewFolder & omni_io_name, text)
