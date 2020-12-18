# Package

version       = "0.0.0"
author        = "Zack Guard"
description   = "Conway's Game of Life in Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["nimgol"]


# Dependencies

requires "nim >= 1.4.2"
requires "sdl2 >= 2.0.3"
requires "winim >= 3.6.0"


# Tasks

task release, "Compile for release":
  exec "nimble build -d:release --opt:speed"
