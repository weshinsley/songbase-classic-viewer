program viewer;

uses
  Forms,
  main in 'main.pas' {FViewer},
  screenunit in 'screenunit.pas' {FScreen};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Songbase Live Viewer';
  Application.CreateForm(TFViewer, FViewer);
  Application.CreateForm(TFScreen, FScreen);
  Application.Run;
end.
