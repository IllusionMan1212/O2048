package freetype

FT_Error :: i32
@private
FT_Short  :: i16
@private
FT_UShort  :: u16
@private
FT_Int  :: i32
@private
FT_UInt  :: u32
@private
FT_Long  :: i64
@private
FT_ULong :: u64
@private
FT_String :: u8

@private
FT_Pos :: i64
@private
FT_Fixed :: i64
@private
FT_SubGlyph :: ^u32 // internal object
@private
FT_Slot_Internal :: ^u32 // opaque handle to internal slot structure
@private
FT_Size_Internal :: ^u32 // opaque handle to internal size structure
@private
FT_Driver :: ^u32 // a handle to a given FreeType font driver object
@private
FT_Memory :: ^u32 // a handle to a given memory manager object

Library :: ^u32 // handle to a library object

@private
FT_Render_Mode_ :: enum {
  NORMAL = 0,
  LIGHT,
  MONO,
  LCD,
  LCD_V,
  SDF,

  MAX
}

LoadFlags :: enum {
  DEFAULT                     = 0x0,
  NO_SCALE                    = 1 << 0,
  NO_HINTING                  = 1 << 1,
  RENDER                      = 1 << 2,
  NO_BITMAP                   = 1 << 3,
  VERTICAL_LAYOUT             = 1 << 4,
  FORCE_AUTOHINT              = 1 << 5,
  CROP_BITMAP                 = 1 << 6,
  PEDANTIC                    = 1 << 7,
  IGNORE_GLOBAL_ADVANCE_WIDTH = 1 << 9,
  NO_RECURSE                  = 1 << 10,
  IGNORE_TRANSFORM            = 1 << 11,
  MONOCHROME                  = 1 << 12,
  LINEAR_DESIGN               = 1 << 13,
  NO_AUTOHINT                 = 1 << 15,
  // Bits 16-19 are used by `FT_LOAD_TARGET_`
  COLOR                       = 1 << 20,
  COMPUTE_METRICS             = 1 << 21,
  BITMAP_METRICS_ONLY         = 1 << 22,

  /* used internally only by certain font drivers */
  ADVANCE_ONLY                = 1 << 8,
  SBITS_ONLY                  = 1 << 14,

  FT_LOAD_TARGET_NORMAL       = (int(FT_Render_Mode_.NORMAL) & 15) << 16,
  FT_LOAD_TARGET_LIGHT        = (int(FT_Render_Mode_.LIGHT)  & 15) << 16,
  FT_LOAD_TARGET_MONO         = (int(FT_Render_Mode_.MONO)   & 15) << 16,
  FT_LOAD_TARGET_LCD          = (int(FT_Render_Mode_.LCD)    & 15) << 16,
  FT_LOAD_TARGET_LCD_V        = (int(FT_Render_Mode_.LCD_V)  & 15) << 16,
}

@private
FT_Encoding :: enum {
  // TODO: fill this out
}

@private
FT_CharMapRec_ :: struct {
  face: Face,
  encoding: FT_Encoding,
  platform_id: FT_UShort,
  encoding_id: FT_UShort,
}

FT_CharMap :: ^FT_CharMapRec_

@private
FT_Bitmap_Size :: struct {
  height: FT_Short,
  width: FT_Short,

  size: FT_Pos,

  x_ppem: FT_Pos,
  y_ppem: FT_Pos,
}

@private
FT_Generic :: struct {
  data: rawptr,
  finalizer: ^proc(object: rawptr),
}

@private
FT_BBox :: struct {
  xMin, yMin: FT_Pos,
  xMax, yMax: FT_Pos,
}

@private
FT_Vector :: struct {
  x, y: FT_Pos,
}

@private
FT_Glyph_Metrics :: struct {
  width: FT_Pos,
  height: FT_Pos,

  horiBearingX: FT_Pos,
  horiBearingY: FT_Pos,
  horiAdvance: FT_Pos,

  vertBearingX: FT_Pos,
  vertBearingY: FT_Pos,
  vertAdvance: FT_Pos,
}

@private
FT_Outline :: struct {
  n_contours: i16,
  n_points: i16,

  points: ^FT_Vector,
  tags: ^u8,
  contours: ^i16,

  flags: i32,
}

@private
FT_GlyphSlotRec_ :: struct {
  library: Library,
  face: Face,
  next: FT_GlyphSlot,
  glyph_index: FT_UInt, /* new in 2.10; was reserved previously */
  generic: FT_Generic,

  metrics: FT_Glyph_Metrics,
  linearHoriAdvance: FT_Fixed,
  linearVertAdvance: FT_Fixed,
  advance: FT_Vector,

  format: u32 /*FT_Glyph_Format*/, // stub this to u32 for now since I can't be bothered to define the enum

  bitmap: Bitmap,
  bitmap_left: FT_Int,
  bitmap_top: FT_Int,

  outline: FT_Outline,

  num_subglyphs: FT_UInt,
  subglyphs: FT_SubGlyph,

  control_data: rawptr,
  control_len: i64,

  lsb_delta: FT_Pos,
  rsb_delta: FT_Pos,

  other: rawptr,

  internal: FT_Slot_Internal,
}

FT_GlyphSlot :: ^FT_GlyphSlotRec_

@private
FT_Size_Metrics :: struct {
  x_ppem: FT_UShort,      /* horizontal pixels per EM               */
  y_ppem: FT_UShort,      /* vertical pixels per EM                 */

  x_scale: FT_Fixed,     /* scaling values used to convert font    */
  y_scale: FT_Fixed,     /* units to 26.6 fractional pixels        */

  ascender: FT_Pos,    /* ascender in 26.6 frac. pixels          */
  descender: FT_Pos,   /* descender in 26.6 frac. pixels         */
  height: FT_Pos,      /* text height in 26.6 frac. pixels       */
  max_advance: FT_Pos, /* max horizontal advance, in 26.6 pixels */
}

@private
FT_SizeRec :: struct {
  face: Face,
  generic: FT_Generic,
  metrics: FT_Size_Metrics,
  internal: FT_Size_Internal,
}

@private
FT_Size :: ^FT_SizeRec

//@private
//FT_StreamRec_ :: struct {
//  unsigned char*       base,
//  size: u64,
//  pos: u64,
//
//  FT_StreamDesc        descriptor,
//  FT_StreamDesc        pathname,
//  FT_Stream_IoFunc     read,
//  FT_Stream_CloseFunc  close,
//
//  FT_Memory            memory,
//  unsigned char*       cursor,
//  unsigned char*       limit,
//}

@private
FT_ListNodeRec_ :: struct {
  prev: FT_ListNode,
  next: FT_ListNode,
  data: rawptr,
}

@private
FT_ListNode :: ^FT_ListNodeRec_

@private
FT_ListRec :: struct {
  head: FT_ListNode,
  tail: FT_ListNode,
}

@private
FT_FaceRec_ :: struct {
  num_faces: FT_Long,
  face_index: FT_Long,

  face_flags: FT_Long,
  style_flags: FT_Long,

  num_glyphs: FT_Long,

  family_name: ^FT_String,
  style_name: ^FT_String,

  num_fixed_sizes: FT_Int,
  available_sizes: ^FT_Bitmap_Size,

  num_charmaps: FT_Int,
  charmaps: ^FT_CharMap,

  generic: FT_Generic,

  /*# The following member variables (down to `underline_thickness`) */
  /*# are only relevant to scalable outlines; cf. @FT_Bitmap_Size    */
  /*# for bitmap fonts.                                              */
  bbox: FT_BBox,

  units_per_EM: FT_UShort,
  ascender: FT_Short,
  descender: FT_Short,
  height: FT_Short,

  max_advance_width: FT_Short,
  max_advance_height: FT_Short,

  underline_position: FT_Short,
  underline_thickness: FT_Short,

  glyph: FT_GlyphSlot,
  size: FT_Size,
  charmap: FT_CharMap,

  /*@private begin */
  driver: FT_Driver,
  memory: FT_Memory,
  stream: /*FT_Stream*/ ^u32, // TODO: stub it out for now

  sizes_list: FT_ListRec,

  autohint: FT_Generic, // face-specific auto-hinter data
  extensions: rawptr,   // unused

  internal: /*FT_Face_Internal*/ ^u32, // TODO: stub it out for now

  /*@private end */

  //@private
  //@packed
  //@align(8)
}

Bitmap :: struct {
  rows: u32,
  width: u32,
  pitch: i32,
  buffer: [^]u8,
  num_grays: u16,
  pixel_mode: u8,
  palette_mode: u8,
  palette: rawptr,
}

Face :: ^FT_FaceRec_
