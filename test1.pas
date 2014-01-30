program test1;

{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
  Allegro5;

const
  DISPLAY_WIDTH  = 800;
  DISPLAY_HEIGHT = 600;

var
  Display: ALLEGRO_DISPLAYptr;

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
end;

procedure cleanup;
begin
  WriteLn('cleanup');
  al_destroy_display(Display);
end;

procedure run;
begin
  WriteLn('run');
  al_rest(2);
end;

begin
  WriteLn('start');

  init;
  run;
  cleanup;

  WriteLn('end');
end.

