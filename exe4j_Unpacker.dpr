program exe4j_Unpacker;

uses
  Forms,
  MainForm in 'MainForm.pas' {exe4jupFrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Texe4jupFrmMain, exe4jupFrmMain);
  Application.Run;
end.
