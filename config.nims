#nimcore, needed for omninim
--define:nimcore

#embed source files
--define:omni_embed

#needed for omninim on windows
when defined(windows):
  -cincludes:"$lib/wrappers/libffi/common"

##arch
#when defined(amd64):
#  --passC:"-march=x86-64"
#  --passL:"-march=x86-64"
#  --cpu:amd64
#elif defined(i386): #needs testing
#  --passC:"-march=i386"
#  --passL:"-march=i386"
#  --cpu:i386
#elif defined(arm64): #needs testing
#  --passC:"-march=arm64"
#  --passL:"-march=arm64"
#  --cpu:arm64
#elif defined(arm): #needs testing
#  --passC:"-march=arm"
#  --passL:"-march=arm"
#  --cpu:arm
#else: #default: native build
#  --passC:"-march=native"
#  --passC:"-mtune=native"
#  --passL:"-march=native"
#  --passL:"-mtune=native"

##generic flags
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
