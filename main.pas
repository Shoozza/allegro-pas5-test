unit main;

interface

procedure run;

implementation

uses
  Allegro5,
  al5primitives,
  al5font,
  al5ttf,
  al5image,
  al5audio,
  al5acodec,
  fastfont,
  SysUtils;

const
  DISPLAY_WIDTH  = 800;
  DISPLAY_HEIGHT = 600;
  WINDOW_TITLE = 'allegro-pas5 test1';
  FRAME_TIMER_RATE = 60;
  GRENADE_RADIUS = 10;
  GRENADE_SPEED = 100;
  GRENADE_COUNT = 9;
  ZOOM_AMOUNT = 2;
  RESERVED_SAMPLES = 1;
  MUSIC_GAIN = 0.5;

  GRENADE_VERTEX_COUNT = 4 * GRENADE_COUNT;
  GRENADE_INDEX_COUNT = 6 * GRENADE_COUNT;

type
  TGrenade = record
    X, Y, XSpeed, YSpeed: Single;
  end;

var
  Display: ALLEGRO_DISPLAYptr;
  EventQueue: ALLEGRO_EVENT_QUEUEptr;
  Music: ALLEGRO_SAMPLEptr;
  MusicId: ALLEGRO_SAMPLE_ID;
  LastFrameTime: TDateTime;
  FrameDeltaTime: Word;
  FrameTimer: ALLEGRO_TIMERptr;
  UsingFrameTimer: Boolean;
  FpsTimer: ALLEGRO_TIMERptr;
  Fps, ElapsedFrames: Integer;
  Font: ALLEGRO_FONTptr;
  FontDrawer: TFastFont;
  GrenadeTexture: ALLEGRO_BITMAPptr;
  BackgroundTexture: ALLEGRO_BITMAPptr;
  Grenades: array[1..GRENADE_COUNT] of TGrenade;
  GrenadeVertices: array[0..GRENADE_VERTEX_COUNT - 1] of ALLEGRO_VERTEX;
  GrenadeIndices: array[0..GRENADE_INDEX_COUNT - 1] of Integer;
  BackgroundVertices: array[0..3] of ALLEGRO_VERTEX;
  ShowingText: Boolean;
  Zoomed: Boolean;
  XZoom, YZoom: Single;
  MusicMuted: Boolean;

procedure init_allegro;
begin
  if not al_init then
  begin
    WriteLn('init error');
    halt(1);
  end;

  al_init_font_addon;
  if not al_init_ttf_addon then
  begin
    WriteLn('init ttf addon error');
    halt(1);
  end;

  if not al_init_image_addon then
  begin
    WriteLn('init image addon error');
    halt(1);
  end;

  if not al_init_primitives_addon then
  begin
    WriteLn('init primitives addon error');
    halt(1);
  end;

  if not al_install_audio then
  begin
    WriteLn('install audio error');
    halt(1);
  end;
  if not al_init_acodec_addon then
  begin
    WriteLn('init acodec addon error');
    halt(1);
  end;
  if not al_reserve_samples(RESERVED_SAMPLES) then
  begin
    WriteLn('reserve samples error');
    halt(1);
  end;

  if not al_install_keyboard then
  begin
    WriteLn('install keyboard error');
    halt(1);
  end;

  if not al_install_mouse then
  begin
    WriteLn('install mouse error');
    halt(1);
  end;

  Display := al_create_display(DISPLAY_WIDTH, DISPLAY_HEIGHT);
  if Display = nil then
  begin
    WriteLn('create display error');
    halt(1);
  end;

  EventQueue := al_create_event_queue();
  if EventQueue = nil then
  begin
    WriteLn('create event queue error');
    halt(1);
  end;
end;

procedure init_resources;
begin
  Music := al_load_sample('media/music.ogg');
  if Music = nil then
  begin
    WriteLn('load music sample error');
    halt(1);
  end;

  Font := al_load_font('media/lucon.ttf', 14, ALLEGRO_TTF_MONOCHROME);
  if Font = nil then
  begin
    WriteLn('load font error');
    halt(1);
  end;
  FontDrawer := TFastFont.create(Font, 128);
  if FontDrawer = nil then
  begin
    WriteLn('create fast font error');
    halt(1);
  end;
  FontDrawer.set_ex(al_map_rgb(255, 255, 255), al_map_rgba(0, 0, 0, 127), 2);

  GrenadeTexture := al_load_bitmap('media/nade.png');
  if GrenadeTexture = nil then
  begin
    WriteLn('load grenade bitmap error');
    halt(1);
  end;

  BackgroundTexture := al_load_bitmap('media/ananas.bmp');
  if BackgroundTexture = nil then
  begin
    WriteLn('load background bitmap error');
    halt(1);
  end;
end;

procedure init;
var
  I: Integer;
  No, Seed: Word;
begin
  WriteLn('init');

  init_allegro;

  al_set_window_title(Display, WINDOW_TITLE);

  DecodeTime(Now, No, No, No, Seed);
  RandSeed := Seed;

  init_resources;

  FrameTimer := al_create_timer(1/FRAME_TIMER_RATE);
  al_start_timer(FrameTimer);
  UsingFrameTimer := true;

  FpsTimer := al_create_timer(1);
  al_start_timer(FpsTimer);
  Fps := 0;
  ElapsedFrames := 0;

  al_register_event_source(EventQueue, al_get_keyboard_event_source);
  al_register_event_source(EventQueue, al_get_mouse_event_source);
  al_register_event_source(EventQueue, al_get_display_event_source(Display));
  al_register_event_source(EventQueue, al_get_timer_event_source(FrameTimer));
  al_register_event_source(EventQueue, al_get_timer_event_source(FpsTimer));

  for I := 1 to High(Grenades) do
  begin
    Grenades[I].X := Random * (DISPLAY_WIDTH - 2 * GRENADE_RADIUS) +
      GRENADE_RADIUS;
    Grenades[I].Y := Random * (DISPLAY_HEIGHT - 2 * GRENADE_RADIUS) +
      GRENADE_RADIUS;
    Grenades[I].XSpeed := 2 * GRENADE_SPEED * Random - GRENADE_SPEED;
    Grenades[I].YSpeed := 2 * GRENADE_SPEED * Random - GRENADE_SPEED;
  end;

  for I := 0 to High(GrenadeVertices) do
  begin
    GrenadeVertices[I].z := 0;
    // Make texcoord squares: (0, 0), (1, 0), (0, 1), (1, 1), repeat...
    GrenadeVertices[I].u := I mod 2 * al_get_bitmap_width(GrenadeTexture);
    GrenadeVertices[I].v := I div 2 mod 2 * al_get_bitmap_height(GrenadeTexture);
    GrenadeVertices[I].color := al_map_rgb(255, 255, 255);
  end;

  for I := 0 to High(GrenadeIndices) do
    // Make index pattern: 0, 1, 2, 1, 2, 3,
    //                     4, 5, 6, 5, 6, 7,
    //                     ...
    GrenadeIndices[I] := (I mod 3) + (I div 3 mod 2) + (I div 6 * 4);

  for I := 0 to High(BackgroundVertices) do
  begin
    // Make vertex and texcoord rectangle.
    BackgroundVertices[I].x := I mod 2 * DISPLAY_WIDTH;
    BackgroundVertices[I].y := I div 2 mod 2 * DISPLAY_HEIGHT;
    BackgroundVertices[I].z := 0;
    BackgroundVertices[I].u := I mod 2 * DISPLAY_WIDTH;
    BackgroundVertices[I].v := I div 2 mod 2 * DISPLAY_HEIGHT;
  end;
  BackgroundVertices[0].color := al_map_rgb(198, 163, 204);
  BackgroundVertices[1].color := al_map_rgb(198, 163, 204);
  BackgroundVertices[2].color := al_map_rgb(16, 24, 15);
  BackgroundVertices[3].color := al_map_rgb(16, 24, 15);

  ShowingText := true;
  Zoomed := false;
  MusicMuted := true;

  LastFrameTime := Now;
end;

procedure cleanup;
begin
  WriteLn('cleanup');

  al_destroy_bitmap(BackgroundTexture);
  al_destroy_bitmap(GrenadeTexture);
  FontDrawer.destroy;
  al_destroy_font(Font);
  al_destroy_sample(Music);
  al_destroy_timer(FpsTimer);
  al_destroy_timer(FrameTimer);
  al_destroy_event_queue(EventQueue);
  al_destroy_display(Display);
  al_uninstall_mouse;
  al_uninstall_keyboard;
  al_uninstall_audio;
  al_shutdown_primitives_addon;
  al_shutdown_image_addon;
  al_shutdown_ttf_addon;
  al_shutdown_font_addon;
end;

function handleEvent(Event: ALLEGRO_EVENT): Boolean;
begin
  Result := true;
  case Event._type of
    ALLEGRO_EVENT_DISPLAY_CLOSE:
      Result := false;
    ALLEGRO_EVENT_KEY_DOWN:
      case Event.keyboard.keycode of
        ALLEGRO_KEY_ESCAPE:
          Result := false;
        ALLEGRO_KEY_F:
        begin
          if UsingFrameTimer then
            al_stop_timer(FrameTimer)
          else
            al_start_timer(FrameTimer);
          UsingFrameTimer := not UsingFrameTimer;
        end;
        ALLEGRO_KEY_T:
        begin
          if not ShowingText then
            al_set_window_title(Display, WINDOW_TITLE);
          ShowingText := not ShowingText;
        end;
        ALLEGRO_KEY_M:
        begin
          if MusicMuted then
            al_play_sample(Music, MUSIC_GAIN, 0, 1, ALLEGRO_PLAYMODE_LOOP,
              Addr(MusicId))
          else
            al_stop_sample(Addr(MusicId));
          MusicMuted := not MusicMuted;
        end;
      end;
    ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
      if Event.mouse.button = 2 then
        Zoomed := not Zoomed;
    ALLEGRO_EVENT_TIMER:
      if Event.timer.source = FpsTimer then
      begin
        Fps := ElapsedFrames;
        ElapsedFrames := 0;
        if not ShowingText then
          al_set_window_title(Display, WINDOW_TITLE + ' [FPS: ' + IntToStr(Fps) +
            ']');
      end;
  end; // case Event._type
end;

procedure render;
var
  I: Integer;
  Text: String;
  LineHeight: Integer;
  Transform: ALLEGRO_TRANSFORM;
begin
  al_identity_transform(Transform);
  if Zoomed then
  begin
    al_translate_transform(Transform, -XZoom, -YZoom);
    al_scale_transform(Transform, ZOOM_AMOUNT, ZOOM_AMOUNT);
  end;
  al_use_transform(Transform);

  al_draw_prim(Addr(BackgroundVertices[0]), nil, BackgroundTexture, 0, 4,
    ALLEGRO_PRIM_TRIANGLE_STRIP);

  for I := 1 to High(Grenades) do
  begin
    GrenadeVertices[I * 4 - 4].x := Grenades[I].X - GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 4].y := Grenades[I].Y - GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 3].x := Grenades[I].X + GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 3].y := Grenades[I].Y - GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 2].x := Grenades[I].X - GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 2].y := Grenades[I].Y + GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 1].x := Grenades[I].X + GRENADE_RADIUS;
    GrenadeVertices[I * 4 - 1].y := Grenades[I].Y + GRENADE_RADIUS;
  end;
  al_draw_indexed_prim(Addr(GrenadeVertices[0]), nil, GrenadeTexture,
    GrenadeIndices, Length(GrenadeIndices), ALLEGRO_PRIM_TRIANGLE_LIST);

  al_identity_transform(Transform);
  al_use_transform(Transform);
  if ShowingText then
  begin
    LineHeight := al_get_font_line_height(Font) + 2;
    FontDrawer.clear;
    Text := 'FPS: ' + IntToStr(Fps);
    FontDrawer.add_ex(0, 0, Text);
    if UsingFrameTimer then
      Text := 'Frame timer: ' + IntToStr(FRAME_TIMER_RATE) + ' [F]'
    else
      Text := 'Frame timer: Off [F]';
    FontDrawer.add_ex(0, LineHeight, Text);
    Text := 'Showing text [T]';
    FontDrawer.add_ex(0, 2 * LineHeight, Text);
    if Zoomed then
      Text := 'Zoom: ' + IntToStr(ZOOM_AMOUNT) + ' [MB2]'
    else
      Text := 'Zoom: 1 [MB2]';
    FontDrawer.add_ex(0, 3 * LineHeight, Text);
    if MusicMuted then
      Text := 'Music: Off [M]'
    else
      Text := 'Music: On [M]';
    FontDrawer.add_ex(0, 4 * LineHeight, Text);

    FontDrawer.add_ex(50, 200, ['1 Desert Eagles', '2 HK MP5', '3 AK-74',
      '4 Steyr AUG', '5 Spas-12', '6 Ruger 77', '7 M79', '8 Barrett M82A1',
      '9 FN Minimi', '0 XM214 Minigun']);
    FontDrawer.draw;
  end;

  al_flip_display();
end;

procedure update;
var
  TimeDiff: TDateTime;
  No, Seconds, MilliSeconds: Word;
  I: Integer;
  MouseState: ALLEGRO_MOUSE_STATE;
begin
  TimeDiff := Now - LastFrameTime;
  LastFrameTime := LastFrameTime + TimeDiff;
  DecodeTime(TimeDiff, No, No, Seconds, MilliSeconds);
  FrameDeltaTime := 1000 * Seconds + MilliSeconds;
  Inc(ElapsedFrames);

  for I := 1 to High(Grenades) do
  begin
    Grenades[I].X := Grenades[I].XSpeed * FrameDeltaTime / 1000 +
      Grenades[I].X;
    Grenades[I].Y := Grenades[I].YSpeed * FrameDeltaTime / 1000 +
      Grenades[I].Y;
    // Border collision.
    if (Grenades[I].X < GRENADE_RADIUS) and (Grenades[I].XSpeed < 0) then
    begin
      Grenades[I].X := 2 * GRENADE_RADIUS - Grenades[I].X;
      Grenades[I].XSpeed := -Grenades[I].XSpeed;
    end;
    if (Grenades[I].Y < GRENADE_RADIUS) and (Grenades[I].YSpeed < 0) then
    begin
      Grenades[I].Y := 2 * GRENADE_RADIUS - Grenades[I].Y;
      Grenades[I].YSpeed := -Grenades[I].YSpeed;
    end;
    if (Grenades[I].X >= DISPLAY_WIDTH - GRENADE_RADIUS) and
      (Grenades[I].XSpeed > 0) then
    begin
      Grenades[I].X := 2 * (DISPLAY_WIDTH - GRENADE_RADIUS) - Grenades[I].X;
      Grenades[I].XSpeed := -Grenades[I].XSpeed;
    end;
    if (Grenades[I].Y >= DISPLAY_HEIGHT - GRENADE_RADIUS) and
      (Grenades[I].YSpeed > 0) then
    begin
      Grenades[I].Y := 2 * (DISPLAY_HEIGHT - GRENADE_RADIUS) - Grenades[I].Y;
      Grenades[I].YSpeed := -Grenades[I].YSpeed;
    end;
  end;

  if Zoomed then
  begin
    al_get_mouse_state(Addr(MouseState));
    XZoom := MouseState.x - DISPLAY_WIDTH / ZOOM_AMOUNT / 2;
    YZoom := MouseState.y - DISPLAY_HEIGHT / ZOOM_AMOUNT / 2;
    if XZoom < 0 then
      XZoom := 0;
    if YZoom < 0 then
      YZoom := 0;
    if XZoom > DISPLAY_WIDTH - DISPLAY_WIDTH / ZOOM_AMOUNT then
      XZoom := DISPLAY_WIDTH - DISPLAY_WIDTH / ZOOM_AMOUNT;
    if YZoom > DISPLAY_HEIGHT - DISPLAY_HEIGHT / ZOOM_AMOUNT then
      YZoom := DISPLAY_HEIGHT - DISPLAY_HEIGHT / ZOOM_AMOUNT;
  end;

  render;
end;

procedure gameLoop;
var
  Running: Boolean;
  Event: ALLEGRO_EVENT;
begin
  WriteLn('run');

  Running := true;

  while Running do
  begin
    if UsingFrameTimer then
    begin
      al_wait_for_event(EventQueue, Event);
      if (Event._type = ALLEGRO_EVENT_TIMER) and
        (Event.timer.source = FrameTimer) then
        update
      else
        Running := handleEvent(Event);
    end else // if UsingFrameTimer
    begin
      if al_get_next_event(EventQueue, Event) then
        Running := handleEvent(Event)
      else
        update;
    end; // if UsingFrameTimer else
  end; // while Running
end;

procedure run;
begin
  WriteLn('start');

  init;
  gameLoop;
  cleanup;

  WriteLn('end');
end;

end.

