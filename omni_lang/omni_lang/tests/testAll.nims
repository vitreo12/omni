import os, system, tables

var errors = newTable[string, string]()

#Path of nimscript file
let current_dir = thisDir()

for kind, file in walkDir(current_dir):
    if kind == pcFile:
        let dirFileExt = file.splitFile().ext
        if dirFileExt == ".omni" or dirFileExt == ".oi" or dirFileExt == ".nim":
            echo "testing: " & $file
            let (output, exitCode) = gorgeEx("nim c \"" & $file & "\"")
            if exitCode != 0:
                echo "error with: " & $file
                errors[file] = file

echo "ERRORS:"
echo errors