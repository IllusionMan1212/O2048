// +build windows
// +private
package zephr

import "core:log"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:container/queue"
import win32 "core:sys/windows"

import gl "vendor:OpenGL"

OsEvent :: struct {
    type: win32.UINT,
    lparam: win32.LPARAM,
    wparam: win32.WPARAM,
}

@(private="file")
hwnd : win32.HWND
@(private="file")
device_ctx : win32.HDC
@(private="file")
wgl_context : win32.HGLRC

@(private="file")
temp_hwnd : win32.HWND
@(private="file")
temp_device_ctx : win32.HDC
@(private="file")
temp_wgl_context: win32.HGLRC

backend_get_screen_size :: proc() -> Vec2 {
    screen_size := Vec2{
        cast(f32)win32.GetSystemMetrics(win32.SM_CXSCREEN),
        cast(f32)win32.GetSystemMetrics(win32.SM_CYSCREEN),
    }
    return screen_size
}

backend_toggle_fullscreen :: proc(fullscreen: bool) {
    // TODO:
}

@(private="file")
init_legacy_gl :: proc(class_name: win32.wstring, hInstance: win32.HINSTANCE) {
    temp_hwnd = win32.CreateWindowExW(
        0,
        class_name,
        win32.L("Fake Window"),
        win32.WS_OVERLAPPEDWINDOW,

        0, 0, 1, 1,

        nil,
        nil,
        hInstance,
        nil,
    )

    if temp_hwnd == nil {
        log.fatal("Failed to create fake window")
    }

    temp_device_ctx = win32.GetDC(temp_hwnd)

    if temp_device_ctx == nil {
        log.error("Failed to create device context for fake window")
    }

    pfd := win32.PIXELFORMATDESCRIPTOR{
        nSize      = size_of(win32.PIXELFORMATDESCRIPTOR),
        nVersion   = 1,
        dwFlags    = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL,
        iPixelType = win32.PFD_TYPE_RGBA,
        cColorBits = 32,
        cAlphaBits = 8,
        cDepthBits = 24,
        iLayerType = win32.PFD_MAIN_PLANE,
    }
    pixel_format := win32.ChoosePixelFormat(temp_device_ctx, &pfd)
    if pixel_format == 0 {
        log.error("Failed to choose pixel format for fake window")
    }

    status := win32.SetPixelFormat(temp_device_ctx, pixel_format, &pfd)
    if !status {
        log.error("Failed to set pixel format for fake window")
    }

    temp_wgl_context = win32.wglCreateContext(temp_device_ctx)

    if temp_wgl_context == nil {
        log.fatal("Failed to create WGL context")
        return
    }

    gl.load_up_to(3, 3, win32.gl_set_proc_address)

    win32.wglMakeCurrent(temp_device_ctx, temp_wgl_context)

    gl_version := gl.GetString(gl.VERSION)

    strs := strings.split(string(gl_version), " ")
    ver := strings.split(strs[0], ".")
    gl_major, gl_minor := strconv.atoi(ver[0]), strconv.atoi(ver[1])

    log.debugf("Fake Window GL: %d.%d", gl_major, gl_minor)

    if !(gl_major > 3 || (gl_major == 3 && gl_minor >= 3)) {
        log.fatalf("You need at least OpenGL 3.3 to run this application. Your OpenGL version is %d.%d", gl_major, gl_minor)
        os.exit(1)
    }
}

@(private="file")
init_gl :: proc(class_name: win32.wstring, window_title: win32.wstring, window_size: Vec2, hInstance: win32.HINSTANCE) {
    screen_size := Vec2{
        cast(f32)win32.GetSystemMetrics(win32.SM_CXSCREEN),
        cast(f32)win32.GetSystemMetrics(win32.SM_CYSCREEN),
    }

    win_x := screen_size.x / 2 - window_size.x / 2
    win_y := screen_size.y / 2 - window_size.y / 2

    rect := win32.RECT{0, 0, cast(i32)window_size.x, cast(i32)window_size.y}
    win32.AdjustWindowRect(&rect, win32.WS_OVERLAPPEDWINDOW, false)

    win_width := rect.right - rect.left
    win_height := rect.bottom - rect.top

    hwnd := win32.CreateWindowExW(
        0,
        class_name,
        window_title,
        win32.WS_OVERLAPPEDWINDOW,

        cast(i32)win_x, cast(i32)win_y, win_width, win_height,

        nil,
        nil,
        hInstance,
        nil,
    )

    if hwnd == nil {
        log.fatal("Failed to create window")
        return
    }

    device_ctx = win32.GetDC(hwnd)

    if device_ctx == nil {
        log.fatal("Failed to create device context")
        return
    }

    wglChoosePixelFormatARB := cast(win32.ChoosePixelFormatARBType)win32.wglGetProcAddress("wglChoosePixelFormatARB")
    wglCreateContextAttribsARB := cast(win32.CreateContextAttribsARBType)win32.wglGetProcAddress("wglCreateContextAttribsARB")
    wglSwapIntervalEXT := cast(win32.SwapIntervalEXTType)win32.wglGetProcAddress("wglSwapIntervalEXT")

    pixel_attribs := []i32{
        win32.WGL_DRAW_TO_WINDOW_ARB, 1,
        win32.WGL_SUPPORT_OPENGL_ARB, 1,
        win32.WGL_DOUBLE_BUFFER_ARB, 1,
        // TODO: test to see if EXCHANGE actually causes problems in fullscreen
        /* WGL_SWAP_EXCHANGE_ARB causes problems with window menu in fullscreen */
        win32.WGL_SWAP_METHOD_ARB, win32.WGL_SWAP_COPY_ARB,
        win32.WGL_PIXEL_TYPE_ARB, win32.WGL_TYPE_RGBA_ARB,
        win32.WGL_ACCELERATION_ARB, win32.WGL_FULL_ACCELERATION_ARB,
        win32.WGL_COLOR_BITS_ARB, 32,
        win32.WGL_ALPHA_BITS_ARB, 8,
        win32.WGL_DEPTH_BITS_ARB, 24,
        win32.WGL_STENCIL_BITS_ARB, 0,
        win32.WGL_SAMPLES_ARB, 4,
        0,
    }

    ctx_attribs := []i32{
        win32.WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
        win32.WGL_CONTEXT_MINOR_VERSION_ARB, 3,
        win32.WGL_CONTEXT_PROFILE_MASK_ARB, win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
        0,
    }

    pixel_format: i32
    num_formats: u32
    success := wglChoosePixelFormatARB(device_ctx, raw_data(pixel_attribs), nil, 1, &pixel_format, &num_formats)

    if !success {
        log.error("Failed to choose pixel format")
        return
    }

    pfd: win32.PIXELFORMATDESCRIPTOR
    win32.DescribePixelFormat(device_ctx, pixel_format, size_of(win32.PIXELFORMATDESCRIPTOR), &pfd)
    success = win32.SetPixelFormat(device_ctx, pixel_format, &pfd)

    if !success {
        log.error("Failed to set pixel format")
        return
    }

    wgl_context = wglCreateContextAttribsARB(device_ctx, nil, raw_data(ctx_attribs))

    if wgl_context == nil {
        log.fatal("Failed to create WGL context")
        return
    }

    win32.wglMakeCurrent(temp_device_ctx, nil)
    win32.wglDeleteContext(temp_wgl_context)
    win32.ReleaseDC(temp_hwnd, temp_device_ctx)
    win32.DestroyWindow(temp_hwnd)

    win32.wglMakeCurrent(device_ctx, wgl_context)

    gl_version := gl.GetString(gl.VERSION)
    log.infof("GL Version: %s", gl_version)

    new_success := wglSwapIntervalEXT(1)
    if !new_success {
        log.error("Failed to enable v-sync")
    }

    gl.load_up_to(3, 3, win32.gl_set_proc_address)

    win32.ShowWindow(hwnd, win32.SW_NORMAL)

    gl.Enable(gl.BLEND)
    gl.Enable(gl.MULTISAMPLE)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

@(private="file")
os_event_to_zephr_event :: proc(msg: win32.UINT) -> EventType {
    switch msg {
        case win32.WM_CLOSE: return .WINDOW_CLOSED
        case win32.WM_SIZE: return .WINDOW_RESIZED
        case win32.WM_MOUSEMOVE: return .MOUSE_MOVED
        case win32.WM_MOUSEWHEEL: return .MOUSE_SCROLL
        case win32.WM_LBUTTONDOWN: fallthrough
        case win32.WM_MBUTTONDOWN: fallthrough
        case win32.WM_RBUTTONDOWN: fallthrough
        case win32.WM_XBUTTONDOWN: return .MOUSE_BUTTON_PRESSED
        case win32.WM_LBUTTONUP: fallthrough
        case win32.WM_MBUTTONUP: fallthrough
        case win32.WM_RBUTTONUP: fallthrough
        case win32.WM_XBUTTONUP: return .MOUSE_BUTTON_RELEASED
        case win32.WM_SYSKEYDOWN: fallthrough
        case win32.WM_KEYDOWN: return .KEY_PRESSED
        case win32.WM_SYSKEYUP: fallthrough
        case win32.WM_KEYUP: return .KEY_RELEASED
    }

    return .UNKNOWN
}

window_proc :: proc(hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    result: win32.LRESULT

    switch msg {
        case win32.WM_CLOSE: fallthrough
        case win32.WM_SIZE: fallthrough
        case win32.WM_MOUSEMOVE: fallthrough
        case win32.WM_MOUSEWHEEL: fallthrough
        case win32.WM_LBUTTONDOWN: fallthrough
        case win32.WM_MBUTTONDOWN: fallthrough
        case win32.WM_RBUTTONDOWN: fallthrough
        case win32.WM_XBUTTONDOWN: fallthrough
        case win32.WM_LBUTTONUP: fallthrough
        case win32.WM_MBUTTONUP: fallthrough
        case win32.WM_RBUTTONUP: fallthrough
        case win32.WM_XBUTTONUP: fallthrough
        case win32.WM_SYSKEYDOWN: fallthrough
        case win32.WM_SYSKEYUP: fallthrough
        case win32.WM_KEYDOWN: fallthrough
        case win32.WM_KEYUP:
            queue.push(&zephr_ctx.event_queue, OsEvent{
                type = msg,
                lparam = lparam,
                wparam = wparam,
            })
        case:
            result = win32.DefWindowProcW(hwnd, msg, wparam, lparam)
    }

    return result
}

backend_init :: proc(window_title: cstring, window_size: Vec2, icon_path: cstring, window_non_resizable: bool) {
    context.logger = logger

    class_name := win32.L("zephr.main_window")
    window_title := win32.utf8_to_wstring(string(window_title))

    hInstance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
    hIcon := win32.LoadImageW(nil, win32.utf8_to_wstring(string(icon_path)), win32.IMAGE_ICON, 0, 0, win32.LR_DEFAULTSIZE | win32.LR_LOADFROMFILE)
    wc := win32.WNDCLASSEXW {
        cbSize        = size_of(win32.WNDCLASSEXW),
        style         = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
        lpfnWndProc   = cast(win32.WNDPROC)window_proc,
        hInstance     = hInstance,
        lpszClassName = class_name,
        hIcon         = cast(win32.HICON)hIcon,
        hIconSm       = cast(win32.HICON)hIcon, // TODO: maybe we can have a 16x16 icon here. can be used on linux too
    }

    status := win32.RegisterClassExW(&wc)

    if status == 0 {
        log.error("Failed to register class")
    }

    // Make process aware of system scaling per monitor
    win32.SetProcessDpiAwarenessContext(win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)

    init_legacy_gl(class_name, hInstance)
    init_gl(class_name, window_title, window_size, hInstance)
}

backend_get_os_events :: proc(e_out: ^Event) -> bool {
    context.logger = logger
    msg: win32.MSG

    for win32.PeekMessageW(&msg, hwnd, 0, 0, win32.PM_REMOVE) != win32.FALSE {
        win32.TranslateMessage(&msg)
        win32.DispatchMessageW(&msg)
    }

    for queue.len(zephr_ctx.event_queue) != 0 {
        event := queue.pop_front(&zephr_ctx.event_queue)

        e_out.type = os_event_to_zephr_event(event.type)

        switch event.type {
            case win32.WM_CLOSE:
                return true
            case win32.WM_SIZE:
                width := win32.LOWORD(auto_cast event.lparam)
                height := win32.HIWORD(auto_cast event.lparam)
                zephr_ctx.window.size = Vec2{cast(f32)width, cast(f32)height}
                zephr_ctx.projection = orthographic_projection_2d(0, zephr_ctx.window.size.x, zephr_ctx.window.size.y, 0)
                gl.Viewport(0, 0, cast(i32)zephr_ctx.window.size.x, cast(i32)zephr_ctx.window.size.y)

                e_out.window.width = cast(u32)width
                e_out.window.height = cast(u32)height

                return true
            case win32.WM_LBUTTONDOWN, win32.WM_LBUTTONUP:
                x := win32.GET_X_LPARAM(event.lparam)
                y := win32.GET_Y_LPARAM(event.lparam)

                e_out.mouse.pos = Vec2{cast(f32)x, cast(f32)y}

                e_out.mouse.button = .BUTTON_LEFT
                zephr_ctx.mouse.button = .BUTTON_LEFT

                if event.type == win32.WM_LBUTTONDOWN {
                    zephr_ctx.mouse.pressed = true
                } else {
                    zephr_ctx.mouse.released = true
                    zephr_ctx.mouse.pressed = false
                }

                return true
            case win32.WM_MBUTTONDOWN, win32.WM_MBUTTONUP:
                x := win32.GET_X_LPARAM(event.lparam)
                y := win32.GET_Y_LPARAM(event.lparam)

                e_out.mouse.pos = Vec2{cast(f32)x, cast(f32)y}

                e_out.mouse.button = .BUTTON_MIDDLE
                zephr_ctx.mouse.button = .BUTTON_MIDDLE

                if event.type == win32.WM_MBUTTONDOWN {
                    zephr_ctx.mouse.pressed = true
                } else {
                    zephr_ctx.mouse.released = true
                    zephr_ctx.mouse.pressed = false
                }

                return true
            case win32.WM_RBUTTONDOWN, win32.WM_RBUTTONUP:
                x := win32.GET_X_LPARAM(event.lparam)
                y := win32.GET_Y_LPARAM(event.lparam)

                e_out.mouse.pos = Vec2{cast(f32)x, cast(f32)y}

                e_out.mouse.button = .BUTTON_RIGHT
                zephr_ctx.mouse.button = .BUTTON_RIGHT

                if event.type == win32.WM_RBUTTONDOWN {
                    zephr_ctx.mouse.pressed = true
                } else {
                    zephr_ctx.mouse.released = true
                    zephr_ctx.mouse.pressed = false
                }

                return true
            case win32.WM_XBUTTONDOWN, win32.WM_XBUTTONUP:
                x := win32.GET_X_LPARAM(event.lparam)
                y := win32.GET_Y_LPARAM(event.lparam)

                e_out.mouse.pos = Vec2{cast(f32)x, cast(f32)y}

                btn := win32.HIWORD(auto_cast event.wparam)

                if btn == win32.XBUTTON1 {
                    e_out.mouse.button = .BUTTON_BACK
                    zephr_ctx.mouse.button = .BUTTON_BACK
                } else if btn == win32.XBUTTON2 {
                    e_out.mouse.button = .BUTTON_FORWARD
                    zephr_ctx.mouse.button = .BUTTON_FORWARD
                }

                if event.type == win32.WM_XBUTTONDOWN {
                    zephr_ctx.mouse.pressed = true
                } else {
                    zephr_ctx.mouse.released = true
                    zephr_ctx.mouse.pressed = false
                }

                return true
            case win32.WM_MOUSEMOVE:
                x := win32.GET_X_LPARAM(event.lparam)
                y := win32.GET_Y_LPARAM(event.lparam)

                zephr_ctx.mouse.pos = Vec2{cast(f32)x, cast(f32)y}
                e_out.mouse.pos = zephr_ctx.mouse.pos

                return true
            case win32.WM_MOUSEWHEEL:
                // This will be a multiple of win32.WHEEL_DELTA which is 120
                wheel_delta := win32.GET_WHEEL_DELTA_WPARAM(event.wparam)

                e_out.mouse.scroll_direction = .UP if (wheel_delta > 0) else .DOWN

                return true
            case win32.WM_SYSKEYDOWN: fallthrough
            case win32.WM_KEYDOWN:
                log.debug(event.lparam)
                // Bits 16-23 hold the scancode
                system_scancode := (event.lparam & 0xFF0000) >> 16

                scancode := scan1_scancode_to_zephr_scancode_map[system_scancode]

                log.debug(system_scancode)
                log.debug(scancode)
                // TODO:
            case win32.WM_SYSKEYUP: fallthrough
            case win32.WM_KEYUP:
                // TODO:
                // 0101 0010
                //log.debug("released key")
        }
    }

    return false
}

backend_shutdown :: proc() {
    win32.wglMakeCurrent(device_ctx, nil)
    win32.wglDeleteContext(wgl_context)
    win32.ReleaseDC(hwnd, device_ctx)
    win32.DestroyWindow(hwnd)
}

backend_swapbuffers :: proc() {
    win32.SwapBuffers(device_ctx)
}

// https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#scan-codes
// https://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/translate.pdf
@(private="file")
scan1_scancode_to_zephr_scancode_map :: proc(scancode: u8, is_extended: bool) -> Scancode {
    switch scancode {
        case 0: return .NULL

        case 0x1E: return .A
        case 0x30: return .B
        case 0x2E: return .C
        case 0x20: return .D
        case 0x12: return .E
        case 0x21: return .F
        case 0x22: return .G
        case 0x23: return .H
        case 0x17: return .I
        case 0x24: return .J
        case 0x25: return .K
        case 0x26: return .L
        case 0x32: return .M
        case 0x31: return .N
        case 0x18: return .O
        case 0x19: return .P
        case 0x10: return .Q
        case 0x13: return .R
        case 0x1F: return .S
        case 0x14: return .T
        case 0x16: return .U
        case 0x2F: return .V
        case 0x11: return .W
        case 0x2D: return .X
        case 0x15: return .Y
        case 0x2C: return .Z

        case 0x02: return .KEY_1
        case 0x03: return .KEY_2
        case 0x04: return .KEY_3
        case 0x05: return .KEY_4
        case 0x06: return .KEY_5
        case 0x07: return .KEY_6
        case 0x08: return .KEY_7
        case 0x09: return .KEY_8
        case 0x0A: return .KEY_9
        case 0x0B: return .KEY_0

        case 0x1C: return .ENTER
        case 0x01: return .ESCAPE
        case 0x0E: return .BACKSPACE // Says "Keyboard Delete" on microsoft.com but it's actually backspace
        case 0x0F: return .TAB
        case 0x39: return .SPACE

        case 0x0C: return .MINUS
        case 0x0D: return .EQUALS
        case 0x1A: return .LEFT_BRACKET
        case 0x1B: return .RIGHT_BRACKET
        case 0x2B: return .BACKSLASH
        //case 0x2B: return = .NON_US_HASH, // European keyboards have a hash instead of a backslash. Maps to a different HID scancode
        case 0x27: return .SEMICOLON
        case 0x28: return .APOSTROPHE
        case 0x29: return .GRAVE
        case 0x33: return .COMMA
        case 0x34: return .PERIOD
        case 0x35: return .SLASH

        case 0x3A: return .CAPS_LOCK

        case 0x3B: return .F1
        case 0x3C: return .F2
        case 0x3D: return .F3
        case 0x3E: return .F4
        case 0x3F: return .F5
        case 0x40: return .F6
        case 0x41: return .F7
        case 0x42: return .F8
        case 0x43: return .F9
        case 0x44: return .F10
        case 0x57: return .F11
        case 0x58: return .F12

        case 0x54: return .PRINT_SCREEN
        //case 0xE037 = .PRINT_SCREEN, // SysRq ???
        case 0x46: return .SCROLL_LOCK
        case 0x45: return .PAUSE
        //case 0xE046 = .PAUSE, // Break ??
        //case 0xE11D45 = .PAUSE, // Some legacy stuff ???
        case 0x52:
            // INSERT
            // KP_0
        case 0x47:
            // HOME
            // KP_7
        case 0x49:
            // PAGE_UP
            // KP_9
        case 0x53:
            // DELETE
            // KP_PERIOD
        case 0x4F:
            // END
            // KP_1
        case 0x51:
            // PAGE_DOWN
            // KP_3
        case 0x4D:
            // RIGHT
            // KP_6
        case 0x4B:
            // LEFT
            // KP_4
        case 0x50:
            // DOWN
            // KP_2
        case 0xE048:
            // UP
            // KP_8
    }





    //0x45 = .NUM_LOCK_OR_CLEAR, // conflicts with Pause, Pause doesn't have the extended bit set. don't know about this
    //0xE045 = .NUM_LOCK_OR_CLEAR, // Legacy stuff
    0xE035 = .KP_DIVIDE,
    0x37 = .KP_MULTIPLY,
    0x4A = .KP_MINUS,
    0x4E = .KP_PLUS,
    0xE01C = .KP_ENTER,
    0x4C = .KP_5,

    0x56 = .NON_US_BACKSLASH,
    0xE05D = .APPLICATION,
    0xE05E = .POWER,
    0x59 = .KP_EQUALS,
    0x64 = .F13,
    0x65 = .F14,
    0x66 = .F15,
    0x67 = .F16,
    0x68 = .F17,
    0x69 = .F18,
    0x6A = .F19,
    0x6B = .F20,
    0x6C = .F21,
    0x6D = .F22,
    0x6E = .F23,
    0x76 = .F24,

    0x7E = .KP_COMMA,
    0x73 = .INTERNATIONAL1,
    0x70 = .INTERNATIONAL2,
    0x7D = .INTERNATIONAL3,
    0x79 = .INTERNATIONAL4,
    0x7B = .INTERNATIONAL5,
    0x5C = .INTERNATIONAL6,
    0x72 = .LANG1, // Only emitted on Key Release
    0xF2 = .LANG1, // Legacy, Only emitted on Key Release
    0x71 = .LANG2, // Only emitted on Key Release
    0xF1 = .LANG2, // Legacy, Only emitted on Key Release
    0x78 = .LANG3,
    0x77 = .LANG4,
    //0x76 = .LANG5, // Conflicts with F24

    0x1D = .LEFT_CTRL,
    0x2A = .LEFT_SHIFT,
    0x38 = .LEFT_ALT,
    0xE05B = .LEFT_META,
    0xE01D = .RIGHT_CTRL,
    0x36 = .RIGHT_SHIFT,
    0xE038 = .RIGHT_ALT,
    0xE05C = .RIGHT_META,
    // End of Keyboard/Keypad section on microsoft.com
    // We currently don't map or care about the Consumer section
}