object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'IDE font'
  ClientHeight = 82
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 248
    Top = 17
    Width = 47
    Height = 13
    Caption = 'Font size:'
  end
  object Label2: TLabel
    Left = 8
    Top = 17
    Width = 55
    Height = 13
    Caption = 'Font name:'
  end
  object cbFontSize: TComboBox
    Left = 301
    Top = 14
    Width = 81
    Height = 21
    Style = csDropDownList
    TabOrder = 1
  end
  object btnOK: TButton
    Left = 8
    Top = 50
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 89
    Top = 50
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object btnRestoreDefaults: TButton
    Left = 170
    Top = 49
    Width = 103
    Height = 25
    Cancel = True
    Caption = 'Restore defaults'
    ModalResult = 3
    TabOrder = 4
  end
  object btnIDEStructure: TButton
    Left = 279
    Top = 49
    Width = 103
    Height = 25
    Cancel = True
    Caption = 'IDE Structure...'
    ModalResult = 2
    TabOrder = 5
    OnClick = btnIDEStructureClick
  end
  object cbFontName: TComboBox
    Left = 69
    Top = 14
    Width = 164
    Height = 21
    TabOrder = 0
  end
end
