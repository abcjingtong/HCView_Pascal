object frmConnSet: TfrmConnSet
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #26381#21153#22120#35774#32622
  ClientHeight = 216
  ClientWidth = 355
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
    Left = 24
    Top = 14
    Width = 60
    Height = 13
    Caption = #19994#21153#26381#21153#31471
  end
  object lbl2: TLabel
    Left = 50
    Top = 46
    Width = 24
    Height = 13
    Caption = #22320#22336
  end
  object lbl3: TLabel
    Left = 234
    Top = 46
    Width = 24
    Height = 13
    Caption = #31471#21475
  end
  object lbl4: TLabel
    Left = 24
    Top = 86
    Width = 60
    Height = 13
    Caption = #28040#24687#26381#21153#31471
  end
  object lbl5: TLabel
    Left = 50
    Top = 118
    Width = 24
    Height = 13
    Caption = #22320#22336
  end
  object lbl6: TLabel
    Left = 234
    Top = 118
    Width = 24
    Height = 13
    Caption = #31471#21475
  end
  object edtBLLServerIP: TEdit
    Left = 80
    Top = 43
    Width = 121
    Height = 21
    TabOrder = 0
  end
  object edtBLLServerPort: TEdit
    Left = 264
    Top = 43
    Width = 64
    Height = 21
    TabOrder = 1
  end
  object edtMsgServerIP: TEdit
    Left = 80
    Top = 115
    Width = 121
    Height = 21
    TabOrder = 2
  end
  object edtMsgServerPort: TEdit
    Left = 264
    Top = 115
    Width = 64
    Height = 21
    TabOrder = 3
  end
  object btnSave: TButton
    Left = 140
    Top = 168
    Width = 75
    Height = 25
    Caption = #20445#23384
    TabOrder = 4
    OnClick = btnSaveClick
  end
end
