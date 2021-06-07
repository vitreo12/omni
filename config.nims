##generic flags
##--gc:arc
#--panics:on
#--checks:off
#--passC:"-flto"
#--passL:"-flto"

##danger
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
#--excessiveStackTrace:off
#--opt:speed
#--define:release

