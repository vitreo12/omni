(
Server.scsynth;
s.boot;
)

s.sendMsg(\cmd, "/compile_sine");
s.sendMsg(\cmd, "/load_sine");

{Nim.ar(SinOsc.ar(1).linlin(-1, 1, 50, 500))}.play;

{SinOsc.ar(SinOsc.ar(1).linlin(-1, 1, 50, 500))}.play;

s.scope;

s.quit;