object frmParagraph: TfrmParagraph
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = #27573#33853#23646#24615#35774#32622
  ClientHeight = 223
  ClientWidth = 303
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 28
    Top = 16
    Width = 36
    Height = 13
    Caption = #34892#38388#36317
  end
  object lbl2: TLabel
    Left = 16
    Top = 81
    Width = 48
    Height = 13
    Caption = #39318#34892#32553#36827
  end
  object lbl3: TLabel
    Left = 28
    Top = 116
    Width = 36
    Height = 13
    Caption = #24038#32553#36827
  end
  object lbl4: TLabel
    Left = 165
    Top = 81
    Width = 36
    Height = 13
    Caption = #32972#26223#33394
  end
  object lbl5: TLabel
    Left = 16
    Top = 47
    Width = 48
    Height = 13
    Caption = #27700#24179#23545#40784
  end
  object lbl6: TLabel
    Left = 165
    Top = 47
    Width = 48
    Height = 13
    Caption = #22402#30452#23545#40784
  end
  object lbl7: TLabel
    Left = 116
    Top = 81
    Width = 24
    Height = 13
    Caption = #27627#31859
  end
  object lbl8: TLabel
    Left = 116
    Top = 116
    Width = 24
    Height = 13
    Caption = #27627#31859
  end
  object lbl9: TLabel
    Left = 165
    Top = 116
    Width = 36
    Height = 13
    Caption = #21491#32553#36827
  end
  object lbl10: TLabel
    Left = 253
    Top = 116
    Width = 24
    Height = 13
    Caption = #27627#31859
  end
  object lblUnit: TLabel
    Left = 262
    Top = 16
    Width = 12
    Height = 13
    Caption = #30917
  end
  object btnOk: TButton
    Left = 116
    Top = 190
    Width = 75
    Height = 25
    Caption = #30830#23450
    TabOrder = 0
    OnClick = btnOkClick
  end
  object clrbxBG: TColorBox
    Left = 210
    Top = 78
    Width = 76
    Height = 22
    DefaultColorColor = clNone
    NoneColorColor = clNone
    Selected = clScrollBar
    TabOrder = 1
  end
  object cbbAlignHorz: TComboBox
    Left = 70
    Top = 44
    Width = 77
    Height = 21
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 2
    Text = #24038
    Items.Strings = (
      #24038
      #23621#20013
      #21491
      #20004#31471
      #20998#25955)
  end
  object cbbAlignVert: TComboBox
    Left = 219
    Top = 44
    Width = 67
    Height = 21
    Style = csDropDownList
    ItemIndex = 2
    TabOrder = 3
    Text = #19979
    Items.Strings = (
      #19978
      #23621#20013
      #19979)
  end
  object cbbSpaceMode: TComboBox
    Left = 70
    Top = 13
    Width = 77
    Height = 21
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 4
    Text = #21333#20493
    OnChange = cbbSpaceModeChange
    Items.Strings = (
      #21333#20493
      '1.15'#20493
      '1.5'#20493
      '2'#20493
      #26368#23567#20540
      #22266#23450#20540
      #22810#20493)
  end
  object edtFirstIndent: TEdit
    Left = 70
    Top = 78
    Width = 40
    Height = 21
    TabOrder = 5
    Text = '8'
  end
  object edtLeftIndent: TEdit
    Left = 70
    Top = 113
    Width = 40
    Height = 21
    TabOrder = 6
    Text = '10'
  end
  object edtRightIndent: TEdit
    Left = 207
    Top = 113
    Width = 40
    Height = 21
    TabOrder = 7
    Text = '10'
  end
  object edtLineSpace: TEdit
    Left = 168
    Top = 13
    Width = 88
    Height = 21
    TabOrder = 8
    Text = '10'
  end
  object chkBreakRough: TCheckBox
    Left = 16
    Top = 152
    Width = 279
    Height = 17
    Caption = #31895#26292#25442#34892#65288#25442#34892#26102#19981#21028#26029#30456#21516#31867#22411#23383#31526#21516#26102#25442#34892#65289
    TabOrder = 9
  end
end
