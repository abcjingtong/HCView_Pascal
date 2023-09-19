unit CFDateTimePicker;

interface

uses
  Windows, Classes, Messages, Controls, Graphics, CFControl, CFPopup, CFMonthCalendar, CFButtonEdit;

type
  TECalendar = class(TCFMonthCalendar)
  private
    procedure WMCFMOUSEMOVE(var Message: TMessage); message WM_CF_MOUSEMOVE;
    procedure WMCFLBUTTONDOWN(var Message: TMessage); message WM_CF_LBUTTONDOWN;
    procedure WMCFLBUTTONUP(var Message: TMessage); message WM_CF_LBUTTONUP;
    procedure WMCFLBUTTONDBLCLK(var Message: TMessage); message WM_CF_LBUTTONDBLCLK;
  end;

  TDateTimeArea = (dtaNone, dtaYear, dtaMonth, dtaDay, dtaHour, dtaMinute,
    dtaSecond, dtaMillisecond);

  TCFDateTimePicker = class(TCFTextControl)
  private
    FFocus: Boolean;
    FReadOnly: Boolean;
    FButtonVisible: Boolean;
    //FAlwaysShowButton: Boolean;
    FFormat: string;
    FCalendar: TECalendar;
    FPopup: TCFPopup;
    FArea: TDateTimeArea;  // ��ǰ���������ʱ������
    FAreaRect: TRect;  // ����Χ
    FNewYear: string; // ��ǰ���������ֵ
    FJoinKey: Boolean;  // �����޸ĳ�����ʱ����¼�Ƿ���������

    /// <summary> ����ʱ����ƫ��(>=0) </summary>
    FLeftDrawOffset: Integer;

    procedure DoDateTimeChanged(Sender: TObject);
    procedure PopupPicker;
    procedure DoOnPopupDrawWindow(const ADC: HDC; const AClentRect: TRect);
    procedure DoButtonClick(Sender: TObject);
    /// <summary> ����ָ��λ��������ʱ�����һ��λ(���겻����ƫ��) </summary>
    /// <param name="X">������(��ƫ��)</param>
    /// <param name="Y">������(��ƫ��)</param>
    /// <param name="AArea">����ʱ��ĳһ��λ</param>
    /// <returns>�ò�λ��Ӧ������(��ƫ��)</returns>
    function GetAreaAt(const X, Y: Integer; var AArea: TDateTimeArea; const ACalcArea: Boolean = True): TRect;

    /// <summary> ���ݵ�ǰ�������¼��㵱ǰ����ʱ�䲿λ������ƫ�ơ���λ����(ƫ�ƺ�) </summary>
    /// <param name="X">������(��ƫ��)</param>
    /// <param name="Y">������(��ƫ��)</param>
    procedure ReBuildArea(X, Y: Integer);

    /// <summary> �����ڵ��겿���޸�Ϊ��������ַ��� </summary>
    procedure SetInputYear;

    /// <summary> ���ظ�ʽ������ʱ���ĵ�һ����Ч��λ(�����ڷ�������ʱ����ĳһ��λ) </summary>
    /// <param name="AArea">��λ</param>
    /// <returns>��λ����</returns>
    function FindFirstDateTimeArea(var AArea: TDateTimeArea): TRect;
    // ͨ��Tab���뽹��
    //procedure CMUIActivate(var Message: TMessage); message CM_UIACTIVATE;
    // ͨ��Tab�Ƴ�����
    //procedure CMUIDeActivate(var Message: TMessage); message CM_UIDEACTIVATE;
  protected
    procedure DrawControl(ACanvas: TCanvas); override;
    procedure AdjustBounds; override;

    function GetMaxDateTime: TDateTime;
    procedure SetMaxDateTime(Value: TDateTime);
    function GetMinDateTime: TDateTime;
    procedure SetMinDateTime(Value: TDateTime);
    function GetDateTime: TDateTime;
    procedure SetDateTime(Value: TDateTime);
    procedure SetFormat(Value: string);

    procedure SetButtonVisible(Value: Boolean);

    /// <summary> ȡ������״̬ </summary>
    procedure DisActive;  // ����Ƕ�׸��ؼ�����ȡ��

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
        MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure CMMouseEnter(var Msg: TMessage ); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage ); message CM_MOUSELEAVE;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMCFLBUTTONDOWN(var Message: TMessage); message WM_CF_LBUTTONDOWN;
    procedure WMCFLBUTTONUP(var Message: TMessage); message WM_CF_LBUTTONUP;
    procedure WMCFMOUSEMOVE(var Message: TMessage); message WM_CF_MOUSEMOVE;
    procedure WMCFLBUTTONDBLCLK(var Message: TMessage); message WM_CF_LBUTTONDBLCLK;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property DateTime: TDateTime read GetDateTime write SetDateTime;
    property MaxDateTime: TDateTime read GetMaxDateTime write SetMaxDateTime;
    property MinDateTime: TDateTime read GetMinDateTime write SetMinDateTime;
    property Format: string read FFormat write SetFormat;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;

    /// <summary> True��һֱ��ʾ��ť False���������������н���ʱ��ʾ��ť </summary>
    property ButtonVisible: Boolean read FButtonVisible write SetButtonVisible;
    property OnChange;
  end;

implementation

uses
  SysUtils, DateUtils;

{ TECalendar }

procedure TECalendar.WMCFLBUTTONDBLCLK(var Message: TMessage);
var
  vOldDate: TDate;
begin
  vOldDate := Self.Date;
  MouseDown(mbLeft, KeysToShiftState(Message.WParam) + MouseOriginToShiftState, Message.LParam and $FFFF, Message.LParam shr 16);
  if CompareDate(vOldDate, Self.Date) <> 0 then  // ѡ����������
    Message.Result := 1;  // ���ر�
end;

procedure TECalendar.WMCFLBUTTONDOWN(var Message: TMessage);
var
  vOldDate: TDate;
begin
  vOldDate := Self.Date;
  MouseDown(mbLeft, KeysToShiftState(Message.WParam) + MouseOriginToShiftState, Message.LParam and $FFFF, Message.LParam shr 16);

  Message.Result := 1;
  if CompareDate(vOldDate, Self.Date) <> 0 then  // ѡ����������
  begin
    if Message.LParam shr 16 > 50 then  // ��������ѡ����������
      Message.Result := 0;  // �ر�
  end;
end;

procedure TECalendar.WMCFLBUTTONUP(var Message: TMessage);
var
  X, Y: Integer;
  vRect: TRect;
  vOldDisplayModel: TDisplayModel;
begin
  if not HandleAllocated then Exit;

  X := Message.LParam and $FFFF;
  Y := Message.LParam shr 16;
  vRect := ClientRect;
  if PtInRect(vRect, Point(X, Y)) then  // ������
  begin
    vOldDisplayModel := Self.FDisplayModel;
    MouseUp(mbLeft, KeysToShiftState(Message.WParam) + MouseOriginToShiftState, X, Y);
    if Self.FDisplayModel <> vOldDisplayModel then
      Message.Result := 1; // ���ر�
  end;
end;

procedure TECalendar.WMCFMOUSEMOVE(var Message: TMessage);
var
  vShift: TShiftState;
  X, Y: Integer;
  vRect: TRect;
  vOldMoveDate: TDate;
begin
  if not HandleAllocated then Exit;

  X := Message.LParam and $FFFF;
  Y := Message.LParam shr 16;
  vRect := ClientRect;
  if PtInRect(vRect, Point(X, Y)) then  // ������
  begin
    vShift := [];
    if Message.WParam and MK_LBUTTON <> 0 then
    begin
      Include(vShift, ssLeft);
      Message.Result := 1;
    end;
    vOldMoveDate := Self.FMoveDate;
    MouseMove(vShift, X, Y);
    if Self.FMoveDate <> vOldMoveDate then
      Message.Result := 1;
  end;
end;

{ TCFDateTimePicker }

procedure TCFDateTimePicker.AdjustBounds;
var
  vDC: HDC;
  vHeight, vWidth: Integer;
begin
  if not (csReading in ComponentState) then
  begin
    vDC := GetDC(0);
    try
      Canvas.Handle := vDC;
      Canvas.Font := Font;

      vWidth := Canvas.TextWidth(FormatDateTime('YYYY-MM-DD', Now)) + GetSystemMetrics(SM_CYBORDER) * 2;
      if FButtonVisible then
        vWidth := vWidth + GIconWidth;

      if vWidth < Width then
        vWidth := Width;

      vHeight := Canvas.TextHeight('��') + GetSystemMetrics(SM_CYBORDER) * 4 + GBorderWidth + GBorderWidth;
      if vHeight < Height then
        vHeight := Height;

      Canvas.Handle := 0;
    finally
      ReleaseDC(0, vDC);
    end;

    SetBounds(Left, Top, vWidth, vHeight);
  end;
end;

procedure TCFDateTimePicker.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFDateTimePicker.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFDateTimePicker.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

constructor TCFDateTimePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLeftDrawOffset := 0;
  FButtonVisible := True;
  FFormat := 'YYYY-M-D HH:mm:ss';
  //Self.OnButtonClick := DoButtonClick;
  FCalendar := TECalendar.Create(Self);
  FCalendar.Parent := Self;
  FCalendar.Top := 1000;
  Width := 75;
  Height := 20;
  FCalendar.Width := 210;
  FCalendar.Height := 231;
  Text := FormatDateTime(FFormat, FCalendar.Date);
end;

procedure TCFDateTimePicker.DoDateTimeChanged(Sender: TObject);
begin
  Text := FormatDateTime(FFormat, FCalendar.Date);
end;

destructor TCFDateTimePicker.Destroy;
begin
  FCalendar.Free;
  inherited;
end;

procedure TCFDateTimePicker.DisActive;
begin
  SetInputYear;
  if FArea <> dtaNone then
  begin
    FArea := dtaNone;
    FLeftDrawOffset := 0;
    UpdateDirectUI
  end;
end;

procedure TCFDateTimePicker.DoButtonClick(Sender: TObject);
begin
  if not (csDesigning in ComponentState) then
  begin
    if ReadOnly then Exit;
    PopupPicker;
  end;
end;

function TCFDateTimePicker.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  vPt: TPoint;
  vYear, vMonth, vDay, vMSec, vCount: Word;
  vHour: Word absolute vYear;
  vMin: Word absolute vMonth;
  vSec: Word absolute vDay;
begin
  vPt := ScreenToClient(Mouse.CursorPos);
  if not PtInRect(ClientRect, vPt) then Exit;

  if FArea <> dtaNone then
  begin
    case FArea of
      dtaYear:
        begin
          if WheelDelta < 0 then  // ����
            DateTime := IncYear(DateTime, -1)
          else
            DateTime := IncYear(DateTime);
        end;
      dtaMonth:
        begin
          DecodeDate(DateTime, vYear, vMonth, vDay);
          if vMonth > 9 then
            vMSec := 1  // 2λ��
          else
            vMSec := 0; // 1λ��

          if WheelDelta < 0 then  // ����
          begin
            Dec(vMonth);
            if vMonth < 1 then
              vMonth := 12;
          end
          else
          begin
            Inc(vMonth);
            if vMonth > 12 then
              vMonth := 1;
          end;
          BeginUpdate;
          try
            vCount := DaysInAMonth(vYear, vMonth);  // ���µ�����
            if vDay > vCount then  // ��ǰ����������������
              DateTime := RecodeDay(DateTime, vCount);  // ����
            DateTime := RecodeMonth(DateTime, vMonth);
          finally
            EndUpdate;
          end;
          // ����Ӧ���ٵ���DecodeDate(DateTime, vYear, vMonth, vDay);��������
          // ��ΪDateTime��ֵ����ܳ�������Χ����û�з����仯
          // ʵ�ʲ�û�е�������ΪӰ����Ժ���
          if vMonth > 9 then  // ����2λ�� and (vMSec = 0))  // 1λ��2λ then
          begin
            if vMSec = 0 then  // ����1λ��
              ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
          end
          else  // ����1λ��
          if vMSec = 1 then  // ����2λ��
            ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
        end;
      dtaDay:
        begin
          vCount := DaysInMonth(DateTime);
          DecodeDate(DateTime, vYear, vMonth, vDay);
          if vDay > 9 then
            vMSec := 1  // 2λ��
          else
            vMSec := 0; // 1λ��

          if WheelDelta < 0 then  // ����
          begin
            Dec(vDay);
            if vDay < 1 then
              vDay := vCount;
          end
          else
          begin
            Inc(vDay);
            if vDay > vCount then
              vDay := 1;
          end;
          DateTime := RecodeDay(DateTime, vDay);

          if vDay > 9 then  // ����2λ�� and (vMSec = 0))  // 1λ��2λ then
          begin
            if vMSec = 0 then  // ����1λ��
              ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
          end
          else  // ����1λ��
          if vMSec = 1 then  // ����2λ��
            ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
        end;
      dtaHour:
        begin
          DecodeTime(DateTime, vHour, vMin, vSec, vMSec);
          if vHour > 9 then
            vMSec := 1  // 2λ��
          else
            vMSec := 0; // 1λ��

          if WheelDelta < 0 then  // ����
          begin
            Dec(vHour);
            if vHour > 23 then
              vHour := 23;
          end
          else
          begin
            Inc(vHour);
            if vHour > 23 then
              vHour := 0;
          end;
          DateTime := RecodeHour(DateTime, vHour);

          if vHour > 9 then  // ��ʱ2λ�� and (vMSec = 0))  // 1λ��2λ then
          begin
            if vMSec = 0 then  // ��ʱ1λ��
              ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
          end
          else  // ��ʱ1λ��
          if vMSec = 1 then  // ��ʱ2λ��
            ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
        end;
      dtaMinute:
        begin
          DecodeTime(DateTime, vHour, vMin, vSec, vMSec);
          if vMin > 9 then
            vMSec := 1  // 2λ��
          else
            vMSec := 0; // 1λ��

          if WheelDelta < 0 then  // ����
          begin
            Dec(vMin);
            if vMin > 59 then
              vMin := 59;
          end
          else
          begin
            Inc(vMin);
            if vMin > 59 then
              vMin := 0;
          end;
          DateTime := RecodeMinute(DateTime, vMin);

          if vMin > 9 then  // �·�2λ�� and (vMSec = 0))  // 1λ��2λ then
          begin
            if vMSec = 0 then  // �ɷ�1λ��
              ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
          end
          else  // �·�1λ��
          if vMSec = 1 then  // �ɷ�2λ��
            ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
        end;
      dtaSecond:
        begin
          DecodeTime(DateTime, vHour, vMin, vSec, vMSec);
          if vSec > 9 then
            vMSec := 1  // 2λ��
          else
            vMSec := 0; // 1λ��

          if WheelDelta < 0 then  // ����
          begin
            Dec(vSec);
            if vSec > 59 then
              vSec := 59;
          end
          else
          begin
            Inc(vSec);
            if vSec > 59 then
              vSec := 0;
          end;
          DateTime := RecodeSecond(DateTime, vSec);

          if vSec > 9 then  // ����2λ�� and (vMSec = 0))  // 1λ��2λ then
          begin
            if vMSec = 0 then  // ����1λ��
              ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
          end
          else  // ����1λ��
          if vMSec = 1 then  // ����2λ��
            ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
        end;
      //dtaMillisecond: ;
    end;
  end;
end;

procedure TCFDateTimePicker.DoOnPopupDrawWindow(const ADC: HDC;
  const AClentRect: TRect);
var
  vCanvas: TCanvas;
begin
  vCanvas := TCanvas.Create;
  try
    vCanvas.Handle := ADC;
    FCalendar.DrawTo(vCanvas);
    vCanvas.Handle := 0;
  finally
    vCanvas.Free;
  end;
end;

procedure TCFDateTimePicker.DrawControl(ACanvas: TCanvas);
var
  vRect: TRect;
  vLeft, vTop: Integer;
  vBmp: TBitmap;
begin
  inherited DrawControl(ACanvas);
  // ��ۣ�Բ�Ǿ���
  vRect := Rect(0, 0, Width, Height);
  ACanvas.Brush.Style := bsSolid;

  if FReadOnly then
    ACanvas.Brush.Color := GReadOlnyBackColor;

  if BorderVisible then
  begin
    if FFocus or (cmsMouseIn in MouseState) then
      ACanvas.Pen.Color := GBorderHotColor
    else
      ACanvas.Pen.Color := GBorderColor;

    ACanvas.Pen.Style := psSolid;
  end
  else
    ACanvas.Pen.Style := psClear;

  if RoundCorner > 0 then
    ACanvas.RoundRect(vRect, GRoundSize, GRoundSize)
  else
    ACanvas.Rectangle(vRect);

  // ��ť
  if FButtonVisible then
  begin
    // if FAlwayShowButton or Focus or (cmsMouseIn in MouseState) then
    vRect.Right := vRect.Right - GIconWidth;
    if Self.Focused or (cmsMouseIn in MouseState) then
    begin
      {ACanvas.Brush.Color := GHotColor;
      if BorderVisible then
        ACanvas.FillRect(Rect(vRect.Right, GBorderWidth, Width - GBorderWidth - GBorderWidth, Height - GBorderWidth - GBorderWidth))
      else
        ACanvas.FillRect(Rect(vRect.Right, GBorderWidth, Width - GBorderWidth, Height - GBorderWidth));}
    end;

    ACanvas.Pen.Color := GLineColor;
    ACanvas.MoveTo(vRect.Right, GBorderWidth);
    ACanvas.LineTo(vRect.Right, Height - GBorderWidth);

    vBmp := TBitmap.Create;
    try
      vBmp.Transparent := True;
      vBmp.LoadFromResourceName(HInstance, 'DROPDOWN');
      ACanvas.Draw(vRect.Right, (Height - GIconWidth) div 2, vBmp);
    finally
      vBmp.Free;
    end;
  end;

  // �������ݿɻ�������
  InflateRect(vRect, -GBorderWidth, -GBorderWidth);

  vRect.Left := vRect.Left + GPadding;

//  IntersectClipRect(ACanvas.Handle, vRect.Left, vRect.Top, vRect.Right, vRect.Bottom);
//  try
    // ��������
    if FArea <> dtaNone then
    begin
      ACanvas.Brush.Color := GHightLightColor;
      ACanvas.FillRect(FAreaRect);
    end;

    // ����
    vLeft := GPadding - FLeftDrawOffset;
    vTop := (Height - ACanvas.TextHeight('��')) div 2;
    ACanvas.Brush.Style := bsClear;
    Windows.ExtTextOut(ACanvas.Handle, vLeft, vTop, 0, nil, Text, Length(Text), nil);

    if (FArea = dtaYear) and (FNewYear <> '') then
    begin
      //vRect := Rect(vLeft, vTop, FAreaRect.Right, FAreaRect.Bottom);
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := GHightLightColor;
      ACanvas.FillRect(FAreaRect);
      Windows.DrawText(ACanvas.Handle, FNewYear, -1, FAreaRect, DT_RIGHT or DT_SINGLELINE);
    end;
//  finally
//    SelectClipRgn(ACanvas.Handle, 0);  // �����������
//  end;
end;

function TCFDateTimePicker.FindFirstDateTimeArea(var AArea: TDateTimeArea): TRect;
var
  vDC: HDC;
  vSize: TSize;
  vS, vDateTimeText: string;
  vOffset, AppendLevel: Integer;

  {$REGION '�ڲ�����'}
  procedure AppendChars(P: PChar; Count: Integer);
  begin
    Inc(vOffset, Count);
  end;

  function NumberText(Number, Digits: Integer): string;
  const
    Format: array[0..3] of Char = '%.*d';
  var
    NumBuf: array[0..15] of Char;
    vLen: Integer;
  begin
    vLen := FormatBuf(NumBuf, Length(NumBuf), Format,
      Length(Format), [Digits, Number]);
    SetString(Result, NumBuf, vLen);
  end;

  procedure AppendFormat(Format: PChar);
  var
    Starter, Token, LastToken: Char;
    DateDecoded, TimeDecoded, Use12HourClock,
    BetweenQuotes: Boolean;
    P: PChar;
    Count: Integer;
    Year, Month, Day, Hour, Min, Sec, MSec, H: Word;

    procedure GetCount;  // ��ȡ������Starter���ַ��м���
    var
      P: PChar;
    begin
      P := Format;
      while Format^ = Starter do
        Inc(Format);
      Count := Format - P + 1;
    end;

    procedure GetDate;  // �ֽ�����
    begin
      if not DateDecoded then
      begin
        DecodeDate(DateTime, Year, Month, Day);
        DateDecoded := True;
      end;
    end;

    procedure GetTime;  // �ֽ�ʱ��
    begin
      if not TimeDecoded then
      begin
        DecodeTime(DateTime, Hour, Min, Sec, MSec);
        TimeDecoded := True;
      end;
    end;

    function ConvertEraString(const Count: Integer) : string;
    var
      FormatStr: string;
      SystemTime: TSystemTime;
      Buffer: array[Byte] of Char;
      P: PChar;
    begin
      Result := '';
      with SystemTime do
      begin
        wYear  := Year;
        wMonth := Month;
        wDay   := Day;
      end;

      FormatStr := 'gg';
      if GetDateFormat(GetThreadLocale, DATE_USE_ALT_CALENDAR, @SystemTime,
        PChar(FormatStr), Buffer, Length(Buffer)) <> 0 then
      begin
        Result := Buffer;
        if Count = 1 then
        begin
          case SysLocale.PriLangID of
            LANG_JAPANESE:
              Result := Copy(Result, 1, CharToBytelen(Result, 1));
            LANG_CHINESE:
              if (SysLocale.SubLangID = SUBLANG_CHINESE_TRADITIONAL)
                and (ByteToCharLen(Result, Length(Result)) = 4) then
              begin
                P := Buffer + CharToByteIndex(Result, 3) - 1;
                SetString(Result, P, CharToByteLen(P, 2));
              end;
          end;
        end;
      end;
    end;

    function ConvertYearString(const Count: Integer): string;
    var
      FormatStr: string;
      SystemTime: TSystemTime;
      Buffer: array[Byte] of Char;
    begin
      Result := '';
      with SystemTime do
      begin
        wYear  := Year;
        wMonth := Month;
        wDay   := Day;
      end;

      if Count <= 2 then
        FormatStr := 'yy' // avoid Win95 bug.
      else
        FormatStr := 'yyyy';

      if GetDateFormat(GetThreadLocale, DATE_USE_ALT_CALENDAR, @SystemTime,
        PChar(FormatStr), Buffer, Length(Buffer)) <> 0 then
      begin
        Result := Buffer;
        if (Count = 1) and (Result[1] = '0') then
          Result := Copy(Result, 2, Length(Result)-1);
      end;
    end;

  begin
    if (Format <> nil) and (AppendLevel < 2) then
    begin
      Inc(AppendLevel);
      LastToken := ' ';
      DateDecoded := False;
      TimeDecoded := False;
      Use12HourClock := False;
      while Format^ <> #0 do
      begin
        Starter := Format^;  // ��ǰ�ַ�����1���ַ�
        if IsLeadChar(Starter) then  // ���� MBCS Ansi �ַ��ļ���
        begin
          Format := StrNextChar(Format);
          LastToken := ' ';
          Continue;
        end;
        Format := StrNextChar(Format);
        Token := Starter;
        if Token in ['a'..'z'] then
          Dec(Token, 32);
        if Token in ['A'..'Z'] then
        begin
          if (Token = 'M') and (LastToken = 'H') then
            Token := 'N';
          LastToken := Token;
        end;
        case Token of
          'Y': // ��
            begin
              GetCount;  // ���м�λ
              GetDate;   // �ֽ�����
              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              if Count <= 2 then
              begin
                vS := NumberText(Year mod 100, 2);
                Inc(vOffset, Length(vS));
              end
              else
              begin
                vS := NumberText(Year, 4);
                Inc(vOffset, Length(vS));
              end;
              // ���������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaYear;
              Exit;
            end;
          'G':  // ��Ԫ
            begin
              GetCount;  // ��Ԫ��λ��ʾ
              GetDate;
              //AppendString(ConvertEraString(Count));
              Inc(vOffset, Length(ConvertEraString(Count)));
            end;
          'E':  // �ֻ꣬��һ��Eʱ��ʾ��2λ��
            begin
              GetCount;
              GetDate;
              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              vS := ConvertYearString(Count);
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaYear;
              Exit;
            end;
          'M':  // ��
            begin
              GetCount;  // �·ݼ�λ��ʾ
              GetDate;

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              case Count of
                1, 2:
                  vS := NumberText(Month, Count);
                3:
                  vS := FormatSettings.ShortMonthNames[Month];
              else
                vS := FormatSettings.LongMonthNames[Month];
              end;
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaMonth;
              Exit;
            end;
          'D': // ��
            begin
              GetCount;  // ���ڼ�λ��ʾ

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              if Count < 5 then
              begin
                case Count of
                  1, 2:
                    begin
                      GetDate;
                      vS := NumberText(Day, Count);
                    end;
                  3: vS := FormatSettings.ShortDayNames[DayOfWeek(DateTime)];
                  4: vS := FormatSettings.LongDayNames[DayOfWeek(DateTime)];
                end;
                Inc(vOffset, Length(vS));
                // ���������ڷ�Χ
                Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;

                AArea := dtaDay;
                Exit;
              end
              else
              if Count = 5 then
                AppendFormat(Pointer(FormatSettings.ShortDateFormat))
              else
              if Count > 5 then
                AppendFormat(Pointer(FormatSettings.LongDateFormat));
            end;
          'H': // ʱ
            begin
              GetCount;  // Сʱ��λ��ʾ
              GetTime;   // ��ɢʱ��
              BetweenQuotes := False;
              P := Format;
              while P^ <> #0 do
              begin
                if IsLeadChar(P^) then
                begin
                  P := StrNextChar(P);
                  Continue;
                end;
                case P^ of
                  'A', 'a':
                    if not BetweenQuotes then
                    begin
                      if ( (StrLIComp(P, 'AM/PM', 5) = 0)
                        or (StrLIComp(P, 'A/P',   3) = 0)
                        or (StrLIComp(P, 'AMPM',  4) = 0) ) then
                        Use12HourClock := True;
                      Break;
                    end;
                  'H', 'h':
                    Break;
                  '''', '"':
                    BetweenQuotes := not BetweenQuotes;
                end;
                Inc(P);
              end;
              H := Hour;
              if Use12HourClock then
                if H = 0 then
                  H := 12
                else
                if H > 12 then
                  Dec(H, 12);
              if Count > 2 then
                Count := 2;
              //AppendNumber(H, Count);

              // ʱ��ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ʱ����
              vS := NumberText(H, Count);
              Inc(vOffset, Length(vS));
              // ʱ�������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaHour;
              Exit;
            end;
          'N':  // ��
            begin
              GetCount;
              GetTime;
              if Count > 2 then
                Count := 2;
              //AppendNumber(Min, Count);

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              vS := NumberText(Min, Count);
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaMinute;
              Exit;
            end;
          'S':  // ��
            begin
              GetCount;
              GetTime;
              if Count > 2 then
                Count := 2;
              //AppendNumber(Sec, Count);

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              vS := NumberText(Sec, Count);
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaSecond;
              Exit;
            end;
          'T':  // ʱ��
            begin
              GetCount;
              if Count = 1 then
                AppendFormat(Pointer(FormatSettings.ShortTimeFormat))
              else
                AppendFormat(Pointer(FormatSettings.LongTimeFormat));
            end;
          'Z':  // ����
            begin
              GetCount;
              GetTime;
              if Count > 3 then
                Count := 3;
              //AppendNumber(MSec, Count);

              // ������ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ��������
              vS := NumberText(MSec, Count);
              Inc(vOffset, Length(vS));
              // �����������ڷ�Χ
              Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              AArea := dtaMillisecond;
              Exit;
            end;
          'A':  // ���硢����
            begin
              GetTime;
              P := Format - 1;
              if StrLIComp(P, 'AM/PM', 5) = 0 then
              begin
                if Hour >= 12 then
                  Inc(P, 3);
                //AppendChars(P, 2);
                Inc(vOffset, 2);
                Inc(Format, 4);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'A/P', 3) = 0 then
              begin
                if Hour >= 12 then
                  Inc(P, 2);
                //AppendChars(P, 1);
                Inc(vOffset);
                Inc(Format, 2);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'AMPM', 4) = 0 then
              begin
                if Hour < 12 then
                begin
                  //AppendString(TimeAMString);
                  Inc(vOffset, Length(FormatSettings.TimeAMString));
                end
                else
                begin
                  //AppendString(TimePMString);
                  Inc(vOffset, Length(FormatSettings.TimePMString));
                end;
                Inc(Format, 3);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'AAAA', 4) = 0 then
              begin
                GetDate;
                //AppendString(LongDayNames[DayOfWeek(DateTime)]);
                Inc(vOffset, Length(FormatSettings.LongDayNames[DayOfWeek(DateTime)]));
                Inc(Format, 3);
              end
              else
              if StrLIComp(P, 'AAA', 3) = 0 then
              begin
                GetDate;
                //AppendString(ShortDayNames[DayOfWeek(DateTime)]);
                Inc(vOffset, Length(FormatSettings.ShortDayNames[DayOfWeek(DateTime)]));
                Inc(Format, 2);
              end
              else
              begin
                //AppendChars(@Starter, 1);
                Inc(vOffset);
              end;
            end;
          'C':  // �̸�ʽ����ʱ��
            begin
              GetCount;
              AppendFormat(Pointer(FormatSettings.ShortDateFormat));
              GetTime;
              if (Hour <> 0) or (Min <> 0) or (Sec <> 0) then
              begin
                //AppendChars(' ', 1);
                Inc(vOffset);
                AppendFormat(Pointer(FormatSettings.LongTimeFormat));
              end;
            end;
          '/':  // ���ڷָ�
            if FormatSettings.DateSeparator <> #0 then
            begin
              //AppendChars(@DateSeparator, 1);
              Inc(vOffset);
            end;
          ':':  // ʱ��ָ�
            if FormatSettings.TimeSeparator <> #0 then
            begin
              //AppendChars(@TimeSeparator, 1);
              Inc(vOffset);
            end;
          '''', '"':  // ��Ч�ַ��������?
            begin
              P := Format;
              while (Format^ <> #0) and (Format^ <> Starter) do
              begin
                if IsLeadChar(Format^) then
                  Format := StrNextChar(Format)
                else
                  Inc(Format);
              end;
              //AppendChars(P, Format - P);
              Inc(vOffset, Format - P);
              if Format^ <> #0 then
                Inc(Format);
            end;
        else
          begin
            //AppendChars(@Starter, 1);
            Inc(vOffset);
          end;
        end;
      end;
      Dec(AppendLevel);
    end;
  end;
  {$ENDREGION}

var
  vOldFont: hGdiObj;
begin
  SetRectEmpty(Result);
  AArea := dtaNone;
  vDateTimeText := FormatDateTime(FFormat, DateTime);
  vOffset := 0;
  AppendLevel := 0;
  vDC := GetDC(0);
  try
    vOldFont := GetCurrentObject(vDC, OBJ_FONT);
    SelectObject(vDC, Font.Handle);
    try
      if FFormat <> '' then
        AppendFormat(PChar(FFormat))
      else
        AppendFormat('C');  // C �ö̸�ʽ��ʾ������ʱ��
    finally
      SelectObject(vDC, vOldFont);
    end;
  finally
    ReleaseDC(0, vDC);
  end;
end;

function TCFDateTimePicker.GetAreaAt(const X, Y: Integer; var AArea: TDateTimeArea; const ACalcArea: Boolean = True): TRect;
var
  //vDC: HDC;
  vSize: TSize;
  vS, vDateTimeText: string;
  vOffset, AppendLevel: Integer;

  {$REGION '�ڲ�����'}
  procedure AppendChars(P: PChar; Count: Integer);
  begin
    Inc(vOffset, Count);
  end;

  function NumberText(Number, Digits: Integer): string;
  const
    Format: array[0..3] of Char = '%.*d';
  var
    NumBuf: array[0..15] of Char;
    vLen: Integer;
  begin
    vLen := FormatBuf(NumBuf, Length(NumBuf), Format,
      Length(Format), [Digits, Number]);
    SetString(Result, NumBuf, vLen);
  end;

  procedure AppendFormat(Format: PChar);
  var
    Starter, Token, LastToken: Char;
    DateDecoded, TimeDecoded, Use12HourClock,
    BetweenQuotes: Boolean;
    P: PChar;
    Count: Integer;
    Year, Month, Day, Hour, Min, Sec, MSec, H: Word;

    procedure GetCount;  // ��ȡ������Starter���ַ��м���
    var
      P: PChar;
    begin
      P := Format;
      while Format^ = Starter do
        Inc(Format);
      Count := Format - P + 1;
    end;

    procedure GetDate;  // �ֽ�����
    begin
      if not DateDecoded then
      begin
        DecodeDate(DateTime, Year, Month, Day);
        DateDecoded := True;
      end;
    end;

    procedure GetTime;  // �ֽ�ʱ��
    begin
      if not TimeDecoded then
      begin
        DecodeTime(DateTime, Hour, Min, Sec, MSec);
        TimeDecoded := True;
      end;
    end;

    function ConvertEraString(const Count: Integer) : string;
    var
      FormatStr: string;
      SystemTime: TSystemTime;
      Buffer: array[Byte] of Char;
      P: PChar;
    begin
      Result := '';
      with SystemTime do
      begin
        wYear  := Year;
        wMonth := Month;
        wDay   := Day;
      end;

      FormatStr := 'gg';
      if GetDateFormat(GetThreadLocale, DATE_USE_ALT_CALENDAR, @SystemTime,
        PChar(FormatStr), Buffer, Length(Buffer)) <> 0 then
      begin
        Result := Buffer;
        if Count = 1 then
        begin
          case SysLocale.PriLangID of
            LANG_JAPANESE:
              Result := Copy(Result, 1, CharToBytelen(Result, 1));
            LANG_CHINESE:
              if (SysLocale.SubLangID = SUBLANG_CHINESE_TRADITIONAL)
                and (ByteToCharLen(Result, Length(Result)) = 4)
              then
              begin
                P := Buffer + CharToByteIndex(Result, 3) - 1;
                SetString(Result, P, CharToByteLen(P, 2));
              end;
          end;
        end;
      end;
    end;

    function ConvertYearString(const Count: Integer): string;
    var
      FormatStr: string;
      SystemTime: TSystemTime;
      Buffer: array[Byte] of Char;
    begin
      Result := '';
      with SystemTime do
      begin
        wYear  := Year;
        wMonth := Month;
        wDay   := Day;
      end;

      if Count <= 2 then
        FormatStr := 'yy' // avoid Win95 bug.
      else
        FormatStr := 'yyyy';

      if GetDateFormat(GetThreadLocale, DATE_USE_ALT_CALENDAR, @SystemTime,
        PChar(FormatStr), Buffer, Length(Buffer)) <> 0 then
      begin
        Result := Buffer;
        if (Count = 1) and (Result[1] = '0') then
          Result := Copy(Result, 2, Length(Result)-1);
      end;
    end;

  begin
    if (Format <> nil) and (AppendLevel < 2) then
    begin
      Inc(AppendLevel);
      LastToken := ' ';
      DateDecoded := False;
      TimeDecoded := False;
      Use12HourClock := False;
      while Format^ <> #0 do
      begin
        Starter := Format^;  // ��ǰ�ַ�����1���ַ�
        if IsLeadChar(Starter) then  // ���� MBCS Ansi �ַ��ļ���
        begin
          Format := StrNextChar(Format);
          LastToken := ' ';
          Continue;
        end;
        Format := StrNextChar(Format);

        Token := Starter;
        if Token in ['a'..'z'] then
          Dec(Token, 32);
        if Token in ['A'..'Z'] then
        begin
          if (Token = 'M') and (LastToken = 'H') then
            Token := 'N';
          LastToken := Token;
        end;

        case Token of
          'Y': // ��
            begin
              GetCount;  // ���м�λ
              GetDate;   // �ֽ�����
              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              if Count <= 2 then
              begin
                vS := NumberText(Year mod 100, 2);
                Inc(vOffset, Length(vS));
              end
              else
              begin
                vS := NumberText(Year, 4);
                Inc(vOffset, Length(vS));
              end;
              // ���������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaYear then Exit;
                if Format = '' then
                begin
                  AArea := dtaYear;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaYear;
                Exit;
              end;
            end;
          'G':  // ��Ԫ
            begin
              GetCount;  // ��Ԫ��λ��ʾ
              GetDate;
              //AppendString(ConvertEraString(Count));
              Inc(vOffset, Length(ConvertEraString(Count)));
            end;
          'E':  // �ֻ꣬��һ��Eʱ��ʾ��2λ��
            begin
              GetCount;
              GetDate;
              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              vS := ConvertYearString(Count);
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaYear then Exit;
                if Format = '' then
                begin
                  AArea := dtaYear;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaYear;
                Exit;
              end;
            end;
          'M':  // ��
            begin
              GetCount;  // �·ݼ�λ��ʾ
              GetDate;

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              case Count of
                1, 2:
                  vS := NumberText(Month, Count);
                3:
                  vS := FormatSettings.ShortMonthNames[Month];
              else
                vS := FormatSettings.LongMonthNames[Month];
              end;
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaMonth then Exit;
                if Format = '' then
                begin
                  AArea := dtaMonth;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaMonth;
                Exit;
              end;
            end;
          'D': // ��
            begin
              GetCount;  // ���ڼ�λ��ʾ

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              case Count of
                1, 2:
                  begin
                    GetDate;
                    vS := NumberText(Day, Count);
                  end;
                3: vS := FormatSettings.ShortDayNames[DayOfWeek(DateTime)];
                4: vS := FormatSettings.LongDayNames[DayOfWeek(DateTime)];
              end;
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaDay then Exit;
                if Format = '' then
                begin
                  AArea := dtaDay;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaDay;
                Exit;
              end;

              if Count = 5 then
                AppendFormat(Pointer(FormatSettings.ShortDateFormat))
              else
              if Count > 5 then
                AppendFormat(Pointer(FormatSettings.LongDateFormat));
            end;
          'H': // ʱ
            begin
              GetCount;  // Сʱ��λ��ʾ
              GetTime;   // ��ɢʱ��
              BetweenQuotes := False;
              P := Format;
              while P^ <> #0 do
              begin
                if IsLeadChar(P^) then
                begin
                  P := StrNextChar(P);
                  Continue;
                end;
                case P^ of
                  'A', 'a':
                    if not BetweenQuotes then
                    begin
                      if ( (StrLIComp(P, 'AM/PM', 5) = 0)
                        or (StrLIComp(P, 'A/P',   3) = 0)
                        or (StrLIComp(P, 'AMPM',  4) = 0) ) then
                        Use12HourClock := True;
                      Break;
                    end;
                  'H', 'h':
                    Break;
                  '''', '"':
                    BetweenQuotes := not BetweenQuotes;
                end;
                Inc(P);
              end;
              H := Hour;
              if Use12HourClock then
                if H = 0 then
                  H := 12
                else
                if H > 12 then
                  Dec(H, 12);
              if Count > 2 then
                Count := 2;
              //AppendNumber(H, Count);

              // ʱ��ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ʱ����
              vS := NumberText(H, Count);
              Inc(vOffset, Length(vS));
              // ʱ�������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaHour then Exit;
                if Format = '' then
                begin
                  AArea := dtaHour;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaHour;
                Exit;
              end;
            end;
          'N':  // ��
            begin
              GetCount;
              GetTime;
              if Count > 2 then
                Count := 2;
              //AppendNumber(Min, Count);

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              vS := NumberText(Min, Count);
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaMinute then Exit;
                if Format = '' then
                begin
                  AArea := dtaMinute;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaMinute;
                Exit;
              end;
            end;
          'S':  // ��
            begin
              GetCount;
              GetTime;
              if Count > 2 then
                Count := 2;
              //AppendNumber(Sec, Count);

              // ����ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ������
              vS := NumberText(Sec, Count);
              Inc(vOffset, Length(vS));
              // ���������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaSecond then Exit;
                if Format = '' then
                begin
                  AArea := dtaSecond;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaSecond;
                Exit;
              end;
            end;
          'T':  // ʱ��
            begin
              GetCount;
              if Count = 1 then
                AppendFormat(Pointer(FormatSettings.ShortTimeFormat))
              else
                AppendFormat(Pointer(FormatSettings.LongTimeFormat));
            end;
          'Z':  // ����
            begin
              GetCount;
              GetTime;
              if Count > 3 then
                Count := 3;
              //AppendNumber(MSec, Count);

              // ������ʼ����
              vS := Copy(vDateTimeText, 1, vOffset);
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Left := GPadding + vSize.cx;
              // ��������
              vS := NumberText(MSec, Count);
              Inc(vOffset, Length(vS));
              // �����������ڷ�Χ
              vSize := Canvas.TextExtent(vS);
              //Windows.GetTextExtentPoint32(vDC, vS, Length(vS), vSize);
              Result.Top := (Height - vSize.cy) div 2;
              Result.Right := Result.Left + vSize.cx;
              Result.Bottom := Result.Top + vSize.cy;

              if not ACalcArea then
              begin
                if AArea = dtaMillisecond then Exit;
                if Format = '' then
                begin
                  AArea := dtaMillisecond;
                  //SetRectEmpty(Result);
                  Exit;
                end;
              end;

              if PtInRect(Result, Point(X, Y)) then
              begin
                AArea := dtaMillisecond;
                Exit;
              end;
            end;
          'A':  // ���硢����
            begin
              GetTime;
              P := Format - 1;
              if StrLIComp(P, 'AM/PM', 5) = 0 then
              begin
                if Hour >= 12 then
                  Inc(P, 3);
                //AppendChars(P, 2);
                Inc(vOffset, 2);
                Inc(Format, 4);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'A/P', 3) = 0 then
              begin
                if Hour >= 12 then
                  Inc(P, 2);
                //AppendChars(P, 1);
                Inc(vOffset);
                Inc(Format, 2);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'AMPM', 4) = 0 then
              begin
                if Hour < 12 then
                begin
                  //AppendString(TimeAMString);
                  Inc(vOffset, Length(FormatSettings.TimeAMString));
                end
                else
                begin
                  //AppendString(TimePMString);
                  Inc(vOffset, Length(FormatSettings.TimePMString));
                end;
                Inc(Format, 3);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'AAAA', 4) = 0 then
              begin
                GetDate;
                //AppendString(LongDayNames[DayOfWeek(DateTime)]);
                Inc(vOffset, Length(FormatSettings.LongDayNames[DayOfWeek(DateTime)]));
                Inc(Format, 3);
              end
              else
              if StrLIComp(P, 'AAA', 3) = 0 then
              begin
                GetDate;
                //AppendString(ShortDayNames[DayOfWeek(DateTime)]);
                Inc(vOffset, Length(FormatSettings.ShortDayNames[DayOfWeek(DateTime)]));
                Inc(Format, 2);
              end
              else
              begin
                //AppendChars(@Starter, 1);
                Inc(vOffset);
              end;
            end;
          'C':  // �̸�ʽ����ʱ��
            begin
              GetCount;
              AppendFormat(Pointer(FormatSettings.ShortDateFormat));
              GetTime;
              if (Hour <> 0) or (Min <> 0) or (Sec <> 0) then
              begin
                //AppendChars(' ', 1);
                Inc(vOffset);
                AppendFormat(Pointer(FormatSettings.LongTimeFormat));
              end;
            end;
          '/':  // ���ڷָ�
            if FormatSettings.DateSeparator <> #0 then
            begin
              //AppendChars(@DateSeparator, 1);
              Inc(vOffset);
            end;
          ':':  // ʱ��ָ�
            if FormatSettings.TimeSeparator <> #0 then
            begin
              //AppendChars(@TimeSeparator, 1);
              Inc(vOffset);
            end;
          '''', '"':  // ��Ч�ַ��������?
            begin
              P := Format;
              while (Format^ <> #0) and (Format^ <> Starter) do
              begin
                if IsLeadChar(Format^) then
                  Format := StrNextChar(Format)
                else
                  Inc(Format);
              end;
              //AppendChars(P, Format - P);
              Inc(vOffset, Format - P);
              if Format^ <> #0 then
                Inc(Format);
            end;
        else
          begin
            //AppendChars(@Starter, 1);
            Inc(vOffset);
          end;
        end;
      end;
      Dec(AppendLevel);
    end;
  end;
  {$ENDREGION}

begin
  SetRectEmpty(Result);
  if ACalcArea then
    AArea := dtaNone;
  vDateTimeText := FormatDateTime(FFormat, DateTime);
  vOffset := 0;
  AppendLevel := 0;
  if FFormat <> '' then
    AppendFormat(PChar(FFormat))
  else
    AppendFormat('C');  // C �ö̸�ʽ��ʾ������ʱ��
end;

function TCFDateTimePicker.GetDateTime: TDateTime;
begin
  Result := FCalendar.Date;
end;

function TCFDateTimePicker.GetMaxDateTime: TDateTime;
begin
  Result := FCalendar.MaxDate;
end;

function TCFDateTimePicker.GetMinDateTime: TDateTime;
begin
  Result := FCalendar.MinDate;
end;

procedure TCFDateTimePicker.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:  // ȡ����������ַ���
      begin
        if FNewYear <> '' then
        begin
          FNewYear := '';
          UpdateDirectUI;
        end;
      end;

    VK_RETURN:
      begin
        if FNewYear <> '' then
          SetInputYear;
      end;

    VK_LEFT:
      begin
        if FNewYear <> '' then
          SetInputYear;

        case FArea of
          dtaNone, dtaYear: FArea := dtaMillisecond;
          dtaMonth: FArea := dtaYear;
          dtaDay: FArea := dtaMonth;
          dtaHour: FArea := dtaDay;
          dtaMinute: FArea := dtaHour;
          dtaSecond: FArea := dtaMinute;
          dtaMillisecond: FArea := dtaSecond;
        end;
        //FArea := Pred(FArea);

        FAreaRect := GetAreaAt(0, 0, FArea, False);
        UpdateDirectUI;
      end;

    VK_RIGHT:
      begin
        if FNewYear <> '' then
          SetInputYear;

        case FArea of
          dtaNone, dtaYear: FArea := dtaMonth;
          dtaMonth: FArea := dtaDay;
          dtaDay: FArea := dtaHour;
          dtaHour: FArea := dtaMinute;
          dtaMinute: FArea := dtaSecond;
          dtaSecond: FArea := dtaMillisecond;
          dtaMillisecond: FArea := dtaYear;
        end;
        //FArea := Succ(FArea);

        FAreaRect := GetAreaAt(0, 0, FArea, False);
        UpdateDirectUI;
      end;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TCFDateTimePicker.KeyPress(var Key: Char);
var
  vNumber, vCount: Word;
begin
  inherited KeyPress(Key);

  if FReadOnly then Exit;

  if FArea <> dtaNone then
  begin
    if Key in ['0'..'9'] then
    begin
      case FArea of
        dtaYear:
          begin
            if Length(FNewYear) > 3 then
              System.Delete(FNewYear, 1, 1);
            FNewYear := FNewYear + Key;
          end;

        dtaMonth:
          begin;
            vNumber := MonthOf(DateTime);  // ��ǰ�·�
            if vNumber > 9 then  // ��ǰ�·��Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λ�·�������0������

              DateTime := RecodeMonth(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ�·���1λ����
            if (vNumber = 1) and FJoinKey then  // ��ǰ�·���1��������������
            begin
              if Key in ['0'..'2'] then  // 10, 11, 12
              begin
                vNumber := vNumber * 10 + StrToInt(Key);
                DateTime := RecodeMonth(DateTime, vNumber);  // ֱ���޸�Ϊ�¼���
              end;
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // �·ݵ�1λ��0������

              DateTime := RecodeMonth(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaDay:
          begin
            vNumber := DayOf(DateTime);  // ��ǰ����
            if vNumber > 9 then  // ��ǰ�����Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λ����������0������

              DateTime := RecodeDay(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ������1λ����
            if FJoinKey then  // ����������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              vCount := DaysInMonth(DateTime);
              if vNumber > vCount then
                vNumber := StrToInt(Key);
              DateTime := RecodeDay(DateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // �·ݵ�1λ��0������

              DateTime := RecodeDay(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaHour:
          begin
            vNumber := HourOf(DateTime);  // ��ǰʱ
            if vNumber > 9 then  // ��ǰʱ�Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λʱ������0������

              DateTime := RecodeHour(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰʱ��1λ����
            if FJoinKey then  // ��ǰʱ������������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              if vNumber > 24 then
                vNumber := StrToInt(Key);
              DateTime := RecodeHour(DateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // ʱ��1λ��0������

              DateTime := RecodeHour(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaMinute:
          begin
            vNumber := MinuteOf(DateTime);  // ��ǰ��
            if vNumber > 9 then  // ��ǰ���Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λʱ������0������

              DateTime := RecodeMinute(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ����1λ����
            if FJoinKey then  // ��ǰ��������������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              if vNumber > 60 then
                vNumber := StrToInt(Key);
              DateTime := RecodeMinute(DateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // �ֵ�1λ��0������

              DateTime := RecodeMinute(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaSecond:
          begin
            vNumber := SecondOf(DateTime);  // ��ǰ��
            if vNumber > 9 then  // ��ǰ���Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λʱ������0������

              DateTime := RecodeSecond(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ����1λ����
            if FJoinKey then  // ��ǰ��������������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              if vNumber > 60 then
                vNumber := StrToInt(Key);
              DateTime := RecodeSecond(DateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // ���1λ��0������

              DateTime := RecodeSecond(DateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaMillisecond: Exit;
      end;
    end;

    if FArea <> dtaYear then // �����⣬��������Ҫʵʱ����
    begin
      ReBuildArea(FAreaRect.Left + FLeftDrawOffset, FAreaRect.Top);
      FJoinKey := True;
    end;

    UpdateDirectUI;
  end;
end;

procedure TCFDateTimePicker.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  vOldArea: TDateTimeArea;
begin
  inherited MouseDown(Button, Shift, X, Y);

  FJoinKey := False;  // �ж���������
  vOldArea := FArea;

  ReBuildArea(X + FLeftDrawOffset, Y);  // ��ƫ��ʱ���������ʱ�����һ��λ

  if FArea <> vOldArea then
  begin
    if vOldArea = dtaYear then  // ��һ���������������
      SetInputYear;

    UpdateDirectUI;
  end;
end;

procedure TCFDateTimePicker.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  // ����ŵ�DouseDonw�У��򵯳�����ʾʱ�ٵ����ťִ�йرյ�����
  if PtInRect(Rect(Width - GIconWidth, GBorderWidth, Width - GBorderWidth, Height - GBorderWidth), Point(X, Y)) then
    DoButtonClick(Self);
end;

procedure TCFDateTimePicker.PopupPicker;
begin
  FPopup := TCFPopup.Create(Self);
  try
    FPopup.PopupControl := Self;
    FPopup.OnDrawWindow := DoOnPopupDrawWindow;
    FPopup.SetSize(FCalendar.Width, FCalendar.Height);
    FPopup.Popup(Self);
  finally
    FPopup.Free;
  end;
end;

procedure TCFDateTimePicker.ReBuildArea(X, Y: Integer);
begin
  FAreaRect := GetAreaAt(X, Y, FArea);
  if FArea <> dtaNone then  // ��Ч���򣬼���ƫ��
  begin
    if FAreaRect.Left - FLeftDrawOffset < GPadding then  // �����ж���಻����ʾȫ
      FLeftDrawOffset := FAreaRect.Left - FLeftDrawOffset
    else
    begin
      if FButtonVisible then
      begin
        if FAreaRect.Right > Width - GIconWidth then  // �Ҳ಻����ʾȫ
          FLeftDrawOffset := FAreaRect.Right - (Width - GIconWidth);
      end
      else
      begin
        if FAreaRect.Right > Width - GPadding then  // �Ҳ಻����ʾȫ
          FLeftDrawOffset := FAreaRect.Right - (Width - GPadding);
      end;
    end;

    OffsetRect(FAreaRect, -FLeftDrawOffset, 0);
  end
  else
    FLeftDrawOffset := 0;
end;

procedure TCFDateTimePicker.SetFormat(Value: string);
begin
  if FFormat <> Value then
  begin
    FFormat := Value;
    Text := FormatDateTime(FFormat, FCalendar.Date);
  end;
end;

procedure TCFDateTimePicker.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  vDC: HDC;
  vHeight, vWidth: Integer;
begin
  vDC := GetDC(0);
  try
    Canvas.Handle := vDC;
    Canvas.Font := Font;

    vWidth := Canvas.TextWidth(FormatDateTime('YYYY-MM-DD', Now)) + GetSystemMetrics(SM_CYBORDER) * 2;
    if FButtonVisible then
      vWidth := vWidth + GIconWidth;

    if vWidth < AWidth then
      vWidth := AWidth;

    vHeight := Canvas.TextHeight('��') + GetSystemMetrics(SM_CYBORDER) * 4 + GBorderWidth + GBorderWidth;
    if vHeight < AHeight then
      vHeight := AHeight;

    Canvas.Handle := 0;
  finally
    ReleaseDC(0, vDC);
  end;

  inherited SetBounds(ALeft, ATop, vWidth, vHeight);
end;

procedure TCFDateTimePicker.SetButtonVisible(Value: Boolean);
begin
  if FButtonVisible <> Value then
  begin
    FButtonVisible := Value;
    UpdateDirectUI;
  end;
end;

procedure TCFDateTimePicker.SetDateTime(Value: TDateTime);
begin
  FCalendar.Date := Value;
  DoDateTimeChanged(Self);
end;

procedure TCFDateTimePicker.SetInputYear;

  function GetYear(const AYear: string): Word;

    function Power10(const Sqr: Byte): Cardinal;
    var
      i: Integer;
    begin
      Result := 10;
      for i := 2 to Sqr do
        Result := Result * 10;
    end;

  var
    vYear: Word;
    vPie: Cardinal;
  begin
    Result := YearOf(DateTime);
    vYear := StrToIntDef(AYear, Result);
    if vYear < Result then
    begin
      vPie := Power10(System.Length(AYear));
      Result := Result div vPie;
      Result := Result * vPie + vYear;
    end
    else
      Result := vYear;
  end;

begin
  if FNewYear <> '' then  // �������꣬���������ַ���ȷ���������
  begin
    DateTime := RecodeYear(DateTime, GetYear(FNewYear));
    FNewYear := '';  // ȡ�������������
  end;
end;

procedure TCFDateTimePicker.SetMaxDateTime(Value: TDateTime);
begin
  FCalendar.MaxDate := Value;
end;

procedure TCFDateTimePicker.SetMinDateTime(Value: TDateTime);
begin
  FCalendar.MinDate := Value;
end;

procedure TCFDateTimePicker.WMCFLBUTTONDBLCLK(var Message: TMessage);
begin
//  if (CompareDate(FCalendar.Date, MinDate) >= 0)
//    and (CompareDate(FCalendar.Date, FMaxDate) <= 0)  // �ڱ߽緶Χ��
//  then
  if FCalendar.Perform(Message.Msg, Message.WParam, Message.LParam) = 1 then
    FPopup.UpdatePopup
  else
  begin
    FPopup.ClosePopup(False);
    DoDateTimeChanged(Self);
  end;
  {if Assigned(FOnCloseUp) then
    FOnCloseUp(Self);}
end;

procedure TCFDateTimePicker.WMCFLBUTTONDOWN(var Message: TMessage);
begin
  if FCalendar.Perform(Message.Msg, Message.WParam, Message.LParam) = 1 then
    FPopup.UpdatePopup
  else
  begin
    FPopup.ClosePopup(False);
    DoDateTimeChanged(Self);
  end;
end;

procedure TCFDateTimePicker.WMCFLBUTTONUP(var Message: TMessage);
begin
  if FCalendar.Perform(Message.Msg, Message.WParam, Message.LParam) = 1 then
    FPopup.UpdatePopup;
end;

procedure TCFDateTimePicker.WMCFMOUSEMOVE(var Message: TMessage);
begin
  if FCalendar.Perform(Message.Msg, Message.WParam, Message.LParam) = 1 then
    FPopup.UpdatePopup;
end;

procedure TCFDateTimePicker.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  DisActive;
end;

end.
