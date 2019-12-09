(
Server.scsynth;
s.boot;
)

s.sendMsg(\cmd, "/compile_sine");
s.sendMsg(\cmd, "/load_sine");

{Nim.ar(SinOsc.ar(1).linlin(-1, 1, 50, 500))}.play;

//This bugs (because of kr input in Nim.ar(1). It also crashes the whole Nim.
{Nim.ar(Nim.ar(1).linlin(-1, 1, 50, 500))}.play;

//This works
{Nim.ar(Nim.ar(DC.ar(1)).linlin(-1, 1, 50, 500))}.play;

{SinOsc.ar(SinOsc.ar(1).linlin(-1, 1, 50, 500))}.play;

s.scope;

s.quit;