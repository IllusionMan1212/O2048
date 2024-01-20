package zephr

import "core:math"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat3 :: matrix[3, 3]f32
Mat4 :: matrix[4, 4]f32

Color :: struct { r, g, b, a: u8 }

orthographic_projection_2d :: proc(left, right, bottom, top: f32) -> Mat4 {
  result := identity()

  result[0][0] = 2 / (right - left)
  result[3][0] = -(right + left) / (right - left)
  result[1][1] = 2 / (top - bottom)
  result[3][1] = -(top + bottom) / (top - bottom)
  result[2][2] = -1
  result[3][3] = 1

  return result
}

identity :: proc() -> Mat4 {
  return Mat4 {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  }
}

translate :: proc(m: ^Mat4, v: Vec3) {
  temp := identity()

  temp[3][0] = v.x
  temp[3][1] = v.y
  temp[3][2] = v.z

  m^ = temp * m^
}

rotate :: proc(m: ^Mat4, angle: f32, axis: Vec3) {
  temp := identity()

  c := math.cos(math.to_radians(angle))
  s := math.sin(math.to_radians(angle))
  t := 1 - c

  x, y, z := axis.x, axis.y, axis.z

  res := Mat4{
    t*x*x + c,     t*x*y - s*z,   t*x*z + s*y,   0,
    t*x*y + s*z,   t*y*y + c,     t*y*z - s*x,   0,
    t*x*z - s*y,   t*y*z + s*x,   t*z*z + c,     0,
    0 ,            0,             0,             1,
  }

  m^ = res * m^
}

scale :: proc(m: ^Mat4, v: Vec3) {
  temp := identity()

  temp[0][0] = v.x
  temp[1][1] = v.y
  temp[2][2] = v.z

  m^ = temp * m^
}

mult_color :: proc(color: Color, scalar: f32) -> Color {
  color := color
  
  color.r = clamp(cast(u8)(cast(f32)color.r * scalar), 0, 255)
  color.g = clamp(cast(u8)(cast(f32)color.g * scalar), 0, 255)
  color.b = clamp(cast(u8)(cast(f32)color.b * scalar), 0, 255)

  return color
}

hsv2rgb :: proc(h: f32, s: f32, v: f32) -> Color {
  c := v * s
  x := (c * (1 - abs(math.mod(h / 60.0, 2) - 1)))
  m := v - c

  r, g, b: f32

  if (h >= 0 && h < 60) {
    r = c
    g = x
    b = 0
  } else if (h >= 60 && h < 120) {
    r = x
    g = c
    b = 0
  } else if (h >= 120 && h < 180) {
    r = 0
    g = c
    b = x
  } else if (h >= 180 && h < 240) {
    r = 0
    g = x
    b = c
  } else if (h >= 240 && h < 300) {
    r = x
    g = 0
    b = c
  } else {
    r = c
    g = 0
    b = x
  }

  return (Color){(u8)((r + m) * 255), (u8)((g + m) * 255), (u8)((b + m) * 255), 255}
}

determine_color_contrast :: proc(bg: Color) -> Color {
  white_contrast := get_contrast(bg, COLOR_WHITE)
  black_contrast := get_contrast(bg, COLOR_BLACK)

  return white_contrast > black_contrast ? COLOR_WHITE : COLOR_BLACK
}

@private
get_srgb :: proc(component: f32) -> f32 {
  return (component / 255 <= 0.03928
      ? component / 255 / 12.92
      : math.pow((component / 255 + 0.055) / 1.055, 2.4))
}

get_luminance :: proc(color: Color) -> f32 {
  return ((0.2126 * get_srgb(cast(f32)color.r)) +
  (0.7152 * get_srgb(cast(f32)color.g)) +
  (0.0722 * get_srgb(cast(f32)color.b))) / 255
}

@private
get_contrast :: proc(fg: Color, bg: Color) -> f32 {
  l1 := get_luminance(fg)
  l2 := get_luminance(bg)

  return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
}
