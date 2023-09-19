{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-5-4              }
{                                                       }
{           �ı����HCItem��ʽƥ�䴦��Ԫ              }
{                                                       }
{*******************************************************}

unit HCStyleMatch;

interface

uses
  Graphics, HCStyle, HCTextStyle, HCParaStyle;

type
  TOnTextStyle = procedure(const ACurStyleNo: Integer; const AWillStyle: THCTextStyle) of object;

  THCStyleMatch = class(TObject)  // �ı���ʽƥ����
  private
    FAppend: Boolean;  // ��ӻ���ȥ����Ӧ����ʽ True���
    FLock: Boolean;  // �����ɵ�һ��ҪӦ����ʽ��Item������ӻ���ȥ����ʽ��������ѡ�ж����Ԫ��Ӧ����ʽʱ�Ե�һ��ѡ�еĵ�һ��Item����
    FOnTextStyle: TOnTextStyle;
  protected
    procedure SetAppend(const Value: Boolean);
    function DoMatchCur(const ATextStyle: THCTextStyle): Boolean; virtual; abstract;
    procedure DoMatchNew(const ATextStyle: THCTextStyle); virtual; abstract;
  public
    constructor Create;
    function GetMatchStyleNo(const AStyle: THCStyle; const ACurStyleNo: Integer): Integer;
    function StyleHasMatch(const AStyle: THCStyle; const ACurStyleNo: Integer): Boolean; virtual;
    property Append: Boolean read FAppend write SetAppend;
    property OnTextStyle: TOnTextStyle read FOnTextStyle write FOnTextStyle;
  end;

  TTextStyleMatch = class(THCStyleMatch)  // ������ʽƥ����
  private
    FFontStyle: THCFontStyle;
  protected
    function DoMatchCur(const ATextStyle: THCTextStyle): Boolean; override;
    procedure DoMatchNew(const ATextStyle: THCTextStyle); override;
  public
    function StyleHasMatch(const AStyle: THCStyle; const ACurStyleNo: Integer): Boolean; override;
    property FontStyle: THCFontStyle read FFontStyle write FFontStyle;
  end;

  TFontNameStyleMatch = class(THCStyleMatch)  // ��������ƥ����
  private
    FFontName: string;
  protected
    function DoMatchCur(const ATextStyle: THCTextStyle): Boolean; override;
    procedure DoMatchNew(const ATextStyle: THCTextStyle); override;
  public
    property FontName: string read FFontName write FFontName;
  end;

  TFontSizeStyleMatch = class(THCStyleMatch)  // �����Сƥ����
  private
    FFontSize: Single;
  protected
    function DoMatchCur(const ATextStyle: THCTextStyle): Boolean; override;
    procedure DoMatchNew(const ATextStyle: THCTextStyle); override;
  public
    property FontSize: Single read FFontSize write FFontSize;
  end;

  TColorStyleMatch = class(THCStyleMatch)  // ������ɫƥ����
  private
    FColor: TColor;
  protected
    function DoMatchCur(const ATextStyle: THCTextStyle): Boolean; override;
    procedure DoMatchNew(const ATextStyle: THCTextStyle); override;
  public
    property Color: TColor read FColor write FColor;
  end;

  TBackColorStyleMatch = class(THCStyleMatch)  // ���屳��ɫƥ����
  private
    FColor: TColor;
  protected
    function DoMatchCur(const ATextStyle: THCTextStyle): Boolean; override;
    procedure DoMatchNew(const ATextStyle: THCTextStyle); override;
  public
    property Color: TColor read FColor write FColor;
  end;

  THCParaMatch = class(TObject)  // ����ʽƥ����
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; virtual; abstract;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); virtual; abstract;
  public
    function GetMatchParaNo(const AStyle: THCStyle; const ACurParaNo: Integer): Integer;
  end;

  TParaAlignHorzMatch = class(THCParaMatch)  // ��ˮƽ����ƥ����
  private
    FAlign: TParaAlignHorz;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property Align: TParaAlignHorz read FAlign write FAlign;
  end;

  TParaAlignVertMatch = class(THCParaMatch)  // �δ�ֱ����ƥ����
  private
    FAlign: TParaAlignVert;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property Align: TParaAlignVert read FAlign write FAlign;
  end;

  TParaLineSpaceMatch = class(THCParaMatch)  // ���м��ƥ����
  private
    FSpaceMode: TParaLineSpaceMode;
    FSpace: Single;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property SpaceMode: TParaLineSpaceMode read FSpaceMode write FSpaceMode;
    property Space: Single read FSpace write FSpace;
  end;

  TParaBackColorMatch = class(THCParaMatch)  // �α���ɫƥ����
  private
    FBackColor: TColor;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property BackColor: TColor read FBackColor write FBackColor;
  end;

  TParaBreakRoughMatch = class(THCParaMatch)  // �λ��нض�ƥ����
  private
    FBreakRough: Boolean;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property BreakRough: Boolean read FBreakRough write FBreakRough;
  end;

  TParaFirstIndentMatch = class(THCParaMatch)  // ����������ƥ����
  private
    FIndent: Single;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property Indent: Single read FIndent write FIndent;
  end;

  TParaLeftIndentMatch = class(THCParaMatch)  // ��������ƥ����
  private
    FIndent: Single;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property Indent: Single read FIndent write FIndent;
  end;

  TParaRightIndentMatch = class(THCParaMatch)  // ��������ƥ����
  private
    FIndent: Single;
  protected
    function DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean; override;
    procedure DoMatchNewPara(const AParaStyle: THCParaStyle); override;
  public
    property Indent: Single read FIndent write FIndent;
  end;

implementation

uses
  HCCommon, HCUnitConversion;

{ TTextStyleMatch }

function TTextStyleMatch.DoMatchCur(const ATextStyle: THCTextStyle): Boolean;
begin
  Result := Append and (FFontStyle in ATextStyle.FontStyles);  // ������У����������ʱTrue
end;

procedure TTextStyleMatch.DoMatchNew(const ATextStyle: THCTextStyle);
begin
  if Append then  // ���
  begin
    // ����ͬʱΪ�ϱ���±�
    if FFontStyle = THCFontStyle.tsSuperscript then
      ATextStyle.FontStyles := ATextStyle.FontStyles - [THCFontStyle.tsSubscript]
    else
    if FFontStyle = THCFontStyle.tsSubscript then
      ATextStyle.FontStyles := ATextStyle.FontStyles - [THCFontStyle.tsSuperscript];

    ATextStyle.FontStyles := ATextStyle.FontStyles + [FFontStyle];
  end
  else  // ��ȥ
    ATextStyle.FontStyles := ATextStyle.FontStyles - [FFontStyle]
end;

function TTextStyleMatch.StyleHasMatch(const AStyle: THCStyle;
  const ACurStyleNo: Integer): Boolean;
begin
  Result := FFontStyle in AStyle.TextStyles[ACurStyleNo].FontStyles;
end;

{ THCStyleMatch }

constructor THCStyleMatch.Create;
begin
  FLock := False;
end;

function THCStyleMatch.GetMatchStyleNo(const AStyle: THCStyle;
  const ACurStyleNo: Integer): Integer;
var
  vTextStyle: THCTextStyle;
begin
  Result := THCStyle.Null;
  if DoMatchCur(AStyle.TextStyles[ACurStyleNo]) then
  begin
    Result := ACurStyleNo;
    Exit;
  end;

  vTextStyle := THCTextStyle.Create;
  try
    vTextStyle.AssignEx(AStyle.TextStyles[ACurStyleNo]);  // item��ǰ����ʽ
    DoMatchNew(vTextStyle);
    if Assigned(FOnTextStyle) then
      FOnTextStyle(ACurStyleNo, vTextStyle);

    Result := AStyle.GetStyleNo(vTextStyle, True);  // ����ʽ���
  finally
    vTextStyle.Free;
  end;
end;

procedure THCStyleMatch.SetAppend(const Value: Boolean);
begin
  if (FAppend <> Value) and (not FLock) then
    FAppend := Value;

  FLock := True;  // ֻҪ���ù���ҪLock�������Ƿ�append
end;

function THCStyleMatch.StyleHasMatch(const AStyle: THCStyle;
  const ACurStyleNo: Integer): Boolean;
begin
  Result := False;
end;

{ THCParaMatch }

function THCParaMatch.GetMatchParaNo(const AStyle: THCStyle;
  const ACurParaNo: Integer): Integer;
var
  vParaStyle: THCParaStyle;
begin
  Result := THCStyle.Null;
  if DoMatchCurPara(AStyle.ParaStyles[ACurParaNo]) then
  begin
    Result := ACurParaNo;
    Exit;
  end;

  vParaStyle := THCParaStyle.Create;
  try
    vParaStyle.AssignEx(AStyle.ParaStyles[ACurParaNo]);
    DoMatchNewPara(vParaStyle);
    Result := AStyle.GetParaNo(vParaStyle, True);  // �¶���ʽ
  finally
    vParaStyle.Free;
  end;
end;

{ TParaAlignHorzMatch }

function TParaAlignHorzMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.AlignHorz = FAlign;
end;

procedure TParaAlignHorzMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.AlignHorz := FAlign;
end;

{ TParaAlignVertMatch }

function TParaAlignVertMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.AlignVert = FAlign;
end;

procedure TParaAlignVertMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.AlignVert := FAlign;
end;

{ TParaLineSpaceMatch }

function TParaLineSpaceMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.LineSpaceMode = FSpaceMode;
  if Result then
  begin
    if FSpaceMode = TParaLineSpaceMode.plsFix then
      Result := FSpace = AParaStyle.LineSpace
    else
    if FSpaceMode = TParaLineSpaceMode.plsMult then
      Result := FSpace = AParaStyle.LineSpace;
  end;
end;

procedure TParaLineSpaceMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.LineSpaceMode := FSpaceMode;
  AParaStyle.LineSpace := FSpace;
end;

{ TParaBackColorMatch }

function TParaBackColorMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.BackColor = FBackColor;
end;

procedure TParaBackColorMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.BackColor := FBackColor;
end;

{ TParaLeftIndentMatch }

function TParaLeftIndentMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.LeftIndent = FIndent;
end;

procedure TParaLeftIndentMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.LeftIndent := FIndent;
end;

{ TFontNameStyleMatch }

function TFontNameStyleMatch.DoMatchCur(const ATextStyle: THCTextStyle): Boolean;
begin
  Result := ATextStyle.Family = FFontName;
end;

procedure TFontNameStyleMatch.DoMatchNew(const ATextStyle: THCTextStyle);
begin
  ATextStyle.Family := FFontName;
end;

{ TFontSizeStyleMatch }

function TFontSizeStyleMatch.DoMatchCur(const ATextStyle: THCTextStyle): Boolean;
begin
  Result := ATextStyle.Size = FFontSize;
end;

procedure TFontSizeStyleMatch.DoMatchNew(const ATextStyle: THCTextStyle);
begin
  ATextStyle.Size := FFontSize;
end;

{ TColorStyleMatch }

function TColorStyleMatch.DoMatchCur(const ATextStyle: THCTextStyle): Boolean;
begin
  Result := ATextStyle.Color = FColor;
end;

procedure TColorStyleMatch.DoMatchNew(const ATextStyle: THCTextStyle);
begin
  ATextStyle.Color := FColor;
end;

{ TBackColorStyleMatch }

function TBackColorStyleMatch.DoMatchCur(const ATextStyle: THCTextStyle): Boolean;
begin
  Result := ATextStyle.BackColor = FColor;
end;

procedure TBackColorStyleMatch.DoMatchNew(const ATextStyle: THCTextStyle);
begin
  ATextStyle.BackColor := FColor;
end;

{ TParaFirstIndentMatch }

function TParaFirstIndentMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.FirstIndent = FIndent;
end;

procedure TParaFirstIndentMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.FirstIndent := FIndent
end;

{ TParaRightIndentMatch }

function TParaRightIndentMatch.DoMatchCurPara(const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.RightIndent = FIndent;
end;

procedure TParaRightIndentMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.RightIndent := FIndent;
end;

{ TParaBreakRoughMatch }

function TParaBreakRoughMatch.DoMatchCurPara(
  const AParaStyle: THCParaStyle): Boolean;
begin
  Result := AParaStyle.BreakRough = FBreakRough;
end;

procedure TParaBreakRoughMatch.DoMatchNewPara(const AParaStyle: THCParaStyle);
begin
  AParaStyle.BreakRough := FBreakRough;
end;

end.
