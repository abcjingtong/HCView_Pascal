unit CFMonthCalendar;

interface

uses
  Windows, Graphics, Classes, CFControl, Controls;

type
  TDisplayModel = (cdmDate, cdmMonth, cdmYear, cdmCentury);
  TPaintDateEvent = procedure(Sender: TObject; const ACanvas: TCanvas; const ADate: TDate; const ARect: TRect) of object;

  TCFCustomMonthCalendar = class(TCFTextControl)
  private
    /// <summary> ��ǰ���ڡ��������ޡ��������� </summary>
    FDate: TDateTime;
    FMinDate, FMaxDate: TDate;
    /// <summary> ��ͬ��ʾģʽ���и� </summary>
    FRowHeight,
    /// <summary> ��ͬ��ʾе���п� </summary>
    FColWidth,
    /// <summary> ����߶� </summary>
    FTitleBandHeight,
    /// <summary> ���ڸ߶� </summary>
    FWeekBandHeight,
    /// <summary> ����߶� </summary>
    FTodayBandHeight
      : Integer;
    FOnPaintDate: TPaintDateEvent;

    /// <summary>
    /// �������ڷ�Χ�ж������Ƿ񳬳����糬����������Ϊ�߽�ֵ
    /// </summary>
    /// <param name="ADate">����</param>
    procedure CheckValidDate(var ADate: TDateTime);

    /// <summary>
    /// �ж�ָ���������Ƿ񳬳���Ч��Χ
    /// </summary>
    /// <param name="ADate">����</param>
    /// <returns>True��������Χ</returns>
    function DateOutRang(const ADate: TDate): Boolean;

    /// <summary>
    /// ��ȡ��ͬģʽ��������������ڡ��·ݡ��ꡢ10������
    /// </summary>
    /// <param name="X">������</param>
    /// <param name="Y">������</param>
    /// <returns>����or�·�or��or10������</returns>
    function GetDateAt(const X, Y: Integer): TDate;

    /// <summary>
    /// ������ģʽ�£�����ָ��������Կؼ��ͻ���������
    /// </summary>
    /// <param name="ADate">����</param>
    /// <returns>����</returns>
    function GetDataRect(const ADate: TDate): TRect;
    procedure SetDisplayModelProperty(const AModel: TDisplayModel);
  protected
    FMoveDate: TDate;  // ΪDateTimePicker��������ʱ����ƶ����Ʒŵ�����������
    /// <summary> ʱ��ģʽ </summary>
    FDisplayModel: TDisplayModel;

    function GetDate: TDateTime;
    procedure SetDate(Value: TDateTime);
    procedure SetMaxDate(Value: TDate);
    procedure SetMinDate(Value: TDate);
    /// <summary> ���ñ߿� </summary>
    procedure AdjustBounds; override;
    function CanResize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure DrawControl(ACanvas: TCanvas); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;

    /// <summary> Ϊ������ؿؼ�(��DateTimePicker)ʹ�ã�Dateʵ��ΪTDateTime���� </summary>
    property Date: TDateTime read GetDate write SetDate;
    property MaxDate: TDate read FMaxDate write SetMaxDate;
    property MinDate: TDate read FMinDate write SetMinDate;
    property TitleBandHeight: Integer read FTitleBandHeight write FTitleBandHeight;
    property OnPaintDate: TPaintDateEvent read FOnPaintDate write FOnPaintDate;
  end;

  TCFMonthCalendar = class(TCFCustomMonthCalendar)
  published
    property Date;
    property MaxDate;
    property MinDate;
    property OnPaintDate;
    property OnChange;
  end;

implementation

{$R CFMonthCalendar.RES}

uses
  SysUtils, DateUtils;

{ TCFCustomMonthCalendar }

procedure TCFCustomMonthCalendar.AdjustBounds;
var
  DC: HDC;
  vNewHeight, vNewWidth, vHeight: Integer;
begin
  //if not (csReading in ComponentState) then
  begin
    DC := GetDC(0);
    try
      Canvas.Handle := DC;
      Canvas.Font := Font;

      vHeight := Canvas.TextHeight('��');
      FTitleBandHeight := vHeight + Round(vHeight * 0.25);
      FWeekBandHeight := vHeight;
      FRowHeight := Round(vHeight + vHeight * 0.5);
      FColWidth := Canvas.TextWidth('�й�');
      FTodayBandHeight := Round(vHeight + vHeight * 5);

      vNewHeight := FTitleBandHeight + FWeekBandHeight + 6 * FRowHeight + FTodayBandHeight + GPadding * 2;  // �� 12.5 ������ĸ߶�
      if vNewHeight < Height then
        vNewHeight := Height;

      vNewWidth := 7 * FColWidth + GPadding * 2;
      if vNewWidth < Width then
        vNewWidth := Width;
      Canvas.Handle := 0;
    finally
      ReleaseDC(0, DC);
    end;
    SetBounds(Left, Top, vNewWidth, vNewHeight);
  end;
end;

function TCFCustomMonthCalendar.CanResize(var NewWidth, NewHeight: Integer): Boolean;
var
  vSize: TSize;
  vWidth, vHeight: Integer;
begin
  Result := True;

  vSize := Canvas.TextExtent('�й�');

  vWidth := vSize.cx + GPadding * 2;
  vHeight := Round(vSize.cy * 12.5) ;
  if NewWidth < vWidth then
    NewWidth := vWidth
  else
    FColWidth := (Width - GPadding * 2) div 7;
  if NewHeight < vHeight then
    NewHeight := vHeight
  else
  begin
    vHeight := Round((Height - GPadding * 2) / 12.5);  // ÿ������Ԥ���ĸ߶�
    FRowHeight := Round(vHeight * 1.5);  // �� 12.5 ������ĸ߶�, һ����1.5��������ĸ߶�
    FTitleBandHeight := Round(vHeight * 1.25);  // ����ĸ߶�
    FWeekBandHeight := vHeight;
    FTodayBandHeight := Round(vHeight * 1.25);
  end;
end;

procedure TCFCustomMonthCalendar.CheckValidDate(var ADate: TDateTime);
begin
  if (FMaxDate <> 0.0) and (ADate > FMaxDate) then
    ADate := FMaxDate;
  if (FMinDate <> 0.0) and (ADate < FMinDate) then
    ADate := FMinDate;
end;

constructor TCFCustomMonthCalendar.Create(AOwner: TComponent);
begin
  inherited;
  FDisplayModel := cdmDate;
  SetDisplayModelProperty(FDisplayModel);
  FDate := Now;
  FMaxDate := 0.0;
  FMinDate := 0.0;
  Color := GBackColor;
end;

function TCFCustomMonthCalendar.DateOutRang(const ADate: TDate): Boolean;
begin
  Result := False;
  if (FMaxDate <> 0.0) and (ADate > FMaxDate) then
    Result := True;

  if not Result then
  begin
    if (FMinDate <> 0.0) and (ADate < FMinDate) then
      Result := True;
  end;
end;

procedure TCFCustomMonthCalendar.DrawControl(ACanvas: TCanvas);
var
  vLeft, vTop: Integer;
  vS: string;
  vRect: TRect;

  {$REGION '����ģʽ����'}

  {$REGION 'DrawModelTitle���Ʊ���ͽ���'}
  procedure DrawModelTitle(const ATitle: string);
  var
    vBmp: TBitmap; //vIcon: HICON;
  begin
    // ���Ʊ�������
    vRect := Bounds(GPadding, GPadding, Width - GPadding, GPadding + FTitleBandHeight);
    DrawTextEx(ACanvas.Handle, PChar(ATitle), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    // ���Ʊ����ϵ��������ǰ�ť��ʵ�ַ���
    vBmp := TBitmap.Create;
    try
      vBmp.Transparent := True;
      //vIcon := LoadIcon(HInstance, 'DROPLEFT');
      vBmp.LoadFromResourceName(HInstance, 'LEFT');
      ACanvas.Draw(GPadding, GPadding + Round((GPadding + FTitleBandHeight - GIconWidth) / 2), vBmp);
      //DrawIconEx(ACanvas.Handle, GPadding, GPadding + Round((GPadding + FTitleBandHeight - GIconWidth) / 2), vIcon,
      //  GIconWidth, GIconWidth, 0, 0, DI_NORMAL);
      vBmp.LoadFromResourceName(HInstance, 'RIGHT');
      ACanvas.Draw(Width - GPadding - GIconWidth, GPadding + Round((GPadding + FTitleBandHeight - GIconWidth) / 2), vBmp);
      //DrawIconEx(ACanvas.Handle, Width - GPadding - GIconWidth, GPadding + Round((GPadding + FTitleBandHeight - GIconWidth) / 2), vIcon,
      //  GIconWidth, GIconWidth, 0, 0, DI_NORMAL);
    finally
      vBmp.Free;
    end;

    // ���ƽ���
    vRect := Bounds(GPadding, Height - GPadding - Round(FTodayBandHeight * 0.8),  Width - 2 * GPadding, FTodayBandHeight);  // ���ƽ����������ƫ�ͣ���ԭ���ĸ߶Ȼ�����*0.8
    vS := '���죺' + FormatDateTime('YYYY/MM/DD', Now);
    DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
  end;
  {$ENDREGION}

  {$REGION 'DrawDateModelWeek������'}
  procedure DrawDateModelWeek;
  begin
    vLeft := GPadding;
    FWeekBandHeight := FRowHeight;
    vTop := GPadding + FTitleBandHeight + Round(FWeekBandHeight * 0.9) ;
    // �����ں����ڵļ����
    ACanvas.Pen.Color := clBtnFace;
    ACanvas.MoveTo(GPadding, vTop);
    ACanvas.LineTo(Width - GPadding, vTop);

    // �����ڼ���
    vTop := GPadding + FTitleBandHeight;
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('����'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    Inc(vLeft, FColWidth);
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('��һ'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    Inc(vLeft, FColWidth);
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('�ܶ�'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    Inc(vLeft, FColWidth);
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('����'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    Inc(vLeft, FColWidth);
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('����'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    Inc(vLeft, FColWidth);
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('����'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

    Inc(vLeft, FColWidth);
    vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
    DrawTextEx(ACanvas.Handle, PChar('����'), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
  end;
  {$ENDREGION}

  {$REGION 'DrawDateModel�������ںͽ���'}
  procedure DrawDateModel;
  var
    vStartDate, vEndDate: TDate;
    vWeekNo,  // �ܼ�
    vCount  // ��¼�����˶��ٸ�����
      : Byte;
  begin
    vStartDate := StartOfTheMonth(FDate);
    vEndDate := EndOfTheMonth(FDate);
    vWeekNo := DayOfTheWeek(vStartDate);
    vLeft := GPadding + vWeekNo * FColWidth;
    vTop := GPadding + FTitleBandHeight + FWeekBandHeight;
    while vStartDate < vEndDate do  // ���Ʋ��ܳ������µ����һ��
    begin
      while vWeekNo < 7 do  // һ�����Ǵ����յ�����
      begin
        vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
        if IsSameDay(vStartDate, Now) then  // ����ĵ�ɫ�� clBtnFace ��ɫ���
        begin
          ACanvas.Brush.Color := clBtnFace;
          ACanvas.FillRect(vRect);
          ACanvas.Brush.Style := bsClear;
        end;
        if IsSameDay(vStartDate, FMoveDate) then  // ������ƶ��������ڣ���������
        begin
          ACanvas.Brush.Color := GHightLightColor;
          ACanvas.FillRect(vRect);
          ACanvas.Brush.Style := bsClear;
        end;
        if IsSameDay(vStartDate, FDate) then  // �������� GBorderColor ��ɫ���
        begin
          ACanvas.Brush.Style := bsClear;
          ACanvas.Pen.Color := GBorderColor;
          ACanvas.Rectangle(vRect);
        end;

        if Assigned(FOnPaintDate) then
          FOnPaintDate(Self, ACanvas, vStartDate, vRect)
        else
        begin
          if DateOutRang(vStartDate) then
            ACanvas.Font.Color := clMedGray
          else
            ACanvas.Font.Color := clBlack;
          vS := FormatDateTime('D', DateOf(vStartDate));
          DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
        end;
        vStartDate := IncDay(vStartDate);
        if vStartDate >= vEndDate then
          Break;
        Inc(vWeekNo);
        vLeft := vLeft + FColWidth;
      end;
      vWeekNo := 0;
      vTop := vTop + FRowHeight;
      vLeft := GPadding;
    end;

    // �����ϸ��µ������(����)
    ACanvas.Font.Color := clGray;
    vStartDate := StartOfTheMonth(FDate);
    vWeekNo := DayOfTheWeek(vStartDate);
    if vWeekNo <> 7 then  // ��������
      vLeft := GPadding + (vWeekNo - 1)  * FColWidth
    else  // �����մ���һ�����ʼ
      vLeft := Width - GPadding - FColWidth;
    vTop := GPadding + FTitleBandHeight + FWeekBandHeight;

    repeat
      vStartDate := IncDay(vStartDate, -1);
      Dec(vWeekNo);
      vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
      if IsSameDay(vStartDate, FMoveDate) then  // ������ƶ��������ڣ���������
      begin
        ACanvas.Brush.Color := GHightLightColor;
        ACanvas.FillRect(vRect);
        ACanvas.Brush.Style := bsClear;
      end;

      if Assigned(FOnPaintDate) then
        FOnPaintDate(Self, ACanvas, vStartDate, vRect)
      else
      begin
        if DateOutRang(vStartDate) then
          ACanvas.Font.Color := clMedGray
        else
          ACanvas.Font.Color := clBlack;
        vS := FormatDateTime('D', DateOf(vStartDate));
        DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
      end;

      vLeft := vLeft - FColWidth;
    until vWeekNo = 0;

    // ��������˶��ٸ�����
    vStartDate := StartOfTheMonth(FDate);
    vCount := DayOfTheWeek(vStartDate);  // �ϸ��»����˼���
    vCount := vCount + DaysInMonth(FDate);  // ��ǰ�� + �ϸ���

    // ������һ���µ�ͷ����
    vCount := 42 - vCount;
    if vCount > 7 then  // ����Ҫ����2��
      vTop := GPadding + FTitleBandHeight + FWeekBandHeight + 4 * FRowHeight
    else // ����Ҫ����1��
      vTop := GPadding + FTitleBandHeight + FWeekBandHeight + 5 * FRowHeight;
    vStartDate := EndOfTheMonth(FDate);  // ���µ����һ��
    vWeekNo := DayOfTheWeek(vStartDate);  // ���µ����һ�������ڼ�

    if vWeekNo < 6 then  // ���µ����һ�첻�����������գ���
      vLeft := GPadding + (vWeekNo + 1) * FColWidth
    else
    if vWeekNo > 6 then  // ���µ����һ�������գ�Ҳ���� vWeekNo = 7��
      vLeft := GPadding + FColWidth
    else  // ���µ����һ��������
      vLeft := GPadding;

    vStartDate := IncDay(vStartDate);
    Inc(vWeekNo);
    repeat  // ����ֱ�������������е�����λ��
      vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);

      if IsSameDay(vStartDate, FMoveDate) then  // ������ƶ��������ڣ���������
      begin
        ACanvas.Brush.Color := GHightLightColor;
        ACanvas.FillRect(vRect);
        ACanvas.Brush.Style := bsClear;
      end;
      if Assigned(FOnPaintDate) then
        FOnPaintDate(Self, ACanvas, vStartDate, vRect)
      else
      begin
        if DateOutRang(vStartDate) then
          ACanvas.Font.Color := clMedGray
        else
          ACanvas.Font.Color := clBlack;
        vS := FormatDateTime('D', DateOf(vStartDate));
        DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
      end;
      vStartDate := IncDay(vStartDate);
      Inc(vWeekNo);
      vLeft := vLeft + FColWidth;
      if vWeekNo = 7 then  // ����������һ�еĿ�ʼ
      begin
        vTop := vTop + FRowHeight;
        vLeft := GPadding;
        vWeekNo := 0;
      end;
      Dec(vCount);
    until vCount = 0;
  end;
  {$ENDREGION}

  {$ENDREGION}

  {$REGION '�·�ģʽ����'}

  {$REGION 'DrawManthModel�����·�'}
  procedure DrawMonthModel;
  var
    vCount: Byte;
  const
    Month: array[1..12] of string = ('һ��','����', '����', '����', '����', '����', '����', '����', '����', 'ʮ��', 'ʮһ��', 'ʮ����');
  begin
    vLeft := GPadding;
    vTop := GPadding + FTitleBandHeight;

    for vCount := 1 to Length(Month) do  // ���� 12 ���·�
    begin
      vS := Month[vCount];
      vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);

      if MonthOf(FMoveDate) = vCount then  // ����ƶ������·ݣ���������
      begin
        ACanvas.Brush.Color := GHightLightColor;
        ACanvas.FillRect(vRect);
        ACanvas.Brush.Style := bsClear;
      end;

      DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);

      if MonthOf(FDate) = vCount then  // �����ѡ�е��·�
      begin
        ACanvas.Brush.Style := bsClear;
        ACanvas.Pen.Color := GBorderColor;
        ACanvas.Rectangle(vRect);
      end;

      if vCount mod 4 <> 0 then  // ÿ��ֻ�ܷ�4����
        Inc(vLeft, FColWidth)
      else  // ÿ�еĿ�ʼ��Ҫ���и�
      begin
        vLeft := GPadding;
        vTop := vTop + FRowHeight;
      end;
    end;
  end;
  {$ENDREGION}

  {$ENDREGION}

  {$REGION '����ģʽ����'}

  {$REGION 'DrawYearModel��������'}
  procedure DrawYearModel;
  var
    vStartYear, vEndYear, // ��ʼ���޺ͽ�������
    vIndex  // ��ǰҪ���Ƶ���
      : Integer;
  begin
    // �������ޣ���ʼ��ͽ����꣩
    vStartYear := YearOf(FDate) div 10 * 10 - 1;  // ��ʾ���޵���ʼ�꣬���ڿؼ��ռ�ɻ���12���꣬��Ҫ��ʾ10�꣬���Լ�1����һ��10������ʼ
    vEndYear := vStartYear + 11;  // ��ʾ���޵Ľ�����
    vIndex := 1;

    vLeft := GPadding;
    vTop := GPadding + FTitleBandHeight;
    while vStartYear <= vEndYear do
    begin
      if (vIndex = 1) or (vIndex = 12) then  // ��1�������1��
        ACanvas.Font.Color := clGray
      else
        ACanvas.Font.Color := clBackground;
      vS := IntToStr(vStartYear);
      vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
      // ���Ƶ�ǰ������
      if vStartYear > 1899 then  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������
      begin
        if vStartYear = YearOf(FMoveDate) then // ����ƶ������꣬��������
        begin
          ACanvas.Brush.Color := GHightLightColor;
          ACanvas.FillRect(vRect);
          ACanvas.Brush.Style := bsClear;
        end;
        DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
        if vStartYear = YearOf(FDate) then  // ��ǰѡ����
        begin
          ACanvas.Brush.Style := bsClear;
          ACanvas.Pen.Color := GBorderColor;
          ACanvas.Rectangle(vRect);
        end;
      end;
      if (vIndex mod 4) = 0 then  // ��ÿ�е����һ���꣬��һ�����Ҫ�Ӹߣ��������Ҫ��Ϊ�߽���λ��
      begin
        vLeft := GPadding;
        vTop := vTop + FRowHeight;
      end
      else  // ����ÿ�е����һ����
      begin
        vLeft := vLeft + FColWidth;
      end;
      Inc(vStartYear);
      Inc(vIndex);
    end;
  end;
  {$ENDREGION}

  {$ENDREGION}

  {$REGION '����ģʽ����'}

  {$REGION '��������DrawCenturyModel'}
  procedure DrawCenturyModel;
  var
    vStartYear, vEndYear, vCount: Integer;  // ��ʼ���޺ͽ�������
  begin
    // �������ޣ���ʼ��ͽ����꣩
    vStartYear := YearOf(FDate) div 100 * 100 - 10;  // ����ģʽ�Ŀ�ʼ��
    vEndYear := vStartYear + 110;  // ����ģʽ�Ľ�����
    vCount := 1;

    vLeft := GPadding;
    vTop := GPadding + FTitleBandHeight;
    while vStartYear <= vEndYear do  // ���������е�������
    begin
      if (vCount = 1) or (vCount = 12) then  // ��һ������������һ��������
        ACanvas.Font.Color := clGray
      else  // �����͵�������
        ACanvas.Font.Color := clBackground;
      vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);

      if vStartYear > 1899 then  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������
      begin
        if vStartYear = YearOf(FMoveDate) div 10 * 10 then  // ����ƶ����������䣬��������
        begin
          ACanvas.Brush.Color := GHightLightColor;
          ACanvas.FillRect(vRect);
          ACanvas.Brush.Style := bsClear;
        end;
        // ���������ʼ
        vS := IntToStr(vStartYear) + '-';
        vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight div 2);
        DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_BOTTOM or DT_SINGLELINE, nil);
        // ���������ʼ
        vS := IntToStr(vStartYear + 9) + ' ';
        vRect := Bounds(vLeft, vTop + FRowHeight div 2, FColWidth, FRowHeight div 2);
        DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_TOP or DT_SINGLELINE, nil);
        if vStartYear = YearOf(FDate) div 10 * 10 then  // ��ǰ�����䣨ʮ����һ���䣬����Ŀ�ʼ�㷨�� year div 10 * 10��
        begin
          vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
          ACanvas.Brush.Style := bsClear;
          ACanvas.Pen.Color := GBorderColor;
          ACanvas.Rectangle(vRect);
        end;
      end;
      if (vCount mod 4) <> 0 then  // ����ÿ�е����һ�������䣨��һ�������俪ʼ��ʱ����Ҫ�Ӹߣ�
      begin
        vLeft := vLeft + FColWidth;
      end
      else  // ��ÿ�е����һ�������䣬��һ������������һ���еĿ�ʼ����Ҫ���иߣ�������ߵ����Ϊ�߽���
      begin
        vLeft := GPadding;
        vTop := vTop + FRowHeight;
      end;
      Inc(vStartYear, 10);  // һ��������Ϊ 10 �꣬��Ҫ + 10
      Inc(vCount);
    end;
  end;
  {$ENDREGION}
  {$ENDREGION}

begin
  inherited;
  if not HandleAllocated then Exit;

  vRect := ClientRect;
  ACanvas.Brush.Style := bsSolid;
  if BorderVisible then  // �߿�
  begin
    if Self.Focused or (cmsMouseIn in MouseState) then
      ACanvas.Pen.Color := GBorderHotColor
    else
      ACanvas.Pen.Color := GBorderColor;

    ACanvas.Pen.Style := psSolid;
  end
  else
    ACanvas.Pen.Style := psClear;

  if RoundCorner > 0 then
    ACanvas.RoundRect(vRect, RoundCorner, RoundCorner)
  else
    ACanvas.Rectangle(vRect);

  SetDisplayModelProperty(FDisplayModel);  // ������Ӧ��ģʽ������Ӧ

  // ���Ƶ�ǰ������
  if YearOf(FDate) < 1900 then Exit;  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������

  case FDisplayModel of
    cdmDate:
      begin
        {$REGION '����ģʽ����'}
        // �������·ݻ���
        ACanvas.Font.Size := FRowHeight * 4;  //����������ֵĴ�С
        ACanvas.Pen.Color := clBtnFace;  // ����������ɫ
        vS := FormatDateTime('M', FDate);  // ��������
        vRect.Top := GPadding + FTitleBandHeight + FWeekBandHeight;
        BeginPath(ACanvas.Handle);
        ACanvas.Brush.Style := bsClear;
        DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE, nil);
        EndPath(ACanvas.Handle);
        StrokePath(ACanvas.Handle);  // ���·������
        // ��������ģʽ������
        ACanvas.Font := Font;
        vS := FormatDateTime('YYYY��MM��', FDate);
        DrawModelTitle(vS);  // ���Ʊ���
        DrawDateModelWeek;   // ������
        DrawDateModel;       // ��������
        {$ENDREGION}
      end;

    cdmMonth:
      begin
        {$REGION '�·�ģʽ����'}
        ACanvas.Font := Font;
        vS := FormatDateTime('YYYY��', FDate);
        DrawModelTitle(vS);  // ���Ʊ���
        DrawMonthModel;  // �����·�
        {$ENDREGION}
      end;

    cdmYear:
      begin
        {$REGION '��ģʽ����'}
        ACanvas.Font := Font;
        vS := FormatDateTime('YYYY', FDate);
        vS := IntToStr(StrToInt(vS) div 10 * 10) + '-' + IntToStr((StrToInt(vS) div 10 + 1) * 10 - 1);
        DrawModelTitle(vS);  // ���Ʊ���
        DrawYearModel;  // ��������
        {$ENDREGION}
      end;

    cdmCentury:
      begin
        {$REGION '����ģʽ����'}
        ACanvas.Font := Font;
        vS := FormatDateTime('YYYY', FDate);
        vS := IntToStr(StrToInt(vS) div 100 * 100) + '-' + IntToStr((StrToInt(vS) div 100 + 1) * 100 - 1);
        DrawModelTitle(vS);  // ���Ʊ���
        DrawCenturyModel;  // ��������
        {$ENDREGION}
      end;
  end;
end;

function TCFCustomMonthCalendar.GetDate: TDateTime;
begin
  CheckValidDate(FDate);
  Result := FDate;
end;

function TCFCustomMonthCalendar.GetDataRect(const ADate: TDate): TRect;
var
  vStartDate, vEndDate: TDate;
  vLeft, vTop, vWeekNo, vCount: Integer;
  vIStartYear, vIEndYear: Integer;
begin
  case FDisplayModel of
    cdmDate:
      begin
        {$REGION '��ȡ����ģʽ����������'}
        // �ڵ�ǰ���е������
        vStartDate := StartOfTheMonth(FDate);
        vEndDate := EndOfTheMonth(FDate);
        vWeekNo := DayOfTheWeek(vStartDate);
        vLeft := GPadding + vWeekNo * FColWidth;
        vTop := GPadding + FTitleBandHeight + FWeekBandHeight;
        // �жϵ���Ƿ��ڵ�������
        while vStartDate < vEndDate do  // �������ڷ�Χ
        begin
          while vWeekNo < 7 do  // ��������
          begin
            if IsSameDay(vStartDate, ADate) then  // ����ƶ�������������
            begin
              Result:= Bounds(vLeft, vTop, FColWidth, FRowHeight);
              Exit;
            end;
            vStartDate := IncDay(vStartDate);
            if vStartDate >= vEndDate then  // �������ڷ�Χ
              Break;
            vLeft := vLeft + FColWidth;
            Inc(vWeekNo);
          end;
          vWeekNo := 0;
          vTop := vTop + FRowHeight;  // + �и�
          vLeft := GPadding;
        end;

        // �����ϸ��µĺ���
        vStartDate := StartOfTheMonth(FDate);
        vWeekNo := DayOfTheWeek(vStartDate);
        if vWeekNo <> 7 then  // ��������
          vLeft := GPadding + (vWeekNo - 1) * FColWidth
        else  // �����մ���һ�����ʼ
          vLeft := Width - GPadding - FColWidth;
        vTop := GPadding + FTitleBandHeight + FWeekBandHeight;

        repeat
          vStartDate := IncDay(vStartDate, -1);
          Dec(vWeekNo);
          if IsSameDay(vStartDate, ADate) then  // ����ƶ�������������
          begin
            Result:= Bounds(vLeft, vTop, FColWidth, FRowHeight);
            Exit;
          end;
          vLeft := vLeft - FColWidth;
        until vWeekNo = 0;

        // ��������˶��ٸ�����
        vStartDate := StartOfTheMonth(FDate);
        vCount := DayOfTheWeek(vStartDate);
        vCount := vCount + DaysInMonth(FDate);

        // ������һ���µ�ͷ����
        vCount := 42 - vCount;
        if vCount > 7 then  // ����Ҫ����2��
          vTop := GPadding + FTitleBandHeight + FWeekBandHeight + 4 * FRowHeight
        else // ����Ҫ����1��
          vTop := GPadding + FTitleBandHeight + FWeekBandHeight + 5 * FRowHeight;
        vStartDate := EndOfTheMonth(FDate);
        vWeekNo := DayOfTheWeek(vStartDate);

        if vWeekNo < 6 then  // ���µ����һ�첻�����������գ��������ڣ�
          vLeft := GPadding + (vWeekNo + 1) * FColWidth
        else
        if vWeekNo > 6 then  // ���µ����һ�������գ�Ҳ���� vWeekNo = 7��
          vLeft := GPadding + FColWidth
        else  // ���µ����һ��������
          vLeft := GPadding;

        vStartDate := IncDay(vStartDate);
        Inc(vWeekNo);
        repeat
          if IsSameDay(vStartDate, ADate) then  // ����ƶ�������������
          begin
            Result:= Bounds(vLeft, vTop, FColWidth, FRowHeight);
            Exit;
          end;
          vStartDate := IncDay(vStartDate);
          Inc(vWeekNo);
          vLeft := vLeft + FColWidth;
          if vWeekNo = 7 then // ��������գ����������еĿ�ʼ
          begin
            vTop := vTop + FRowHeight;
            vLeft := GPadding;
            vWeekNo := 0;
          end;
          Dec(vCount);
        until vCount = 0;
        {$ENDREGION}
      end;

    cdmMonth:
      begin
        {$REGION '��ȡ�·�ģʽ���·�����'}
        vLeft := GPadding;
        vTop := GPadding + FTitleBandHeight;
        for vCount := 1 to 12 do  //  ��1�µ�12�½��б��� �ҳ�ѡ����
        begin
          if MonthOf(ADate) = vCount then  // ����ƶ������·�����
          begin
            Result := Bounds(vLeft, vTop, FColWidth, FRowHeight);
            Exit;
          end;
          if vCount mod 4 <> 0 then  // ÿ��ֻ�ܷ�4����
            Inc(vLeft, FColWidth)
          else  // ÿ�е����һ���µ���һ����Ҫ���м��и�
          begin
            vLeft := GPadding;
            vTop := vTop + FRowHeight;
          end;
        end;
        {$ENDREGION}
      end;

    cdmYear:
      begin
        {$REGION '��ȡ��ģʽ��������'}
        // �������ޣ���ʼ��ͽ����꣩
        vIStartYear := YearOf(FDate) div 10 * 10 - 1;  // ��ʼ��
        vIEndYear := vIStartYear + 11;  // ������
        vCount := 1;

        vLeft := GPadding;
        vTop := GPadding + FTitleBandHeight;
        while vIStartYear <= vIEndYear do  // �ҳ�����ƶ�������
        begin
          if YearOf(ADate) = vIStartYear then  // ����ƶ�����������
          begin
            Result := Bounds(vLeft, vTop, FColWidth, FRowHeight);
            Exit;
          end;
          if (vCount mod 4) <> 0 then  // ����ÿ�е����һ����
          begin
            vLeft := vLeft + FColWidth;
          end
          else  // ��ÿ�е����һ���꣬����һ���Ҫ���и�
          begin
            vLeft := GPadding;
            vTop := vTop + FRowHeight;
          end;
          Inc(vIStartYear);
          Inc(vCount);
        end;
        {$ENDREGION}
      end;

    cdmCentury:
      begin
        {$REGION '��ȡ����ģʽ������������'}
        vIStartYear := YearOf(FDate) div 100 * 100 - 10;  // ��¼��һ����������Ŀ�ʼ��
        vIEndYear := vIStartYear + 110;  // ��¼���һ�����������еĿ�ʼ��
        vCount := 1;

        vLeft := GPadding;
        vTop := GPadding + FTitleBandHeight;
        while vIStartYear <= vIEndYear do  // �ҵ�����ƶ�����������
        begin
          if vIStartYear = YearOf(ADate) div 10 * 10 then  // ����ƶ���������������
          begin
            Result := Bounds(vLeft, vTop, FColWidth, FRowHeight);
            Exit;
          end;
          if (vCount mod 4) <> 0 then  // ����ÿ�е�ÿ�е����һ����������
          begin
            vLeft := vLeft + FColWidth;
          end
          else  // ��ÿ�е����һ���������䣬��һ����������Ҫ���и�
          begin
            vLeft := GPadding;
            vTop := vTop + FRowHeight;
          end;
          Inc(vIStartYear, 10);
          Inc(vCount);
        end;
        {$ENDREGION}
      end;
  end;
end;

function TCFCustomMonthCalendar.GetDateAt(const X, Y: Integer): TDate;
var
  vStartDate, vEndDate: TDate;
  vS: string;
  vWeekNo: Byte;
  vLeft, vTop, vCount: Integer;
  vRect: TRect;
  vIStartYear, vIEndYear: Integer;
begin
  Result := 0;
  case FDisplayModel of
    cdmDate:
      begin
        {$REGION '��ȡ��������ʱ��'}
        // �ڵ�ǰ���е������
        vStartDate := StartOfTheMonth(FDate);
        vEndDate := EndOfTheMonth(FDate);
        vWeekNo := DayOfTheWeek(vStartDate);
        vLeft := GPadding + vWeekNo * FColWidth;
        vTop := GPadding + FTitleBandHeight + FWeekBandHeight;
        // �жϵ���Ƿ��ڵ�������
        while vStartDate < vEndDate do  // �������ڷ�Χ
        begin
          while vWeekNo < 7 do  // ��������
          begin
            vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
            if PtInRect(vRect, Point(X, Y)) then  // ���������������������
            begin
              Result := vStartDate;
              Exit;
            end;
            vStartDate := IncDay(vStartDate);
            if vStartDate >= vEndDate then
              Break;
            vLeft := vLeft + FColWidth;
            Inc(vWeekNo);
          end;
          vWeekNo := 0;
          vTop := vTop + FRowHeight;  // + �и�
          vLeft := GPadding;
        end;

        // �ж��Ƿ������ϸ��µĺ���
        vStartDate := StartOfTheMonth(FDate);
        vWeekNo := DayOfTheWeek(vStartDate);
        if vWeekNo <> 7 then  // ��������
          vLeft := GPadding + (vWeekNo - 1) * FColWidth
        else  // �����մ���һ�����ʼ
          vLeft := Width - GPadding - FColWidth;
        vTop := GPadding + FTitleBandHeight + FWeekBandHeight;

        repeat
          vStartDate := IncDay(vStartDate, -1);
          Dec(vWeekNo);
          vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
          if PtInRect(vRect, Point(X, Y)) then  // ���������������������
          begin
            Result := vStartDate;
            Exit;
          end;
          vLeft := vLeft - FColWidth;
        until vWeekNo = 0;

        // ��������˶��ٸ�����
        vStartDate := StartOfTheMonth(FDate);
        vCount := DayOfTheWeek(vStartDate);
        vCount := vCount + DaysInMonth(FDate);
        // �ж��Ƿ�������һ���µ�ͷ����
        vCount := 42 - vCount;
        if vCount > 7 then  // ����Ҫ����2��
          vTop := GPadding + FTitleBandHeight + FWeekBandHeight + 4 * FRowHeight
        else // ����Ҫ����1��
          vTop := GPadding + FTitleBandHeight + FWeekBandHeight + 5 * FRowHeight;
        vStartDate := EndOfTheMonth(FDate);
        vWeekNo := DayOfTheWeek(vStartDate);

        if vWeekNo < 6 then  // ���µ����һ�첻�����������գ��������ڣ�
          vLeft := GPadding + (vWeekNo + 1) * FColWidth
        else
        if vWeekNo > 6 then  // ���µ����һ�������գ�Ҳ���� vWeekNo = 7��
          vLeft := GPadding + FColWidth
        else  // ���µ����һ��������
          vLeft := GPadding;

        vStartDate := IncDay(vStartDate);
        Inc(vWeekNo);
        repeat
          vS := FormatDateTime('D', DateOf(vStartDate));
          vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
          if PtInRect(vRect, Point(X, Y)) then  // ���������������������
          begin
            Result := vStartDate;
            Exit;
          end;
          vStartDate := IncDay(vStartDate);
          Inc(vWeekNo);
          vLeft := vLeft + FColWidth;
          if vWeekNo = 7 then // ��������գ����������еĿ�ʼ
          begin
            vTop := vTop + FRowHeight;
            vLeft := GPadding;
            vWeekNo := 0;
          end;
          Dec(vCount);
        until vCount = 0;
        {$ENDREGION}
      end;

    cdmMonth:
      begin
        {$REGION '��ȡ�·�����ʱ��'}
        vLeft := GPadding;
        vTop := GPadding + FTitleBandHeight;
        for vCount := 1 to 12 do  //  ��1�µ�12�½��б��� �ҳ�ѡ����
        begin
          vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
          if PtInRect(vRect, Point(X, Y)) then  // ���������
          begin
            Result := RecodeMonth(FDate, vCount);
            Break;
          end;
          if vCount mod 4 <> 0 then  //
            Inc(vLeft, FColWidth)
          else
          begin
            vLeft := GPadding;
            vTop := vTop + FRowHeight;
          end;
        end;
        {$ENDREGION}
      end;

    cdmYear:
      begin
        {$REGION '��ȡ��������ʱ��'}
        // �������ޣ���ʼ��ͽ����꣩
        vIStartYear := YearOf(FDate) div 10 * 10 - 1;  // ��ʼ��
        vIEndYear := vIStartYear + 11;  // ������
        vCount := 1;

        vLeft := GPadding;
        vTop := GPadding + FTitleBandHeight;
        while vIStartYear <= vIEndYear do  // �ҳ��������
        begin
          if vIStartYear > 1899 then
          begin
            vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
            if PtInRect(vRect, Point(X, Y)) then  // �õ��������
            begin
              Result := RecodeYear(FDate, vIStartYear);
              Exit;
            end;
          end
          else
            Result := StrToDate('1899/ 1/1');
          if (vCount mod 4) <> 0 then  // ����ÿ�е����һ����
          begin
            vLeft := vLeft + FColWidth;
          end
          else  // ��ÿ�е����һ���꣬����һ���Ҫ���и�
          begin
            vLeft := GPadding;
            vTop := vTop + FRowHeight;
          end;
          Inc(vIStartYear);
          Inc(vCount);
        end;
        {$ENDREGION}
      end;

    cdmCentury:
      begin
        {$REGION '��ȡ��������ʱ��'}
        vIStartYear := YearOf(FDate) div 100 * 100 - 10;  // ��¼��һ����������Ŀ�ʼ��
        vIEndYear := vIStartYear + 110;  // ��¼���һ�����������еĿ�ʼ��
        vCount := 1;

        vLeft := GPadding;
        vTop := GPadding + FTitleBandHeight;
        while vIStartYear <= vIEndYear do  // �ҵ������������
        begin
          if vIStartYear > 1899 then
          begin
            vRect := Bounds(vLeft, vTop, FColWidth, FRowHeight);
            if PtInRect(vRect, Point(X, Y)) then  // �ҵ������������
            begin
              Result := RecodeYear(FDate, (StrToInt(FormatDateTime('YYYY', FDate)) div 100 * 100 - 10) + (vCount - 1) * 10  + StrToInt(FormatDateTime('YYYY', FDate)) mod 10);
              Exit;
            end;
          end
          else
            Result := StrToDate('1899/1/1');
          if (vCount mod 4) <> 0 then  // ����ÿ�е�ÿ�е����һ����������
          begin
            vLeft := vLeft + FColWidth;
          end
          else  // ��ÿ�е����һ���������䣬��һ����������Ҫ���и�
          begin
            vLeft := GPadding;
            vTop := vTop + FRowHeight;
          end;
          Inc(vIStartYear, 10);
          Inc(vCount);
        end;
        {$ENDREGION}
      end;
  end;
end;

procedure TCFCustomMonthCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vDate, vOldDate: TDate;
  vRect: TRect;
begin
  inherited;
  if FDisplayModel = cdmDate then  // ����ģʽ��������
    vRect := Bounds(GPadding, GPadding + FTitleBandHeight + FWeekBandHeight, 7 * FColWidth, 6 * FRowHeight)
  else
    vRect := Bounds(GPadding, GPadding + FTitleBandHeight, 4 * FColWidth, 3 * FRowHeight);

  if PtInRect(vRect, Point(X, Y)) then  // �������������
  begin
    vDate := GetDateAt(X, Y);  // ������������
    if DateOutRang(vDate) then Exit;

    if YearOf(vDate) > 1899 then
    begin
      if vDate <> 0 then  // ���������ָʱ�䲻Ϊ 0
      begin
        vOldDate := FDate;
        FDate := vDate;
        if FDisplayModel > cdmDate then  // ��������ģʽ
          Dec(FDisplayModel);

        UpdateDirectUI;
        // �������������β������ʱ���л��������������������Բ���ֻ����ԭѡ�����ڲ���
        // Ҳ����˵��ֻ���ڵ�ǰ�²�ͬ�����л�ʱ������Ҫ�������ϴ�ѡ��������
        // ����ʱȫ���������
        {if FDisplayModel > cdmDate then  // ��������ģʽ
        begin
          Dec(FDisplayModel);
          UpdateDirectUI;
        end
        else  // ����ģʽ
        begin
          // ���ԭ������
          vRect := GetDataRect(vOldDate);
          UpdateDirectUI(vRect);
          // �ػ�������
          vRect := GetDataRect(FDate);
          UpdateDirectUI(vRect);
        end;}
      end;

      Exit;
    end;
  end;

  // �ص���������
  if FDisplayModel = cdmDate then  // ����ģʽ��������
    vRect := Bounds(GPadding, GPadding + FTitleBandHeight + FWeekBandHeight + 6 * FRowHeight, 7 * FColWidth, FTodayBandHeight)
  else  // ����ģʽ�µĽ�����
    vRect := Bounds(GPadding, GPadding + FTitleBandHeight + 3 * FRowHeight, 4 * FColWidth, FTodayBandHeight);

  if PtInRect(vRect, Point(X, Y)) then  // ������ڽ�����
  begin
    Date := Today;
    UpdateDirectUI;

    Exit;
  end;

  // ����������������
  vRect := Bounds(2 * GPadding, GPadding + (FTitleBandHeight - GIconWidth) div 2, 2 * GIconWidth, 2 * GIconWidth);  // ��������Χ���øߺͿ�Ϊ2����ͼ����
  if PtInRect(vRect, Point(X, Y)) then
  begin
    case FDisplayModel of
      cdmDate:
        begin
          Date := IncMonth(FDate, -1);
          if YearOf(FDate) < 1900 then  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������
          begin
            Date := IncMonth(FDate, 1);
            Exit;
          end;
          UpdateDirectUI;

          Exit;
        end;

      cdmMonth:
        begin
          Date := IncYear(FDate, -1);
          if YearOf(FDate) < 1900 then  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������
          begin
            Date := IncYear(FDate, 1);
            Exit;
          end;
          UpdateDirectUI;

          Exit;
        end;

      cdmYear:
        begin
          Date := IncYear(FDate, - 10);
          if YearOf(FDate) < 1900 then  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������
          begin
            Date := IncYear(FDate, 10);  // ����ԭ��������
            Exit;
          end;
          UpdateDirectUI;

          Exit;
        end;

      cdmCentury:
        begin
          Date := IncYear(FDate, - 100);
          if YearOf(FDate) < 1900 then  // 1899����ǰ��ʱ����� IsSameday ʱ���ִ���������������
          begin
            Date := IncYear(FDate, 100);  // ����ԭ��������
            Exit;
          end;
          UpdateDirectUI;

          Exit;
        end;
    end;
  end;

  // ����������������
  vRect := Bounds(Width - GPadding - 2 * GIconWidth, GPadding + (FTitleBandHeight - GIconWidth) div 2, 2 * GIconWidth, 2 * GIconWidth);
  if PtInRect(vRect, Point(X, Y)) then
  begin
    case FDisplayModel of
      cdmDate:
        begin
          Date := IncMonth(FDate);
          UpdateDirectUI;

          Exit;
        end;

      cdmMonth:
        begin
          Date := IncYear(FDate, 1);
          UpdateDirectUI;
          Exit;
        end;
      cdmYear:
        begin
          Date := IncYear(FDate, 10);
          UpdateDirectUI;

          Exit;
        end;

      cdmCentury:
        begin
          Date := IncYear(FDate, 100);
          UpdateDirectUI;

          Exit;
        end;
    end;
  end;
end;

procedure TCFCustomMonthCalendar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vRect: TRect;
  vDate, vOldDate: TDate;
begin
  inherited;
  if FDisplayModel = cdmDate then  // ����ģʽ��������
    vRect := Bounds(GPadding, GPadding + FTitleBandHeight + FWeekBandHeight, 7 * FColWidth, 6 * FRowHeight)
  else
    vRect := Bounds(GPadding, GPadding + FTitleBandHeight, 4 * FColWidth, 3 * FRowHeight);

  if PtInRect(vRect, Point(X, Y)) then  // �������������
  begin
    vDate := GetDateAt(X, Y);  // �õ���괦������
    if DateOutRang(vDate) then Exit;

    if (vDate <> 0) and not IsSameDay(vDate, FMoveDate) then  // ���������ָ���ڲ�Ϊ 0
    begin
      vOldDate := FMoveDate;
      FMoveDate := vDate;
      // ���ԭ������
      vRect := GetDataRect(vOldDate);
      UpdateDirectUI(vRect);
      // �ػ�������
      vRect := GetDataRect(FMoveDate);
      UpdateDirectUI(vRect);
    end;
  end;
end;

procedure TCFCustomMonthCalendar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vRect: TRect;
begin
  inherited;
  // ������
  vRect := Rect(GPadding + GIconWidth, GPadding, Width - GPadding - GIconWidth, GPadding + FTitleBandHeight);
  if PtInRect(vRect, Point(X, Y)) then  // �ڱ�����
  begin
    if FDisplayModel < cdmCentury then
    begin
      Inc(FDisplayModel);
      UpdateDirectUI;
    end;
  end;
end;

procedure TCFCustomMonthCalendar.SetDate(Value: TDateTime);
begin
  if FDate <> Value then
  begin
    FDate := Value;
    CheckValidDate(FDate);
    UpdateDirectUI;
    if Assigned(OnChange) then
      OnChange(Self);
  end;
end;

procedure TCFCustomMonthCalendar.SetDisplayModelProperty(const AModel: TDisplayModel);
var
  vWidth, vHeight: Integer;
begin
  vHeight := Round((Height - GPadding  * 2) / 12.5);  // ÿ������Ԥ���ĸ߶�
  FRowHeight := Round(vHeight * 1.5);  // �� 12.25 ������ĸ߶�, һ����1.5��������ĸ߶�
  FTitleBandHeight := Round(vHeight * 1.25);  // ����ĸ߶�
  FWeekBandHeight := vHeight;
  FTodayBandHeight := Round(vHeight * 1.25);
  FColWidth := (Width - GPadding * 2) div 7;
  if AModel <> cdmDate then
  begin
    FColWidth := (Width - GPadding * 2) div 4;
    FRowHeight := (FWeekBandHeight + 6 * FRowHeight) div 3;
  end;
end;

procedure TCFCustomMonthCalendar.SetMaxDate(Value: TDate);
begin
  if FMaxDate <> Value then
  begin
    if Value < FMinDate then Exit;

    FMaxDate := Value;
    CheckValidDate(FDate);
  end;
end;

procedure TCFCustomMonthCalendar.SetMinDate(Value: TDate);
begin
  if FMinDate <> Value then
  begin
    if Value > FMaxDate then Exit;

    FMinDate := Value;
    CheckValidDate(FDate);
  end;
end;

end.

