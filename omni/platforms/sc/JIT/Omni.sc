OmniDef {
    
}

Omni : UGen {
    *ar { |freq|
        ^this.multiNew('audio', freq);
    }
}