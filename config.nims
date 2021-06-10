#generic flags
#--gc:arc
#--define:useMalloc
#--panics:on
#--checks:off
#--passC:"-flto"
#--passL:"-flto"

##danger
#--define:danger
#--objChecks:off
#--fieldChecks:off
#--rangeChecks:off
#--boundChecks:off
#--overflowChecks:off
#--assertions:off
#--stacktrace:off
#--linetrace:off
#--debugger:off
#--lineDir:off
#--deadCodeElim:on
#--nilchecks:off

##release
#--define:release
#--excessiveStackTrace:off
#--opt:speed

#nimcore, needed for omninim
--define:nimcore
