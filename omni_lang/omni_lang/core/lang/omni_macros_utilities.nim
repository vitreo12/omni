import macros

proc typedToUntyped*(code_block : NimNode) : NimNode {.inline, compileTime.} =
    return parseStmt(code_block.repr())