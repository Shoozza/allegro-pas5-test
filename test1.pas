program test1;

{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
  Allegro5;

procedure init;
begin
  WriteLn('init');
  if not al_init then
  begin
    WriteLn('init error');
    halt(1);
  end;
end;

procedure cleanup;
begin
  WriteLn('cleanup');
end;

procedure run;
begin
  WriteLn('run');
end;

begin
  WriteLn('start');

  init;
  run;
  cleanup;

  WriteLn('end');
end.

