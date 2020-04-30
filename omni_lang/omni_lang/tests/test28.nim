import ../../omni_lang
import macros

def bubu():
    return 0.5

struct Zu:
    a

struct Bla:
    b Zu

expandMacros:
    def newZu(val):
        return Zu(val)

    def newZuzu():
        return newZu(bubu())

init:
    bla = Bla(newZuZu())
    bla.b = newZu(2)

sample:
    out1 = in1