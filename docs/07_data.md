# Data

`Data` is an in-built kind of `struct` that allows to allocate a certain amount of memory to be used and accessed as an array.

```nim
ins:  2
outs: 1

init:
    dataLength = 1000

    #Allocate an array of 1000 float (Data's default type) elements.
    myData = Data.new(dataLength)

    #Allocate an array of 1000 int elements.
    myDataInt = Data.new(dataLength, dataType=int)

    #Allocate a 2 channels array of 1000 float elements.
    myTwoChansData = Data.new(dataLength, 2)

    #Allocate a 2 channels array of 1000 int elements.
    myTwoChansDataInt = Data.new(dataLength, 2, int)

    readIndex = 0

sample:
    #Assign new value
    myData[readIndex] = in1

    #Read value
    value = myData[readIndex]

    #Assign value to first/second channel
    myTwoChansData[0, readIndex] = in1
    myTwoChansData[1, readIndex] = in2

    #Read value1 from first channel and value2 from second
    value1 = myTwoChansData[0, readIndex]
    value2 = myTwoChansData[1, readIndex]

    #Mix them at output
    out1 = (value1 * 0.5) + (value2 * 0.5)

    readIndex = (readIndex + 1) % dataLength
```