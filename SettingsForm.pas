unit SettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmSettings = class(TForm)
    Label1: TLabel;
    cbFontSize: TComboBox;
    btnOK: TButton;
    btnCancel: TButton;
    btnRestoreDefaults: TButton;
    btnIDEStructure: TButton;
    cbFontName: TComboBox;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnIDEStructureClick(Sender: TObject);
  end;

var
  frmSettings: TfrmSettings;

implementation

{$R *.dfm}

uses System.Win.Registry, AdjustFonts, IDEStructureForm;

procedure TfrmSettings.btnIDEStructureClick(Sender: TObject);
begin
  TfrmIDEStructure.Open;
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
var
  i, fontSize, currentIndex: integer;
  fontName: string;
begin
  GetCurrentFont(fontName, fontSize);
  cbFontName.Items := Screen.Fonts;
  cbFontName.ItemIndex := cbFontName.Items.IndexOf(fontName);
  currentIndex := 1;
  for i := 7 to 30 do
  begin
    cbFontSize.Items.Add(IntToStr(i));
    if fontSize = i then
      currentIndex := cbFontSize.Items.Count - 1;
  end;
  cbFontSize.ItemIndex := currentIndex;
end;

end.
