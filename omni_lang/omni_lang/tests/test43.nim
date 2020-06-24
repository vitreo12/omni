import ../../omni_lang, macros

def something():
    return Data()

#expandMacros:
init:
    a = 1
    b int = 0
    c = int(0.0)
    d = 0.0
    e = something()
    f int = e.len * 4
    g int
    l = true

    CONST int = 1

    if d == CONST:
        print("hello")
    
    if d != CONST:
        print("hello")

    if d >= CONST:
        print("hello")

    if d <= CONST:
        print("hello")

    if d > CONST:
        print("hello")

    if d < CONST:
        print("hello")

    for i in 0.0..d:
        print("hello")

    for i in 0..d:
        print("hello")

    for i in 0..CONST:
        print("hello")

    for i in 0..10:
        print("hello")
    
    for i in (0.0)..10:
        print("helloe")
    
    for i in 0..132.32:
        print("helloe")

    for i in 0.0..132.32:
        print("helloe")