unit IDEStructureForm;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Forms,
  Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TfrmIDEStructure = class(TForm)
    Memo: TMemo;
    Timer: TTimer;
    StatusBar: TStatusBar;
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    lastHwnd: THandle;
    procedure ShowComponents(path: string; c: TComponent; level: integer);
    function GetParentClasses(c: TClass): string;
    procedure ShowWindowInfo(pos: TPoint);
  public
    class procedure Open;
  end;

var
  frmIDEStructure: TfrmIDEStructure;

procedure GetProperties(obj: TObject; fileName: string);

implementation

{$R *.dfm}

uses Rtti, IOUtils, Generics.Collections, StrUtils, SysUtils, Tabs;

procedure GetProperties(obj: TObject; fileName: string);
var
  rttiContext: TRttiContext;
  props: TArray<TRttiProperty>;
  s: string;
  i, n: integer;
begin
  rttiContext := TRttiContext.Create;
  props := rttiContext.GetType(obj.ClassType).GetProperties;
  s := obj.ClassName + ':' + #13#10;
  n := 0;
  for i := 0 to Length(props) - 1 do
  begin
    Inc(n);
    s := s + props[i].Name + '; ';
    if n > 7 then
    begin
      n := 0;
      s := s + #13#10;
    end;
  end;
  TFile.WriteAllText(fileName, s);
end;

function TfrmIDEStructure.GetParentClasses(c: TClass): string;
begin
  Result := c.ClassParent.ClassName;
  if (c.ClassParent = TComponent) or (c.ClassParent = TControl)
      or (c.ClassParent = TWinControl) then
    exit;
  Result := Result + ':' + GetParentClasses(c.ClassParent);
end;

procedure TfrmIDEStructure.ShowComponents(path: string; c: TComponent;
    level: integer);
var
  i: integer;
  text, s: string;
  cs: TDictionary<TComponent, TComponent>;
begin
  text := '';
  if level > 0 then
    text := DupeString('-', level * 2);
  text := text + path + ': ' + c.ClassName + ', Name: ' + c.Name
      + ', ClassParents: ' + GetParentClasses(c.ClassType);
  if c is TControl then
    text := text + ', Caption: ' + TLabel(c).Caption;
  if c is TTabSet then
  begin
    text := text + ', Tabs: ';
    for s in TTabSet(c).Tabs.ToStringArray do
      text := text + s + '|';
    if TTabSet(c).Tabs.Count > 0 then
      text := LeftStr(text, Length(text) - 1);
  end;
  Memo.Lines.Add(text);
  cs := TDictionary<TComponent, TComponent>.Create;
  try
    if c is TWinControl then
      for i := 0 to TWinControl(c).ControlCount - 1 do
      begin
        ShowComponents('Controls[' + IntToStr(i) + ']',
            TWinControl(c).Controls[i], level + 1);
        cs.Add(TWinControl(c).Controls[i], TWinControl(c).Controls[i]);
      end;
    for i := 0 to c.ComponentCount - 1 do
      if not cs.ContainsKey(c.Components[i]) then
      begin
        ShowComponents('Components[' + IntToStr(i) + ']',
            c.Components[i], level + 1);
        cs.Add(c.Components[i], c.Components[i]);
      end;
  finally
    cs.Free;
  end;
  if level = 0 then
  begin
    Memo.Lines.Add('*********************************************************');
    Memo.Lines.Add('');
  end;
end;

procedure TfrmIDEStructure.TimerTimer(Sender: TObject);
var
  pos: TPoint;
begin
  if Boolean(GetCursorPos(pos)) then
    ShowWindowInfo(pos);
end;

procedure TfrmIDEStructure.ShowWindowInfo(pos: TPoint);
var
  hwnd: THandle;
  control: TWinControl;
  name: array [0..254] of char;
begin
  hwnd := WindowFromPoint(pos);
  if lastHwnd <> hwnd then
  begin
    StatusBar.Panels[0].Text := 'A window under the cursor... Handle: ' + IntToStr(hwnd);
    control := FindControl(hwnd);
    if assigned(control) then
    begin
      StatusBar.Panels[0].Text := StatusBar.Panels[0].Text + '; ClassName: ' + control.ClassName;
      if control.Name <> '' then
        StatusBar.Panels[0].Text := StatusBar.Panels[0].Text + '; Name: ' + control.Name;
    end
    else if boolean(GetClassName(hwnd, name, 255)) then
      StatusBar.Panels[0].Text := StatusBar.Panels[0].Text + '; ClassName: ' + string(name)
    else
      StatusBar.Panels[0].Text := StatusBar.Panels[0].Text + '; ClassName: not found';
    lastHwnd := hwnd;
  end;
end;

procedure TfrmIDEStructure.FormCreate(Sender: TObject);
begin
  lastHwnd := 0;
end;

procedure TfrmIDEStructure.FormDestroy(Sender: TObject);
begin
  frmIDEStructure := nil;
end;

procedure TfrmIDEStructure.FormShow(Sender: TObject);
var
  i: integer;
begin
  Screen.Cursor := crHourGlass;
  try
    for i := 0 to Screen.FormCount - 1 do
      ShowComponents('Screen.Forms[' + IntToStr(i) + ']', Screen.Forms[i], 0);
  finally
    Screen.Cursor := crDefault;
  end;
end;

class procedure TfrmIDEStructure.Open;
begin
  if not assigned(frmIDEStructure) then
    frmIDEStructure := TfrmIDEStructure.Create(Application);
  frmIDEStructure.Show;
end;

initialization
  frmIDEStructure := nil;

finalization
  if assigned(frmIDEStructure) then
    frmIDEStructure.Free;

end.
