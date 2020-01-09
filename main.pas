
unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, ExtActns, ComCtrls, IdBaseComponent, Grids,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, StrUtils, ScreenUnit, DateUtils;

type
  TFViewer = class(TForm)
    Image1: TImage;
    BExit: TButton;
    BRun: TButton;
    EHost: TEdit;
    EPort: TEdit;
    LHost: TLabel;
    LPort: TLabel;
    Timer: TTimer;
    idHTTP: TIdHTTP;
    GroupBox1: TGroupBox;
    LUpdate: TLabel;
    EInterval: TEdit;
    LUtility: TLabel;
    CBUtility: TCheckBox;
    LClock: TLabel;
    CBClock: TCheckBox;
    LSonglist: TLabel;
    CBSonglist: TCheckBox;
    LSongParts: TLabel;
    CBParts: TCheckBox;
    LIgnoreBlank: TLabel;
    CBIgnoreBlank: TCheckBox;
    LInteractive: TLabel;
    CBInteractive: TCheckBox;
    BEditClockFont: TButton;
    FontDialog1: TFontDialog;
    CBSongFont: TCheckBox;
    LForceSongFont: TLabel;
    BSongFont: TButton;
    BSonglistFont: TButton;
    BSongPartFont: TButton;
    LAbout: TLabel;
    LShowFirstLine: TLabel;
    CBFirstLines: TCheckBox;
    BSongFirstLineFont: TButton;
    CBConfig: TComboBox;
    LSettings: TLabel;
    BAddConfig: TButton;
    BDelConfig: TButton;
    BRenameConfig: TButton;
    PLine: TPanel;
    OpenDialog1: TOpenDialog;
    ColorDialog1: TColorDialog;
    procedure BExitClick(Sender: TObject);
    procedure downloadToFile(remoteFile, localFile : string);
    function downloadToString(remotefile : string) : string;
    procedure sendMsg(msg : string);
    procedure BRunClick(Sender: TObject);
    procedure showRTF();
    procedure hideRTF();
    function handshake() : boolean;
    procedure REKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure REExit(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure UpdateTime();
    procedure CheckPage();
    procedure CheckList();
    procedure BEditClockFontClick(Sender: TObject);
    procedure CopyFont(f1 : Tfont; f2: Tfont);
    procedure CopyFontAttrs(f1: TFont; f2: TTextAttributes);
    procedure FormCreate(Sender: TObject);
    procedure writeFont(var F : TextFile; s : string; ff : TFont);
    procedure BSongFontClick(Sender: TObject);
    procedure BSonglistFontClick(Sender: TObject);
    procedure BSongPartFontClick(Sender: TObject);
    procedure UpdateButtons(Sender: TObject);
    procedure BSongFirstLineFontClick(Sender: TObject);
    procedure UpdateViewer();
    procedure V18toV19();
    procedure loadIni(config_no : integer);
    procedure writeSingle(var F2 : TextFile);
    procedure SaveIni(config_to_save : integer; config_to_select : integer;
                      add_new : boolean; add_name : string;
                      del_one : boolean; del_index : integer);

    procedure CBConfigChange(Sender: TObject);
    procedure BRenameConfigClick(Sender: TObject);
    procedure BAddConfigClick(Sender: TObject);
    procedure BDelConfigClick(Sender: TObject);

  private
    { Private declarations }

  public
    { Public declarations }
    currentSelectedSong : integer;
    currentSongButtons : string;
    currentFirstLines : string;
    latestShortcut : word;
    songFont : TFont;
    partFont : TFont;

  end;

var
  FViewer: TFViewer;

  latestPage : integer;
  latestList : integer;
  currentConfig : integer;
  error : boolean;
  tab : string = chr(9);
  newline : string = chr(13)+chr(10);
  showing_extra : boolean;

  // My version.
  version : String = '1.13';
  version_internal : integer = 23;

  // The Songbase version I *need* to run safely.
  sbv_wanted : integer = 37;
  sbv : String = '3.6.1';

  // The version of ME, sitting on the Songbase server.
  // (They get overwritten by querying server.)
  servers_version : String = '1.8';
  servers_version_internal : integer = 18;



implementation

{$R *.dfm}

procedure TFViewer.sendMsg(msg : string);
var stream : TMemoryStream;

begin
  stream:=TMemoryStream.Create;
  try
    try
      idHttp.get(msg, stream);
      FScreen.INetOk.BringToFront();
      FScreen.INetOk.Update;

    except
      on e:exception do
      begin
        FScreen.INetNotOk.BringToFront();
        FScreen.INetNotOk.Update;
      end;
    end;
  finally
    stream.free;

  end;
end;

function TFViewer.downloadToString(remotefile : string) : string;
var s : string;
begin
  S:='';
  try
    try
      S := IdHTTP.Get(remotefile);
      FScreen.INetOk.BringToFront();
      FScreen.INetOk.Update;
    except
      on e:exception do
      begin
        FScreen.INetNotOk.BringToFront();
        FScreen.INetNotOk.Update;
      end;
    end;
  finally
   end;
  downloadToString:=s;
end;

procedure TFViewer.downloadToFile(remoteFile, localFile : string);
var stream : TMemoryStream;
begin
  stream:=TMemoryStream.Create;
  try
    try
      idHttp.get(remoteFile, stream);
      if fileexists(localFile) then deletefile(localFile);
      stream.SaveToFile(LocalFile);
      FScreen.INetOk.BringToFront();
      FScreen.INetOk.Update;
    except
      on e:exception do
      begin
        FScreen.INetNotOk.BringToFront();
        FScreen.INetNotOk.Update;
      end;
    end;
  finally
    stream.free;
  end;
end;



function FontStyleToInt(f: tfont) : integer;
var i : integer;
begin
  i:=0;
  if (fsBold in f.Style) then i:=i+1;
  if (fsItalic in f.Style) then i:=i+2;
  if (fsUnderline in f.Style) then i:=i+4;
  if (fsStrikeout in f.Style) then i:=i+8;
  FontStyleToInt:=i;
end;

procedure setFontStyle(f : TFont; i: integer);
begin
  f.Style:=[];
  if (i>=8) then begin f.Style:=f.Style+[fsStrikeout]; i:=i-8; end;
  if (i>=4) then begin f.Style:=f.Style+[fsUnderline]; i:=i-4; end;
  if (i>=2) then begin f.Style:=f.Style+[fsItalic]; i:=i-2; end;
  if (i>=1) then f.Style:=f.Style+[fsBold];
end;

procedure TFViewer.BExitClick(Sender: TObject);
begin
  close;
end;

procedure TFViewer.UpdateViewer();
begin
  if (FileExists('viewer_update.exe')) then deletefile('viewer_update.exe');
  if (FileExists('viewer_old.exe')) then deletefile('viewer_old.exe');
  downloadToFile(EHost.Text+':'+EPort.Text+'/_Update_Viewer_Please','viewer_update.exe');
  renamefile('viewer.exe','viewer_old.exe');
  renamefile('viewer_update.exe','viewer.exe');
  messagedlg('Update done - Restarting Viewer',mtInformation,[mbOk],0);
  winexec('viewer.exe',SW_NORMAL);
  close;
  FViewer.close;
end;

function TFViewer.handshake() : boolean;
var s2,s : string;
    res: boolean;
    mdr : integer;
begin
  res:=false;
  s2:=downloadToString(EHost.TexT+':'+EPort.Text+'/_Handshake_VW_'+inttoStr(version_internal)+'_'+inttostr(sbv_wanted)+'_'+sbv);
  s:=copy(s2,1,pos(tab,s2)-1);
  s2:=copy(S2,pos(tab,s2)+length(tab),length(s2));
  if (s='SB_VER') then begin
    messagedlg('This viewer requires Songbase server '+sbv+' - the server you chose is running '+s2,mtError,[mbOk],0);
    res:=false;
  end else if (s='VIEWER_VER') then begin
    mdr:=messagedlg('This Songbase server wants to upgrade Viewer to version '+s2+' - ok?',mtWarning,[mbYes,mbNo],0);
    if (mdr=mrYes) then begin
      updateViewer();
      res:=true;
    end else begin
      res:=false;
    end;
  end else if (s='OK') then begin
  s:=copy(s2,1,pos(tab,s2)-1);
  s2:=copy(S2,pos(tab,s2)+length(tab),length(s2));
  servers_version_internal:=StrToInt(s);
  servers_version:=s2;
  if (servers_version_internal>version_internal) then begin
    FScreen.IUpdate.Enabled:=true;
    FScreen.IUpdate.Visible:=true;
  end;

  res:=true;
  end;

  handshake:=res;
end;

procedure TFViewer.showRTF();
begin
  FScreen.updateUtilPanelFixed();
  FScreen.updateUtilPanelUnFixed();
  timer.enabled:=true;
end;

procedure TFViewer.hideRTF();
begin
  timer.Enabled:=false;
  FScreen.RE.Visible:=false;
  FScreen.Visible:=false;
  FViewer.Visible:=true;
end;

procedure TFViewer.writeFont(var F : TextFile; s : string; ff : TFont);
begin
  writeln(F,s+'FontName='+ff.Name);
  writeln(F,s+'FontSize='+IntToStr(ff.Size));
  writeln(F,s+'FontCharset='+IntToStr(ff.Charset));
  writeln(F,s+'FontColour='+IntToStr(ff.Color));
  writeln(F,s+'FontStyle='+IntToStr(Byte(ff.Style)));
end;



procedure TFViewer.BRunClick(Sender: TObject);
var S : String;
begin
  s:=EHost.Text;
  while (s[length(s)])='/' do s:=copy(s,1,length(s)-1);
  EHost.Text:=s;
  saveIni(currentConfig,currentConfig,false,'',false,0);
  Timer.Interval:=StrToInt(EInterval.Text);
  latestPage:=-1;
  latestList:=-1;
  if (handshake()) then showRTF();
end;

procedure TFViewer.REKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_ESCAPE) then hideRTF();
end;

procedure TFViewer.REExit(Sender: TObject);
begin
  if (FScreen.RE.Visible) then FScreen.RE.SetFocus;
end;


procedure TFViewer.CheckPage();
var sz : integer;
    s : string;
    mem : TMemoryStream;
begin
  s:=downloadToString(EHost.TexT+':'+EPort.Text+'/page.rtf');
  if (length(s)>0) then begin
    sz:=length(s);
    if ((not CBIgnoreBlank.Checked) or (sz>5)) then begin
      mem := TMemoryStream.Create;
      try
        mem.WriteBuffer (pchar(s)^, Length(s));
        mem.Position := 0;
        FScreen.RE.Lines.Clear;
        FScreen.RE.Lines.LoadFromStream (mem);
      finally
        mem.Free;
      end;
  end;

    if (CBSongFont.Checked) then begin
      FScreen.RE.SelectAll;
      CopyFontAttrs(SongFont,FScreen.RE.SelAttributes);
      FScreen.RE.SelLength:=0
    end;

    FScreen.updatePartButtons();
    HideCaret(FScreen.RE.Handle);
  end;
end;

procedure TFViewer.CheckList();
var num,i,tot,title_width,alttitle_width : integer;
    s,s2 : string;
    title,alttitle : string;
    LBmp : TBitmap;
begin
  tot:=0;
  s2:=downloadToString(EHost.TexT+':'+EPort.Text+'/current_list.txt');
  if (length(s2)>0) then begin
    s:=copy(s2,1,pos(newline,s2)-1);
    s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
    num:= StrToInt(s);
    s:=copy(s2,1,pos(newline,s2)-1);
    s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
    currentSelectedSong:=StrToInt(s);
    s:=copy(s2,1,pos(newline,s2)-1);
    s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
    currentSongButtons:=s;
    if (pos(tab,CurrentSongButtons)>0) then begin
      CurrentFirstLines:=copy(CurrentSongButtons,pos(tab,CurrentSongButtons)+length(tab),length(CurrentSongButtons));
      CurrentSongButtons:=copy(CurrentSongButtons,1,pos(tab,CurrentSongButtons)-1);

    end;
    FScreen.SGList.RowCount:=num;
    showing_extra:=false;
    for i:=0 to num do begin   // Go to num instead of (num-1) - in case there's an "X"tra being projected.
      if (length(s2)>0) then begin
        if (i=num) then begin
          FScreen.SGList.RowCount:=num+1; // Catch extra one.
          showing_extra:=true;
        end;
        s:=copy(s2,1,pos(newline,s2)-1);
        s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
        if (i<>num) then fScreen.SGList.Cells[0,i]:=s[1]
        else FScreen.SGList.Cells[0,i]:=' ';

        title:=copy(s,3,length(s));
        if (pos('(',title)>0) then begin
          // It has a sub-title...
          LBmp:=TBitMap.Create;
          try
            LBMp.Canvas.Font:=FScreen.SGList.Font;
            alttitle:=' '+copy(title,pos('(',title),length(title));
            title:=copy(title,1,pos('(',title)-1);
            title_width:=LBmp.Canvas.TextWidth(title);
            alttitle_width:=LBmp.Canvas.TextWidth(alttitle);
            while (title_width+alttitle_width>FScreen.SGList.ColWidths[1]) do begin
              if (title_width>alttitle_width) then begin
                title:=copy(title,1,length(title)-1);
                title_width:=LBmp.Canvas.TextWidth(title);
              end else begin
                alttitle:=copy(alttitle,1,length(alttitle)-1);
                alttitle_width:=LBmp.Canvas.TextWidth(alttitle);
              end;
            end;
          finally
            LBMP.Free;
          end;
          fscreen.SGList.Cells[1,i]:=title+alttitle;
        end else begin
          fscreen.SGList.Cells[1,i]:=title;
        end;
        FScreen.SGList.RowHeights[i]:=15+abs(FScreen.SGList.Font.Height);
        tot:=tot+FScreen.SGList.RowHeights[i];
      end;
    end;

    FScreen.SGList.Height:=20+Tot;
    FScreen.updateUtilPanelUnFixed();
    FScreen.SetPartButtons();
  end;
  if (currentSelectedSong=-1) then currentSelectedSong:=FScreen.SGList.RowCount-1;

end;

procedure TFViewer.TimerTimer(Sender: TObject);
var S,S2 : string;

begin
  timer.enabled:=false;
  s2:=downloadToString(EHost.Text+':'+EPort.Text+'/page.txt');
  if (length(s2)>0) then begin
    s:=copy(s2,1,pos(newline,s2)-1);
    s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
    try
      if (StrToInt(S)<>latestPage) then begin
        latestPage:=StrToInt(S);
        checkPage();
      end;
    except
    end;

    try
      s:=copy(s2,1,pos(newline,s2)-1);
      s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
      if (StrToInt(S)<>latestList) then begin
        if (CBSonglist.Enabled) then begin
          latestList:=StrToInt(S);
          checkList();
        end;
      end;
    except
    end;

    try
      s:=copy(s2,1,pos(newline,s2)-1);
      s2:=copy(s2,pos(newline,s2)+length(newline),length(s2));
      if (StrToInt(s)<>latestShortcut) then begin
        latestShortcut:=StrToInt(s);
        FScreen.updatePartButtons();
      end;
    except
    end;
  end;

  updateTime();
end;

procedure TFViewer.UpdateTime();
var S : string;
    dt : TDateTime;
    m,h : integer;
begin
  if (CBUtility.Checked and CBClock.Checked) then begin
    S := TimeToStr(Time);
    dt := time;
    h:=HourOf(dt);
    m:=MinuteOf(dt);
    s:='';
    if (h<10) then s:='0';
    s:=s+IntToStr(h)+':';
    if (m<10) then s:=s+'0';
    s:=s+IntToStr(m);
    FScreen.LClock.Caption:=s;
  end;
  timer.enabled:=true;
end;

procedure TFViewer.V18toV19();
var F1,F2 : TextFile;
    S : string;
begin
  assignfile(f1,'viewer.ini');
  if fileExists('viewer2.ini') then deletefile('viewer2.ini');
  assignfile(f2,'viewer2.ini');
  reset(f1);
  rewrite(f2);
  writeln(f2,'[Viewer 1.9]');
  writeln(f2,'[LastConfig 0]');
  writeln(f2,'[Config Default]');
  while (not eof(f1)) do begin
    readln(f1,s);
    writeln(f2,s);
  end;
  writeln(f2,'[End Config]');
  closefile(f1);
  closefile(f2);
  deletefile('viewer.ini');
  rename(f2,'viewer.ini');
end;

procedure TFViewer.loadIni(config_no : integer);
var F : TextFile;
    S : string;
    peq,config_file_no : integer;
    key : string;
    value : string;
    eh : TNotifyEvent;
begin
  assignfile(f,'viewer.ini');
  reset(F);
  readln(F,S);
  if (trim(s)<>'[Viewer 1.9]') then begin
    closefile(F);
    V18toV19();
    assignfile(f,'viewer.ini');
    reset(F);
    readln(F,S);
  end;
  CBConfig.Items.clear;

  readln(F,S); // [LastConfig xx]
  if (config_no=-1) then begin
    s:=copy(trim(S),12,length(S));
    s:=copy(s,1,length(s)-1);
    config_no:=strtoint(s);
  end;
  config_file_no:=0;

  while (not eof(f)) do begin
    readln(F,S);  // [Config configname];
    s:=copy(trim(S),9,length(S));
    s:=copy(S,1,length(S)-1);
    CBConfig.Items.Add(s);
    readln(F,S);
    if (config_file_no=config_no) then begin
      while (trim(s)<>'[End Config]') do begin
        peq:=pos('=',S);
        key:=leftStr(S,peq-1);
        value:=rightstr(S,length(s)-peq);
        if (uppercase(key)='HOST') then EHost.Text:=value
        else if (uppercase(key)='PORT') then EPort.Text:=value
        else if (uppercase(key)='INTERVAL') then EInterval.Text:=value
        else if (uppercase(key)='UTILITY') then CBUtility.Checked:=StrToBool(value)
        else if (uppercase(key)='CLOCK') then CBClock.Checked:=StrToBool(value)
        else if (uppercase(key)='SONGLIST') then CBSonglist.Checked:=StrToBool(value)
        else if (uppercase(key)='SONGPARTS') then CBParts.Checked:=StrToBool(value)
        else if (uppercase(key)='IGNOREBLANK') then CBIgnoreBlank.Checked:=StrToBool(value)
        else if (uppercase(key)='INTERACTIVE') then CBInteractive.Checked:=StrToBool(value)
        else if (uppercase(key)='CLOCKFONTNAME') then FScreen.LClock.Font.Name:=value
        else if (uppercase(key)='CLOCKFONTSIZE') then FScreen.LClock.Font.Size:=StrToInt(value)
        else if (uppercase(key)='CLOCKFONTSTYLE') then setFontStyle(FScreen.LClock.Font,StrToInt(value))
        else if (uppercase(key)='CLOCKFONTCOLOUR') then FScreen.LClock.Font.Color:=StrToInt(value)
        else if (uppercase(key)='CLOCKFONTCHARSET') then FScreen.LClock.Font.Charset:=StrToInt(value)
        else if (uppercase(key)='SONGFONTNAME') then SongFont.Name:=value
        else if (uppercase(key)='SONGFONTSIZE') then SongFont.Size:=StrToInt(value)
        else if (uppercase(key)='SONGFONTSTYLE') then setFontStyle(SongFont,StrToInt(value))
        else if (uppercase(key)='SONGFONTCOLOUR') then SongFont.Color:=StrToInt(value)
        else if (uppercase(key)='SONGFONTCHARSET') then SongFont.Charset:=StrToInt(value)
        else if (uppercase(key)='FORCESONGFONT') then CBSongFont.Checked:=StrToBool(value)
        else if (uppercase(key)='LISTFONTNAME') then FScreen.SGList.Font.Name:=value
        else if (uppercase(key)='LISTFONTSIZE') then FScreen.SGList.Font.Size:=StrToInt(value)
        else if (uppercase(key)='LISTFONTSTYLE') then setFontStyle(FScreen.SGList.Font,StrToInt(value))
        else if (uppercase(key)='LISTFONTCOLOUR') then FScreen.SGList.Font.Color:=StrToInt(value)
        else if (uppercase(key)='LISTFONTCHARSET') then FScreen.SGList.Font.Charset:=StrToInt(value)
        else if (uppercase(key)='PARTFONTNAME') then PArtFont.Name:=value
        else if (uppercase(key)='PARTFONTSIZE') then PartFont.Size:=StrToInt(value)
        else if (uppercase(key)='PARTFONTSTYLE') then setFontStyle(PartFont,StrToInt(value))
        else if (uppercase(key)='PARTFONTCOLOUR') then PartFont.Color:=StrToInt(value)
        else if (uppercase(key)='PARTFONTCHARSET') then PartFont.Charset:=StrToInt(value)
        else if (uppercase(key)='FIRSTLINEFONTNAME') then FScreen.SGFirstLines.Font.Name:=value
        else if (uppercase(key)='FIRSTLINEFONTSIZE') then FScreen.SGFirstLines.Font.Size:=StrToInt(value)
        else if (uppercase(key)='FIRSTLINEFONTSTYLE') then setFontStyle(FScreen.SGFirstLines.Font,StrToInt(value))
        else if (uppercase(key)='FIRSTLINEFONTCOLOUR') then FScreen.SGFirstLines.Font.Color:=StrToInt(value)
        else if (uppercase(key)='FIRSTLINEFONTCHARSET') then FScreen.SGFirstLines.Font.Charset:=StrToInt(value)
        else if (uppercase(key)='FIRSTLINES') then CBFirstLines.Checked:=StrToBool(value);
        readln(F,S);
      end;
    end else begin
      while (trim(s)<>'[End Config]') do readln(F,S);
    end;
    inc(config_file_no);
  end;
  eh:=CBConfig.OnChange;
  CBConfig.OnChange:=nil;
  CBConfig.ItemIndex:=config_no;
  currentConfig:=config_no;
  CBConfig.OnChange:=eh;
  closefile(f);
end;

procedure TFViewer.writeSingle(var F2 : TextFile);
begin
  writeln(F2,'Host='+EHost.Text);
  writeln(F2,'Port='+EPort.Text);
  writeln(F2,'Interval='+EInterval.Text);
  writeln(F2,'Utility='+BoolToStr(CBUtility.Checked));
  writeln(F2,'Clock='+BoolToStr(CBClock.Checked));
  writeln(F2,'Songlist='+BoolToStr(CBSonglist.Checked));
  writeln(F2,'Songparts='+BoolToStr(CBParts.Checked));
  writeln(F2,'IgnoreBlank='+BoolToStr(CBIgnoreBlank.Checked));
  writeln(F2,'Interactive='+BoolToStr(CBInteractive.Checked));
  writeln(F2,'ForceSongFont='+BoolToStr(CBSongFont.Checked));
  writeln(F2,'FirstLines='+BoolToStr(CBFirstLines.Checked));
  writeFont(F2,'Clock',FScreen.LClock.Font);
  writeFont(F2,'Song',SongFont);
  writeFont(F2,'List',FScreen.SGList.Font);
  writeFont(F2,'Part',partFont);
  writeFont(F2,'FirstLine',FScreen.SGFirstLines.Font);
  writeLn(F2,'[End Config]');
end;

procedure TFViewer.SaveIni(config_to_save : integer; config_to_select : integer;
                            add_new : boolean; add_name : string;
                            del_one : boolean; del_index : integer);
var f1,f2 : TextFile;
    s : string;
    config_no : integer;
begin
  assignfile(f1,'viewer.ini');
  reset(f1);
  if (FileExists('viewer2.ini')) then deletefile('viewer2.ini');
  assignfile(f2,'viewer2.ini');
  rewrite(F2);
  readln(F1,s);
  writeln(F2,'[Viewer 1.9]');
  readln(F1,s);
  writeln(F2,'[LastConfig '+inttostr(config_to_select)+']');
  config_no:=0;
  while (not eof(f1)) do begin
    readln(f1,s);  // [Config name]
    if (del_one) and (del_index=config_no) then begin
      while (s<>'[End Config]') do readln(F1,s);
    end else if (config_no=config_to_save) then begin
      writeln(F2,'[Config '+CBConfig.Items[config_to_save]+']');
      writeSingle(F2);
      while (s<>'[End Config]') do readln(F1,s);
    end else begin
      writeln(F2,s); // Write [Config name]
      while (s<>'[End Config]') do begin
        readln(F1,s);
        writeln(F2,s);
      end;
    end;
    inc(config_no);
  end;
  if (add_new) then begin
    writeln(F2,'[Config '+add_name+']');
    writeSingle(f2);
  end;
  flush(F2);
  closefile(F2);
  closefile(F1);
  deletefile('viewer.ini');
  rename(f2,'viewer.ini');

end;

procedure TFViewer.FormActivate(Sender: TObject);
begin
  if fileexists('viewer.ini') then loadIni(-1);
  UpdateButtons(Sender);
  FScreen.ChoiceMode:=0;
end;

procedure TFViewer.UpdateButtons(Sender: TObject);
begin

  BSongFont.Enabled:=CBSongFont.Checked;
  CBClock.Enabled:=CBUtility.Checked;
  BEditClockFont.Enabled:=CBClock.Enabled and CBClock.Checked;
  CBSonglist.Enabled:=CBUtility.Checked;
  BSongListFont.Enabled:=CBSongList.Checked and CBUtility.Checked;
  CBParts.Enabled:=CBUtility.Checked;
  BSongPartFont.Enabled:=CBParts.Checked and CBUtility.Checked;
  CBFirstLines.Enabled:=CBUtility.Checked;
  BSongFirstLineFont.Enabled:=CBFirstLines.Checked and CBUtility.Checked;
  CBInteractive.Enabled:=CBUtility.Checked;
  LClock.Enabled:=CBUtility.Checked;
  LSonglist.Enabled:=CBUtility.Checked;
  LSongParts.Enabled:=CBUtility.Checked;
  LShowFirstLine.Enabled:=CBUtility.Checked;
  LInteractive.Enabled:=CBUtility.Checked;

end;


procedure TFViewer.BEditClockFontClick(Sender: TObject);
begin
  CopyFont(FScreen.LClock.Font,FontDialog1.Font);
  FontDialog1.Execute;
  CopyFont(FontDialog1.Font,FScreen.LClock.Font);
end;

procedure TFViewer.CopyFont(f1 : Tfont; f2: Tfont);
begin
  f2.Name:=f1.Name;
  f2.Size:=f1.Size;
  f2.Color:=f1.Color;
  f2.Style:=f1.Style;
  f2.Charset:=f1.Charset;
end;

procedure TFViewer.CopyFontAttrs(f1: TFont; f2: TTextAttributes);
begin
  f2.Name:=f1.Name;
  f2.Size:=f1.Size;
  f2.Color:=f1.Color;
  f2.Style:=f1.Style;
  f2.Charset:=f1.Charset;
end;

procedure TFViewer.FormCreate(Sender: TObject);
begin
  songFont:=TFont.Create();
  partFont:=TFont.Create();
  LAbout.Caption:='Live Viewer '+version;
end;

procedure TFViewer.BSongFontClick(Sender: TObject);
begin
  CopyFont(SongFont,FontDialog1.Font);
  FontDialog1.Execute;
  CopyFont(FontDialog1.Font,SongFont);
end;

procedure TFViewer.BSonglistFontClick(Sender: TObject);
begin
  CopyFont(FScreen.SGList.Font,FontDialog1.Font);
  FontDialog1.Execute;
  CopyFont(FontDialog1.Font,FScreen.SGList.Font);
end;

procedure TFViewer.BSongPartFontClick(Sender: TObject);
begin
  CopyFont(partFont,FontDialog1.Font);
  FontDialog1.Execute;
  CopyFont(FontDialog1.Font,partFont);
end;

procedure TFViewer.BSongFirstLineFontClick(Sender: TObject);
begin
  CopyFont(FScreen.SGFirstLines.Font,FontDialog1.Font);
  FontDialog1.Execute;
  CopyFont(FontDialog1.Font,FScreen.SGFirstLines.Font);
end;

procedure TFViewer.CBConfigChange(Sender: TObject);
begin
  saveIni(currentConfig,CBConfig.ItemIndex,false,'',false,0);
  loadIni(CBConfig.ItemIndex);
end;

procedure TFViewer.BRenameConfigClick(Sender: TObject);
var rn : string;
    i : integer;
    dup : boolean;
    eh : TNotifyEvent;
begin
  rn:=inputbox('Rename','Rename Configuration to:',CBConfig.Items[CBConfig.ItemIndex]);
  if (rn<>cbconfig.items[CbConfig.ItemIndex]) then begin
    if (length(trim(rn))>0) then begin
      dup:=false;
      for i:=0 to CBConfig.Items.Count-1 do begin
        if (CBConfig.Items[i]=rn) then begin
          dup:=true;
          messagedlg('Already a configuration with that name',mtInformation,[mbOk],0);
        end;
      end;
      if (not dup) then begin
        i:=CBConfig.ItemIndex;
        eh:=CBConfig.OnChange;
        CBConfig.OnChange:=nil;
        CBConfig.items.delete(i);
        CBConfig.items.Insert(i,rn);
        CBConfig.ItemIndex:=i;
        CBConfig.OnChange:=eh;
        CBConfig.Update;
        saveIni(currentConfig,currentConfig,false,'',false,0);
      end;
    end;
  end;
end;

procedure TFViewer.BAddConfigClick(Sender: TObject);
var rn : string;
    i : integer;
    dup : boolean;
    eh : TNotifyEvent;
begin
  rn:='New Config';
  if (inputquery('Add','Name for new configuration:',rn)) then begin
    if (length(trim(rn))>0) then begin
      dup:=false;
      for i:=0 to CBConfig.ITems.Count-1 do begin
        if (CBConfig.Items[i]=rn) then begin
          dup:=true;
          messagedlg('Already a configuration with that name',mtInformation,[mbOk],0);
        end;
      end;
      if (not dup) then begin
        eh:=CBConfig.OnChange;
        CBConfig.OnChange:=nil;
        CBConfig.Items.Add(rn);
        CBConfig.ItemIndex:=CBConfig.Items.Count-1;
        CBConfig.OnChange:=eh;
        saveIni(currentConfig,CBConfig.ItemIndex,true,rn,false,0);
        currentConfig:=CBConfig.ItemIndex;
      end;
    end;
  end;
end;
procedure TFViewer.BDelConfigClick(Sender: TObject);
var eh : TNotifyEvent;
    delme,i : integer;
begin
  if (CBConfig.Items.Count=1) then begin
    messagedlg('Can''t delete the only configuration',mtInformation,[mbOk],0);
  end else begin
    if (messagedlg('Really delete this configuration?',mtConfirmation,[mbYes,mbNo],0)=mrYes) then begin
      delme:=CBConfig.ItemIndex;
      i:=delme+1;
      if (i>=CBConfig.Items.Count) then dec(i,2);
      loadIni(i);
      eh:=CBConfig.OnChange;
      CBConfig.OnChange:=nil;
      CBConfig.Items.delete(delme);
      currentConfig:=i;
      saveIni(currentConfig,currentConfig,false,'',true,delme);
      CBConfig.OnChange:=eh;
    end;
  end;
end;

end.
