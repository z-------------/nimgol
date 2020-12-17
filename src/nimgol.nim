import strutils
import os
import terminal
import nre

import ./board

# main #

template loop(count = -1; cb: (proc ())): untyped =
  if count == -1:
    while true:
      cb()
  else:
    for _ in 0..<count:
      cb()

template intParam(idx: int; default: int): int =
  if paramCount() >= idx:
    paramStr(idx).parseInt()
  else:
    default

template strParam(idx: int; default: string): string =
  if paramCount() >= idx:
    paramStr(idx)
  else:
    default

when isMainModule:
  # parse args

  let
    fn = strParam(1, "")
    n = intParam(2, -1)
    t = intParam(3, 0)
    oi = intParam(4, 0)
    oj = intParam(5, 0)

  # handle args

  var s = newStepper(terminalWidth() div 2, terminalHeight() - 1)

  if fn.len > 0:
    let f = open(fn, fmRead)
    s.board[].pat(oi, oj, f)
    f.close()

  let sleep =
    if t > 0:
      (proc () = sleep(t))
    else:
      (proc () = discard)
    
  # loop

  echo s
  stdout.hideCursor()
  loop(n) do:
    sleep()
    s.step()
    stdout.cursorUp(s.size.h)
    stdout.setCursorXPos(0)
    echo s
