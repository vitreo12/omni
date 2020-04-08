# init

The `init` block takes care of initializing and storing all variables that might be needed in your algorithm. Also, here is where all the creation of any `struct` (more on them later) should happen.


```nim
ins  1
outs 1

init:
    myVariable = 0.0

sample:
    out1 = myVariable
```


```nim
ins 2:
    "input"
    "delayTime" {0.5, 0, 1}

outs 1

init:
    delayLength  = samplerate
    myDelay = Delay.new(delayLength)

    #the build block only passes specific variables to perform/sample
    build:
        myDelay

sample:
    input = in1
    out1 = input + myDelay.read(in2 * samplerate)
    myDelay.write(input)
```