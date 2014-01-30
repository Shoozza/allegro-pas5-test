program test1;

{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
  Allegro5;

const
  DISPLAY_WIDTH  = 800;
  DISPLAY_HEIGHT = 600;

var
  Display: ALLEGRO_DISPLAYptr;
  EventQueue: ALLEGRO_EVENT_QUEUEptr;

procedure init;
begin
  WriteLn('init');

  if not al_init then
  begin
    WriteLn('init error');
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
    writeln('create event queue error');
    halt(1);
  end;

  al_register_event_source(EventQueue, al_get_display_event_source(display));
end;

procedure cleanup;
begin
  WriteLn('cleanup');

  al_destroy_event_queue(EventQueue);
  al_destroy_display(Display);
end;

procedure run;
var
  Running: Boolean;
  Event: ALLEGRO_EVENT;
begin
  WriteLn('run');

  al_clear_to_color(al_map_rgb(0, 0, 0));
  al_flip_display();

  Running := true;

  while Running do
  begin
    al_wait_for_event(eventQueue, event);

    case event._type of
      ALLEGRO_EVENT_DISPLAY_CLOSE:
        running := false;
    end;
  end;
end;

begin
  WriteLn('start');

  init;
  run;
  cleanup;

  WriteLn('end');
end.

