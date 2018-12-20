object frmIDEStructure: TfrmIDEStructure
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'IDE Structure'
  ClientHeight = 501
  ClientWidth = 719
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 719
    Height = 482
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 482
    Width = 719
    Height = 19
    Panels = <
      item
        Width = 300
      end>
  end
  object Timer: TTimer
    Interval = 100
    OnTimer = TimerTimer
    Left = 200
    Top = 160
  end
end
