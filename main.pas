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
  GRENADE_RADIUS = 10;
  GRENADE_SPEED = 100;

type
  TGrenade = record
    X, Y, XSpeed, YSpeed: Single;
  end;

var
  Display: ALLEGRO_DISPLAYptr;
  EventQueue: ALLEGRO_EVENT_QUEUEptr;
  LastFrameTime: TDateTime;
  FrameDeltaTime: Word;
  FpsTimer: ALLEGRO_TIMERptr;
  Fps, ElapsedFrames: Integer;
  Font: ALLEGRO_FONTptr;
  Grenades: array[1..10] of TGrenade;

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

  FpsTimer := al_create_timer(1);
  al_start_timer(FpsTimer);
  Fps := 0;
  ElapsedFrames := 0;

  al_register_event_source(EventQueue, al_get_keyboard_event_source);
  al_register_event_source(EventQueue, al_get_display_event_source(Display));
  al_register_event_source(EventQueue, al_get_timer_event_source(FpsTimer));

  Font := al_load_font('media/lucon.ttf', 18, ALLEGRO_TTF_MONOCHROME);

  for I := 1 to High(Grenades) do
  begin
    Grenades[I].X := Random * (DISPLAY_WIDTH - 2 * GRENADE_RADIUS) +
      GRENADE_RADIUS;
    Grenades[I].Y := Random * (DISPLAY_HEIGHT - 2 * GRENADE_RADIUS) +
      GRENADE_RADIUS;
    Grenades[I].XSpeed := 2 * GRENADE_SPEED * Random - GRENADE_SPEED;
    Grenades[I].YSpeed := 2 * GRENADE_SPEED * Random - GRENADE_SPEED;
  end;

  LastFrameTime := Now;
end;

procedure cleanup;
begin
  WriteLn('cleanup');

  al_destroy_font(Font);
  al_destroy_timer(FpsTimer);
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
      if Event.keyboard.keycode = ALLEGRO_KEY_ESCAPE then
        Result := false;
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
  FpsText: String;
begin
  al_clear_to_color(al_map_rgb(0, 0, 0));

  for I := 1 to High(Grenades) do
  begin
    al_draw_filled_circle(Grenades[I].X, Grenades[I].Y, GRENADE_RADIUS,
      al_map_rgb(0, 255, 0));
    al_draw_filled_circle(Grenades[I].X, Grenades[I].Y, 0.8 * GRENADE_RADIUS,
      al_map_rgb(0, 127, 0));
  end;

  FpsText := 'FPS: ' + IntToStr(Fps);
  al_draw_text(Font, al_map_rgb(255, 255, 255), 1, 1, 0, FpsText);
  al_draw_text(Font, al_map_rgb(255, 0, 0), 0, 0, 0, FpsText);

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
    if al_get_next_event(EventQueue, Event) then
    begin
      Running := handleEvent(Event);
    end else
    begin
      TimeDiff := Now - LastFrameTime;
      LastFrameTime := LastFrameTime + TimeDiff;
      DecodeTime(TimeDiff, No, No, Seconds, MilliSeconds);
      FrameDeltaTime := 1000 * Seconds + MilliSeconds;
      Inc(ElapsedFrames);

      update;
      render;
    end;
  end;
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

