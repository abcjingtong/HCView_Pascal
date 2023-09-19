unit CFControl;

interface

uses
  Windows, Classes, Controls, Messages, Graphics;

const
  WM_CF_CAPTIONBAR = WM_USER + $100;
  WM_CF_CARETCHANGE = WM_USER + $101;
  WM_CF_LBUTTONDOWN = WM_USER + $102;
  WM_CF_LBUTTONUP = WM_USER + $103;
  WM_CF_MOUSEMOVE = WM_USER + $104;
  WM_CF_LBUTTONDBLCLK = WM_USER + $105;
  WM_CF_REMOVECONTROL = WM_USER + $106;

type
  TMouseState = set of (cmsMouseIn, cmsMouseDown);

  TCFCustomControl = class(TCustomControl)
  private
    FAlpha: Byte;
    FMouseState: TMouseState;
    FBorderVisible: Boolean;
    FUpdateCount: Integer;
    FBorderColor: TColor;
  protected
    procedure DrawControl(ACanvas: TCanvas); virtual;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    //procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure CMMouseEnter(var Msg: TMessage ); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage ); message CM_MOUSELEAVE;
    /// <summary> ��ӦTab���ͷ���� </summary>
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMERASEBKGND(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure SetBorderVisible(Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    procedure DrawTo(const ACanvas: TCanvas); virtual;
    procedure UpdateDirectUI; overload;
    procedure UpdateDirectUI(ARect: TRect); overload;
    property MouseState: TMouseState read FMouseState;
  published
    property BorderVisible: Boolean read FBorderVisible write SetBorderVisible;
    property Alpha: Byte read FAlpha write FAlpha;
    property Align;
  end;

  /// <summary>
  /// �ı���ؼ�����
  /// </summary>
  TCFTextControl = class(TCFCustomControl)
  private
    FRoundCorner: Byte;
    FOnChange: TNotifyEvent;
  protected
    procedure DrawControl(ACanvas: TCanvas); override;
    procedure AdjustBounds; dynamic;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    property RoundCorner: Byte read FRoundCorner write FRoundCorner;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Font;
    property Text;
  end;

  function KeysToShiftState(Keys: Word): TShiftState;

var
  GRoundSize: Byte = 5;
  GPadding: Byte = 2;
  GIconWidth: Byte = 16;
  GBorderWidth: Byte = 1;
  GSpace: Byte = 2;
  GMinWidth: Integer = 10;
  GMinHeight: Integer = 20;
  // ȫ����ɫ
  //GThemeColor: TColor = $FFFFFF;  // ��ɫ��
  GTitleBackColor: TColor = $E8FFDF;  // �������򱳾�ɫ
  GBackColor: TColor = $FFFFFF;  // Ĭ�ϱ���ɫ
  GAreaBackColor: TColor = $008BBB68;  // ���򱳾�ɫ
  GHotColor: TColor = $98F392;  // ��������ɫ
  GReadOlnyBackColor: TColor = clInfoBk;  // ֻ������ɫ
  GAlertColor: TColor = $839EDA;  // ����ɫ
  GDownColor: TColor = $90E78B;  // ѡ�б���ɫ
  GBorderColor: TColor = $78C074;  // �߿�̬ɫ
  GBorderHotColor: TColor = $588D55;  // �߿򼤻�ʱ��ɫ
  GLineColor: TColor = clMedGray;
  GHightLightColor: TColor = clHighlight;

implementation

uses
  SysUtils;

function KeysToShiftState(Keys: Word): TShiftState;
begin
  Result := [];
  if Keys and MK_SHIFT <> 0 then Include(Result, ssShift);
  if Keys and MK_CONTROL <> 0 then Include(Result, ssCtrl);
  if Keys and MK_LBUTTON <> 0 then Include(Result, ssLeft);
  if Keys and MK_RBUTTON <> 0 then Include(Result, ssRight);
  if Keys and MK_MBUTTON <> 0 then Include(Result, ssMiddle);
  if GetKeyState(VK_MENU) < 0 then Include(Result, ssAlt);
end;

{ TCFCustomControl }

procedure TCFCustomControl.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TCFCustomControl.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FMouseState := FMouseState + [cmsMouseIn];
end;

procedure TCFCustomControl.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FMouseState := FMouseState - [cmsMouseIn, cmsMouseDown];
end;

constructor TCFCustomControl.Create(AOwner: TComponent);
begin
  inherited;
  Self.DoubleBuffered := True;
  Color := GBackColor;
  FAlpha := 255;
  FUpdateCount := 0;
  FBorderColor := GBorderColor;
  FBorderVisible := True;
  Width := 75;
  Height := 25;
end;

procedure TCFCustomControl.DrawControl(ACanvas: TCanvas);
begin
  ACanvas.Brush.Color := GBackColor;
end;

procedure TCFCustomControl.DrawTo(const ACanvas: TCanvas);
var
  vMemDC: HDC;
  vMemBitmap, vOldBitmap: HBITMAP;
  vCanvas: TCanvas;
  vBlendFunction: TBlendFunction;
  vDCState: Integer;
  vPoint: TPoint;
begin
  if FAlpha <> 255 then
  begin
    // ��ʹ��GDI��Ϊ��dll�г�ʼ��gdiʱ���治��ʾ
    vMemBitmap := CreateCompatibleBitmap(ACanvas.Handle, Width, Height);
    try
      vMemDC := CreateCompatibleDC(ACanvas.Handle);
      vOldBitmap := SelectObject(vMemDC, vMemBitmap);
      BitBlt(vMemDC, 0, 0, Width, Height, ACanvas.Handle, Left, Top, SRCCOPY);  // ����Canvas��λ�õ�ͼ��
      try
        vCanvas := TCanvas.Create;
        vCanvas.Handle := vMemDC;
        vDCState := Windows.SaveDC(vCanvas.Handle);  // �����豸������������ջ��
        try
          DrawControl(vCanvas);  // ���ƿؼ�(Ϊ֧��ֱ�ӵ���DrawTo����͸��Ч��������͸��������ڸ��ؼ���DrawTo��)
        finally
          Windows.RestoreDC(vCanvas.Handle, vDCState);  // ���豸������ջ�жԻָ��豸����
        end;

        vBlendFunction.BlendOp := AC_SRC_OVER;
        vBlendFunction.BlendFlags := 0;
        vBlendFunction.AlphaFormat := AC_SRC_OVER;  // Դλͼ������32λ��
        vBlendFunction.SourceConstantAlpha := FAlpha; // ͸����
        Windows.AlphaBlend(ACanvas.Handle,
                           Left,
                           Top,
                           Width,
                           Height,
                           vMemDC,
                           0,
                           0,
                           Width,
                           Height,
                           vBlendFunction
                           );
      finally
        SelectObject(vMemDC, vOldBitmap)
      end;
    finally
      vCanvas.Free;
      DeleteDC(vMemDC);
      DeleteObject(vMemBitmap);
    end;
  end
  else
    DrawControl(ACanvas);
end;

procedure TCFCustomControl.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  UpdateDirectUI;  // ����У�� FUpdateCount = 0
end;

procedure TCFCustomControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if not (csDesigning in ComponentState)
    and (CanFocus {or (GetParentForm(Self) = nil)})
  then
  begin
    SetFocus;
    FMouseState := FMouseState + [cmsMouseDown];
  end;

  inherited;
end;

procedure TCFCustomControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if not (csDesigning in ComponentState)
    and (CanFocus {or (GetParentForm(Self) = nil)})
  then
  begin
    FMouseState := FMouseState - [cmsMouseDown];
  end;

  inherited;
end;

procedure TCFCustomControl.Paint;
begin
  inherited Paint;
  if Self.Visible then
    DrawControl(Canvas);
end;

procedure TCFCustomControl.SetBorderVisible(Value: Boolean);
begin
  if FBorderVisible <> Value then
  begin
    FBorderVisible := Value;
    UpdateDirectUI;
  end;
end;

procedure TCFCustomControl.UpdateDirectUI(ARect: TRect);
begin
  if FUpdateCount <> 0 then Exit;
  if HandleAllocated then
    InvalidateRect(Handle, ARect, False);  // ��������False �����в���
end;

procedure TCFCustomControl.WMERASEBKGND(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TCFCustomControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTTAB or DLGC_WANTARROWS;
end;

procedure TCFCustomControl.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFCustomControl.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFCustomControl.UpdateDirectUI;
begin
  if HandleAllocated then
    UpdateDirectUI(ClientRect);
end;

{ TCFTextControl }

procedure TCFTextControl.AdjustBounds;
var
  vNewHeight, vNewWidth: Integer;
begin
  if not (csReading in ComponentState) then
  begin
    Canvas.Font := Font;
    vNewHeight := Canvas.TextHeight('��') + GetSystemMetrics(SM_CYBORDER) * 4;
    vNewWidth := Canvas.TextWidth(Caption) + GetSystemMetrics(SM_CYBORDER) * 4;
    if vNewWidth < GMinWidth then
      vNewWidth := GMinWidth;

    SetBounds(Left, Top, vNewWidth, vNewHeight);
  end;
end;

constructor TCFTextControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRoundCorner := 0;
end;

procedure TCFTextControl.DrawControl(ACanvas: TCanvas);
begin
  inherited DrawControl(ACanvas);
  ACanvas.Font := Font;
end;

procedure TCFTextControl.Loaded;
begin
  inherited Loaded;
  AdjustBounds;
end;

end.
