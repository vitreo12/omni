import ../../../omni_lang

ins 1
outs 1

struct Bubu:
    x

def newBubu():
    return Bubu()

def operate(bubu Bubu, bubu2 Bubu):
    print(bubu.x)
    print(bubu2.x)

init:
    data = Data(10, dataType=Bubu)

    for i in 0..9:
        data[i] = Bubu(i)

    for entry in data:
        print(entry.x)

    k = newBubu()

    print(Bubu().x)
    operate(k, Bubu())
    k.operate(Bubu())