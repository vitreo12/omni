import ../../../omni_lang, macros, os

#[ expandMacros:
    use Bubu
 ]#

try:
    error "ah"
except:
    echo getCurrentExceptionMsg()