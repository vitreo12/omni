#needed for http stuff
--define:ssl

#smallest binary size with gc none, lto and opt size
--gc:none
--panics:on
--checks:off
--passC:"-flto"
--passL:"-flto"
--opt:size

--define:danger
--objChecks:off
--fieldChecks:off
--rangeChecks:off
--boundChecks:off
--overflowChecks:off
--assertions:off
--stacktrace:off
--linetrace:off
--debugger:off
--lineDir:off
--deadCodeElim:on
--nilchecks:off

--define:release
--excessiveStackTrace:off
