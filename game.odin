package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:time"

import "zephr"

Icon :: enum {
  HELP_ICON,
  SETTINGS_ICON,
  CLOSE_ICON,
}

MoveDir :: enum {
  UP,
  DOWN,
  LEFT,
  RIGHT,
}

ColorPalette :: struct {
  bg_color: zephr.Color,
  board_bg_color: zephr.Color,
  tile_colors: [11]zephr.Color,
}

Tile :: struct {
  start_pos: zephr.Vec2,
  position: zephr.Vec2,
  new_pos: zephr.Vec2,
  anim_timer: time.Duration,
  scale: zephr.Vec2,
  value: u16,
  new_value: u16,
  merged: bool,
}

Game :: struct {
  board: [4][4]Tile,
  score: u32,
  last_move_dir: MoveDir,
  animating: bool,
  spawning_new_tile: bool,
  has_lost: bool,
  game_over_bg_opacity: f32,
  game_over_opacity: f32,
  spawning_tile_scale: zephr.Vec2,
  spawning_tile_coords: zephr.Vec2,
  spawning_tile_value: u16,

  quit_dialog: bool,
  settings_dialog: bool,
  help_dialog: bool,

  icon_textures: [Icon]zephr.TextureId,
  palette: ColorPalette,
}

@private
TILE_ANIM_DURATION :: time.Millisecond * 250
@private
TILE_SPAWN_DURATION    :: time.Millisecond * 200
@private
GAMEOVER_ANIM_DURATION :: time.Millisecond * 300

@private
neighbors := [4]zephr.Vec2 {
  {-1, 0}, // left
  {1, 0},  // right 
  {0, -1}, // up
  {0, 1},  // down
}

gameover_anim_time: time.Duration = 0

@private
game : Game

get_tile_color :: proc(value: u16) -> zephr.Color {
  switch (value) {
    case 2:
      return game.palette.tile_colors[0]
    case 4:
      return game.palette.tile_colors[1]
    case 8:
      return game.palette.tile_colors[2]
    case 16:
      return game.palette.tile_colors[3]
    case 32:
      return game.palette.tile_colors[4]
    case 64:
      return game.palette.tile_colors[5]
    case 128:
      return game.palette.tile_colors[6]
    case 256:
      return game.palette.tile_colors[7]
    case 512:
      return game.palette.tile_colors[8]
    case 1024:
      return game.palette.tile_colors[9]
    case 2048:
      return game.palette.tile_colors[10]
    case:
      return game.palette.tile_colors[10]
  }
}

get_tile_font_size :: proc(value: u16) -> u32 {
  switch (value) {
    case 2: fallthrough
    case 4: fallthrough
    case 8:
      return 60
    case 16: fallthrough
    case 32: fallthrough
    case 64:
      return 55
    case 128: fallthrough
    case 256: fallthrough
    case 512:
      return 50
    case 1024: fallthrough
    case 2048:
      return 45
    case:
      return 40
  }
}

/////////////////////////////
//
//
// Game Logic
//
//
/////////////////////////////


move_right :: proc() {
  game.last_move_dir = .RIGHT

  for row in 0..<4 {
    for col := 2; col >= 0; col -= 1 {
      if (game.board[row][col].value == 0) {
        continue
      }
      tiles_to_move := 0
      x := col

      src := &game.board[row][col]
      dest := &game.board[row][x]

      for {
        if (x >= 3) do break
        x += 1
        dest = &game.board[row][x]

        // next tile is empty so we can move there
        if (dest.new_value == 0) {
          tiles_to_move += 1
          continue
        }

        // next tile has the same value so we can merge and move
        if (dest.new_value == src.new_value && !dest.merged) {
          tiles_to_move += 1
          dest.merged = true
          break
        } else {
          // next tile has a different value so we can't move there
          x -= 1
          break
        }
      }

      dest = &game.board[row][x]

      if (tiles_to_move > 0) {
        if (dest.merged) {
          dest.new_value *= 2
          game.score += auto_cast dest.new_value
        } else {
          dest.new_value = src.new_value
        }
        src.new_value = 0
        src.new_pos = zephr.Vec2{cast(f32)row, cast(f32)x}
        src.anim_timer = 0
        game.animating = true
        game.spawning_tile_coords = get_random_available_tile_coords()
        game.spawning_tile_value = get_spawned_tile_value()
      }
    }
  }
}

move_left :: proc() {
  game.last_move_dir = .LEFT

  for row in 0..<4 {
    for col in 1..<4 {
      if (game.board[row][col].value == 0) {
        continue
      }
      tiles_to_move := 0
      x := col

      src := &game.board[row][col]
      dest := &game.board[row][x]

      for {
        if (x <= 0) do break
        x -= 1
        dest = &game.board[row][x]

        // next tile is empty so we can move there
        if (dest.new_value == 0) {
          tiles_to_move += 1
          continue
        }

        // next tile has the same value so we can merge and move
        if ((dest.new_value == src.new_value) && !dest.merged) {
          tiles_to_move += 1
          dest.merged = true
          break
        } else {
          // next tile has a different value so we can't move there
          x += 1
          break
        }
      }

      dest = &game.board[row][x]

      if (tiles_to_move > 0) {
        if (dest.merged) {
          dest.new_value *= 2
          game.score += auto_cast dest.new_value
        } else {
          dest.new_value = src.new_value
        }
        src.new_value = 0
        src.new_pos = zephr.Vec2{cast(f32)row, cast(f32)x}
        src.anim_timer = 0
        game.animating = true
        game.spawning_tile_coords = get_random_available_tile_coords()
        game.spawning_tile_value = get_spawned_tile_value()
      }
    }
  }
}

move_down :: proc() {
  game.last_move_dir = .DOWN

  for row := 2; row >= 0; row -= 1 {
    for col in 0..<4 {
      if (game.board[row][col].value == 0) {
        continue
      }
      tiles_to_move := 0
      y := row

      src := &game.board[row][col]
      dest := &game.board[y][col]

      for {
        if (y >= 3) do break
        y += 1
        dest = &game.board[y][col]

        if (dest.new_value == 0) {
          tiles_to_move += 1
          continue
        }

        if ((dest.new_value == src.new_value) && !dest.merged) {
          tiles_to_move += 1
          dest.merged = true
          break
        } else {
          y -= 1
          break
        }
      }

      dest = &game.board[y][col]

      if (tiles_to_move > 0) {
        if (dest.merged) {
          dest.new_value *= 2
          game.score += auto_cast dest.new_value
        } else {
          dest.new_value = src.new_value
        }
        src.new_value = 0
        src.new_pos = zephr.Vec2{cast(f32)y, cast(f32)col}
        src.anim_timer = 0
        game.animating = true
        game.spawning_tile_coords = get_random_available_tile_coords()
        game.spawning_tile_value = get_spawned_tile_value()
      }
    }
  }
}

move_up :: proc() {
  game.last_move_dir = .UP

  for row in 1..<4 {
    for col in 0..<4 {
      if (game.board[row][col].value == 0) {
        continue
      }
      tiles_to_move := 0
      y := row

      src := &game.board[row][col]
      dest := &game.board[y][col]

      for {
        if (y <= 0) do break
        y -= 1
        dest = &game.board[y][col]

        if (dest.new_value == 0) {
          tiles_to_move += 1
          continue
        }

        if (dest.new_value == src.new_value && !dest.merged) {
          tiles_to_move += 1
          dest.merged = true
          break
        } else {
          y += 1
          break
        }
      }

      dest = &game.board[y][col]

      if (tiles_to_move > 0) {
        if (dest.merged) {
          dest.new_value *= 2
          game.score += auto_cast dest.new_value
        } else {
          dest.new_value = src.new_value
        }
        src.new_value = 0
        src.new_pos = zephr.Vec2{cast(f32)y, cast(f32)col}
        src.anim_timer = 0
        game.animating = true
        game.spawning_tile_coords = get_random_available_tile_coords()
        game.spawning_tile_value = get_spawned_tile_value()
      }
    }
  }
}

reset_palette :: proc() {
  game.palette = ColorPalette{
    bg_color = zephr.Color{248, 250, 230, 255},
    board_bg_color = zephr.Color{140, 154, 147, 255},

    tile_colors = [11]zephr.Color{
      zephr.Color{238, 228, 218, 255}, // 2
      zephr.Color{237, 224, 200, 255}, // 4
      zephr.Color{242, 177, 121, 255}, // 8
      zephr.Color{245, 149, 99, 255},  // 16
      zephr.Color{246, 124, 95, 255},  // 32
      zephr.Color{246, 94, 59, 255},   // 64
      zephr.Color{237, 207, 114, 255}, // 128
      zephr.Color{237, 204, 97, 255},  // 256
      zephr.Color{237, 200, 80, 255},  // 512
      zephr.Color{237, 197, 63, 255},  // 1024
      zephr.Color{237, 194, 46, 255}, // 2048
    },
  }
}

reset_game :: proc() {
  gameover_anim_time = 0

  game.score = 0
  game.animating = false
  game.spawning_new_tile = false
  game.quit_dialog = false
  game.help_dialog = false
  game.settings_dialog = false
  game.has_lost = false
  game.game_over_bg_opacity = 0
  game.game_over_opacity = 0

  for y in 0..<4 {
    for x in 0..<4 {
      game.board[y][x].value = 0
      game.board[y][x].new_value = 0
      game.board[y][x].merged = false
    }
  }

  for i in 0..<2 {
    spawn_random_tile()
  }
}

game_attempt_quit :: proc() {
  game.help_dialog = false
  game.settings_dialog = false
  game.quit_dialog = true
}

game_init :: proc() {
  game.icon_textures[.HELP_ICON] = zephr.load_texture("assets/icons/help.png")
  game.icon_textures[.SETTINGS_ICON] = zephr.load_texture("assets/icons/settings.png")
  game.icon_textures[.CLOSE_ICON] = zephr.load_texture("assets/icons/close.png")

  reset_palette()

  for i in 0..<2 {
    spawn_random_tile()
  }
}

get_spawned_tile_value :: proc() -> u16 {
  // 90% chance of spawning a 2, 10% chance of spawning a 4
  if (rand.int_max(11) < 9) {
    return 2
  } else {
    return 4
  }
}

spawn_new_tile_with_value :: proc(x, y: u8, value: u16) {
  game.board[x][y] = Tile{
    value = value,
    new_value = value,
    position = zephr.Vec2{cast(f32)x, cast(f32)y},
    start_pos = zephr.Vec2{cast(f32)x, cast(f32)y},
    new_pos = zephr.Vec2{cast(f32)x, cast(f32)y},
    scale = zephr.Vec2{0, 0},
  }
}

spawn_new_tile :: proc(x, y: u8) {
  val := get_spawned_tile_value()

  game.board[x][y] = Tile{
    value = val,
    new_value = val,
    position = zephr.Vec2{cast(f32)x, cast(f32)y},
    start_pos = zephr.Vec2{cast(f32)x, cast(f32)y},
    new_pos = zephr.Vec2{cast(f32)x, cast(f32)y},
    scale = zephr.Vec2{1, 1},
  }
}

get_random_available_tile_coords :: proc() -> zephr.Vec2 {
  available_tiles_count := 0
  available_tiles: [16]int

  for i in 0..<4 {
    for j in 0..<4 {
      if (game.board[i][j].new_value == 0 && !game.board[i][j].merged) {
        available_tiles[available_tiles_count] = i * 4 + j
        available_tiles_count += 1
      }
    }
  }

  rand_idx := rand.int_max(available_tiles_count)

  x := available_tiles[rand_idx] / 4
  y := available_tiles[rand_idx] % 4

  return zephr.Vec2{cast(f32)x, cast(f32)y}
}

spawn_random_tile :: proc() {
  coords := get_random_available_tile_coords()
  spawn_new_tile(cast(u8)coords.x, cast(u8)coords.y)
}

gameover :: proc() -> bool {
  if (game.has_lost) do return false

  for y in 0..<4 {
    for x in 0..<4 {
      if (game.board[y][x].value == 0) {
        return false
      }

      for i in 0..<4 {
        new_y := cast(int)clamp(cast(f32)y + neighbors[i].y, 0, 3)
        new_x := cast(int)clamp(cast(f32)x + neighbors[i].x, 0, 3)

        if ((new_y != y || new_x != x) && game.board[y][x].value == game.board[new_y][new_x].value) {
          return false
        }
      }
    }
  }


  return true
}

handle_keyboard_input :: proc(e: zephr.Event) {
  can_move := !game.quit_dialog && !game.help_dialog && !game.settings_dialog && !game.animating

  if (.LEFT_CTRL in e.key.mods && e.key.scancode == .Q) {
    game_attempt_quit()
  } else if (e.key.scancode == .ESCAPE) {
    game.quit_dialog = false
    game.help_dialog = false
    game.settings_dialog = false
  } else if (e.key.scancode == .F11) {
    zephr.toggle_fullscreen()
  } else if (e.key.scancode == .UP) {
    if (can_move) do move_up()
  } else if (e.key.scancode == .DOWN) {
    if (can_move) do move_down()
  } else if (e.key.scancode == .LEFT) {
    if (can_move) do move_left()
  } else if (e.key.scancode == .RIGHT) {
    if (can_move) do move_right()
  } else if (e.key.scancode == .N) {
    reset_game()
  }
}

game_loop :: proc() {
  game_init()

  last_frame: time.Duration = 0

  for (!zephr.should_quit()) {
    e: zephr.Event

    for (zephr.iter_events(&e)) {
      #partial switch (e.type) {
        case .WINDOW_CLOSED:
        if (game.quit_dialog) {
          zephr.quit()
        } else {
          game_attempt_quit()
        }
        case .KEY_PRESSED:
        handle_keyboard_input(e)
      }
    }

    now := zephr.get_time()
    delta_t := now - last_frame
    last_frame = now

    update_positions(delta_t)

    draw_bg()
    draw_board()
    draw_ui()

    zephr.swap_buffers()
  }
}

update_positions :: proc(delta_t: time.Duration) {
  if (game.animating) {
    switch game.last_move_dir {
      case .LEFT:
      for i in 0..<4 {
        for j in 1..<4 {
          src := &game.board[i][j]
          if src.value == 0 || src.start_pos == src.new_pos {
            continue
          }
          if src.anim_timer < TILE_ANIM_DURATION {
            src.position.x = math.lerp(src.start_pos.x, src.new_pos.x, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.position.y = math.lerp(src.start_pos.y, src.new_pos.y, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.anim_timer += delta_t
          } else {
            dest := &game.board[cast(int)src.new_pos.x][cast(int)src.new_pos.y]

            if dest.new_value == src.value * 2 {
              dest.merged = false
            }

            dest^ = Tile{
              value = dest.new_value,
              new_value = dest.new_value,
              position = src.new_pos,
              start_pos = src.new_pos,
              new_pos = src.new_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }
            src^ = Tile{
              value = src.new_value,
              new_value = src.new_value,
              position = src.start_pos,
              start_pos = src.start_pos,
              new_pos = src.start_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }

            game.spawning_new_tile = true
          }
        }
      }
      case .RIGHT:
      for i in 0..<4 {
        for j := 2; j >= 0; j -= 1 {
          src := &game.board[i][j]
          if src.value == 0 || src.start_pos == src.new_pos {
            continue
          }
          if src.anim_timer < TILE_ANIM_DURATION {
            src.position.x = math.lerp(src.start_pos.x, src.new_pos.x, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.position.y = math.lerp(src.start_pos.y, src.new_pos.y, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.anim_timer += delta_t
          } else {
            dest := &game.board[cast(int)src.new_pos.x][cast(int)src.new_pos.y]

            if dest.new_value == src.value * 2 {
              dest.merged = false
            }

            dest^ = Tile{
              value = dest.new_value,
              new_value = dest.new_value,
              position = src.new_pos,
              start_pos = src.new_pos,
              new_pos = src.new_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }
            src^ = Tile{
              value = src.new_value,
              new_value = src.new_value,
              position = src.start_pos,
              start_pos = src.start_pos,
              new_pos = src.start_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }

            game.spawning_new_tile = true
          }
        }
      }
      case .UP:
      for i in 1..<4 {
        for j in 0..<4 {
          src := &game.board[i][j]
          if src.value == 0 || src.start_pos == src.new_pos {
            continue
          }
          if src.anim_timer < TILE_ANIM_DURATION {
            src.position.x = math.lerp(src.start_pos.x, src.new_pos.x, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.position.y = math.lerp(src.start_pos.y, src.new_pos.y, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.anim_timer += delta_t
          } else {
            dest := &game.board[cast(int)src.new_pos.x][cast(int)src.new_pos.y]

            if dest.new_value == src.value * 2 {
              dest.merged = false
            }

            dest^ = Tile{
              value = dest.new_value,
              new_value = dest.new_value,
              position = src.new_pos,
              start_pos = src.new_pos,
              new_pos = src.new_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }
            src^ = Tile{
              value = src.new_value,
              new_value = src.new_value,
              position = src.start_pos,
              start_pos = src.start_pos,
              new_pos = src.start_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }

            game.spawning_new_tile = true
          }
        }
      }
      case .DOWN:
      for i := 2; i >= 0; i -= 1 {
        for j in 0..<4 {
          src := &game.board[i][j]
          if src.value == 0 || src.start_pos == src.new_pos {
            continue
          }
          if src.anim_timer < TILE_ANIM_DURATION {
            src.position.x = math.lerp(src.start_pos.x, src.new_pos.x, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.position.y = math.lerp(src.start_pos.y, src.new_pos.y, cast(f32)zephr.ease_in_out_back(cast(f64)src.anim_timer / cast(f64)TILE_ANIM_DURATION))
            src.anim_timer += delta_t
          } else {
            dest := &game.board[cast(int)src.new_pos.x][cast(int)src.new_pos.y]

            if dest.new_value == src.value * 2 {
              dest.merged = false
            }

            dest^ = Tile{
              value = dest.new_value,
              new_value = dest.new_value,
              position = src.new_pos,
              start_pos = src.new_pos,
              new_pos = src.new_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }
            src^ = Tile{
              value = src.new_value,
              new_value = src.new_value,
              position = src.start_pos,
              start_pos = src.start_pos,
              new_pos = src.start_pos,
              anim_timer = 0,
              scale = zephr.Vec2{1, 1},
            }

            game.spawning_new_tile = true
          }
        }
      }
    }
  }

  if (gameover()) {
    game.has_lost = true
    game.animating = true
  }

  if (game.spawning_new_tile) {
    tile := &game.board[cast(int)game.spawning_tile_coords.x][cast(int)game.spawning_tile_coords.y]

    if tile.anim_timer < TILE_SPAWN_DURATION {
      game.spawning_tile_scale.x = math.lerp(cast(f32)0, 1, zephr.ease_out_circ(cast(f32)tile.anim_timer / cast(f32)TILE_SPAWN_DURATION))
      game.spawning_tile_scale.y = math.lerp(cast(f32)0, 1, zephr.ease_out_circ(cast(f32)tile.anim_timer / cast(f32)TILE_SPAWN_DURATION))
      tile.anim_timer += delta_t
    } else {
      spawn_new_tile_with_value(cast(u8)game.spawning_tile_coords.x, cast(u8)game.spawning_tile_coords.y, game.spawning_tile_value);
      tile.anim_timer = 0
      game.spawning_tile_coords = zephr.Vec2{0, 0}
      game.spawning_tile_value = 0
      game.spawning_tile_scale = 0.0
      game.spawning_new_tile = false
      game.animating = false
    }
  }

  if (game.has_lost) {
    if gameover_anim_time < GAMEOVER_ANIM_DURATION {
      game.game_over_opacity = cast(f32)math.lerp(0.0, 255.0, cast(f64)gameover_anim_time / cast(f64)GAMEOVER_ANIM_DURATION)
      game.game_over_bg_opacity = cast(f32)math.lerp(0.0, 200.0, cast(f64)gameover_anim_time / cast(f64)GAMEOVER_ANIM_DURATION)
      gameover_anim_time += delta_t
    } else {
      game.game_over_bg_opacity = 255
      game.game_over_bg_opacity = 200
    }
  }
}


///////////////////////////////////
//
//
// Drawing
//
//
///////////////////////////////////


draw_bg :: proc() {
  window_size := zephr.get_window_size()
  board_con := zephr.DEFAULT_UI_CONSTRAINTS

  zephr.set_width_constraint(&board_con, window_size.x, .FIXED)
  zephr.set_height_constraint(&board_con, window_size.y, .FIXED)

  // bg
  style := zephr.UiStyle{
    bg_color = game.palette.bg_color,
    align = .TOP_LEFT,
  }
  zephr.draw_quad(&board_con, style)

  text_batch: zephr.GlyphInstanceList
  reserve(&text_batch, 32)

  // 2048 text
  text_con := zephr.DEFAULT_UI_CONSTRAINTS

  zephr.set_y_constraint(&text_con, 0.05, .RELATIVE)
  zephr.set_width_constraint(&text_con, 1.5, .RELATIVE_PIXELS)

  zephr.add_text_instance(&text_batch, "2048", 100, text_con, zephr.Color{34, 234, 82, 155}, .TOP_CENTER)

  // score
  buf: [24]byte
  score := fmt.bprintf(buf[:], "Score   %d", game.score)

  zephr.set_parent_constraint(&text_con, nil)
  zephr.set_x_constraint(&text_con, 0.05, .RELATIVE)
  zephr.set_y_constraint(&text_con, 0.8, .RELATIVE)
  zephr.add_text_instance(&text_batch, score, 40, text_con, zephr.COLOR_BLACK, .TOP_LEFT)

  zephr.draw_text_batch(&text_batch)
}

draw_board :: proc() {
  // board
  board_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_y_constraint(&board_con, 0.05, .RELATIVE)
  zephr.set_height_constraint(&board_con, 0.6, .RELATIVE)
  zephr.set_width_constraint(&board_con, 1, .ASPECT_RATIO)
  style := zephr.UiStyle{
    bg_color = game.palette.board_bg_color,
    border_radius = board_con.width * 0.02,
    align = .CENTER,
  }
  zephr.draw_quad(&board_con, style)

  // empty tiles
  tile_padding := board_con.width * 0.02
  tile_height := board_con.height * 0.225
  tile_board_radius := tile_height * 0.15

  empty_tile_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&empty_tile_con, &board_con)
  zephr.set_height_constraint(&empty_tile_con, tile_height, .FIXED)
  zephr.set_width_constraint(&empty_tile_con, 1, .ASPECT_RATIO)

  style = zephr.UiStyle{
    bg_color = zephr.mult_color(game.palette.board_bg_color, 0.85),
    border_radius = tile_board_radius,
    align = .TOP_LEFT,
  }
  for i in 0..<4 {
    zephr.set_y_constraint(&empty_tile_con, (tile_height + tile_padding) * cast(f32)i + tile_padding, .FIXED)
    for j in 0..<4 {
      zephr.set_x_constraint(&empty_tile_con, (tile_height + tile_padding) * cast(f32)j + tile_padding, .FIXED)
      zephr.draw_quad(&empty_tile_con, style)
    }
  }

  // filled tiles
  text_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_width_constraint(&text_con, 1.5, .RELATIVE_PIXELS)
  tile_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&tile_con, &board_con)
  zephr.set_height_constraint(&tile_con, tile_height, .FIXED)
  zephr.set_width_constraint(&tile_con, 1, .ASPECT_RATIO)

  for row in 0..<4 {
    for col in 0..<4 {
      tile := &game.board[row][col]
      if tile.value == 0 {
        continue
      }

      tile_color := get_tile_color(tile.value)
      style := zephr.UiStyle {
        bg_color = tile_color,
        border_radius = tile_board_radius,
        align = .TOP_LEFT,
      }
      buf: [16]byte
      value := fmt.bprintf(buf[:], "%d", tile.value)
      tile_y_pos := ((tile_height + tile_padding) * tile.position.x + tile_padding)
      tile_x_pos := ((tile_height + tile_padding) * tile.position.y + tile_padding)

      zephr.set_y_constraint(&tile_con, tile_y_pos, .FIXED)
      zephr.set_x_constraint(&tile_con, tile_x_pos, .FIXED)
      zephr.draw_quad(&tile_con, style)

      // value text
      zephr.set_parent_constraint(&text_con, &tile_con)
      zephr.set_x_constraint(&text_con, 0, .FIXED)
      zephr.set_y_constraint(&text_con, 0, .FIXED)

      zephr.draw_text(value, get_tile_font_size(tile.value), text_con, zephr.mult_color(tile_color, 0.5), .CENTER)
    }
  }

  if (game.spawning_new_tile) {
    // spawning tile
    tile_color := get_tile_color(game.spawning_tile_value)
    style := zephr.UiStyle {
      bg_color = tile_color,
      border_radius = tile_board_radius,
      align = .TOP_LEFT,
    }
    tile_x_pos := ((tile_height + tile_padding) * game.spawning_tile_coords.y + tile_padding)
    tile_y_pos := ((tile_height + tile_padding) * game.spawning_tile_coords.x + tile_padding)
    zephr.set_x_constraint(&tile_con, tile_x_pos, .FIXED)
    zephr.set_y_constraint(&tile_con, tile_y_pos, .FIXED)
    zephr.set_height_constraint(&tile_con, tile_height, .FIXED)
    zephr.set_width_constraint(&tile_con, 1, .ASPECT_RATIO)
    tile_con.scale = game.spawning_tile_scale
    zephr.draw_quad(&tile_con, style)
    // value text
    zephr.set_parent_constraint(&text_con, &tile_con)
    zephr.set_x_constraint(&text_con, 0, .FIXED)
    zephr.set_y_constraint(&text_con, 0, .FIXED)
    text_con.scale = game.spawning_tile_scale

    buf: [16]byte
    value := fmt.bprintf(buf[:], "%d", game.spawning_tile_value)
    zephr.draw_text(value, cast(u32)get_tile_font_size(game.spawning_tile_value), text_con, zephr.mult_color(tile_color, 0.5), .CENTER)
  }
}

draw_ui :: proc() {
  bg_btns_state: zephr.ButtonState = (game.quit_dialog || game.help_dialog || game.settings_dialog || game.has_lost) ? .INACTIVE : .ACTIVE
  icon_btn_width :: 80
  icon_btn_offset :: 8
  icon_btns_padding :: 10

  btn_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_x_constraint(&btn_con, -icon_btn_offset, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&btn_con, icon_btn_offset, .RELATIVE_PIXELS)
  zephr.set_width_constraint(&btn_con, icon_btn_width, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&btn_con, 1, .ASPECT_RATIO)

  style := zephr.UiStyle {
    bg_color = zephr.Color{201, 146, 126, 255},
    fg_color = zephr.Color{40, 92, 100, 255},
    border_radius = btn_con.height * 0.15,
    align = .TOP_RIGHT,
  }
  if (zephr.draw_icon_button(&btn_con, game.icon_textures[.HELP_ICON], style, bg_btns_state)) {
    game.help_dialog = true
  }

  zephr.set_x_constraint(&btn_con, -icon_btn_offset - icon_btn_width - icon_btns_padding, .RELATIVE_PIXELS)
  if (zephr.draw_icon_button(&btn_con, game.icon_textures[.SETTINGS_ICON], style, bg_btns_state)) {
    game.settings_dialog = true
  }

  zephr.set_x_constraint(&btn_con, 0, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&btn_con, -0.05, .RELATIVE)
  zephr.set_width_constraint(&btn_con, 200, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&btn_con, 65, .RELATIVE_PIXELS)
  style = zephr.UiStyle {
    bg_color = zephr.Color{201, 172, 126, 255},
    fg_color = zephr.COLOR_BLACK,
    border_radius = btn_con.height * 0.25,
    align = .BOTTOM_CENTER,
  }
  if (zephr.draw_button(&btn_con, "New Game", style, bg_btns_state)) {
    reset_game()
  }

  if (game.settings_dialog) {
    draw_settings_dialog()
  }

  if (game.help_dialog) {
    draw_help_dialog()
  }

  if (game.has_lost) {
    draw_game_over()
  }

  if (game.quit_dialog) {
    draw_quit_dialog()
  }
}

draw_settings_dialog :: proc() {
  dialog_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_width_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_height_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_x_constraint(&dialog_con, 0, .FIXED)
  zephr.set_y_constraint(&dialog_con, 0, .FIXED)
  style := zephr.UiStyle {
    bg_color = zephr.Color{0, 0, 0, 200},
    align = .CENTER,
  }
  zephr.draw_quad(&dialog_con, style)

  content_card_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&content_card_con, &dialog_con)
  zephr.set_width_constraint(&content_card_con, 0.55, .RELATIVE)
  zephr.set_height_constraint(&content_card_con, 0.6, .RELATIVE)
  style = zephr.UiStyle{
    bg_color = zephr.Color{135, 124, 124, 255},
    border_radius = 8,
    align = .CENTER,
  }
  zephr.draw_quad(&content_card_con, style)

  text_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&text_con, &content_card_con)
  zephr.set_width_constraint(&text_con, 1, .RELATIVE_PIXELS)
  zephr.set_x_constraint(&text_con, 0, .FIXED)
  zephr.set_y_constraint(&text_con, 40, .RELATIVE_PIXELS)
  zephr.draw_text("Settings", 64, text_con, zephr.COLOR_YELLOW, .TOP_CENTER)

  zephr.set_x_constraint(&text_con, 30, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&text_con, 150, .RELATIVE_PIXELS)
  zephr.draw_text("Color Palette", 40, text_con, zephr.COLOR_WHITE, .TOP_LEFT)

  bg_color_text := "Background: "
  font_size: u32 = 30
  zephr.set_x_constraint(&text_con, 30, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&text_con, 220, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&text_con, 0.9, .RELATIVE)
  zephr.draw_text(bg_color_text, font_size, text_con, zephr.COLOR_WHITE, .TOP_LEFT)

  text_size := zephr.calculate_text_size(bg_color_text, font_size)
  color_picker_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&color_picker_con, &content_card_con)
  zephr.set_x_constraint(&color_picker_con, 30 + text_size.x + 20, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&color_picker_con, 220 - text_size.y / 2 + 6, .RELATIVE_PIXELS)
  zephr.set_width_constraint(&color_picker_con, 100, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&color_picker_con, 40, .RELATIVE_PIXELS)
  zephr.draw_color_picker(&color_picker_con, &game.palette.bg_color, .TOP_LEFT, .ACTIVE)

  zephr.set_y_constraint(&text_con, 270, .RELATIVE_PIXELS)
  zephr.draw_text("Board: ", font_size, text_con, zephr.COLOR_WHITE, .TOP_LEFT)

  zephr.set_x_constraint(&color_picker_con, 30 + text_size.x + 20, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&color_picker_con, 270 - text_size.y / 2 + 6, .RELATIVE_PIXELS)
  zephr.set_width_constraint(&color_picker_con, 100, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&color_picker_con, 40, .RELATIVE_PIXELS)
  zephr.draw_color_picker(&color_picker_con, &game.palette.board_bg_color, .TOP_LEFT, .ACTIVE)

  zephr.set_y_constraint(&text_con, 320, .RELATIVE_PIXELS)
  zephr.draw_text("Tiles: ", font_size, text_con, zephr.COLOR_WHITE, .TOP_LEFT)

  tile_size: f32 = 60
  for i in 0..<11 {
    zephr.set_x_constraint(&color_picker_con, 30 + text_size.x + 20 + (cast(f32)i * (tile_size + 10)), .RELATIVE_PIXELS)
    zephr.set_y_constraint(&color_picker_con, 320 - text_size.y / 2 + 6, .RELATIVE_PIXELS)
    zephr.set_width_constraint(&color_picker_con, tile_size, .RELATIVE_PIXELS)
    zephr.set_height_constraint(&color_picker_con, tile_size, .RELATIVE_PIXELS)
    zephr.draw_color_picker(&color_picker_con, &game.palette.tile_colors[i], .TOP_LEFT, .ACTIVE, cast(u32)i)

    tile_val := cast(u16)math.pow(2, cast(f32)i + 1)
    buf: [16]byte
    text := fmt.bprintf(buf[:], "%d", tile_val)
    font_size := get_tile_font_size(tile_val) / 2
    tile_color := get_tile_color(tile_val)
    zephr.set_parent_constraint(&text_con, &color_picker_con)
    zephr.set_x_constraint(&text_con, 0, .RELATIVE_PIXELS)
    zephr.set_y_constraint(&text_con, 0, .RELATIVE_PIXELS)
    zephr.draw_text(text, font_size, text_con, zephr.mult_color(tile_color, 0.5), .CENTER)
  }

  btn_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&btn_con, &content_card_con)
  zephr.set_x_constraint(&btn_con, 0, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&btn_con, 400, .RELATIVE_PIXELS)
  zephr.set_width_constraint(&btn_con, 150, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&btn_con, 0.35, .ASPECT_RATIO)
  style = zephr.UiStyle{
    bg_color = zephr.Color{201, 146, 126, 255},
    fg_color = zephr.COLOR_BLACK,
    border_radius = 8,
    align = .TOP_CENTER,
  }
  if (zephr.draw_button(&btn_con, "Reset", style, .ACTIVE)) {
    reset_palette()
  }

  zephr.set_width_constraint(&btn_con, 56, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&btn_con, 1, .ASPECT_RATIO)
  zephr.set_y_constraint(&btn_con, -24, .RELATIVE_PIXELS)
  zephr.set_x_constraint(&btn_con, 24, .RELATIVE_PIXELS)
  style = zephr.UiStyle{
    bg_color = zephr.mult_color(zephr.COLOR_WHITE, 0.8),
    fg_color = zephr.Color{232, 28, 36, 255},
    border_radius = btn_con.height * 0.2,
    align = .TOP_RIGHT,
  }
  if (zephr.draw_icon_button(&btn_con, game.icon_textures[.CLOSE_ICON], style, .ACTIVE)) {
    game.settings_dialog = false
  }
}

draw_help_dialog :: proc() {
  dialog_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_width_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_height_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_x_constraint(&dialog_con, 0, .FIXED)
  zephr.set_y_constraint(&dialog_con, 0, .FIXED)
  style := zephr.UiStyle {
    bg_color = zephr.Color{0, 0, 0, 200},
    align = .CENTER,
  }
  zephr.draw_quad(&dialog_con, style)

  content_card_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&content_card_con, &dialog_con)
  zephr.set_width_constraint(&content_card_con, 0.4, .RELATIVE)
  zephr.set_height_constraint(&content_card_con, 0.33, .RELATIVE)
  style = zephr.UiStyle{
    bg_color = zephr.Color{135, 124, 124, 255},
    border_radius = 8,
    align = .CENTER,
  }
  zephr.draw_quad(&content_card_con, style)

  text_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&text_con, &content_card_con)
  zephr.set_width_constraint(&text_con, 1, .RELATIVE_PIXELS)
  zephr.set_x_constraint(&text_con, 0, .FIXED)
  zephr.set_y_constraint(&text_con, 40, .RELATIVE_PIXELS)
  zephr.draw_text("How to play", 64, text_con, zephr.COLOR_YELLOW, .TOP_CENTER)

  zephr.set_y_constraint(&text_con, 30, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&text_con, 0.9, .RELATIVE)
  zephr.draw_text("Use the arrow keys to move the tiles.\n" +
            "When two tiles with the same number touch, they\n" +
            "merge into one!\n\nYour goal is to reach 2048 without filling all the tiles", 30., text_con, zephr.COLOR_WHITE, .CENTER)

  btn_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&btn_con, &content_card_con)
  zephr.set_width_constraint(&btn_con, 56, .RELATIVE_PIXELS)
  zephr.set_height_constraint(&btn_con, 1, .ASPECT_RATIO)
  zephr.set_y_constraint(&btn_con, -24, .RELATIVE_PIXELS)
  zephr.set_x_constraint(&btn_con, 24, .RELATIVE_PIXELS)
  style = zephr.UiStyle{
    bg_color = zephr.mult_color(zephr.COLOR_WHITE, 0.8),
    fg_color = zephr.Color{232, 28, 36, 255},
    border_radius = btn_con.height * 0.2,
    align = .TOP_RIGHT,
  }
  if (zephr.draw_icon_button(&btn_con, game.icon_textures[.CLOSE_ICON], style, .ACTIVE)) {
    game.help_dialog = false
  }
}

draw_game_over :: proc() {
  dialog_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_width_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_height_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_x_constraint(&dialog_con, 0, .FIXED)
  zephr.set_y_constraint(&dialog_con, 0, .FIXED)
  style := zephr.UiStyle {
    bg_color = zephr.Color{0, 0, 0, cast(u8)game.game_over_bg_opacity},
    align = .CENTER,
  }
  zephr.draw_quad(&dialog_con, style)

  content_card_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&content_card_con, &dialog_con)
  zephr.set_width_constraint(&content_card_con, 0.3, .RELATIVE)
  zephr.set_height_constraint(&content_card_con, 0.2, .RELATIVE)
  style = zephr.UiStyle{
    bg_color = zephr.Color{135, 124, 124, cast(u8)game.game_over_opacity},
    border_radius = 8,
    align = .CENTER,
  }
  zephr.draw_quad(&content_card_con, style)

  text_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&text_con, &content_card_con)
  zephr.set_width_constraint(&text_con, 1, .RELATIVE_PIXELS)
  zephr.set_x_constraint(&text_con, 0, .FIXED)
  zephr.set_y_constraint(&text_con, 40, .RELATIVE_PIXELS)
  zephr.draw_text("Game Over!", 64, text_con, zephr.Color{255, 255, 0, cast(u8)game.game_over_opacity}, .TOP_CENTER)

  btn_con := zephr.DEFAULT_UI_CONSTRAINTS
  btn_state: zephr.ButtonState = game.quit_dialog ? .INACTIVE : game.game_over_opacity > 0 ? .ACTIVE : .INACTIVE
  zephr.set_parent_constraint(&btn_con, &content_card_con)
  zephr.set_x_constraint(&btn_con, 0, .RELATIVE_PIXELS)
  zephr.set_y_constraint(&btn_con, -24, .RELATIVE_PIXELS)
  zephr.set_width_constraint(&btn_con, 0.30, .RELATIVE)
  zephr.set_height_constraint(&btn_con, 0.3, .ASPECT_RATIO)
  style = zephr.UiStyle{
    bg_color = zephr.Color{201, 146, 126, cast(u8)game.game_over_opacity},
    fg_color = zephr.Color{0, 0, 0, cast(u8)game.game_over_opacity},
    border_radius = 8,
    align = .BOTTOM_CENTER,
  }
  if (zephr.draw_button(&btn_con, "Try Again", style, btn_state)) {
    reset_game()
  }
}

draw_quit_dialog :: proc() {
  dialog_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_x_constraint(&dialog_con, 0, .FIXED)
  zephr.set_y_constraint(&dialog_con, 0, .FIXED)
  zephr.set_width_constraint(&dialog_con, 1, .RELATIVE)
  zephr.set_height_constraint(&dialog_con, 1, .RELATIVE)
  style := zephr.UiStyle {
    bg_color = zephr.Color{0, 0, 0, 200},
    align = .CENTER,
  }
  zephr.draw_quad(&dialog_con, style)

  zephr.set_width_constraint(&dialog_con, 0.4, .RELATIVE)
  zephr.set_height_constraint(&dialog_con, 0.2, .RELATIVE)
  style = zephr.UiStyle{
    bg_color = zephr.Color{135, 124, 124, 255},
    border_radius = 8,
    align = .CENTER,
  }
  zephr.draw_quad(&dialog_con, style)

  text_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&text_con, &dialog_con)
  zephr.set_x_constraint(&text_con, 0, .FIXED)
  zephr.set_y_constraint(&text_con, -0.25, .RELATIVE)
  zephr.set_width_constraint(&text_con, 1, .RELATIVE_PIXELS)
  zephr.draw_text("Are you sure you want to quit?", 36, text_con, zephr.COLOR_WHITE, .CENTER)

  btn_con := zephr.DEFAULT_UI_CONSTRAINTS
  zephr.set_parent_constraint(&btn_con, &dialog_con)
  zephr.set_width_constraint(&btn_con, 0.25, .RELATIVE)
  zephr.set_height_constraint(&btn_con, 0.25, .RELATIVE)
  zephr.set_y_constraint(&btn_con, -0.10, .RELATIVE)
  zephr.set_x_constraint(&btn_con, -0.20, .RELATIVE)
  style = zephr.UiStyle{
    bg_color = zephr.mult_color(zephr.COLOR_WHITE, 0.9),
    fg_color = zephr.COLOR_BLACK,
    border_radius = btn_con.height * 0.2,
    align = .BOTTOM_CENTER,
  }
  if (zephr.draw_button(&btn_con, "Yes", style, .ACTIVE)) {
    zephr.quit()
  }

  zephr.set_y_constraint(&btn_con, -0.10, .RELATIVE)
  zephr.set_x_constraint(&btn_con, 0.20, .RELATIVE)
  if (zephr.draw_button(&btn_con, "No", style, .ACTIVE)) {
    game.quit_dialog = false
  }
}
