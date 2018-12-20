unit AdjustFonts;

interface

uses Vcl.Forms, Vcl.Controls, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus,
    Vcl.ActnMenus, Vcl.ThemedActnCtrls, SysUtils, Vcl.Graphics;

procedure GetCurrentFont(var fontName: string; var fontSize: integer);

implementation

uses ToolsAPI, System.Win.Registry, WinApi.Windows, Math, SettingsForm,
    System.Rtti, Vcl.Tabs, Vcl.ExtCtrls, Vcl.ComCtrls, Classes,
    Generics.Collections, IDEStructureForm;

type

TListener = class(TObject)
public
  oldMenuFontChangeEvent: TNotifyEvent;
  procedure SettingsMIClick(Sender: TObject);
  procedure MenuFontChange(Sender: TObject);
end;

var
  listener: TListener;
  miIDEFont: TMenuItem;
  NTAServices: INTAServices;
  pGetThemeFont: pointer;
  pUseThemeFont: pointer;
  pGetThemeFontBytes: array[0..7] of byte;
  pGetThemeFontByteCount: SIZE_T;

function GetRegistryPath: string;
var
  ver: integer;
begin
  if (CompilerVersion < 23) or (CompilerVersion > 33) then
    raise Exception.Create('Unsupported version of IDE.');
  //Registry paths: https://gist.github.com/jpluimers/b8c6b3bf29dbbf98a801f01beb8284a5
  if CompilerVersion >= 27 then
    ver := Floor(CompilerVersion) - 13
  else
    ver := Floor(CompilerVersion) - 14;
  Result := Format('Software\Embarcadero\BDS\%d.0\ModernTheme', [ver]);
end;

procedure GetCurrentFont(var fontName: string; var fontSize: integer);
var
  registry: TRegistry;
begin
  fontName := 'Segoe UI';
  fontSize := 8;
  registry := TRegistry.Create(KEY_READ);
  try
    registry.RootKey := HKEY_CURRENT_USER;
    if registry.OpenKey(GetRegistryPath, false) then
    begin
      if registry.ValueExists('FontName') then
        fontName := registry.ReadString('FontName');
      if registry.ValueExists('FontSize') then
        fontSize := registry.ReadInteger('FontSize');
    end;
  finally
    registry.Free;
  end;
end;

procedure SaveFont(const fontName: string; const fontSize: integer);
var
  registry: TRegistry;
begin
  registry := TRegistry.Create;
  try
    registry.RootKey := HKEY_CURRENT_USER;
    if registry.OpenKey(GetRegistryPath, true) then
    begin
      registry.WriteString('FontName', fontName);
      registry.WriteInteger('FontSize', fontSize);
      if not registry.ValueExists('MainToolBarColor') then
        registry.WriteString('MainToolBarColor', 'clGradientActiveCaption');
    end;
  finally
    registry.Free;
  end;
end;

procedure RestoreDefaults;
var
  registry: TRegistry;
begin
  registry := TRegistry.Create;
  try
    registry.RootKey := HKEY_CURRENT_USER;
    if registry.KeyExists(GetRegistryPath) then
      registry.DeleteKey(GetRegistryPath);
  finally
    registry.Free;
  end;
end;

procedure UpdateFontSize(const fontName: string; const fontSize: integer);
var
  i, j, textItemHeight: integer;
  rttiContext: TRttiContext;
begin
  rttiContext := TRttiContext.Create;
  for i := 0 to Application.MainForm.ComponentCount - 1 do
    if (Application.MainForm.Components[i].ClassName = 'TDesktopComboBox')
        and (Application.MainForm.Components[i] is TCustomComboBox) then
      TLabel(Application.MainForm.Components[i]).ParentFont := false;
  if CompilerVersion >= 32 then
  begin
    if not assigned(listener.oldMenuFontChangeEvent) then
      listener.oldMenuFontChangeEvent := Application.DefaultFont.OnChange;
    Screen.MenuFont.OnChange := listener.MenuFontChange;
  end;
  Application.DefaultFont.Size := fontSize;
  Application.DefaultFont.Name := fontName;
  Screen.MenuFont := Application.DefaultFont;
  Screen.HintFont := Application.DefaultFont;
  Screen.IconFont := Application.DefaultFont;
  Application.MainForm.Font := Application.DefaultFont;
  with TLabel.Create(nil) do
    try
      Font := Application.DefaultFont;
      Caption := 'Iq';
      textItemHeight := Ceil(1.3 * Height);
    finally
      Free
    end;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Screen.Forms[i].ClassName = 'TPropertyInspector' then
    begin
      Screen.Forms[i].Font := Application.DefaultFont;
      for j := 0 to Screen.Forms[i].ComponentCount - 1 do
        if (Screen.Forms[i].Components[j].Name = 'PropList')
            and (Screen.Forms[i].Components[j] is TCustomListBox) then
          with TListBox(Screen.Forms[i].Components[j]) do
          begin
            Font := Application.DefaultFont;
            ItemHeight:= textItemHeight;
          end
        else if (Screen.Forms[i].Components[j].Name = 'TabControl')
            and (Screen.Forms[i].Components[j] is TTabSet) then
          TTabSet(Screen.Forms[i].Components[j]).Font := Application.DefaultFont;
    end
    else if Screen.Forms[i].ClassName = 'TToolForm' then
    begin
      Screen.Forms[i].Font := Application.DefaultFont;
      for j := 0 to Screen.Forms[i].ControlCount - 1 do
        if Screen.Forms[i].Controls[j].ClassName = 'TIDECategoryButtons' then
        begin
          TLabel(Screen.Forms[i].Controls[j]).Font := Application.DefaultFont;
          rttiContext.GetType(Screen.Forms[i].Controls[j].ClassType)
              .GetProperty('ButtonHeight').SetValue(
                  Screen.Forms[i].Controls[j], textItemHeight);
        end;
    end
    else if (Screen.Forms[i].ClassName = 'TProjectManagerForm')
        or (Screen.Forms[i].ClassName = 'TStructureViewForm')
        or (Screen.Forms[i].ClassName = 'TLocalVarsWindow')
        or (Screen.Forms[i].ClassName = 'TCallStackWindow')
        or (Screen.Forms[i].ClassName = 'TWatchWindow')
        or (Screen.Forms[i].ClassName = 'TMessageViewForm') then
    begin
      Screen.Forms[i].Font := Application.DefaultFont;
      for j := 0 to Screen.Forms[i].ControlCount - 1 do
        //Virtual Treeview: http://www.lischke-online.de/index.php/controls/virtual-treeview
        if (Screen.Forms[i].Controls[j].ClassName = 'TVirtualStringTree')
            or (Screen.Forms[i].Controls[j].ClassName
                = 'TBetterHintWindowVirtualDrawTree') then
        begin
          TLabel(Screen.Forms[i].Controls[j]).Font := Application.DefaultFont;
          rttiContext.GetType(Screen.Forms[i].Controls[j].ClassType)
              .GetProperty('DefaultNodeHeight').SetValue(
                  Screen.Forms[i].Controls[j], textItemHeight);
        end;
    end;
  end;
end;

procedure TListener.SettingsMIClick(Sender: TObject);
var
  form: TfrmSettings;
  fontSize, oldFontSize: integer;
  fontName, oldFontName: string;
begin
  GetCurrentFont(oldFontName, oldFontSize);
  form := TfrmSettings.Create(Application);
  try
    case form.ShowModal of
      mrOK:
      begin
        fontSize := StrToInt(form.cbFontSize.Text);
        fontName := form.cbFontName.Text;
        SaveFont(fontName, fontSize);
        UpdateFontSize(fontName, fontSize);
        if (oldFontName <> fontName) or (oldFontSize <> fontSize) then
          ShowMessage('Restart IDE for better result.');
      end;
      mrAbort:
      begin
        RestoreDefaults;
        GetCurrentFont(fontName, fontSize);
        UpdateFontSize(fontName, fontSize);
        ShowMessage('Restart IDE for better result.');
      end;
    end;
  finally
    form.Free;
  end;
end;

procedure TListener.MenuFontChange(Sender: TObject);
begin
  if assigned(oldMenuFontChangeEvent) then
  begin
    Screen.MenuFont.OnChange := nil;
    Screen.MenuFont := Application.DefaultFont;
    oldMenuFontChangeEvent(Sender);
    Screen.MenuFont.OnChange := MenuFontChange;
  end;
end;

function GetThemeFont: TFont;
begin
  Result := Application.DefaultFont;
end;

procedure Initialize;
var
  buff: array[0..7] of byte;
  fontName: string;
  fontSize: integer;
begin
  miIDEFont := nil;
  listener := TListener.Create;
  listener.oldMenuFontChangeEvent := nil;
  pGetThemeFontByteCount := 0;
  pUseThemeFont := GetProcAddress(GetModuleHandle('designide260.bpl'),
      '@Brandingapi@UseThemeFont');
  pGetThemeFont := GetProcAddress(GetModuleHandle('designide260.bpl'),
      '@Brandingapi@GetThemeFont$qqrv');
  if assigned(pGetThemeFont) then
  begin
    if ReadProcessMemory(GetCurrentProcess, pGetThemeFont,
            PByte(@pGetThemeFontBytes[0]), 8, pGetThemeFontByteCount)
        and (pGetThemeFontByteCount = 8) then
    begin
      buff[0] := $68; // push
      buff[1] := byte(longint(@GetThemeFont) shr 0);
      buff[2] := byte(longint(@GetThemeFont) shr 8);
      buff[3] := byte(longint(@GetThemeFont) shr 16);
      buff[4] := byte(longint(@GetThemeFont) shr 24);
      buff[5] := $C3; // ret
      WriteProcessMemory(GetCurrentProcess, pGetThemeFont, PByte(@buff[0]), 8,
          pGetThemeFontByteCount);
    end
    else
      pGetThemeFontByteCount := 0;
  end;
  if Supports(BorlandIDEServices, INTAServices, NTAServices) then
  begin
    miIDEFont := TMenuItem.Create(nil);
    miIDEFont.Caption := 'IDE font...';
    miIDEFont.Name := 'miIDEFont';
    miIDEFont.OnClick := listener.SettingsMIClick;
    NTAServices.AddActionMenu('ToolsMenu', nil, miIDEFont, false, true);
  end;
  GetCurrentFont(fontName, fontSize);
  UpdateFontSize(fontName, fontSize);
end;

procedure Finalize;
begin
  if assigned(pGetThemeFont) and (pGetThemeFontByteCount > 0) then
    WriteProcessMemory(GetCurrentProcess, pGetThemeFont,
        PByte(@pGetThemeFontBytes[0]), pGetThemeFontByteCount,
        pGetThemeFontByteCount);
  Screen.MenuFont.OnChange := listener.oldMenuFontChangeEvent;
  if assigned(miIDEFont) then
    miIDEFont.Free;
  listener.Free;
end;

initialization
  Initialize;

finalization
  Finalize;

end.
