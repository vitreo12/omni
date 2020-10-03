import ../../omni_lang

ins 1:
    freq {440, 1, 20000}

outs 1

def newSineTable(numOfPoints):
    table = Data(numOfPoints)
    for i, entry in table:
        entry = sin(i / (numOfPoints - 1) * TWOPI)
    return table

def newPhasorBank(numOfSines):
    phasorBank = Data(numOfSines)
    return phasorBank

def calcSines(phasorBank, table, numOfSines, points, freq, invertedSampleRate):
    outSample = 0
    loop 1000 i:
        phase = phasorBank[i]
        freqIncr = (freq * (i + 1)) * invertedSampleRate
        tableRead = (phase * (points - 1))
        outSample += table[tableRead]
        #outSample += linear_interp(phase, table[tableRead], table[(int(tableRead + 1) % points)])
        phasorBank[i] = (phase + freqIncr) % 1.0
    return outSample

init:
    POINTS int = 512
    INV_NUM_SINES = 1.0 / 100 
    INV_SAMPLERATE = 1.0 / samplerate
    table = newSineTable(POINTS)
    phasorBank = newPhasorBank(100)

sample:
    out1 = calcSines(phasorBank, table, 100, POINTS, freq, INV_SAMPLERATE) * INV_NUM_SINES
