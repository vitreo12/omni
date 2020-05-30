import ../../omni_lang, macros

ins 3:
    "in1"
    "bufferOneChannel"
    "bufferTwoChannels"

outs 4

#expandMacros:
struct UselessStruct:
    #buf Buffer
    data Data[float]

#expandMacros:
init:
    data1 = Data(samplerate)
    phasedata1 = 0.0
    data2 = Data(samplerate, 2)
    phasedata2 = 0.0

    useless = UselessStruct(Data(1))