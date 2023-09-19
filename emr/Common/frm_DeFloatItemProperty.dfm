object frmDeFloatItemProperty: TfrmDeFloatItemProperty
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #28014#21160#23545#35937#23646#24615#65288#31532#19968#21015#26080#20540#26102#19981#20250#23384#20648#65289
  ClientHeight = 229
  ClientWidth = 357
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object sgdProperty: TStringGrid
    Left = 0
    Top = 66
    Width = 357
    Height = 118
    Align = alTop
    ColCount = 2
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
    TabOrder = 0
    ExplicitTop = 74
  end
  object pnlEdit: TPanel
    Left = 0
    Top = 0
    Width = 357
    Height = 66
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 20
    Padding.Right = 20
    TabOrder = 1
    DesignSize = (
      357
      66)
    object lbl1: TLabel
      Left = 19
      Top = 14
      Width = 12
      Height = 13
      Caption = #23485
    end
    object lbl2: TLabel
      Left = 132
      Top = 14
      Width = 12
      Height = 13
      Caption = #39640
    end
    object lbl7: TLabel
      Left = 102
      Top = 40
      Width = 204
      Height = 13
      Anchors = [akLeft, akBottom]
      Caption = #23646#24615#65288#20445#23384#26102#20002#24323#31532#19968#21015#20026#31354#30340#23646#24615#65289
      ExplicitTop = 48
    end
    object edtWidth: TEdit
      Left = 37
      Top = 11
      Width = 80
      Height = 21
      TabOrder = 0
    end
    object edtHeight: TEdit
      Left = 150
      Top = 11
      Width = 80
      Height = 21
      TabOrder = 1
    end
    object chkDeleteAllow: TCheckBox
      Left = 247
      Top = 12
      Width = 80
      Height = 17
      Caption = #20801#35768#21024#38500
      TabOrder = 2
    end
    object btnAddProperty: TButton
      Left = 19
      Top = 38
      Width = 75
      Height = 25
      Caption = #26032#22686#23646#24615
      TabOrder = 3
      OnClick = btnAddPropertyClick
    end
  end
  object btnSave: TButton
    Left = 141
    Top = 198
    Width = 75
    Height = 25
    Caption = #20445#23384
    TabOrder = 2
    OnClick = btnSaveClick
  end
end
