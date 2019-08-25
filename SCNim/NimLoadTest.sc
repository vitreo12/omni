s.boot;

s.sendMsg(\cmd, "/load_libSine");

{Nim.ar(SinOsc.ar(1).linlin(-1, 1, 50, 500))}.play;

{SinOsc.ar(SinOsc.ar(1).linlin(-1, 1, 50, 500))}.play;

s.quit;