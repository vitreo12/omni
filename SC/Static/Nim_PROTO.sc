Nim_PROTO : UGen {
    *ar { |in1|
        ^this.multiNew('audio', in1);
    }
}