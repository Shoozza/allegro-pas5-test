program test1;

{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

procedure init;
begin
  WriteLn('init');
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

