#These should work with zigcc everywhere
proc dup(oldfd: FileHandle): FileHandle {.importc, header: "unistd.h".}
proc dup2(oldfd: FileHandle, newfd: FileHandle): cint {.importc, header: "unistd.h".}

template captureStdout*(ident: untyped, body: untyped) =
  # tmp file. Use addr of something to generate a random number
  let tmpFileName = "/tmp/nim_compiler" & $(cast[culong](stdout.unsafeAddr)) & ".txt"
  var stdout_fileno = stdout.getFileHandle()
  # Duplicate stoud_fileno
  var stdout_dupfd = dup(stdout_fileno)
  # Create a new file
  var tmp_file: File = open(tmpFileName, fmWrite)
  # Get the FileHandle (the file descriptor) of your file
  var tmp_file_fd: FileHandle = tmp_file.getFileHandle()
  # dup2 tmp_file_fd to stdout_fileno -> writing to stdout_fileno now writes to tmp_file
  discard dup2(tmp_file_fd, stdout_fileno)
  # Actual code
  body
  # Force flush
  tmp_file.flushFile()
  # Close tmp
  tmp_file.close()
  # Read tmp
  ident = readFile(tmpFileName)
  # Restore stdout
  discard dup2(stdout_dupfd, stdout_fileno)
