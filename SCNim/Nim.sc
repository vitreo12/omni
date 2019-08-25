Nim : UGen {
    *ar { |freq|
        ^this.multiNew('audio', freq);
    }
}