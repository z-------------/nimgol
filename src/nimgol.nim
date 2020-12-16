import sequtils
import strutils
import os
import sugar
from math import floorMod
import terminal
import nre

const
  Neighborhood = 1  # 8 neighbors
  ChDead = ' '
  ChAlive = '#'

# types #

type
  Cell = uint8
  Board = seq[seq[Cell]]
  Stepper = object
    board: ref Board
    buf: ref Board

template size(board: Board): tuple[w, h: int] =
  (board[0].len, board.len)

template size(s: Stepper): tuple[w, h: int] =
  s.board[].size

proc `$`(board: Board): string =
  board.map(
    row => row.map(
      cell => (if cell == 0: ChDead else: ChAlive)
    ).join(" ")
  ).join("\n")

proc `$`(s: Stepper): string =
  $s.board[]

# constructors #

proc initBoard(board: var Board; w, h: int) =
  board = newSeq[seq[Cell]](h)
  for i in 0..<h:
    board[i] = newSeq[Cell](w)
    for j in 0..<w:
      board[i][j] = 0

# proc newBoard(l: int): Board =
#   initBoard(result, l)

proc newBoardRef(w, h: int): ref Board =
  new[Board](result)
  initBoard(result[], w, h)

proc newStepper(w, h: int): Stepper =
  result.board = newBoardRef(w, h)
  result.buf = newBoardRef(w, h)

# board stuff #

template wrapCoord(i, l: int): int =
  floorMod(i, l)

iterator neighbors(board: Board; i, j: int): Cell =
  var
    offsetI = -Neighborhood
    offsetJ = -Neighborhood
  while true:
    if offsetI != 0 or offsetJ != 0:
      let
        u = wrapCoord(i + offsetI, board.size.h)
        v = wrapCoord(j + offsetJ, board.size.w)
      yield board[u][v]
    offsetJ += 1
    if offsetJ > Neighborhood:
      offsetJ = -Neighborhood
      offsetI += 1
    if offsetI > Neighborhood:
      break

proc neighborCount(board: Board; i, j: int): int =
  for n in board.neighbors(i, j):
    if n == 1:
      result += 1

proc step(s: var Stepper) =
  let (w, h) = s.board[].size
  for i in 0..<h:
    for j in 0..<w:
      let
        cell = s.board[i][j]
        n = s.board[].neighborCount(i, j)
      if cell == 1 and n == 2 or n == 3:
        # Any live cell with two or three live neighbours survives.
        s.buf[i][j] = 1
      elif cell == 0 and n == 3:
        # Any dead cell with three live neighbours becomes a live cell.
        s.buf[i][j] = 1
      else:
        # All other live cells die in the next generation. Similarly, all other dead cells stay dead.
        s.buf[i][j] = 0
  swap(s.board, s.buf)

# cell patterns #

template placeCell(board: var Board; i, j, u, v: int; val: Cell = 1) =
  let
    wI = wrapCoord(i + u, board.size.h)
    wJ = wrapCoord(j + v, board.size.w)
  board[wI][wJ] = val

# template placeCells[T](board: var Board; i, j: int; offsets: array[T, (int, int)]; val: Cell = 1) =
#   for (u, v) in offsets:
#     board.placeCell(i, j, u, v)

template pat(board: var Board; i, j: int; repr: string) =
  var u = 0
  for line in repr.splitLines:
    for (v, c) in line.pairs:
      if c == 'O':
        board.placeCell(i, j, u, v)
    u += 1

template pat(board: var Board; oi, oj: int; f: File) =
  let pat = re"([+-]?\d+),(\w*[+-]?\d+)"
  var
    reprLines = newSeq[string]()
    i, j: int
  for line in f.lines:
    if line.len != 0 and line[0] == '!': continue
    let m = line.match(pat)
    if m.isSome:
      let caps = m.get.captures
      i = caps[0].parseInt
      j = caps[1].parseInt
    else:
      reprLines.add(line)
  board.pat(oi + i, oj + j, reprLines.join("\n"))

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
