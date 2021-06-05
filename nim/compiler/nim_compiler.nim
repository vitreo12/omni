
include compiler/nim

#Same as handleCmdLine but without stdin handle and paramCount() == 0 (which triggers help file)
proc nim_compile*(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    supportsStdinFile: false, #it is true here for normal nim
    processCmdLine: processCmdLine
  )
  self.initDefinesProg(conf, "nim_compiler")
  # if paramCount() == 0:
  #   writeCommandLineUsage(conf)
  #   return
  self.processCmdLineAndProjectPath(conf)
  var graph = newModuleGraph(cache, conf)
  if not self.loadConfigsAndRunMainCommand(cache, conf, graph): return
  mainCommand(graph)
  if conf.hasHint(hintGCStats): echo(GC_getStatistics())
  #echo(GC_getStatistics())
  if conf.errorCounter != 0: return
  when hasTinyCBackend:
    if conf.cmd == cmdRun:
      tccgen.run(conf, conf.arguments)
  if optRun in conf.globalOptions:
    let output = conf.absOutFile
    case conf.cmd
    of cmdCompileToBackend:
      var cmdPrefix = ""
      case conf.backend
      of backendC, backendCpp, backendObjc: discard
      of backendJs: cmdPrefix = findNodeJs() & " "
      else: doAssert false, $conf.backend
      execExternalProgram(conf, cmdPrefix & output.quoteShell & ' ' & conf.arguments)
    of cmdDoc, cmdRst2html:
      if conf.arguments.len > 0:
        # reserved for future use
        rawMessage(conf, errGenerated, "'$1 cannot handle arguments" % [$conf.cmd])
      openDefaultBrowser($output)
    else:
      # support as needed
      rawMessage(conf, errGenerated, "'$1 cannot handle --run" % [$conf.cmd])
