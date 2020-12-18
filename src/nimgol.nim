import strutils
import os
import sdl2 as sdl
import winim/lean

import ./board

const CellSize = 10

# SDL stuff

let
  screenW = GetSystemMetrics(SM_CXSCREEN)
  screenH = GetSystemMetrics(SM_CYSCREEN)
  # screenW = 700
  # screenH = 500
  boardW = (screenW - 100) div CellSize
  boardH = (screenH - 100) div CellSize
  windowW = boardW * CellSize
  windowH = boardH * CellSize

const
  Title = "nimgol"
  WindowFlags = 0
  RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

# global rect used for drawing cells
var rect: sdl.Rect
rect.w = CellSize
rect.h = CellSize

type
  App = ref AppObj
  AppObj = object
    window*: sdl.WindowPtr  # Window pointer
    renderer*: sdl.RendererPtr  # Rendering state pointer

proc initSdl(app: App): bool =
  # Init SDL
  if sdl.init(sdl.InitVideo) != SdlSuccess:
    echo "ERROR: Can't initialize SDL: ", sdl.getError()
    return false

  # Create window
  app.window = sdl.createWindow(
    Title,
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    windowW,
    windowH,
    WindowFlags)
  if app.window == nil:
    echo "ERROR: Can't create window: ", sdl.getError()
    return false

  # Create renderer
  app.renderer = sdl.createRenderer(app.window, -1, RendererFlags)
  if app.renderer == nil:
    echo "ERROR: Can't create renderer: ", sdl.getError()
    return false

  echo "SDL initialized successfully"
  return true

proc exitSdl(app: App) =
  app.renderer.destroyRenderer()
  app.window.destroyWindow()
  sdl.quit()
  echo "SDL shutdown completed"

proc drawBoardRects(app: App; board: ref Board) =
  for i in 0..<board[].size.h:
    for j in 0..<board[].size.w:
      if board[i][j] == 1:
        rect.x = (j * CellSize).int32
        rect.y = (i * CellSize).int32
        discard app.renderer.fillRect(rect.addr)

proc drawBoard(app: App; board: ref Board; prev: ref Board) =
  # draw over old cells
  discard app.renderer.setDrawColor(0x00, 0x00, 0x00, 0xff)
  drawBoardRects(app, prev)

  # current cells
  discard app.renderer.setDrawColor(0xff, 0xff, 0xff, 0xff)
  drawBoardRects(app, board)
  
  # show
  app.renderer.present()

# main #

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
  var done = false
  setControlCHook() do:
    done = true

  # parse args

  let
    fn = strParam(1, "")
    n = intParam(2, -1)
    t = intParam(3, 0)
    oj = intParam(4, 0)
    oi = intParam(5, 0)

  # handle args

  var s = newStepper(boardW, boardH)

  if fn.len > 0:
    let f = open(fn, fmRead)
    s.board[].pat(oi, oj, f)
    f.close()

  let sleep =
    if t > 0:
      (proc () = sleep(t))
    else:
      (proc () = discard)
  
  # init SDL

  var app = App(window: nil, renderer: nil)
  if not initSdl(app):
    stderr.writeLine("Failed to initialize SDL")
    quit(1)
      
  # loop

  app.drawBoard(s.board, s.buf)
  var c = 0
  while c != n and not done:
    sleep()
    s.step()
    app.drawBoard(s.board, s.buf)
    c += 1
  
  exitSdl(app)
