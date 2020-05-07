import ../../omni_lang
import macros

ins 11:
    "upfreq1" {440}
    "upfreq2" {440}
    "upfreq3" {440}
    "upfreq4" {440}
    "downfreq1" {440}
    "downfreq2" {440}
    "downfreq3" {440}
    "downfreq4" {440}
    "low_limit" {0}
    "high_limit" {1}
    "smooth" {0.5}

outs 4

struct Fourse:
    val
    inc
    dec
    adder
    incy
    incym1
    decy
    decym1

struct DCFilter:
    prev_sample
    prev_out

def clip(input, low, high):
    return if input <= low: low elif input >= high: high else: input

def dcblock(dcfilter DCFilter, input):
    filter_fb = 0.995
    out_val = (input - dcfilter.prev_sample) + (filter_fb * dcfilter.prev_out)
    dcfilter.prev_sample = input
    dcfilter.prev_out = out_val
    return out_val

expandMacros:
    init:
        NUM_FOURSES = 4 #could be also set with an argument perhaps
        smoother = 0.0
        inverse_samplerate = 1.0 / samplerate
        fourses = Data(NUM_FOURSES + 2, dataType=Fourse) #need 2 dummy fourse for bounds of first and last fourse
        dcfilters = Data(NUM_FOURSES, dataType=DCFilter)

        #Initialize Datas
        for i in 0..NUM_FOURSES+1:
            fourses[i] = Fourse()
            if i < NUM_FOURSES:
                dcfilters[i] = DCFilter()

sample:
    fourses[1].inc = abs(in1) * 4 * inverse_samplerate
    fourses[2].inc = abs(in2) * 4 * inverse_samplerate
    fourses[3].inc = abs(in3) * 4 * inverse_samplerate
    fourses[4].inc = abs(in4) * 4 * inverse_samplerate

    fourses[1].dec = abs(in5) * -4 * inverse_samplerate
    fourses[2].dec = abs(in6) * -4 * inverse_samplerate
    fourses[3].dec = abs(in7) * -4 * inverse_samplerate
    fourses[4].dec = abs(in8) * -4 * inverse_samplerate
    
    fourses[5].val = in9  #low
    fourses[0].val = in10 #high
    low_limit  = in9
    high_limit = in10

    smoother = clip(in11, 0.0, 1.0)
    smoother = 0.01 - pow(smoother, 0.2) * 0.01

    val = 0.0

    for i in 1..NUM_FOURSES: #1 to 4 (included)
        fourses[i].incy   = (fourses[i].inc * smoother) + (fourses[i].incym1 * (1.0 - smoother))
        fourses[i].incym1 = fourses[i].inc

        fourses[i].decy   = (fourses[i].dec * smoother) + (fourses[i].decym1 * (1.0 - smoother))
        fourses[i].decym1 = fourses[i].decy

        val =  fourses[i].val
        val += fourses[i].adder

        if val <= fourses[i+1].val or val <= low_limit:
            fourses[i].adder = fourses[i].incy
        elif val >= fourses[i-1].val or val >= high_limit:
            fourses[i].adder = fourses[i].decy
        
        fourses[i].val = val
    
    out1 = dcblock(dcfilters[0], fourses[1].val)
    out2 = dcblock(dcfilters[1], fourses[2].val)
    out3 = dcblock(dcfilters[2], fourses[3].val)
    out4 = dcblock(dcfilters[3], fourses[4].val)