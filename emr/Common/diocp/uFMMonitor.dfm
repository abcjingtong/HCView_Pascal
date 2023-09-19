object FMMonitor: TFMMonitor
  Left = 0
  Top = 0
  Width = 625
  Height = 334
  TabOrder = 0
  object lblServerStateCaption: TLabel
    Left = 16
    Top = 16
    Width = 59
    Height = 13
    Caption = 'server state'
  end
  object lblsvrState: TLabel
    Left = 112
    Top = 16
    Width = 51
    Height = 13
    Caption = 'lblsvrState'
  end
  object lblRecvCaption: TLabel
    Left = 16
    Top = 48
    Width = 21
    Height = 13
    Hint = 'double click to reset'
    Caption = 'recv'
    ParentShowHint = False
    ShowHint = True
    OnDblClick = lblRecvCaptionDblClick
  end
  object lblPostRecvINfo: TLabel
    Left = 112
    Top = 38
    Width = 76
    Height = 13
    Caption = 'lblPostRecvINfo'
  end
  object lblSendCaption: TLabel
    Left = 16
    Top = 81
    Width = 23
    Height = 13
    Caption = 'send'
  end
  object lblSend: TLabel
    Left = 112
    Top = 81
    Width = 34
    Height = 13
    Caption = 'lblSend'
  end
  object lblAcceptExCaption: TLabel
    Left = 16
    Top = 206
    Width = 48
    Height = 13
    Caption = 'acceptex:'
  end
  object lblAcceptEx: TLabel
    Left = 112
    Top = 206
    Width = 55
    Height = 13
    Caption = 'lblAcceptEx'
  end
  object lblOnlineCounter: TLabel
    Left = 405
    Top = 144
    Width = 79
    Height = 13
    Caption = 'lblOnlineCounter'
  end
  object lblOnlineCaption: TLabel
    Left = 347
    Top = 144
    Width = 32
    Height = 13
    Caption = 'online:'
  end
  object lblRunTimeINfo: TLabel
    Left = 113
    Top = 247
    Width = 72
    Height = 13
    Caption = 'lblRunTimeINfo'
  end
  object lblWorkersCaption: TLabel
    Left = 347
    Top = 164
    Width = 38
    Height = 13
    Caption = 'workers'
  end
  object lblWorkerCount: TLabel
    Left = 405
    Top = 164
    Width = 79
    Height = 13
    Cursor = crHandPoint
    AutoSize = False
    Caption = 'lblWorkerCount'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    OnClick = lblWorkerCountClick
  end
  object lblRunTimeCaption: TLabel
    Left = 17
    Top = 247
    Width = 43
    Height = 13
    Caption = 'run time:'
  end
  object lblRecvdSize: TLabel
    Left = 112
    Top = 59
    Width = 59
    Height = 13
    Caption = 'lblRecvdSize'
  end
  object lblSentSize: TLabel
    Left = 112
    Top = 103
    Width = 51
    Height = 13
    Caption = 'lblSentSize'
  end
  object lblSendQueue: TLabel
    Left = 112
    Top = 124
    Width = 66
    Height = 13
    Caption = 'lblSendQueue'
  end
  object lblSendingQueueCaption: TLabel
    Left = 16
    Top = 124
    Width = 70
    Height = 13
    Caption = 'sending queue'
  end
  object lblSocketHandle: TLabel
    Left = 112
    Top = 185
    Width = 75
    Height = 13
    Caption = 'lblSocketHandle'
  end
  object lblSocketHandleCaption: TLabel
    Left = 16
    Top = 184
    Width = 68
    Height = 13
    Caption = 'Socket Handle'
  end
  object lblContextInfo: TLabel
    Left = 112
    Top = 228
    Width = 69
    Height = 13
    Caption = 'lblContextInfo'
  end
  object lblContextInfoCaption: TLabel
    Left = 16
    Top = 228
    Width = 62
    Height = 13
    Caption = 'context info:'
  end
  object lblSendRequest: TLabel
    Left = 111
    Top = 144
    Width = 74
    Height = 13
    Caption = 'lblSendRequest'
  end
  object lblSendRequestCaption: TLabel
    Left = 16
    Top = 144
    Width = 63
    Height = 13
    Caption = 'sendRequest'
  end
  object lblPCInfo: TLabel
    Left = 113
    Top = 268
    Width = 43
    Height = 13
    Caption = 'lblPCInfo'
  end
  object lblDEBUG_ON: TLabel
    Left = 200
    Top = 16
    Width = 64
    Height = 13
    Caption = 'lblDEBUG_ON'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBtnShadow
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Visible = False
  end
  object lblFirstRunTime: TLabel
    Left = 296
    Top = 16
    Width = 72
    Height = 13
    Caption = 'lblFirstRunTime'
  end
  object lblRecvRequest: TLabel
    Left = 111
    Top = 164
    Width = 74
    Height = 13
    Caption = 'lblRecvRequest'
  end
  object lblRecvRequestCaption: TLabel
    Left = 16
    Top = 164
    Width = 61
    Height = 13
    Caption = 'recvRequest'
  end
  object tmrReader: TTimer
    Enabled = False
    OnTimer = tmrReaderTimer
    Left = 440
    Top = 24
  end
end
