type OmniProcess = object of RootObj

type Sine = object of OmniProcess

let a = Sine()

#a() in perform / sample
when typeof(a) is OmniProcess:
    echo "'a' is an OmniProcess"
else:
    echo "nope"