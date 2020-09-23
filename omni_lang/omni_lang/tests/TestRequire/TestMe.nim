import ../../../omni_lang, macros

use ImportMe:
    #ImportMe as ImportMe1
    something as something1
    blah as blah1

#expandMacros:
init:
    a = ImportMe()
    a.blah1()
    blah1(10)
    blah1()

    a.something1()
    something1(1)
    something1()