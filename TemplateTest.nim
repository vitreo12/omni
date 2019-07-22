from macros import expandMacros
import macrosDSP
    
#inputs 2, "freq", "phase"

#[ inputs 2:
    "freq"
    "phase"

inputs:
    2
    "freq"
    "phase" ]#

#expandMacros(inputs(2, "freq", "phase"))

#expandMacros(outputs(2))

#expandMacros(inputs(2))

inputs 2:
    "freq"
    "phase"

outputs 1:
    "audio"

echo ugen_inputs
echo ugen_input_names

echo ugen_outputs
echo ugen_output_names