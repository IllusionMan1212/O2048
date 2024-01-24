// +build windows
// +private
package zephr

import "core:log"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:os"
import win32 "core:sys/windows"

import gl "vendor:OpenGL"

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

// TODO: two solutions to the window_proc problem.
// 1- set up an event queue where I push events here and process them in backend_get_os_events
// 2- "handle" the events in window_proc by returning the value the system expects and then
//    actually handle events in backend_get_os_events by reading the msg variable.
window_proc :: proc(hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    result: win32.LRESULT

    switch msg {
        case win32.WM_SIZE:
            width := win32.LOWORD(auto_cast lparam)
            height := win32.HIWORD(auto_cast lparam)
            zephr_ctx.window.size = Vec2{cast(f32)width, cast(f32)height}
            zephr_ctx.projection = orthographic_projection_2d(0, zephr_ctx.window.size.x, zephr_ctx.window.size.y, 0)
            gl.Viewport(0, 0, cast(i32)zephr_ctx.window.size.x, cast(i32)zephr_ctx.window.size.y)
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
        // TODO: we can define our own window_proc that can handle events like window resizing and stuff
        // we probably want a custom one.
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

        log.info(msg)
    }
    // TODO: somehow get the events from window proc here???

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