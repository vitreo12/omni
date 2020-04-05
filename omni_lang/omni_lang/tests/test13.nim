import ../../omni_lang
import macros

expandMacros:
    ins 4:
        "freq" {440, 0, 22000}
        {330.0 0.43 10000}
        {0, 1}
        {1.0 2.0}

    outs: 3


#ins 1, "freq" {440, 0, 22000}

#[ 
ins 2:
    "freq"  {440, 0, 22000}
    "phase" {0, 0, 1}

ins 2:
    {440, 0, 22000}
    {0, 0, 1}

ins 2, "freq" {440, 0, 22000}, "phase" {0, 0, 1}

ins 2, {440, 0, 22000}, {0, 0, 1} 
]#