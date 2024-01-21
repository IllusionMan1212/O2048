package zephr

import "core:fmt"
import "core:log"
import "core:os"

import x11 "vendor:x11/xlib"
import gl "vendor:OpenGL"
import "vendor:stb/image"

import "../glx"
import "../xcursor"

Cursor :: enum {
  ARROW,
  IBEAM,
  CROSSHAIR,
  HAND,
  HRESIZE,
  VRESIZE,
  DISABLED,
}

EventType :: enum {
  UNKNOWN,
  KEY_PRESSED,
  KEY_RELEASED,
  MOUSE_BUTTON_PRESSED,
  MOUSE_BUTTON_RELEASED,
  MOUSE_SCROLL,
  MOUSE_MOVED,
  WINDOW_RESIZED,
  WINDOW_CLOSED,
}

MouseButton :: enum {
  BUTTON_LEFT,
  BUTTON_RIGHT,
  BUTTON_MIDDLE,
  BUTTON_BACK,
  BUTTON_FORWARD,
  BUTTON_3,
  BUTTON_4,
  BUTTON_5,
  BUTTON_6,
  BUTTON_7,
}

MouseScrollDirection :: enum {
  UP,
  DOWN,
}

KeyMod :: bit_set[KeyModBits; u16]
KeyModBits :: enum {
  NONE        = 0,

  LEFT_SHIFT  = 1,
  RIGHT_SHIFT = 2,
  SHIFT       = 3,

  LEFT_CTRL   = 4,
  RIGHT_CTRL  = 5,
  CTRL        = 6,

  LEFT_ALT    = 7,
  RIGHT_ALT   = 8,
  ALT         = 9,

  LEFT_META   = 10,
  RIGHT_META  = 11,
  META        = 12,

  CAPS_LOCK   = 13,
  NUM_LOCK    = 14,
}

Scancode :: enum {
  NULL = 0,

  A = 4,
  B = 5,
  C = 6,
  D = 7,
  E = 8,
  F = 9,
  G = 10,
  H = 11,
  I = 12,
  J = 13,
  K = 14,
  L = 15,
  M = 16,
  N = 17,
  O = 18,
  P = 19,
  Q = 20,
  R = 21,
  S = 22,
  T = 23,
  U = 24,
  V = 25,
  W = 26,
  X = 27,
  Y = 28,
  Z = 29,

  KEY_1 = 30,
  KEY_2 = 31,
  KEY_3 = 32,
  KEY_4 = 33,
  KEY_5 = 34,
  KEY_6 = 35,
  KEY_7 = 36,
  KEY_8 = 37,
  KEY_9 = 38,
  KEY_0 = 39,

  ENTER = 40,
  ESCAPE = 41,
  BACKSPACE = 42,
  TAB = 43,
  SPACE = 44,

  MINUS = 45,
  EQUALS = 46,
  LEFT_BRACKET = 47,
  RIGHT_BRACKET = 48,
  BACKSLASH = 49,
  NON_US_HASH = 50,
  SEMICOLON = 51,
  APOSTROPHE = 52,
  GRAVE = 53,
  COMMA = 54,
  PERIOD = 55,
  SLASH = 56,

  CAPS_LOCK = 57,

  F1 = 58,
  F2 = 59,
  F3 = 60,
  F4 = 61,
  F5 = 62,
  F6 = 63,
  F7 = 64,
  F8 = 65,
  F9 = 66,
  F10 = 67,
  F11 = 68,
  F12 = 69,

  PRINT_SCREEN = 70,
  SCROLL_LOCK = 71,
  PAUSE = 72,
  INSERT = 73,
  HOME = 74,
  PAGE_UP = 75,
  DELETE = 76,
  END = 77,
  PAGE_DOWN = 78,
  RIGHT = 79,
  LEFT = 80,
  DOWN = 81,
  UP = 82,

  NUM_LOCK_OR_CLEAR = 83,
  KP_DIVIDE = 84,
  KP_MULTIPLY = 85,
  KP_MINUS = 86,
  KP_PLUS = 87,
  KP_ENTER = 88,
  KP_1 = 89,
  KP_2 = 90,
  KP_3 = 91,
  KP_4 = 92,
  KP_5 = 93,
  KP_6 = 94,
  KP_7 = 95,
  KP_8 = 96,
  KP_9 = 97,
  KP_0 = 98,
  KP_PERIOD = 99,

  NON_US_BACKSLASH = 100,
  APPLICATION = 101,
  POWER = 102,
  KP_EQUALS = 103,
  F13 = 104,
  F14 = 105,
  F15 = 106,
  F16 = 107,
  F17 = 108,
  F18 = 109,
  F19 = 110,
  F20 = 111,
  F21 = 112,
  F22 = 113,
  F23 = 114,
  F24 = 115,
  EXECUTE = 116,
  HELP = 117,
  MENU = 118,
  SELECT = 119,
  STOP = 120,
  AGAIN = 121,
  UNDO = 122,
  CUT = 123,
  COPY = 124,
  PASTE = 125,
  FIND = 126,
  MUTE = 127,
  VOLUME_UP = 128,
  VOLUME_DOWN = 129,
  KP_COMMA = 133,
  KP_EQUALSAS400 = 134,

  INTERNATIONAL1 = 135,
  INTERNATIONAL2 = 136,
  INTERNATIONAL3 = 137,
  INTERNATIONAL4 = 138,
  INTERNATIONAL5 = 139,
  INTERNATIONAL6 = 140,
  INTERNATIONAL7 = 141,
  INTERNATIONAL8 = 142,
  INTERNATIONAL9 = 143,
  LANG1 = 144,
  LANG2 = 145,
  LANG3 = 146,
  LANG4 = 147,
  LANG5 = 148,
  LANG6 = 149,
  LANG7 = 150,
  LANG8 = 151,
  LANG9 = 152,

  ALT_ERASE = 153,
  SYSREQ = 154,
  CANCEL = 155,
  CLEAR = 156,
  PRIOR = 157,
  ENTER_2 = 158,
  SEPARATOR = 159,
  OUT = 160,
  OPER = 161,
  CLEARAGAIN = 162,
  CRSEL = 163,
  EXSEL = 164,

  KP_00 = 176,
  KP_000 = 177,
  THOUSANDSSEPARATOR = 178,
  DECIMALSEPARATOR = 179,
  CURRENCYUNIT = 180,
  CURRENCYSUBUNIT = 181,
  KP_LEFT_PAREN = 182,
  KP_RIGHT_PAREN = 183,
  KP_LEFT_BRACE = 184,
  KP_RIGHT_BRACE = 185,
  KP_TAB = 186,
  KP_BACKSPACE = 187,
  KP_A = 188,
  KP_B = 189,
  KP_C = 190,
  KP_D = 191,
  KP_E = 192,
  KP_F = 193,
  KP_XOR = 194,
  KP_POWER = 195,
  KP_PERCENT = 196,
  KP_LESS = 197,
  KP_GREATER = 198,
  KP_AMPERSAND = 199,
  KP_DBLAMPERSAND = 200,
  KP_VERTICALBAR = 201,
  KP_DBLVERTICALBAR = 202,
  KP_COLON = 203,
  KP_HASH = 204,
  KP_SPACE = 205,
  KP_AT = 206,
  KP_EXCLAM = 207,
  KP_MEMSTORE = 208,
  KP_MEMRECALL = 209,
  KP_MEMCLEAR = 210,
  KP_MEMADD = 211,
  KP_MEMSUBTRACT = 212,
  KP_MEMMULTIPLY = 213,
  KP_MEMDIVIDE = 214,
  KP_PLUS_MINUS = 215,
  KP_CLEAR = 216,
  KP_CLEARENTRY = 217,
  KP_BINARY = 218,
  KP_OCTAL = 219,
  KP_DECIMAL = 220,
  KP_HEXADECIMAL = 221,

  LEFT_CTRL = 224,
  LEFT_SHIFT = 225,
  LEFT_ALT = 226,
  LEFT_META = 227,
  RIGHT_CTRL = 228,
  RIGHT_SHIFT = 229,
  RIGHT_ALT = 230,
  RIGHT_META = 231,

  /** Not a key. Marks the number of scancodes. */
  ZEPHR_KEYCODE_COUNT = 512,
}

Event :: struct {
  type: EventType,

  using _: struct #raw_union {
    key: struct {
      is_pressed: bool,
      is_repeat: bool,
      scancode: Scancode,
      //code: Keycode,
      mods: KeyMod,
    },
    mouse: struct {
      button: MouseButton,
      using pos: Vec2,
      scroll_direction: MouseScrollDirection,
    },
    window: struct {
      width: u32,
      height: u32,
    },
  }
}

Mouse :: struct {
  using pos: Vec2,
  pressed: bool,
  released: bool,
  button: MouseButton,
}

Window :: struct {
  size: Vec2,
  pre_fullscreen_size: Vec2,
  is_fullscreen: bool,
  non_resizable: bool,
}

Keyboard :: struct {
  mods: KeyMod,
}

Context :: struct {
  window_delete_atom: x11.Atom,
  should_quit: bool,
  screen_size: Vec2,
  window: Window,
  font: Font,
  mouse: Mouse,
  keyboard: Keyboard,
  cursor: Cursor,
  cursors: [Cursor]x11.Cursor,
  ui: Ui,

  /* ZephrKeyboard keyboard; */
  /* XkbDescPtr xkb; */
  /* XIM xim; */
  /* CoreStack(ZephrEvent) event_queue; */
  /* u32 event_queue_cursor; */

  projection: Mat4,
}

@private
PropModeReplace :: 0
@private
XA_ATOM         :: x11.Atom(4)
@private
XA_STRING       :: x11.Atom(31)
@private
XA_CARDINAL     :: x11.Atom(6)
@private
FNV_HASH32_INIT :: 0x811c9dc5
@private
FNV_HASH32_PRIME :: 0x01000193
@private
INIT_UI_STACK_SIZE :: 256

when ODIN_DEBUG {
  @private
  TerminalLoggerOpts :: log.Options{
    .Level,
    .Terminal_Color,
    .Short_File_Path,
    .Line,
  }
} else {
  TerminalLoggerOpts :: log.Default_Console_Logger_Opts
}

COLOR_BLACK   :: Color{0, 0, 0, 255}
COLOR_WHITE   :: Color{255, 255, 255, 255}
COLOR_RED     :: Color{255, 0, 0, 255}
COLOR_GREEN   :: Color{0, 255, 0, 255}
COLOR_BLUE    :: Color{0, 0, 255, 255}
COLOR_YELLOW  :: Color{255, 255, 0, 255}
COLOR_MAGENTA :: Color{255, 0, 255, 255}
COLOR_CYAN    :: Color{0, 255, 255, 255}
COLOR_ORANGE  :: Color{255, 128, 0, 255}
COLOR_PURPLE  :: Color{128, 0, 255, 255}

evdev_scancode_to_zephr_scancode_map := []Scancode {
  0 = .NULL,
  1 = .ESCAPE,
  2 = .KEY_1,
  3 = .KEY_2,
  4 = .KEY_3,
  5 = .KEY_4,
  6 = .KEY_5,
  7 = .KEY_6,
  8 = .KEY_7,
  9 = .KEY_8,
  10 = .KEY_9,
  11 = .KEY_0,
  12 = .MINUS,
  13 = .EQUALS,
  14 = .BACKSPACE,
  15 = .TAB,
  16 = .Q,
  17 = .W,
  18 = .E,
  19 = .R,
  20 = .T,
  21 = .Y,
  22 = .U,
  23 = .I,
  24 = .O,
  25 = .P,
  26 = .LEFT_BRACKET,
  27 = .RIGHT_BRACKET,
  28 = .ENTER,
  29 = .LEFT_CTRL,
  30 = .A,
  31 = .S,
  32 = .D,
  33 = .F,
  34 = .G,
  35 = .H,
  36 = .J,
  37 = .K,
  38 = .L,
  39 = .SEMICOLON,
  40 = .APOSTROPHE,
  41 = .GRAVE,
  42 = .LEFT_SHIFT,
  43 = .BACKSLASH,
  44 = .Z,
  45 = .X,
  46 = .C,
  47 = .V,
  48 = .B,
  49 = .N,
  50 = .M,
  51 = .COMMA,
  52 = .PERIOD,
  53 = .SLASH,
  54 = .RIGHT_SHIFT,
  55 = .KP_MULTIPLY,
  56 = .LEFT_ALT,
  57 = .SPACE,
  58 = .CAPS_LOCK,
  59 = .F1,
  60 = .F2,
  61 = .F3,
  62 = .F4,
  63 = .F5,
  64 = .F6,
  65 = .F7,
  66 = .F8,
  67 = .F9,
  68 = .F10,
  69 = .NUM_LOCK_OR_CLEAR,
  70 = .SCROLL_LOCK,
  71 = .KP_7,
  72 = .KP_8,
  73 = .KP_9,
  74 = .KP_MINUS,
  75 = .KP_4,
  76 = .KP_5,
  77 = .KP_6,
  78 = .KP_PLUS,
  79 = .KP_1,
  80 = .KP_2,
  81 = .KP_3,
  82 = .KP_0,
  83 = .KP_PERIOD,
  // 84
  85 = .LANG5, // KEY_ZENKAKUHANKAKU
  86 = .NON_US_BACKSLASH, // KEY_102ND
  87 = .F11,
  88 = .F12,
  89 = .INTERNATIONAL1, // KEY_RO,
  90 = .LANG3, // KEY_KATAKANA
  91 = .LANG4, // KEY_HIRAGANA
  92 = .INTERNATIONAL4, // KEY_HENKAN
  93 = .INTERNATIONAL2, // KEY_KATAKANAHIRAGANA
  94 = .INTERNATIONAL5, // KEY_MUHENKAN
  95 = .INTERNATIONAL5, // KEY_KPJOCOMMA
  96 = .KP_ENTER,
  97 = .RIGHT_CTRL,
  98 = .KP_DIVIDE,
  99 = .SYSREQ,
  100 = .RIGHT_ALT,
  101 = .NULL, // KEY_LINEFEED
  102 = .HOME,
  103 = .UP,
  104 = .PAGE_UP,
  105 = .LEFT,
  106 = .RIGHT,
  107 = .END,
  108 = .DOWN,
  109 = .PAGE_DOWN,
  110 = .INSERT,
  111 = .DELETE,
  112 = .NULL, // KEY_MACRO
  113 = .MUTE,
  114 = .VOLUME_DOWN,
  115 = .VOLUME_UP,
  116 = .POWER,
  117 = .KP_EQUALS,
  118 = .KP_PLUS_MINUS,
  119 = .PAUSE,
  // 120
  121 = .KP_COMMA,
  122 = .LANG1, // KEY_HANGUEL
  123 = .LANG2, // KEY_HANJA
  124 = .INTERNATIONAL3, // KEY_YEN
  125 = .LEFT_META,
  126 = .RIGHT_META,
  127 = .APPLICATION, // KEY_COMPOSE
  128 = .STOP,
  129 = .AGAIN,
  130 = .NULL, // KEY_PROPS
  131 = .UNDO,
  132 = .NULL, // KEY_FRONT
  133 = .COPY,
  134 = .NULL, // KEY_OPEN
  135 = .PASTE,
  136 = .FIND,
  137 = .CUT,
  138 = .HELP,
  139 = .MENU,
  140 = .NULL, // CALCULATOR
  141 = .NULL, // KEY_SETUP
  142 = .NULL, // SLEEP
  143 = .NULL, // KEY_WAKEUP
  144 = .NULL, // KEY_FILE
  145 = .NULL, // KEY_SENDFILE
  146 = .NULL, // KEY_DELETEFILE
  147 = .NULL, // KEY_XFER
  148 = .NULL, // KEY_PROG1
  149 = .NULL, // KEY_PROG2
  150 = .NULL, // WWW
  151 = .NULL, // KEY_MSDOS
  152 = .NULL, // KEY_COFFEE
  153 = .NULL, // KEY_DIRECTION
  154 = .NULL, // KEY_CYCLEWINDOWS
  155 = .NULL, // MAIL
  156 = .NULL, // AC_BOOKMARKS
  157 = .NULL, // COMPUTER
  158 = .NULL, // AC_BACK
  159 = .NULL, // AC_FORWARD
  160 = .NULL, // KEY_CLOSECD
  161 = .NULL, // EJECT
  162 = .NULL, // KEY_EJECTCLOSECD
  163 = .NULL, // AUDIO_NEXT
  164 = .NULL, // AUDIO_PLAY
  165 = .NULL, // AUDIO_PREV
  166 = .NULL, // AUDIO_STOP
  167 = .NULL, // KEY_RECORD
  168 = .NULL, // AUDIO_REWIND
  169 = .NULL, // KEY_PHONE
  170 = .NULL, // KEY_ISO
  171 = .NULL, // KEY_CONFIG
  172 = .NULL, // AC_HOME
  173 = .NULL, // AC_REFRESH
  174 = .NULL, // KEY_EXIT
  175 = .NULL, // KEY_MOVE
  176 = .NULL, // KEY_EDIT
  177 = .NULL, // KEY_SCROLLUP
  178 = .NULL, // KEY_SCROLLDOWN
  179 = .KP_LEFT_PAREN,
  180 = .KP_RIGHT_PAREN,
  181 = .NULL, // KEY_NEW
  182 = .NULL, // KEY_REDO
  183 = .F13,
  184 = .F14,
  185 = .F15,
  186 = .F16,
  187 = .F17,
  188 = .F18,
  189 = .F19,
  190 = .F20,
  191 = .F21,
  192 = .F22,
  193 = .F23,
  194 = .F24,
  // 195-199
  200 = .NULL, // KEY_PLAYCD
  201 = .NULL, // KEY_PAUSECD
  202 = .NULL, // KEY_PROG3
  203 = .NULL, // KEY_PROG4
  // 204
  205 = .NULL, // KEY_SUSPEND
  206 = .NULL, // KEY_CLOSE
  207 = .NULL, // KEY_PLAY
  208 = .NULL, // AUDIO_FASTFORWARD
  209 = .NULL, // KEY_BASSBOOST
  210 = .NULL, // KEY_PRINT
  211 = .NULL, // KEY_HP
  212 = .NULL, // KEY_CAMERA
  213 = .NULL, // KEY_SOUND
  214 = .NULL, // KEY_QUESTION
  215 = .NULL, // KEY_EMAIL
  216 = .NULL, // KEY_CHAT
  217 = .NULL, // AC_SEARCH
  218 = .NULL, // KEY_CONNECT
  219 = .NULL, // KEY_FINANCE
  220 = .NULL, // KEY_SPORT
  221 = .NULL, // KEY_SHOP
  222 = .ALT_ERASE,
  223 = .CANCEL,
  224 = .NULL, // BRIGHTNESS_DOWN
  225 = .NULL, // BRIGHNESS_UP
  226 = .NULL, // KEY_MEDIA
  227 = .NULL, // DISPLAY_SWITCH
  228 = .NULL, // KBD_ILLUM_TOGGLE
  229 = .NULL, // KBD_ILLUM_DOWN
  230 = .NULL, // KBD_ILLUM_UP
  231 = .NULL, // KEY_SEND
  232 = .NULL, // KEY_REPLY
  233 = .NULL, // KEY_FORWARDEMAIL
  234 = .NULL, // KEY_SAVE
  235 = .NULL, // KEY_DOCUMENTS
  236 = .NULL, // KEY_BATTERY
}

@private
x11_display  : ^x11.Display
@private
x11_window   : x11.Window
@private
x11_colormap : x11.Colormap
@private
glx_context  : glx.Context
@private
zephr_ctx    : Context
@private
logger       : log.Logger


////////////////////////////
//
// X11
//
///////////////////////////


@private
x11_go_fullscreen :: proc() {
  // remove the resizing constraint before going fullscreen so WMs such as gnome
  // can add the _NET_WM_ACTION_FULLSCREEN action to the _NET_WM_ALLOWED_ACTIONS atom
  // and properly fullscreen the window
  size_hints := x11.XAllocSizeHints()

  zephr_ctx.window.pre_fullscreen_size.x = zephr_ctx.window.size.x
  zephr_ctx.window.pre_fullscreen_size.y = zephr_ctx.window.size.y
  if (size_hints != nil) {
    size_hints.flags = {.PPosition, .PSize}
    size_hints.width = cast(i32)zephr_ctx.window.size.x
    size_hints.height = cast(i32)zephr_ctx.window.size.y
    x11.XSetWMNormalHints(x11_display, x11_window, size_hints)
    x11.XFree(size_hints)
  }

  xev: x11.XEvent
  wm_state := x11.XInternAtom(x11_display, "_NET_WM_STATE", false)
  fullscreen := x11.XInternAtom(x11_display, "_NET_WM_STATE_FULLSCREEN", false)
  xev.type = .ClientMessage
  xev.xclient.window = x11_window
  xev.xclient.message_type = wm_state
  xev.xclient.format = 32
  xev.xclient.data.l[0] = 1 // _NET_WM_STATE_ADD
  xev.xclient.data.l[1] = cast(int)fullscreen
  xev.xclient.data.l[2] = 0
  x11.XSendEvent(x11_display, x11.XDefaultRootWindow(x11_display), false,
  {.SubstructureNotify, .SubstructureRedirect}, &xev)
}

@private
x11_return_fullscreen :: proc() {
  xev: x11.XEvent
  wm_state := x11.XInternAtom(x11_display, "_NET_WM_STATE", false)
  fullscreen := x11.XInternAtom(x11_display, "_NET_WM_STATE_FULLSCREEN", false)
  xev.type = .ClientMessage
  xev.xclient.window = x11_window
  xev.xclient.message_type = wm_state
  xev.xclient.format = 32
  xev.xclient.data.l[0] = 0 // _NET_WM_STATE_REMOVE
  xev.xclient.data.l[1] = cast(int)fullscreen
  xev.xclient.data.l[2] = 0
  x11.XSendEvent(x11_display, x11.XDefaultRootWindow(x11_display), false,
  {.SubstructureNotify, .SubstructureRedirect}, &xev)

  // restore the resizing constraint as well as the pre-fullscreen window size
  // when returning from fullscreen
  size_hints := x11.XAllocSizeHints()

  if (size_hints != nil) {
    size_hints.flags = {.PPosition, .PSize}
    size_hints.width = cast(i32)zephr_ctx.window.pre_fullscreen_size.x
    size_hints.height = cast(i32)zephr_ctx.window.pre_fullscreen_size.y
    if (zephr_ctx.window.non_resizable) {
      size_hints.flags |= {.PMinSize, .PMaxSize}
      size_hints.min_width = cast(i32)zephr_ctx.window.pre_fullscreen_size.x
      size_hints.min_height = cast(i32)zephr_ctx.window.pre_fullscreen_size.y
      size_hints.max_width = cast(i32)zephr_ctx.window.pre_fullscreen_size.x
      size_hints.max_height = cast(i32)zephr_ctx.window.pre_fullscreen_size.y
    }
    x11.XSetWMNormalHints(x11_display, x11_window, size_hints)
    x11.XFree(size_hints)
  }
}

@private
x11_toggle_fullscreen :: proc(fullscreen: bool) {
  if fullscreen {
    x11_return_fullscreen()
  } else {
    x11_go_fullscreen()
  }
}

@private
x11_assign_window_icon :: proc(icon_path: cstring, window_title: cstring) {
  icon_width, icon_height: i32
  icon_data := image.load(icon_path, &icon_width, &icon_height, nil, 4)
  defer image.image_free(icon_data)
  assert(icon_data != nil, "Failed to load icon image")

  target_size := 2 + icon_width * icon_height

  data := make([]u64, target_size)

  // first two elements are width and height
  data[0] = cast(u64)icon_width
  data[1] = cast(u64)icon_height

  for i in 0..<(icon_width * icon_height) {
    data[i + 2] = (cast(u64)icon_data[i * 4] << 16) | (cast(u64)icon_data[i * 4 + 1] << 8) | (cast(u64)icon_data[i * 4 + 2] << 0) | (cast(u64)icon_data[i * 4 + 3] << 24)
  }

  net_wm_icon := x11.XInternAtom(x11_display, "_NET_WM_ICON", false)
  x11.XChangeProperty(x11_display, x11_window, net_wm_icon, XA_CARDINAL, 32, PropModeReplace, raw_data(data), target_size)
}

@private
x11_get_screen_size :: proc() -> Vec2 {
  screen := x11.XDefaultScreenOfDisplay(x11_display)

  return Vec2{cast(f32)screen.width, cast(f32)screen.height}
}

@private
x11_resize_window :: proc() {
  win_attrs : x11.XWindowAttributes
  x11.XGetWindowAttributes(x11_display, x11_window, &win_attrs)
  gl.Viewport(0, 0, win_attrs.width, win_attrs.height)
}

@private
x11_create_window :: proc(window_title: cstring, window_size: Vec2, icon_path: cstring, window_non_resizable: bool) {
  context.logger = logger
  x11_display = x11.XOpenDisplay(nil)

  if x11_display == nil {
    log.error("Failed to open X11 display")
    return
  }

  screen_num := x11.XDefaultScreen(x11_display)
  root := x11.XRootWindow(x11_display, screen_num)
  visual := x11.XDefaultVisual(x11_display, screen_num)

  x11_colormap = x11.XCreateColormap(x11_display, root, visual, x11.ColormapAlloc.AllocNone)

  attributes: x11.XSetWindowAttributes
  attributes.event_mask = {.Exposure, .KeyPress, .KeyRelease,
  .StructureNotify, .ButtonPress, .ButtonRelease, .PointerMotion}
  attributes.colormap = x11_colormap

  screen := x11.XDefaultScreenOfDisplay(x11_display)

  window_start_x := screen.width / 2 - cast(i32)window_size.x / 2
  window_start_y := screen.height / 2 - cast(i32)window_size.y / 2

  x11_window = x11.XCreateWindow(x11_display, root, window_start_x, window_start_y, cast(u32)window_size.x, cast(u32)window_size.y, 0,
    x11.XDefaultDepth(x11_display), .InputOutput, visual,
    {.CWColormap, .CWEventMask}, &attributes)

  if (icon_path != "") {
    x11_assign_window_icon(icon_path, window_title)
  }

  // Hints to the WM that the window is a normal window
  // Of course this is only a hint and the WM can ignore it
  net_wm_window_type := x11.XInternAtom(x11_display, "_NET_WM_WINDOW_TYPE", false)
  net_wm_window_type_normal := x11.XInternAtom(x11_display, "_NET_WM_WINDOW_TYPE_NORMAL", false)
  x11.XChangeProperty(x11_display, x11_window, net_wm_window_type, XA_ATOM, 32, PropModeReplace, &net_wm_window_type_normal, 1)

  wm_delete_window := x11.XInternAtom(x11_display, "WM_DELETE_WINDOW", false)
  x11.XSetWMProtocols(x11_display, x11_window, &wm_delete_window, 1)
  zephr_ctx.window_delete_atom = wm_delete_window

  // set window name
  {
    UTF8_STRING := x11.XInternAtom(x11_display, "UTF8_STRING", false)
    x11.XStoreName(x11_display, x11_window, window_title)
    text_property: x11.XTextProperty
    text_property.value = raw_data(string(window_title))
    text_property.format = 8
    text_property.encoding = UTF8_STRING
    text_property.nitems = len(window_title)
    x11.XSetWMName(x11_display, x11_window, &text_property)
    net_wm_name := x11.XInternAtom(x11_display, "_NET_WM_NAME", false)
    wm_class := x11.XInternAtom(x11_display, "WM_CLASS", false)
    x11.XChangeProperty(x11_display, x11_window, net_wm_name, UTF8_STRING, 8, PropModeReplace, raw_data(string(window_title)), cast(i32)len(window_title))
    x11.XChangeProperty(x11_display, x11_window, wm_class, XA_STRING, 8, PropModeReplace, raw_data(string(window_title)), cast(i32)len(window_title))

    // name to be displayed when the window is reduced to an icon
    net_wm_icon_name := x11.XInternAtom(x11_display, "_NET_WM_ICON_NAME", false)
    x11.XChangeProperty(x11_display, x11_window, net_wm_icon_name, UTF8_STRING, 8, PropModeReplace, raw_data(string(window_title)), cast(i32)len(window_title))

    text_property.encoding = XA_STRING
    x11.XSetWMIconName(x11_display, x11_window, &text_property)

    class_hint := x11.XAllocClassHint()

    if (class_hint != nil) {
      class_hint.res_name = window_title
      class_hint.res_class = window_title
      x11.XSetClassHint(x11_display, x11_window, class_hint)
      x11.XFree(class_hint)
    }
  }

  size_hints := x11.XAllocSizeHints()

  if (size_hints != nil) {
    size_hints.flags = {.PPosition, .PSize}
    /* size_hints->win_gravity = StaticGravity; */
    size_hints.x = window_start_x
    size_hints.y = window_start_y
    size_hints.width = cast(i32)window_size.x
    size_hints.height = cast(i32)window_size.y
    if (window_non_resizable) {
      size_hints.flags |= {.PMinSize, .PMaxSize}
      size_hints.min_width = cast(i32)window_size.x
      size_hints.min_height = cast(i32)window_size.y
      size_hints.max_width = cast(i32)window_size.x
      size_hints.max_height = cast(i32)window_size.y
    }
    x11.XSetWMNormalHints(x11_display, x11_window, size_hints)
    x11.XFree(size_hints)
  }

  x11.XMapWindow(x11_display, x11_window)

  gl.load_up_to(3, 3, proc(p: rawptr, name: cstring) { (cast(^rawptr)p)^ = glx.GetProcAddressARB(raw_data(string(name))) })

  glx_major : i32
  glx_minor : i32
  glx.QueryVersion(x11_display, &glx_major, &glx_minor)

  log.infof("Loaded GLX: %d.%d", glx_major, glx_minor)

  visual_attributes := []i32 {
    glx.RENDER_TYPE, glx.RGBA_BIT,
    glx.DEPTH_SIZE, 24,
    glx.DOUBLEBUFFER, 1,
    glx.SAMPLES, 4, // MSAA
    x11.None,
  }

  num_fbc: i32
  fbc := glx.ChooseFBConfig(x11_display, screen_num, raw_data(visual_attributes), &num_fbc)

  context_attributes := []i32 {
    glx.CONTEXT_MAJOR_VERSION_ARB, 3,
    glx.CONTEXT_MINOR_VERSION_ARB, 3,
    glx.CONTEXT_PROFILE_MASK_ARB, glx.CONTEXT_CORE_PROFILE_BIT_ARB,
    x11.None,
  }

  glx_context = glx.CreateContextAttribsARB(x11_display, fbc[0], nil, true, raw_data(context_attributes))

  if glx_context == nil {
    log.error("Failed to create GLX context")
    return
  }

  glx.MakeCurrent(x11_display, x11_window, glx_context)

  gl_version := gl.GetString(gl.VERSION)

  log.infof("GL Version: %s", gl_version)

  glx.SwapIntervalEXT(x11_display, x11_window, 1)
  // we enable blending for text
  gl.Enable(gl.BLEND)
  gl.Enable(gl.MULTISAMPLE)
  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
  x11_resize_window()

  x11.XFree(fbc)
}

@private
x11_init :: proc(window_title: cstring, window_size: Vec2, icon_path: cstring, window_non_resizable: bool) {
  x11_create_window(window_title, window_size, icon_path, window_non_resizable)
}

@private
x11_close :: proc() {
  glx.MakeCurrent(x11_display, 0, nil)
  glx.DestroyContext(x11_display, glx_context)

  x11.XDestroyWindow(x11_display, x11_window)
  x11.XFreeColormap(x11_display, x11_colormap)
  x11.XCloseDisplay(x11_display)
}


////////////////////////////
//
// Zephr
//
///////////////////////////


init :: proc(font_path: cstring, icon_path: cstring, window_title: cstring, window_size: Vec2, window_non_resizable: bool) {
    logger_init()

    // TODO: should I initalize the audio here or let the game handle that??
    //int res = audio_init();
    //CORE_ASSERT(res == 0, "Failed to initialize audio");

    x11_init(window_title, window_size, icon_path, window_non_resizable)

    ui_init(font_path)

    zephr_ctx.ui.elements = make([dynamic]UiElement, INIT_UI_STACK_SIZE)
    zephr_ctx.mouse.pos = Vec2{-1, -1}
    zephr_ctx.window.size = window_size
    zephr_ctx.window.non_resizable = window_non_resizable
    zephr_ctx.projection = orthographic_projection_2d(0, window_size.x, window_size.y, 0)

    zephr_ctx.cursors[.ARROW] = x11.XCreateFontCursor(x11_display, .XC_left_ptr)
    zephr_ctx.cursors[.IBEAM] = x11.XCreateFontCursor(x11_display, .XC_xterm)
    zephr_ctx.cursors[.CROSSHAIR] = x11.XCreateFontCursor(x11_display, .XC_crosshair)
    zephr_ctx.cursors[.HAND] = x11.XCreateFontCursor(x11_display, .XC_hand1)
    zephr_ctx.cursors[.HRESIZE] = x11.XCreateFontCursor(x11_display, .XC_sb_h_double_arrow)
    zephr_ctx.cursors[.VRESIZE] = x11.XCreateFontCursor(x11_display, .XC_sb_v_double_arrow)

    // non-standard cursors
    zephr_ctx.cursors[.DISABLED] = xcursor.LibraryLoadCursor(x11_display, "crossed_circle")

    zephr_ctx.screen_size = x11_get_screen_size()
    start_internal_timer()
}

deinit :: proc() {
  x11_close()
  //audio_close()
}

should_quit :: proc() -> bool {
  gl.ClearColor(0, 0, 0, 1)
  gl.Clear(gl.COLOR_BUFFER_BIT)

  zephr_ctx.cursor = .ARROW
  zephr_ctx.mouse.released = false
  zephr_ctx.mouse.pressed = false

  //audio_update();

  return zephr_ctx.should_quit
}

quit :: proc() {
  zephr_ctx.should_quit = true
}

@private
consume_mouse_events :: proc() -> bool {
  defer clear(&zephr_ctx.ui.elements)

  #reverse for e in zephr_ctx.ui.elements {
    if (inside_rect(e.rect, zephr_ctx.mouse.pos)) {
      zephr_ctx.ui.hovered_element = e.id
      return false
    }
  }

  return true
}

swap_buffers :: proc() {
  if (zephr_ctx.ui.popup_open) {
    draw_color_picker_popup(&zephr_ctx.ui.popup_parent_constraints)
  }
  zephr_ctx.ui.popup_open = false

  if consume_mouse_events() {
    zephr_ctx.ui.hovered_element = 0
  }

  glx.SwapBuffers(x11_display, x11_window)
  x11.XDefineCursor(x11_display, x11_window, zephr_ctx.cursors[zephr_ctx.cursor])
}

iter_events :: proc(e_out: ^Event) -> bool {
  context.logger = logger
  xev: x11.XEvent

  for (cast(bool)x11.XPending(x11_display)) {
    x11.XNextEvent(x11_display, &xev)

    if xev.type == .ConfigureNotify {
      xce := xev.xconfigure

      if (xce.width != cast(i32)zephr_ctx.window.size.x || xce.height != cast(i32)zephr_ctx.window.size.y) {
        zephr_ctx.window.size = Vec2{cast(f32)xce.width, cast(f32)xce.height}
        zephr_ctx.projection = orthographic_projection_2d(0, zephr_ctx.window.size.x, zephr_ctx.window.size.y, 0)
        x11_resize_window()

        e_out.type = .WINDOW_RESIZED
        e_out.window.width = cast(u32)xce.width
        e_out.window.height = cast(u32)xce.height

        return true
      }
    } else if xev.type == .DestroyNotify {
      // window destroy event
      e_out.type = .WINDOW_CLOSED

      return true
    } else if xev.type == .ClientMessage {
      // window close event
      if (cast(x11.Atom)xev.xclient.data.l[0] == zephr_ctx.window_delete_atom) {
        e_out.type = .WINDOW_CLOSED

        return true
      }
    } else if xev.type == .KeyPress {
      xke := xev.xkey

      evdev_keycode := xke.keycode - 8
      scancode := evdev_scancode_to_zephr_scancode_map[evdev_keycode]

      e_out.type = .KEY_PRESSED
      e_out.key.scancode = scancode
      //e_out.key.code = keycode;
      e_out.key.mods = x11_mods_to_zephr_mods(scancode, true)

      return true
    } else if xev.type == .KeyRelease {
      xke := xev.xkey

      evdev_keycode := xke.keycode - 8
      scancode := evdev_scancode_to_zephr_scancode_map[evdev_keycode]

      e_out.type = .KEY_RELEASED
      e_out.key.scancode = scancode
      //e_out.key.code = keycode;
      e_out.key.mods = x11_mods_to_zephr_mods(scancode, false)

      return true
    } else if xev.type == .ButtonPress {
      e_out.type = .MOUSE_BUTTON_PRESSED
      e_out.mouse.pos = Vec2{cast(f32)xev.xbutton.x, cast(f32)xev.xbutton.y}
      zephr_ctx.mouse.pressed = true

      switch (xev.xbutton.button) {
        case .Button1:
        e_out.mouse.button = .BUTTON_LEFT
        zephr_ctx.mouse.button = .BUTTON_LEFT
        case .Button2:
        e_out.mouse.button = .BUTTON_MIDDLE
        zephr_ctx.mouse.button = .BUTTON_MIDDLE
        case .Button3:
        e_out.mouse.button = .BUTTON_RIGHT
        zephr_ctx.mouse.button = .BUTTON_RIGHT
        case .Button4:
        e_out.type = .MOUSE_SCROLL
        e_out.mouse.scroll_direction = .UP
        case .Button5:
        e_out.type = .MOUSE_SCROLL
        e_out.mouse.scroll_direction = .DOWN
        case cast(x11.MouseButton)8: // Back
        e_out.mouse.button = .BUTTON_BACK
        zephr_ctx.mouse.button = .BUTTON_BACK
        case cast(x11.MouseButton)9: // Forward
        e_out.mouse.button = .BUTTON_FORWARD
        zephr_ctx.mouse.button = .BUTTON_FORWARD
        case:
        log.warnf("Unknown mouse button pressed: %d", xev.xbutton.button)
      }

      return true
    } else if xev.type == .ButtonRelease {
      e_out.type = .MOUSE_BUTTON_RELEASED
      e_out.mouse.pos = Vec2{cast(f32)xev.xbutton.x, cast(f32)xev.xbutton.y}
      zephr_ctx.mouse.released = true
      zephr_ctx.mouse.pressed = false

      switch (xev.xbutton.button) {
        case .Button1:
        e_out.mouse.button = .BUTTON_LEFT
        case .Button2:
        e_out.mouse.button = .BUTTON_MIDDLE
        case .Button3:
        e_out.mouse.button = .BUTTON_RIGHT
        case .Button4:
        e_out.type = .MOUSE_SCROLL
        e_out.mouse.scroll_direction = .UP
        case .Button5:
        e_out.type = .MOUSE_SCROLL
        e_out.mouse.scroll_direction = .DOWN
        case cast(x11.MouseButton)8: // Back
        e_out.mouse.button = .BUTTON_BACK
        zephr_ctx.mouse.button = .BUTTON_BACK
        case cast(x11.MouseButton)9: // Forward
        e_out.mouse.button = .BUTTON_FORWARD
        zephr_ctx.mouse.button = .BUTTON_FORWARD
      }

      return true
    } else if xev.type == .MappingNotify {
      // input device mapping changed
      if (xev.xmapping.request != .MappingKeyboard) {
        break
      }
      x11.XRefreshKeyboardMapping(&xev.xmapping)
      /* x11_keyboard_map_update(); */
      break
    } else if xev.type == .MotionNotify {
      e_out.type = .MOUSE_MOVED
      e_out.mouse.pos = Vec2{cast(f32)xev.xmotion.x, cast(f32)xev.xmotion.y}
      zephr_ctx.mouse.pos = e_out.mouse.pos

      return true
    }
  }

  return false
}

get_window_size :: proc() -> Vec2 {
  return zephr_ctx.window.size
}

toggle_fullscreen :: proc() {
  x11_toggle_fullscreen(zephr_ctx.window.is_fullscreen)

  zephr_ctx.window.is_fullscreen = !zephr_ctx.window.is_fullscreen
}

@private
set_cursor :: proc(cursor: Cursor) {
  zephr_ctx.cursor = cursor
}


/////////////////////////////
//
//
// Utils
//
//
/////////////////////////////


@private
fnv_hash32 :: proc(data: []byte, size: u32, hash: u32) -> u32 {
  hash := hash

  for i in 0..<size {
    hash ~= cast(u32)data[i]
    hash *= FNV_HASH32_PRIME
  }

  return hash
}

@private
x11_mods_to_zephr_mods :: proc(scancode: Scancode, is_press: bool) -> KeyMod {
  mods := zephr_ctx.keyboard.mods

  if (is_press) {
    if (scancode == .LEFT_SHIFT) {
      mods |= {.LEFT_SHIFT, .SHIFT}
    }
    if (scancode == .RIGHT_SHIFT) {
      mods |= {.RIGHT_SHIFT, .SHIFT}
    }
    if (scancode == .LEFT_CTRL) {
      mods |= {.LEFT_CTRL, .CTRL}
    }
    if (scancode == .RIGHT_CTRL) {
      mods |= {.RIGHT_CTRL, .CTRL}
    }
    if (scancode == .LEFT_ALT) {
      mods |= {.LEFT_ALT, .ALT}
    }
    if (scancode == .RIGHT_ALT) {
      mods |= {.RIGHT_ALT, .ALT}
    }
    if (scancode == .LEFT_META) {
      mods |= {.LEFT_META, .META}
    }
    if (scancode == .RIGHT_META) {
      mods |= {.RIGHT_META, .META}
    }
    if (scancode == .CAPS_LOCK) {
      mods |= {.CAPS_LOCK}
    }
    if (scancode == .NUM_LOCK_OR_CLEAR) {
      mods |= {.NUM_LOCK}
    }
  } else {
    if (scancode == .LEFT_SHIFT) {
      mods &= ~{.LEFT_SHIFT}
    }
    if (scancode == .RIGHT_SHIFT) {
      mods &= ~{.RIGHT_SHIFT}
    }
    if (!(.RIGHT_SHIFT in mods) && !(.LEFT_SHIFT in mods)) {
      mods &= ~{.SHIFT}
    }

    if (scancode == .LEFT_CTRL) {
      mods &= ~{.LEFT_CTRL}
    }
    if (scancode == .RIGHT_CTRL) {
      mods &= ~{.RIGHT_CTRL}
    }
    if (!(.RIGHT_CTRL in mods) && !(.LEFT_CTRL in mods)) {
      mods &= ~{.CTRL}
    }

    if (scancode == .LEFT_ALT) {
      mods &= ~{.LEFT_ALT}
    }
    if (scancode == .RIGHT_ALT) {
      mods &= ~{.RIGHT_ALT}
    }
    if (!(.RIGHT_ALT in mods) && !(.LEFT_ALT in mods)) {
      mods &= ~{.ALT}
    }

    if (scancode == .LEFT_META) {
      mods &= ~{.LEFT_META}
    }
    if (scancode == .RIGHT_META) {
      mods &= ~{.RIGHT_META}
    }
    if (!(.RIGHT_META in mods) && !(.LEFT_META in mods)) {
      mods &= ~{.META}
    }

    if (scancode == .CAPS_LOCK) {
      mods &= ~{.CAPS_LOCK}
    }
    if (scancode == .NUM_LOCK_OR_CLEAR) {
      mods &= ~{.NUM_LOCK}
    }
  }

  zephr_ctx.keyboard.mods = mods
  return mods
}

@private
logger_init :: proc() {
  buf : [128]byte
  log_file_name := fmt.bprintf(buf[:], "%s.log", ODIN_BUILD_PROJECT_NAME)

  log_file, err := os.open(log_file_name, os.O_CREATE | os.O_WRONLY | os.O_TRUNC, 0o644)
  if err != os.ERROR_NONE {
    fmt.eprintln("[ERROR] Failed to open log file. Logs will not be written")
    return
  }

  file_logger := log.create_file_logger(log_file)
  term_logger := log.create_console_logger(opt = TerminalLoggerOpts)

  logger = log.create_multi_logger(file_logger, term_logger)
}

