package freetype

foreign import freetype "system:freetype"

foreign freetype {
  @(link_name = "FT_Init_FreeType")
  Init_FreeType   :: proc(lib: ^Library) -> FT_Error ---
  @(link_name = "FT_New_Face")
  New_Face        :: proc(lib: Library, file_pathname: cstring, face_index: FT_Long, face: ^Face) -> FT_Error ---
  @(link_name = "FT_Set_Pixel_Sizes")
  Set_Pixel_Sizes :: proc(face: Face, pixel_width: FT_UInt, pixel_height: FT_UInt) -> FT_Error ---
  @(link_name = "FT_Load_Char")
  Load_Char       :: proc(face: Face, char_code: FT_ULong, load_flags: LoadFlags) -> FT_Error ---
  @(link_name = "FT_Done_Face")
  Done_Face       :: proc(face: Face) -> FT_Error ---
  @(link_name = "FT_Done_FreeType")
  Done_FreeType   :: proc(lib: Library) -> FT_Error ---
}
