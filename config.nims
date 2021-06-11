#generic flags (arc does not work yet)
--panics:on
--checks:off
--passC:"-flto"
--passC:"-march=native"
--passC:"-mtune=native"
--passL:"-flto"
--passL:"-march=native"
--passL:"-mtune=native"

#danger
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

#release
--define:release
--excessiveStackTrace:off
--opt:speed

#nimcore, needed for omninim
--define:nimcore

#needed for omninim on windows
when declared(windows):
  -cincludes:"$lib/wrappers/libffi/common"
