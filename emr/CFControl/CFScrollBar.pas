unit CFScrollBar;

interface

uses
  Windows, Controls, Classes, Graphics, Messages, CFControl;

type
  TScrollCode = (scLineUp, scLineDown, scPageUp, scPageDown, scPosition,
    scTrack, scTop, scBottom, scEndScroll);

  TScrollEvent = procedure(Sender: TObject; ScrollCode: TScrollCode;
    var ScrollPos: Integer) of object;

  TBarControl = (cbcBar, cbcLeftBtn, cbcThum, cbcRightBtn);
  TOrientation = (coHorizontal, coVertical);  // ˮƽ/��ֱ������/����

  TCFScrollBar = class(TCFCustomControl)
  private
    /// <summary> ������λ�õ���Сֵ </summary>
    FMin,
    /// <summary> ������λ�õ����ֵ </summary>
    FMax,
    /// <summary> �����������λ������Сλ�ò� </summary>
    FRange,
    /// <summary> ��ֱ��������ǰλ�� </summary>
    FPosition: Integer;

    /// <summary> ������ƶ���Χ��ʵ�ʷ�Χ�ı��� </summary>
    FPercent: Single;

    /// <summary> �����ť���ƶ��Ĵ�С </summary>
    FBtnStep: Integer;

    /// <summary> ҳ���С </summary>
    FPageSize: Integer;

    /// <summary> ��ˮƽ���Ǵ�ֱ������ </summary>
    FOrientation: TOrientation;

    /// <summary> �����¼� </summary>
    FOnScroll: TScrollEvent;

    FMouseDownControl: TBarControl;

    /// <summary> �������� </summary>
    FThumRect: TRect;

    /// <summary>
    /// ˮƽ��������Ӧ��ť����ֱ��������Ӧ�ϰ�ť
    /// </summary>
    FLeftBtnRect: TRect;

    /// <summary>
    /// ˮƽ��������Ӧ�Ұ�ť����ֱ��������Ӧ�°�ť
    /// </summary>
    FRightBtnRect: Trect;

    FOnVisibleChanged: TNotifyEvent;

    /// <summary>
    /// �õ������ȥҪʵ�ָı������
    /// </summary>
    procedure ReCalcButtonRect;

    /// <summary>
    /// ���㻬������
    /// </summary>
    procedure ReCalcThumRect;

    /// <summary>
    /// ���ù��������ͣ���ֱ��������ˮƽ��������
    /// </summary>
    /// <param name="Value">����������</param>
    procedure SetOrientation(Value: TOrientation);

    /// <summary>
    /// ���ù���������Сֵ
    /// </summary>
    /// <param name="Value">��Сֵ</param>
    procedure SetMin(const Value: Integer);

    /// <summary>
    /// ���ù����������ֵ
    /// </summary>
    /// <param name="Value">���ֵ</param>
    procedure SetMax(const Value: Integer);

    /// <summary>
    /// ���ù������ĳ�ʼλ��
    /// </summary>
    /// <param name="Value">��ʼλ��</param>
    procedure SetPosition(Value: Integer);

    /// <summary>
    /// ���ù�������ʾ��ҳ���С�����Max - Min��
    /// </summary>
    /// <param name="Value">ҳ���С</param>
    procedure SetPageSize(const Value :Integer);

    /// <summary>
    /// �����������ťҳ���ƶ���Χ
    /// </summary>
    /// <param name="Value">�ƶ���Χ</param>
    procedure SetBtnStep(const Value: Integer);
  protected
    //procedure Resize; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure ScrollStep(ScrollCode: TScrollCode);
    procedure Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DrawControl(ACanvas: TCanvas); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  published
    property Align;
    property Max: Integer read FMax write SetMax;
    property Min: Integer read FMin write SetMin;
    property Rang: Integer read FRange;
    property PageSize: Integer read FPageSize write SetPageSize;
    property BtnStep: Integer read FBtnStep write SetBtnStep;
    property Position: Integer read FPosition write SetPosition;
    property Orientation: TOrientation read FOrientation write SetOrientation default coHorizontal;
    property OnScroll: TScrollEvent read FOnScroll write FOnScroll;
    property OnVisibleChanged: TNotifyEvent read FOnVisibleChanged write FOnVisibleChanged;
  end;

implementation

{$R CFScrollBar.RES}

uses
  SysUtils, Math, CFColorUtils;

const
  ButtonSize = 20;

var
  FMousePt: TPoint;

{ TCFScrollBar }

procedure TCFScrollBar.ReCalcThumRect;
var
  vPer: Single;
  vThumHeight, vPos: Integer;
begin
  case FOrientation of
    coHorizontal:
      begin
        FThumRect.Top := 0;
        FThumRect.Bottom := Height;
        if FPageSize < FRange then  // ҳ��С�ڷ�Χ
        begin
          vPer := FPageSize / FRange;  // ���㻬�����
          // ���㻬��ĸ߶�
          vThumHeight := Round((Width - 2 * ButtonSize) * vPer);
          if vThumHeight < ButtonSize then  // ����߲���С��Ĭ����С�߶�
            vThumHeight := ButtonSize;

          FPercent := (Width - 2 * ButtonSize - vThumHeight) / (FRange - FPageSize);  // ����ɹ�����Χ��ʵ�ʴ���Χ�ı���
          if FPercent < 0 then Exit;  // ��ֹvThumHeightС��Leftbtn��RightBtn��ThumBtnĬ�ϸ߶��ܺ� 3 * ButtonSizeʱ�������
          if FPercent = 0 then
            FPercent := 1;

          FThumRect.Left := ButtonSize + Round(FPosition * FPercent);
          if FThumRect.Left + vThumHeight > Width - ButtonSize then  // �޸�Max��Min����������Ͳ�ʱ�ı��С�Ȳ���ʱ���¼��㻬��߶�
          begin
            FThumRect.Left := Width - ButtonSize - vThumHeight;
            FThumRect.Right := FThumRect.Left + vThumHeight;
            vPos := Round(FThumRect.Left / FPercent);  // ���ݱ��ʻ���λ��
            if vPos > FRange - FPageSize then  // �ı��С�Ȳ���ʱԼ��λ��
              vPos := FRange - FPageSize;

            if FPosition <> vPos then
            begin
              FPosition := vPos;
              Scroll(scTrack, FPosition);  //����ƶ��ı们��Ĵ�ֱλ��
            end;
          end
          else
            FThumRect.Right := FThumRect.Left + vThumHeight;
        end
        else  // ����������ڵ��ڷ�Χ
        begin
          FThumRect.Left := ButtonSize;
          FThumRect.Right := Width - ButtonSize;
        end;
      end;

    coVertical:
      begin
        FThumRect.Left := 0;
        FThumRect.Right := Width;
        if FPageSize < FRange then  // ҳ��С�ڷ�Χ
        begin
          vPer := FPageSize / FRange;  // ���㻬�����
          // ���㻬��ĸ߶�
          vThumHeight := Round((Height - 2 * ButtonSize) * vPer);
          if vThumHeight < ButtonSize then  // ����߲���С��Ĭ����С�߶�
            vThumHeight := ButtonSize;

          FPercent := (Height - 2 * ButtonSize - vThumHeight) / (FRange - FPageSize);  // ����ɹ�����Χ��ʵ�ʴ���Χ�ı���
          if FPercent < 0 then Exit;  // ��ֹvThumHeightС��Leftbtn��RightBtn��ThumBtnĬ�ϸ߶��ܺ� 3 * ButtonSizeʱ�������
          if FPercent = 0 then
            FPercent := 1;

          FThumRect.Top := ButtonSize + Round(FPosition * FPercent);
          if FThumRect.Top + vThumHeight > Height - ButtonSize then  // �޸�Max��Min����������Ͳ�ʱ�ı��С�Ȳ���ʱ���¼��㻬��߶�
          begin
            FThumRect.Top := Height - ButtonSize - vThumHeight;
            FThumRect.Bottom := FThumRect.Top + vThumHeight;
            vPos := Round(FThumRect.Top / FPercent);  // ���ݱ��ʻ���λ��
            if vPos > FRange - FPageSize then  // �ı��С�Ȳ���ʱԼ��λ��
              vPos := FRange - FPageSize;

            if FPosition <> vPos then
            begin
              FPosition := vPos;
              Scroll(scTrack, FPosition);  //����ƶ��ı们��Ĵ�ֱλ��
            end;
          end
          else
            FThumRect.Bottom := FThumRect.Top + vThumHeight;
        end
        else  // ����������ڵ��ڷ�Χ
        begin
          FThumRect.Top := ButtonSize;
          FThumRect.Bottom := Height - ButtonSize;
        end;
      end;
  end;
end;

procedure TCFScrollBar.CMVisibleChanged(var Message: TMessage);
begin
  inherited;
  if not Visible then
    FPosition := FMin;

  if Assigned(FOnVisibleChanged) then
    FOnVisibleChanged(Self);
end;

constructor TCFScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin := 0;
  FMax := 100;
  FRange := 100;
  FPageSize := 0;
  BtnStep := 5;
  //
  Width := 20;
  Height := 20;
end;

destructor TCFScrollBar.Destroy;
begin

  inherited;
end;

procedure TCFScrollBar.DrawControl(ACanvas: TCanvas);
var
  vRect: TRect;
  vBmp: TBitmap;  // vIcon: HICON;
begin
  ACanvas.Brush.Color := Convert2Gray(GTitleBackColor, -20);
  ACanvas.FillRect(Bounds(0, 0, Width, Height));
  case FOrientation of
    coHorizontal:  // ˮƽ������
      begin
        //ACanvas.Brush.Color := GTitleForegColor;
        //ACanvas.FillRect(vRect);
        vBmp := TBitmap.Create;
        try
          vBmp.Transparent := True;
          // ˮƽ��������ť
          vRect := FLeftBtnRect;
          vBmp.LoadFromResourceName(HInstance, 'DROPLEFT');
          ACanvas.Draw(vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vBmp);
          //DrawIconEx(ACanvas.Handle, vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vIcon, GIconWidth, GIconWidth, 0, 0, DI_NORMAL);

          // ˮƽ�������Ұ�ť
          vRect := FRightBtnRect;
          //ACanvas.FillRect(vRect);
          vBmp.LoadFromResourceName(HInstance, 'DROPRIGHT');
          ACanvas.Draw(vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vBmp);
          //DrawIconEx(ACanvas.Handle, vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vIcon, GIconWidth, GIconWidth, 0, 0, DI_NORMAL);
        finally
          vBmp.Free;
        end;

        // ˮƽ����
        vRect := FThumRect;
        InflateRect(vRect, 0, -1);
        ACanvas.Brush.Color := Convert2Gray(GetDownColor(GTitleBackColor));
        ACanvas.Pen.Color := GLineColor;
        ACanvas.Rectangle(vRect);
        // �����ϵ�����
        vRect.Left := vRect.Left + (vRect.Right - vRect.Left) div 2;
        ACanvas.MoveTo(vRect.Left, 5);
        ACanvas.LineTo(vRect.Left, Height - 5);
        ACanvas.MoveTo(vRect.Left + 3, 5);
        ACanvas.LineTo(vRect.Left + 3, Height - 5);
        ACanvas.MoveTo(vRect.Left - 3, 5);
        ACanvas.LineTo(vRect.Left - 3, Height - 5);
      end;

    coVertical:  // ��ֱ������
      begin
        //ACanvas.Brush.Color := GTitleForegColor;
        //ACanvas.FillRect(vRect);
        vBmp := TBitmap.Create;
        try
          vBmp.Transparent := True;
          // �ϰ�ť
          vRect := FLeftBtnRect;
          vBmp.LoadFromResourceName(HInstance, 'DROPUP');
          ACanvas.Draw(vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vBmp);
          //DrawIconEx(ACanvas.Handle, vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vIcon, GIconWidth, GIconWidth, 0, 0, DI_NORMAL);

          // �°�ť
          vRect := FRightBtnRect;
          ACanvas.FillRect(vRect);
          vBmp.LoadFromResourceName(HInstance, 'DROPDOWN');
          ACanvas.Draw(vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vBmp);
          //DrawIconEx(ACanvas.Handle, vRect.Left + (vRect.Right - vRect.Left - GIconWidth) div 2, vRect.Top + (vRect.Bottom - vRect.Top - GIconWidth) div 2, vIcon, GIconWidth, GIconWidth, 0, 0, DI_NORMAL);
        finally
          vBmp.Free;
        end;

        // ����
        vRect := FThumRect;
        InflateRect(vRect, -1, 0);
        //vRect.Right := vRect.Right - 1;
        ACanvas.Brush.Color := Convert2Gray(GetDownColor(GTitleBackColor));
        ACanvas.Pen.Color := GLineColor;
        ACanvas.Rectangle(vRect);
        // �����ϵ�����
        vRect.Top := vRect.Top + (vRect.Bottom - vRect.Top) div 2;
        ACanvas.MoveTo(5, vRect.Top);
        ACanvas.LineTo(Width - 5, vRect.Top);
        ACanvas.MoveTo(5, vRect.Top - 3);
        ACanvas.LineTo(Width - 5, vRect.Top - 3);
        ACanvas.MoveTo(5, vRect.Top + 3);
        ACanvas.LineTo(Width - 5, vRect.Top + 3);
      end;
  end;
end;

procedure TCFScrollBar.ReCalcButtonRect;
begin
  case FOrientation of
    coHorizontal:
      begin
        FLeftBtnRect := Rect(0, 0, ButtonSize, Height);
        FRightBtnRect := Rect(Width - ButtonSize, 0, Width, Height);
      end;

    coVertical:
      begin
        FLeftBtnRect := Rect(0, 0, Width, ButtonSize);
        FRightBtnRect := Rect(0, Height - ButtonSize, Width, Height);
      end;
  end;
end;

procedure TCFScrollBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  FMousePt.X := X;
  FMousePt.Y := Y;
  if PtInRect(FLeftBtnRect, FMousePt) then  // �ж�����Ƿ��ڹ�������/��ť����
  begin
    FMouseDownControl := cbcLeftBtn;  // ���������������
    ScrollStep(scLineUp);  // �������ϣ��󣩹���
  end
  else
  if PtInRect(FThumRect, FMousePt) then  // ����ڻ�������
    FMouseDownControl := cbcThum
  else
  if PtInRect(FRightBtnRect, FMousePt) then  // �������/������
  begin
    FMouseDownControl := cbcRightBtn;
    ScrollStep(scLineDown);  // �������£��ң�����
  end
  else  // ����ڹ���������������
  begin
    FMouseDownControl := cbcBar;  // ������������������
    if (FThumRect.Top > Y) or (FThumRect.Left > X) then
      ScrollStep(scPageUp)  // �������ϣ��󣩷�ҳ
    else
    if (FThumRect.Bottom < Y) or (FThumRect.Right < X) then
        ScrollStep(scPageDown);  // �������£��ң���ҳ
  end;
end;

procedure TCFScrollBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vOffsX, vOffsY, vPos: Integer;
begin
  inherited;
  if ssLeft in Shift then  // �϶�
  begin
    case FOrientation of
      coHorizontal:
        begin
          if FMouseDownControl = cbcThum then  // �����ˮƽ��������������
          begin
            vOffsX := X - FMousePt.X;
            if FThumRect.Right + vOffsX > Width - ButtonSize then  // �����ƶ������ƶ�����ˮƽ���ң�
              vOffsX := Width - ButtonSize - FThumRect.Right  // �����������ƫ����
            else
            if FThumRect.Left + vOffsX < Left + ButtonSize then  // �����ƶ������ƶ�����ˮƽ����
              vOffsX := FThumRect.Left - ButtonSize - Left;  // �����������ƫ����

            OffsetRect(FThumRect, vOffsX, 0);  // ˮƽƫ��
            if FThumRect.Left < ButtonSize + 2 then  // ͨ�����2�������϶��������ʱ���ܵ�0������
              OffsetRect(FThumRect, ButtonSize - FThumRect.Left, 0);  // ��ֱƫ��

            vPos := Round((FThumRect.Left - ButtonSize) / FPercent);  // ��ǰ������ʼֵ�����Max��
            Position := vPos;
            FMousePt.X := X;  // ��ˮƽ���긳ֵ
          end;
        end;

      coVertical:
        begin
          if FMouseDownControl = cbcThum then  // �ڻ������϶�
          begin
            vOffsY := Y - FMousePt.Y;
            if FThumRect.Bottom + vOffsY > Height - ButtonSize then  // �����ƶ������ƶ����򣨴�ֱ���£�
            begin
              vOffsY := Height - ButtonSize - FThumRect.Bottom;  // �����������ƫ����
            end
            else
            if FThumRect.Top + vOffsY < Top + ButtonSize then  // �����ƶ������ƶ����򣨴�ֱ���ϣ�
            begin
              vOffsY := FThumRect.Top - ButtonSize - Top;  // �����������ƫ����
            end;

            OffsetRect(FThumRect, 0, vOffsY);  // ��ֱƫ��
            if FThumRect.Top < ButtonSize + 2 then  // ͨ�����2�������϶������϶�ʱ���ܵ�0������
              OffsetRect(FThumRect, 0, ButtonSize - FThumRect.Top);  // ��ֱƫ��

            vPos := Round((FThumRect.Top - ButtonSize) / FPercent);
            Position := vPos;
            FMousePt.Y := Y;  // �Դ�ֱ���긳��ǰYֵ
          end;
        end;
    end;
  end;
end;

procedure TCFScrollBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

end;

//procedure TCFScrollBar.Resize;
//begin
//  inherited;
//  ReCalcThumRect;  // ���¼��㻬������
//  ReCalcButtonRect;  // ���¼��㰴ť����
//end;

procedure TCFScrollBar.Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if Assigned(FOnScroll) then  // ����
    FOnScroll(Self, ScrollCode, ScrollPos);
end;

procedure TCFScrollBar.ScrollStep(ScrollCode: TScrollCode);
var
  vPos: Integer;
begin
  case ScrollCode of
    scLineUp:  // ����ϣ��󣩰�ť
      begin
        vPos := Position - FBtnStep;
        if vPos < FMin then  // �����ϣ���Խ��
          vPos := FMin;
        if FPosition <> vPos then
        begin
          Position := vPos;
          //Scroll(scLineUp, FPosition);
        end;
      end;

    scLineDown:
      begin
        vPos := Position + FBtnStep;
        if vPos > FRange - FPageSize then  // �����£��ң�Խ��
          vPos := FRange - FPageSize;
        if FPosition <> vPos then
        begin
          Position := vPos;
          //Scroll(scLineDown, FPosition);
        end;
      end;

    scPageUp:
      begin
        vPos := Position - FPageSize;
        {if FKind = sbVertical then
          vPos := Position - Height
        else
          vPos := Position - Width;}
        if vPos < FMin then
          vPos := FMin;
        if FPosition <> vPos then
        begin
          Position := vPos;
          //Scroll(scPageUp, FPosition);
        end;
      end;

    scPageDown:
      begin
        vPos := Position + FPageSize;
        {if FKind = sbVertical then
          vPos := Position + Height
        else
          vPos := Position + Width;}
        if vPos > FRange - FPageSize then
          vPos := FRange - FPageSize;
        if FPosition <> vPos then
        begin
          Position := vPos;
          //Scroll(scPageDown, FPosition);
        end;
      end;

    scPosition: ;
    scTrack: ;
    scTop: ;
    scBottom: ;
    scEndScroll: ;
  end;
end;

procedure TCFScrollBar.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  // ��AlignΪ��noneʱ���������ı��Сʱ������Resize������Ҫ��SetBounds
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  ReCalcThumRect;  // ���¼��㻬������
  ReCalcButtonRect;  // ���¼��㰴ť����
end;

procedure TCFScrollBar.SetBtnStep(const Value: Integer);
begin
  if FBtnStep <> Value then
    FBtnStep := Value;
end;

procedure TCFScrollBar.SetOrientation(Value: TOrientation);
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    if Value = coHorizontal then  // ����Ϊˮƽ������
      Height := 20  // ��ֵˮƽ�������ĸ߶�Ϊ 20
    else
    if Value = coVertical then  // ��ֱ������
      Width := 20;

    ReCalcButtonRect;
    ReCalcThumRect;
    UpdateDirectUI;  // �ػ�
  end;
end;

procedure TCFScrollBar.SetMax(const Value: Integer);
begin
  if FMax <> Value then
  begin
    if Value < FMin then
      FMax := FMin
    else
      FMax := Value;

    if FPosition > FMax then
      FPosition := FMax;

    FRange := FMax - FMin;
    ReCalcThumRect;  // ��������
    UpdateDirectUI;  // �ػ�
  end;
end;

procedure TCFScrollBar.SetMin(const Value: Integer);
begin
  if FMin <> Value then
  begin
    if Value > FMax then
      FMin := FMax
    else
      FMin := Value;

    if FPosition < FMin then
      FPosition := FMin;

    FRange := FMax - FMin;
    ReCalcThumRect;  // ��������
    UpdateDirectUI;  // �ػ�
  end;
end;

procedure TCFScrollBar.SetPageSize(const Value: Integer);
begin
  if FPageSize <> Value then
  begin
    FPageSize := Value;
    ReCalcThumRect;  // ���¼�����Ա��ʣ����Max - Min��
    //UpdateDirectUI;  // �ػ� ���������ߴ�С�ı�ʱ�����ϵͳ�д������Ĵ�����˸
  end;
end;

procedure TCFScrollBar.SetPosition(Value: Integer);
begin
  if Value < FMin then
    Value := FMin
  else
  if Value > FMax then
    Value := FMax;

  if FPosition <> Value then
  begin
    FPosition := Value;
    ReCalcThumRect;  // ��������
    Scroll(scTrack, FPosition);  //����ƶ��ı们��Ĵ�ֱλ��
  end;
end;

end.
