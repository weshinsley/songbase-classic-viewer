unit screen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TFScreen = class(TForm)
    RE: TRichEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FScreen: TFScreen;

implementation

{$R *.dfm}

end.
