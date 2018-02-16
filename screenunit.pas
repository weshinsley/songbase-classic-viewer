unit screenunit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Grids, jpeg;

type
  TFScreen = class(TForm)
    RE: TRichEdit;
    PUtil: TPanel;
    LClock: TLabel;
    PClockLine: TPanel;
    SGList: TStringGrid;
    PSongLine: TPanel;
    LChoosePart: TLabel;
    LChooseSong: TLabel;
    SGFirstLines: TStringGrid;
    PFirstLines: TPanel;
    IUpdate: TImage;
    INetOk: TImage;
    INetNotOk: TImage;
    IRemoteMin: TImage;
    IRemoteMax: TImage;
    procedure updateUtilPanelFixed();
    procedure updateUtilPanelUnFixed();
    procedure SGListDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure SetPartButtons();
    procedure updatePartButtons();
    procedure SGListSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure clickPartButton(Sender: TObject);
    procedure clickClearScreen();
    procedure REKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure REKeyPress(Sender: TObject; var Key: Char);
    procedure REKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SGFirstLinesDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure IUpdateClick(Sender: TObject);
    procedure SGFirstLinesSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure IRemoteMinClick(Sender: TObject);
    procedure IRemoteMaxClick(Sender: TObject);
  private
    { Private declarations }
  public
    PartTop: integer;
    ChoiceMode: integer;
    part_buttons : array of TLabel;
    { Public declarations }
  end;

var
  FScreen: TFScreen;
  current_button_selected : integer;


implementation

uses main;

{$R *.dfm}

procedure TFScreen.updateUtilPanelUnFixed();
var i,y : integer;
begin
  setPartButtons();
  PUtil.Visible:=FViewer.CBUtility.Checked;
  LClock.Visible:=FViewer.CBUtility.Checked and FViewer.CBClock.Checked;
  PClockLine.Visible:=FViewer.CBUtility.Checked and FViewer.CBClock.Checked;
  LChooseSong.Visible:=FViewer.CBUtility.Checked and FViewer.CBSonglist.Checked and FViewer.CBParts.Checked and FViewer.CBInteractive.Checked and (ChoiceMode=0) ;
  SGList.Visible:=FViewer.CBUtility.Checked and FViewer.CBSonglist.Checked;
  PSongline.Visible:=FViewer.CBUtility.Checked and FViewer.CBSongList.Checked;
  LChoosePart.Visible:=FViewer.CBUtility.Checked and FViewer.CBSonglist.Checked and FViewer.CBParts.Checked and FViewer.CBInteractive.Checked and (ChoiceMode=1);
  for i:=0 to length(part_buttons)-1 do begin
    part_buttons[i].Visible:=FViewer.CBUtility.Checked and FViewer.CBParts.Checked;

  end;
  PFirstLines.Visible:=FViewer.CBUtility.Checked and FViewer.CBParts.Checked;
  SGFirstLines.Visible:=FViewer.CBUtility.Checked and FViewer.CBFirstLines.Checked;
  y:=36;
  if (LClock.Visible) then begin
    y:=5;
    FViewer.UpdateTime();
    LClock.Top:=y;
    y:=y+abs(LClock.Height)+5;
    PClockLine.Top:=y;
    y:=y+5;
    if (y<36) then y:=36;
  end;
  if (FViewer.CBUtility.Checked and FViewer.CBSonglist.Checked and FViewer.CBParts.Checked and FViewer.CBInteractive.Checked ) then begin
    LChooseSong.Top:=y;
    y:=y+abs(LChooseSong.Height)+5;
  end;
  if (SGList.Visible) then begin
    SGList.Top:=y;
    y:=y+abs(SGList.Height);
    PSongline.Top:=y;
    y:=y+5;
  end;
  if (FViewer.CBUtility.Checked and FViewer.CBSonglist.Checked and FViewer.CBParts.Checked and FViewer.CBInteractive.Checked) then begin
    LChoosePart.Top:=y;
    y:=y+abs(LChoosePart.Height)+5;
  end;
  if (FViewer.CBUtility.Checked and FViewer.CBParts.Checked) then begin
    partTop:=y;
    y:=y+abs(FViewer.partFont.Height)+5;
    PFirstLines.Top:=y;
    y:=y+5;
  end;
  if (SGFirstLines.Visible) then begin
    SGFirstLines.Top:=y;
    //y:=y+abs(SGFirstLines.Height);
  end;
  if (LChooseSong.Visible) then LChooseSong.BringToFront;
  if (LChoosePart.Visible) then LChoosePart.BringToFront;
end;

procedure TFScreen.updateUtilPanelFixed();
var re_width,ut_width : integer;
const
    sel: TGridRect = (Left: 0; Top: -1; Right: 0; Bottom: -1);
begin
  top:=0;
  left:=0;
  Width:=Screen.width;
  Height:=Screen.Height;
  if (FViewer.CBUtility.Checked) then begin
    re_width:= trunc(0.7*FScreen.Width);
    ut_width:=FScreen.Width-re_width;
    RE.Width:=re_width;
    PUtil.Width:=ut_width;
    PUtil.Left:=re_width;
    PUtil.Height:=FScreen.Height;
    LClock.Left:=FScreen.PUtil.Width-(FScreen.LClock.Width+20);
    PClockLine.Height:=2;
    PClockLine.Left:=5;
    PClockLine.Width:=FScreen.PUtil.Width-10;
    LChooseSong.Left:=10;
    SGList.Left:=10;
    SGList.Width:=FScreen.PUtil.Width-20;
    SGList.ColWidths[0]:=30;
    SGList.ColWidths[1]:=FScreen.SGList.Width-32;
    SGList.Selection:=sel;
    PSongLine.Height:=2;
    PSongLine.Width:=PUtil.Width-10;
    PFirstLines.Height:=2;
    PFirstLines.Left:=5;
    PFirstLines.Width:=PUtil.Width-10;
    SGFirstLines.Left:=10;
    SGFirstLines.Width:=FScreen.PUtil.Width-20;
    SGFirstLines.ColWidths[0]:=30;
    SGFirstLines.ColWidths[1]:=FScreen.SGFirstLines.Width-32;
    SGFirstLines.Selection:=sel;
  end else begin
    FScreen.RE.Width:=Screen.width;
  end;
  RE.Height:=Screen.height;
  RE.Font.Color:=clWhite;
  RE.Color:=clBlack;
  RE.Lines.clear();
  Visible:=true;
  RE.Visible:=true;
  RE.setfocus();
end;


procedure TFScreen.clickPartButton(Sender: TObject);
var but : TButton;
begin
  but:=TButton(Sender);
  if (FViewer.CBInteractive.Checked) then begin
    FViewer.sendMsg(FViewer.EHost.TexT+':'+FViewer.EPort.Text+'/_Request_Part_'+but.Caption);
  end;
  FScreen.RE.SetFocus;
  HideCaret(FScreen.RE.Handle);
  ChoiceMode:=1;
  LChooseSong.Visible:=false;
  if (FViewer.CBUtility.Checked and FViewer.CBSongList.Checked and FViewer.CBParts.Checked) then begin
    LChoosePart.Visible:=true;
    LChoosePart.BringToFront;
  end;
end;

procedure TFScreen.clickClearScreen();
begin
  if (FViewer.CBInteractive.Checked) then begin
    FViewer.sendMsg(FViewer.EHost.TexT+':'+FViewer.EPort.Text+'/_Request_Part_-1');
  end;
  FScreen.RE.SetFocus;
  HideCaret(FScreen.RE.Handle);
end;
                               
procedure TFScreen.SetPartButtons ();
var len_new,len_old : integer;
    tot,i : integer;
    s,s2 : string;
begin
  len_new:=length(FViewer.currentSongButtons);
  len_old:=length(part_buttons);
  if (len_old<len_new) then begin
    setlength(part_buttons,len_new);
    while (len_old<len_new) do begin
      part_buttons[len_old]:=TLabel.Create(FScreen.PUtil);
      part_buttons[len_old].OnClick:=clickPartButton;
      part_buttons[len_old].Parent:=FScreen.PUtil;
      inc(len_old);
   end;
  end;
  for len_old:=0 to length(part_buttons)-1 do begin
    part_buttons[len_old].Font.Color:=FViewer.partFont.Color;
    part_buttons[len_old].Color:=clBlack;
    part_buttons[len_old].Font.Name:=FViewer.partFont.Name;
    part_buttons[len_old].Font.Size:=FViewer.partFont.Size;
    part_buttons[len_old].Font.Charset:=FViewer.partFont.Charset;
    part_buttons[len_old].Font.Style:=FViewer.partFont.Style;
    part_buttons[len_old].SendToBack;
  end;

  updatePartButtons();

  {And set up first lines}
  if (FViewer.CBFirstLines.Checked) then begin
    s:=FViewer.CurrentFirstLines;
    SGFirstLines.RowCount:=len_new;
     for i:=0 to len_new-1 do begin
      if (pos(tab,s)>=1) then begin
        s2:=copy(s,1,pos(tab,s)-1);
        s:=copy(s,pos(tab,s)+length(tab),length(s));
      end else begin
        s2:=s;
      end;
      SGFirstLines.Cells[0,i]:=FViewer.currentSongButtons[i+1];
      SGFirstLines.Cells[1,i]:=s2;
    end;
    tot:=0;
    for i:=0 to SGFirstLines.RowCount-1 do begin
      SGFirstLines.RowHeights[i]:=15+abs(FScreen.SGFirstLines.Font.Height);
      tot:=tot+FScreen.SGFirstLines.RowHeights[i];
    end;
    SGFirstLines.Height:=20+tot;
  end;

end;

procedure TFScreen.updatePartButtons();
var len_new,i : integer;
begin
  current_button_selected:=-1;
  len_new:=length(FViewer.currentSongButtons);
  for i:=0 to len_new-1 do begin
    part_buttons[i].Top:=PartTop;
    part_buttons[i].Left:=FScreen.PSongLine.Left+10+(8+(part_buttons[i].Font.size*i));
    part_buttons[i].Caption:=FViewer.currentSongButtons[i+1];
    part_buttons[i].Visible:=FViewer.CBParts.Checked;
    if (FViewer.currentSongButtons[i+1]=chr(FViewer.latestShortcut)) then begin
      part_buttons[i].Font.Color:=clLime;
      current_button_selected:=i;
    end else begin
      part_buttons[i].Font.Color:=clWhite;
    end;
  end;
  for i:=len_new to length(part_buttons)-1 do begin
    part_buttons[i].visible:=false;
  end;
  if (FViewer.CBFirstLines.Checked) then begin
    SGFirstLines.Repaint;
    SGFirstLines.Update;
  end;
end;


procedure TFScreen.SGListDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  S: string;
  RectForText: TRect;
begin
  S := SGList.Cells[ACol, ARow];
  SGList.Canvas.Brush.Color := clBlack;
  SGList.Canvas.FillRect(Rect);
  SGList.Canvas.Font.Color := clWhite;
  if (ARow=FViewer.currentSelectedSong) then begin
    SGList.Canvas.Font.Color := clLime;
    SGList.Canvas.Font.Style := [fsbold];
  end;

  RectForText := Rect;
  InflateRect(RectForText, -2, -2);
  SGList.Canvas.TextOut(RectForText.Left,RectForText.Top, S);
end;


procedure TFScreen.SGListSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  if (FViewer.CBInteractive.Checked) then begin
    FViewer.sendMsg(FViewer.EHost.TexT+':'+FViewer.EPort.Text+'/_Request_Song_'+SGList.Cells[0,ARow]);
  end;
  FScreen.RE.SetFocus;
  HideCaret(FScreen.RE.Handle);
  ChoiceMode:=0;
  LChoosePart.Visible:=false;
  if (FViewer.CBUtility.Checked and FViewer.CBSongList.Checked and FViewer.CBParts.Checked) then begin
    LChooseSong.Visible:=true;
    LChooseSong.BringToFront;
  end;

end;



procedure TFScreen.REKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var i : integer;
begin
  if (Key=VK_ESCAPE) then begin
    FViewer.hideRTF();
  end else if (FViewer.CBInteractive.Checked) then begin
    if (key=VK_SPACE) then begin
      if (FViewer.CBSonglist.Checked) and (FViewer.CBParts.Checked) then begin
        ChoiceMode:=1-ChoiceMode;
        LChooseSong.Visible:=(ChoiceMode=0);
        LChoosePart.Visible:=(ChoiceMode=1);
      end;
    end else if (key=VK_BACK) then begin
      clickClearScreen();
    end else if ((key=VK_RIGHT) or (key=VK_MULTIPLY) or (key=VK_NEXT)) then begin
      if (current_button_selected<length(part_buttons)-1) then begin
        clickPartButton(part_buttons[current_button_selected+1]);
      end;

    end else if ((key=VK_LEFT) or (key=VK_DIVIDE) or (key=VK_PRIOR)) then begin

      if (current_button_selected>0) then begin
        clickPartButton(part_buttons[current_button_selected-1]);
      end;
    end else if ((key=VK_DOWN) or (key=VK_ADD)) then begin
      if (SGList.Row<SGList.RowCount-1) then begin
        SGList.Row:=SGList.Row+1;
      end;
    end else if ((key=VK_UP) or (key=VK_SUBTRACT)) then begin
      if (SGList.Row>0) then begin
        SGList.Row:=SGList.Row-1;
      end;
    end else if (ChoiceMode=1) then begin
      for i:=0 to length(part_buttons)-1 do begin
        if (part_buttons[i].Caption=chr(Key)) then begin
          clickPartButton(part_buttons[i]);
        end;
      end;
    end else if (ChoiceMode=0) then begin
      for i:=0 to SGList.RowCount-1 do begin
        if (SGList.Cells[0,i]=chr(Key)) then begin
          FViewer.sendMsg(FViewer.EHost.TexT+':'+FViewer.EPort.Text+'/_Request_Song_'+SGList.Cells[0,i]);
        end;
      end;
    end;
  end;

end;

procedure TFScreen.REKeyPress(Sender: TObject; var Key: Char);
begin
  key:=#0;
end;

procedure TFScreen.REKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Key:=0;
end;

procedure TFScreen.SGFirstLinesDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
 var
  S: string;
  RectForText: TRect;
begin
  S := SGFirstLines.Cells[ACol, ARow];
  SGFirstLines.Canvas.Brush.Color := clBlack;
  SGFirstLines.Canvas.FillRect(Rect);
  if (length(part_buttons)>aRow) then begin
    SGFirstLines.Canvas.Font.Color := part_buttons[aRow].Font.Color;
    SGFirstLines.Canvas.Font.Style:=part_buttons[aRow].Font.Style;
  end else begin
    SGFirstLines.Canvas.Font.Color := clWhite;
    SGFirstLines.Canvas.Font.Style:=[];
  end;
  RectForText := Rect;
  InflateRect(RectForText, -2, -2);
  SGFirstLines.Canvas.TextOut(RectForText.Left,RectForText.Top, S);
end;

procedure TFScreen.IUpdateClick(Sender: TObject);
var res : integer;
begin
  res:=messagedlg('Viewer '+servers_version+' is available. Do you want it?',mtInformation,[mbYes,mbNo],0);
  if (res=mrYes) then begin
    FViewer.updateViewer();
  end;
end;

procedure TFScreen.SGFirstLinesSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  ClickPartButton(part_buttons[ARow]);
end;

procedure TFScreen.IRemoteMinClick(Sender: TObject);
begin
  FViewer.sendMsg(FViewer.EHost.TexT+':'+FViewer.EPort.Text+'/_Request_LoseFocus_');
end;

procedure TFScreen.IRemoteMaxClick(Sender: TObject);
begin
  FViewer.sendMsg(FViewer.EHost.TexT+':'+FViewer.EPort.Text+'/_Request_Focus_');
end;

end.

