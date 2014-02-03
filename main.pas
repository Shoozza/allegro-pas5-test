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
  SysUtils;

const
  DISPLAY_WIDTH  = 800;
  DISPLAY_HEIGHT = 600;
  FRAME_TIMER_RATE = 60;
  GRENADE_RADIUS = 10;
  GRENADE_SPEED = 100;
  GRENADE_COUNT = 9;

  GRENADE_VERTEX_COUNT = GRENADE_COUNT*4;
  GRENADE_INDEX_COUNT = GRENADE_COUNT*6;

type
  TGrenade = record
    X, Y, XSpeed, YSpeed: Single;
  end;

var
  Display: ALLEGRO_DISPLAYptr;
  EventQueue: ALLEGRO_EVENT_QUEUEptr;
  LastFrameTime: TDateTime;
  FrameDeltaTime: Word;
  FrameTimer: ALLEGRO_TIMERptr;
  UsingFrameTimer: Boolean;
  FpsTimer: ALLEGRO_TIMERptr;
  Fps, ElapsedFrames: Integer;
  Font: ALLEGRO_FONTptr;
  GrenadeTexture: ALLEGRO_BITMAPptr;
  Grenades: array[1..GRENADE_COUNT] of TGrenade;
  GrenadeVertices: array[0..GRENADE_VERTEX_COUNT - 1] of ALLEGRO_VERTEX;
  GrenadeIndices: array[0..GRENADE_INDEX_COUNT - 1] of Integer;
  BackgroundVertices: array[0..3] of ALLEGRO_VERTEX;

procedure init;
var
  I: Integer;
  No, Seed: Word;
begin
  WriteLn('init');

  DecodeTime(Now, No, No, No, Seed);
  RandSeed := Seed;

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

  if not al_install_keyboard then
  begin
    WriteLn('install keyboard error');
    halt(1);
  end;

  Display := al_create_display(DISPLAY_WIDTH, DISPLAY_HEIGHT);
  if Display = nil then
  begin
    WriteLn('create display error');
    halt(1);
  end;

  al_set_window_title(Display, 'allegro-pas5 test1');

  EventQueue := al_create_event_queue();
  if EventQueue = nil then
  begin
    WriteLn('create event queue error');
    halt(1);
  end;

  FrameTimer := al_create_timer(1/FRAME_TIMER_RATE);
  UsingFrameTimer := false;

  FpsTimer := al_create_timer(1);
  al_start_timer(FpsTimer);
  Fps := 0;
  ElapsedFrames := 0;

  al_register_event_source(EventQueue, al_get_keyboard_event_source);
  al_register_event_source(EventQueue, al_get_display_event_source(Display));
  al_register_event_source(EventQueue, al_get_timer_event_source(FrameTimer));
  al_register_event_source(EventQueue, al_get_timer_event_source(FpsTimer));

  Font := al_load_font('media/lucon.ttf', 18, ALLEGRO_TTF_MONOCHROME);

  GrenadeTexture := al_load_bitmap('media/nade.png');

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
    // Make vertex rectangle.
    BackgroundVertices[I].x := I mod 2 * DISPLAY_WIDTH;
    BackgroundVertices[I].y := I div 2 mod 2 * DISPLAY_HEIGHT;
    BackgroundVertices[I].z := 0;
  end;
  BackgroundVertices[0].color := al_map_rgb(198, 163, 204);
  BackgroundVertices[1].color := al_map_rgb(198, 163, 204);
  BackgroundVertices[2].color := al_map_rgb(16, 24, 15);
  BackgroundVertices[3].color := al_map_rgb(16, 24, 15);

  LastFrameTime := Now;
end;

procedure cleanup;
begin
  WriteLn('cleanup');

  al_destroy_bitmap(GrenadeTexture);
  al_destroy_font(Font);
  al_destroy_timer(FpsTimer);
  al_destroy_timer(FrameTimer);
  al_destroy_event_queue(EventQueue);
  al_destroy_display(Display);
  al_uninstall_keyboard;
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
      end;
    ALLEGRO_EVENT_TIMER:
      if Event.timer.source = FpsTimer then
      begin
        Fps := ElapsedFrames;
        ElapsedFrames := 0;
      end;
  end;
end;

procedure update;
var
  I: Integer;
begin
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
end;

procedure render;
var
  I: Integer;
  Text: String;
  LineHeight: Integer;
begin
  al_draw_prim(Addr(BackgroundVertices[0]), Nil, Nil, 0, 4,
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
  al_draw_indexed_prim(Addr(GrenadeVertices[0]), Nil, GrenadeTexture,
    GrenadeIndices, Length(GrenadeIndices), ALLEGRO_PRIM_TRIANGLE_LIST);

  LineHeight := al_get_font_line_height(Font);
  Text := 'FPS: ' + IntToStr(Fps);
  al_draw_text(Font, al_map_rgb(0, 0, 0), 1, 1, 0, Text);
  al_draw_text(Font, al_map_rgb(255, 255, 255), 0, 0, 0, Text);
  if UsingFrameTimer then
    Text := 'Frame timer: ' + IntToStr(FRAME_TIMER_RATE) + ' [F]'
  else
    Text := 'Frame timer: Off [F]';
  al_draw_text(Font, al_map_rgb(0, 0, 0), 1, LineHeight + 1, 0, Text);
  al_draw_text(Font, al_map_rgb(255, 255, 255), 0, LineHeight, 0, Text);

  al_flip_display();
end;

procedure gameLoop;
var
  Running: Boolean;
  Event: ALLEGRO_EVENT;
  TimeDiff: TDateTime;
  No, Seconds, MilliSeconds: Word;
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
      begin
        TimeDiff := Now - LastFrameTime;
        LastFrameTime := LastFrameTime + TimeDiff;
        DecodeTime(TimeDiff, No, No, Seconds, MilliSeconds);
        FrameDeltaTime := 1000 * Seconds + MilliSeconds;
        Inc(ElapsedFrames);

        update;
        render;
      end else
        Running := handleEvent(Event);
    end else // if UsingFrameTimer
    begin
      if al_get_next_event(EventQueue, Event) then
        Running := handleEvent(Event)
      else
      begin
        TimeDiff := Now - LastFrameTime;
        LastFrameTime := LastFrameTime + TimeDiff;
        DecodeTime(TimeDiff, No, No, Seconds, MilliSeconds);
        FrameDeltaTime := 1000 * Seconds + MilliSeconds;
        Inc(ElapsedFrames);

        update;
        render;
      end;
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

