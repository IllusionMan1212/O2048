package main

import "zephr"

font_path :: "assets/fonts/Rubik/Rubik-VariableFont_wght.ttf"
when ODIN_OS == .Windows {icon_path :: "assets/icon-128x128.ico"}
when ODIN_OS == .Linux   {icon_path :: "assets/icon-128x128.png"}
title     :: "2048"

main :: proc() {
  zephr.init(font_path, icon_path, title, zephr.Vec2{1200, 800}, true)

  game_loop()

  zephr.deinit()
}
