unit main;

interface

procedure run;

implementation

uses
  Allegro5,
  SysUtils;

const
  DISPLAY_WIDTH  = 800;
  DISPLAY_HEIGHT = 600;
  GRENADE_RADIUS = 10;

type
  TGrenade = record
    X, Y: Single;
  end;

var
  Display: ALLEGRO_DISPLAYptr;
  EventQueue: ALLEGRO_EVENT_QUEUEptr;
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

  al_register_event_source(EventQueue, al_get_keyboard_event_source);
  al_register_event_source(EventQueue, al_get_display_event_source(Display));

  for I := 1 to High(Grenades) do
  begin
    Grenades[I].X := Random * (DISPLAY_WIDTH - 2 * GRENADE_RADIUS) +
      GRENADE_RADIUS;
    Grenades[I].Y := Random * (DISPLAY_HEIGHT - 2 * GRENADE_RADIUS) +
      GRENADE_RADIUS;
  end;
end;

procedure cleanup;
begin
  WriteLn('cleanup');

  al_destroy_event_queue(EventQueue);
  al_destroy_display(Display);
  al_uninstall_keyboard;
end;

function handleEvent(Event: ALLEGRO_EVENT): Boolean;
begin
  Result := true;
  case Event._type of
    ALLEGRO_EVENT_DISPLAY_CLOSE:
      Result := false;
    ALLEGRO_EVENT_KEY_DOWN:
      if (Event.keyboard.keycode = ALLEGRO_KEY_ESCAPE) then
        Result := false;
  end;
end;

procedure render;
var
  I: Integer;
begin
  al_clear_to_color(al_map_rgb(0, 0, 0));
  for I := 1 to High(Grenades) do
    al_draw_pixel(Grenades[I].X, Grenades[I].Y, al_map_rgb(0, 255, 0));
  al_flip_display();
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
    if al_get_next_event(EventQueue, Event) then
    begin
      Running := handleEvent(Event);
    end else
    begin
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

