(*
The zlib/libpng License (Zlib)

Copyright (c) 2014 Jacob Lindberg

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
*)

unit fastfont;

interface

uses
  Allegro5,
  al5font,
  al5image,
  al5primitives,
  Types;

type
  TFastFont = class
  private
    GlyphTexture: ALLEGRO_BITMAPptr;
    LineHeight, SpaceWidth: Integer;
    GlyphWidths: array[33..126] of Integer;
    GlyphCoords: array[33..126] of TRect;
    Loaded: Boolean;
    Vertices: array of ALLEGRO_VERTEX;
    VertexOffset: Integer;
    Indices: array of Integer;
    ExColor, ExShadow: ALLEGRO_COLOR;
    ExLineSpacing: Single;
  public
    constructor create(Font: ALLEGRO_FONTptr);
    destructor destroy; override;
    property is_loaded: Boolean read Loaded;
    procedure reserve(GlyphCount: Integer);
    procedure clear;
    procedure add(Color: ALLEGRO_COLOR; X, Y: Single; const Text: String);
    procedure set_ex(Color, Shadow: ALLEGRO_COLOR; LineSpacing: Integer);
    procedure add_ex(X, Y: Single; const Text: String); overload;
    procedure add_ex(X, Y: Single; const Texts: array of String); overload;
    procedure draw;
  end;

implementation

const
  GLYPH_TEXTURE_SIZE = 256;

constructor TFastFont.create(Font: ALLEGRO_FONTptr);
var
  NextX, NextY, I: Integer;
begin
  Loaded := false;

  GlyphTexture := al_create_bitmap(GLYPH_TEXTURE_SIZE, GLYPH_TEXTURE_SIZE);
  if GlyphTexture = nil then
    exit;

  LineHeight := al_get_font_line_height(Font);
  SpaceWidth := al_get_text_width(Font, ' ');

  al_set_target_bitmap(GlyphTexture);
  al_clear_to_color(al_map_rgba(0, 0, 0, 0));
  // Draw all ASCII glyphs to the glyph texture.
  NextX := 0;
  NextY := 0;
  for I := 33 to 126 do
  begin
    GlyphWidths[I] := al_get_text_width(Font, Chr(I));
    if NextX + GlyphWidths[I] > GLYPH_TEXTURE_SIZE then
    begin
      NextX := 0;
      NextY := NextY + LineHeight;
    end;
    al_draw_text(Font, al_map_rgb(255, 255, 255), NextX, NextY, 0, Chr(I));
    GlyphCoords[I].Left := NextX;
    GlyphCoords[I].Top := NextY;
    NextX := NextX + GlyphWidths[I];
    GlyphCoords[I].Right := NextX - 1;
    GlyphCoords[I].Bottom := NextY + LineHeight - 1;
  end;
  al_set_target_backbuffer(al_get_current_display);

  VertexOffset := 0;

  ExColor := al_map_rgb(255, 255, 255);
  ExShadow := al_map_rgb(0, 0, 0);
  ExLineSpacing := 0;

  Loaded := true;
end;

destructor TFastFont.destroy;
begin
  if GlyphTexture <> nil then
    al_destroy_bitmap(GlyphTexture);

  inherited;
end;

procedure TFastFont.reserve(GlyphCount: Integer);
var
  I: Integer;
begin
  if not Loaded then
    exit;

  SetLength(Vertices, 4 * GlyphCount);
  SetLength(Indices, 6 * GlyphCount);

  if GlyphCount > VertexOffset div 4 then
  begin
    for I := VertexOffset to High(Vertices) do
      Vertices[I].z := 0;
    for I := VertexOffset div 4 * 6 to High(Indices) do
      // Make index pattern: 0, 1, 2, 1, 2, 3,
      //                     4, 5, 6, 5, 6, 7,
      //                     ...
      Indices[I] := (I mod 3) + (I div 3 mod 2) + (I div 6 * 4);
  end;
end;

procedure TFastFont.clear;
begin
  if not Loaded then
    exit;

  VertexOffset := 0;
end;

procedure TFastFont.add(Color: ALLEGRO_COLOR; X, Y: Single; const Text: String);
var
  NextX: Single;
  PreOffset, I, Glyph: Integer;
begin
  if not Loaded then
    exit;

  if Length(Text) > (Length(Vertices) - VertexOffset) div 4 then
  begin
    // Reserve vertices and indices to satisfy text length.
    reserve(VertexOffset div 4 + Length(Text));
  end;

  NextX := X;
  PreOffset := VertexOffset;
  for I := 1 to Length(Text) do
  begin
    Glyph := Ord(Text[I]);
    if (Glyph < 32) or (Glyph > 126) then
      // Skip invalid glyph.
      continue;
    if Glyph = 32 then
    begin
      // Don't draw spaces.
      NextX := NextX + SpaceWidth;
      continue;
    end;
    // Make glyph vertex and texcoord rectangle.
    Vertices[VertexOffset].x := NextX;
    Vertices[VertexOffset].y := Y;
    Vertices[VertexOffset].u := GlyphCoords[Glyph].Left + 0.5;
    Vertices[VertexOffset].v := GlyphCoords[Glyph].Top + 0.5;
    Vertices[VertexOffset + 1].x := NextX + GlyphWidths[Glyph];
    Vertices[VertexOffset + 1].y := Y;
    Vertices[VertexOffset + 1].u := GlyphCoords[Glyph].Right + 0.5;
    Vertices[VertexOffset + 1].v := GlyphCoords[Glyph].Top + 0.5;
    Vertices[VertexOffset + 2].x := NextX;
    Vertices[VertexOffset + 2].y := Y + LineHeight;
    Vertices[VertexOffset + 2].u := GlyphCoords[Glyph].Left + 0.5;
    Vertices[VertexOffset + 2].v := GlyphCoords[Glyph].Bottom + 0.5;
    Vertices[VertexOffset + 3].x := NextX + GlyphWidths[Glyph];
    Vertices[VertexOffset + 3].y := Y + LineHeight;
    Vertices[VertexOffset + 3].u := GlyphCoords[Glyph].Right + 0.5;
    Vertices[VertexOffset + 3].v := GlyphCoords[Glyph].Bottom + 0.5;
    Inc(VertexOffset, 4);
    NextX := NextX + GlyphWidths[Glyph];
  end;
  for I := PreOffset to VertexOffset - 1 do
    Vertices[I].color := Color;
end;

procedure TFastFont.set_ex(Color, Shadow: ALLEGRO_COLOR; LineSpacing: Integer);
begin
  if not Loaded then
    exit;

  ExColor := Color;
  ExShadow := Shadow;
  ExLineSpacing := LineSpacing;
end;

procedure TFastFont.add_ex(X, Y: Single; const Text: String);
begin
  if not Loaded then
    exit;

  if ExShadow.a > 0 then
    add(ExShadow, X + 1, Y + 1, Text);
  add(ExColor, X, Y, Text);
end;

procedure TFastFont.add_ex(X, Y: Single; const Texts: array of String);
var
  I: Integer;
begin
  if not Loaded then
    exit;

  for I := 0 to High(Texts) do
    add_ex(X, I * (LineHeight + ExLineSpacing) + Y, Texts[I]);
end;

procedure TFastFont.draw;
begin
  if not Loaded then
    exit;

  if VertexOffset > 0 then
    al_draw_indexed_prim(Addr(Vertices[0]), nil, GlyphTexture, Indices,
      VertexOffset div 4 * 6, ALLEGRO_PRIM_TRIANGLE_LIST);
end;

end.
