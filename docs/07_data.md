---
layout: page
title: Data
---

`Data` is an in-built `struct` that allows to allocate a certain amount of memory to be used and accessed as an array.

```nim
ins:  2
outs: 1

init:
    dataLength = 1000

    #Allocate an array of 1000 float (Data's default type) elements.
    myData = Data(dataLength)

    #Allocate an array of 1000 int elements.
    myDataInt = Data(dataLength, dataType=int)

    #Allocate a 2 channels array of 1000 float elements.
    myTwoChansData = Data(dataLength, 2)

    #Allocate a 2 channels array of 1000 int elements.
    myTwoChansDataInt = Data(dataLength, 2, int)

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

`Data` can store any user defined `struct`, as long as each entry is also initialized. If they are not, a runtime error will be thrown, and the code will output silence.

```nim
ins  3
outs 1

struct Vector:
    x sig
    y sig
    z sig

init:
    dataLength = 100
    data = Data(dataLength, dataType=Vector)
    
    #Initialize the entries of the Data. 
    #If these are not initialized, a runtime error will be raised
    #and the code will output silence.
    for i in 0..dataLength-1:
        data[i] = Vector()

    #Data entries can also be accessed with the iterator syntax
    for entry in data:
        print(entry.x)
        print(entry.y)
        print(entry.z)
...
```

If using a `Data` as a field in another `struct`, its parametrization must always been specified:

```nim
#Invalid: no concrete instantiation of Data
struct StoreDataInvalid:
    data Data

#Valid: Data[float] (or any other type) is specified
struct StoreDataValid:
    data Data[float]
```

<br>

## [Next: 08 - External memory: Buffer](08_buffer.md)