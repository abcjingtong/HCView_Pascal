{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-9-12             }
{                                                       }
{      �ĵ�CDateTimePicker(����ʱ��)����ʵ�ֵ�Ԫ        }
{                                                       }
{*******************************************************}

unit HCDateTimePicker;

interface

uses
  Windows, SysUtils, Classes, Controls, Graphics, HCItem, HCRectItem, HCXml,
  HCStyle, HCCustomData, HCEditItem, HCCommon;

type
  TDateTimeArea = (dtaNone, dtaYear, dtaMonth, dtaDay, dtaHour, dtaMinute,
    dtaSecond, dtaMillisecond);

  THCDateTimePicker = class(THCEditItem)
  private
    FDateTime: TDateTime;
    FFormat: string;
    FAreaRect: TRect;
    FActiveArea: TDateTimeArea;
    FNewYear: string; // ��ǰ���������ֵ
    FJoinKey: Boolean;  // �����޸ĳ�����ʱ����¼�Ƿ���������

    function GetAreaRect(const AArea: TDateTimeArea): TRect;
    function GetAreaAt(const X, Y: Integer): TDateTimeArea;

    procedure SetDateTime(const Value: TDateTime);
    procedure SetInputYear;
    procedure SetFormat(const Value: string);
  protected
    procedure DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
      const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
      const ACanvas: TCanvas; const APaintInfo: TPaintInfo); override;
    procedure SetActive(const Value: Boolean); override;
    function MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer): Boolean; override;
    /// <summary> ��������ʱ�ڲ��Ƿ���ָ����Key��Shif </summary>
    function WantKeyDown(const Key: Word; const Shift: TShiftState): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    function InsertText(const AText: string): Boolean; override;
    procedure SetText(const Value: string); override;
  public
    constructor Create(const AOwnerData: THCCustomData; const ADateTime: TDateTime); virtual;
    //destructor Destroy; override;
    procedure Assign(Source: THCCustomItem); override;

    procedure SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer); override;
    procedure LoadFromStream(const AStream: TStream; const AStyle: THCStyle;
      const AFileVersion: Word); override;
    procedure ToXml(const ANode: IHCXMLNode); override;
    procedure ParseXml(const ANode: IHCXMLNode); override;

    property Format: string read FFormat write SetFormat;
    property DateTime: TDateTime read FDateTime write SetDateTime;
  end;

implementation

{$I HCView.inc}

uses
  DateUtils, Variants;

{ THCDateTimePicker }

procedure THCDateTimePicker.Assign(Source: THCCustomItem);
begin
  inherited Assign(Source);
  FFormat := (Source as THCDateTimePicker).Format;
  FDateTime := (Source as THCDateTimePicker).DateTime;
end;

constructor THCDateTimePicker.Create(const AOwnerData: THCCustomData; const ADateTime: TDateTime);
begin
  FFormat := 'YYYY-MM-DD HH:mm:SS';
  FDateTime := ADateTime;
  inherited Create(AOwnerData, FormatDateTime(FFormat, FDateTime));
  Self.StyleNo := THCStyle.DateTimePicker;
  Width := 80;
  Self.FPaddingLeft := 2;
  FActiveArea := dtaNone;
end;

procedure THCDateTimePicker.DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
  const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
  const ACanvas: TCanvas; const APaintInfo: TPaintInfo);
var
  vAreaRect: TRect;
begin
  vAreaRect := FAreaRect;
  vAreaRect.Offset(ADrawRect.TopLeft);

  if (FActiveArea <> dtaNone) and (not Self.IsSelectComplate) and (not APaintInfo.Print) then
  begin
    ACanvas.Brush.Color := AStyle.SelColor;
    ACanvas.FillRect(vAreaRect);
  end;

  inherited DoPaint(AStyle, ADrawRect, ADataDrawTop, ADataDrawBottom, ADataScreenTop,
    ADataScreenBottom, ACanvas, APaintInfo);

  if (FActiveArea = dtaYear) and (FNewYear <> '') and (not APaintInfo.Print) then
  begin
    ACanvas.Brush.Color := AStyle.SelColor;
    ACanvas.FillRect(vAreaRect);
    Windows.DrawText(ACanvas.Handle, FNewYear, -1, vAreaRect, DT_RIGHT or DT_SINGLELINE);
  end;
end;

function THCDateTimePicker.GetAreaAt(const X, Y: Integer): TDateTimeArea;
var
  vPt: TPoint;
begin
  vPt := Point(X, Y);

  if PtInRect(GetAreaRect(dtaYear), vPt) then
    Result := dtaYear
  else
  if PtInRect(GetAreaRect(dtaMonth), vPt) then
    Result := dtaMonth
  else
  if PtInRect(GetAreaRect(dtaDay), vPt) then
    Result := dtaDay
  else
  if PtInRect(GetAreaRect(dtaHour), vPt) then
    Result := dtaHour
  else
  if PtInRect(GetAreaRect(dtaMinute), vPt) then
    Result := dtaMinute
  else
  if PtInRect(GetAreaRect(dtaSecond), vPt) then
    Result := dtaSecond
  else
  if PtInRect(GetAreaRect(dtaMillisecond), vPt) then
    Result := dtaMillisecond
  else
    Result := dtaNone;
end;

function THCDateTimePicker.GetAreaRect(const AArea: TDateTimeArea): TRect;
var
  vCanvas: TCanvas;
  vSize: TSize;
  vS: string;
  vCharOffset, vAppendLevel: Integer;

  {$REGION '�ڲ�����'}
  {procedure AppendChars(P: PChar; Count: Integer);
  begin
    Inc(vCharOffset, Count);
  end;}

  function NumberText(Number, Digits: Integer): string;
  const
    Format: array[0..3] of Char = '%.*d';
  var
    vNumBuf: array[0..15] of Char;
    vLen: Integer;
  begin
    vLen := FormatBuf(vNumBuf, System.Length(vNumBuf), Format,
      System.Length(Format), [Digits, Number]);
    SetString(Result, vNumBuf, vLen);
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
        DecodeDate(FDateTime, Year, Month, Day);
        DateDecoded := True;
      end;
    end;

    procedure GetTime;  // �ֽ�ʱ��
    begin
      if not TimeDecoded then
      begin
        DecodeTime(FDateTime, Hour, Min, Sec, MSec);
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
        PChar(FormatStr), Buffer, System.Length(Buffer)) <> 0
      then
      begin
        Result := Buffer;
        if Count = 1 then
        begin
          case SysLocale.PriLangID of
            LANG_JAPANESE:
              Result := Copy(Result, 1, CharToBytelen(Result, 1));
            LANG_CHINESE:
              if (SysLocale.SubLangID = SUBLANG_CHINESE_TRADITIONAL)
                and (ByteToCharLen(Result, System.Length(Result)) = 4) then
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
        PChar(FormatStr), Buffer, System.Length(Buffer)) <> 0
      then
      begin
        Result := Buffer;
        if (Count = 1) and (Result[1] = '0') then
          Result := Copy(Result, 2, System.Length(Result)-1);
      end;
    end;

  begin
    if (Format <> nil) and (vAppendLevel < 2) then
    begin
      Inc(vAppendLevel);
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
              if AArea = dtaYear then  // ����ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              if Count <= 2 then  // ������
              begin
                vS := NumberText(Year mod 100, 2);
                Inc(vCharOffset, System.Length(vS));
              end
              else
              begin
                vS := NumberText(Year, 4);
                Inc(vCharOffset, System.Length(vS));
              end;

              if AArea = dtaYear then  // ���������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
              end;
            end;
          'G':  // ��Ԫ
            begin
              GetCount;  // ��Ԫ��λ��ʾ
              GetDate;
              //AppendString(ConvertEraString(Count));
              Inc(vCharOffset, System.Length(ConvertEraString(Count)));
            end;
          'E':  // �ֻ꣬��һ��Eʱ��ʾ��2λ��
            begin
              GetCount;
              GetDate;

              if AArea = dtaYear then // ����ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ������
              vS := ConvertYearString(Count);
              Inc(vCharOffset, System.Length(vS));
              if AArea = dtaYear then  // ���������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
              end;
            end;
          'M':  // ��
            begin
              GetCount;  // �·ݼ�λ��ʾ
              GetDate;

              if AArea = dtaMonth then  // ����ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ������
              case Count of
                1, 2:
                  vS := NumberText(Month, Count);
                3:
                  vS := {$IFDEF DELPHIXE}FormatSettings.{$ENDIF}ShortMonthNames[Month];
              else
                vS := {$IFDEF DELPHIXE}FormatSettings.{$ENDIF}LongMonthNames[Month];
              end;
              Inc(vCharOffset, System.Length(vS));

              if AArea = dtaMonth then  // ���������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
              end;
            end;
          'D': // ��
            begin
              GetCount;  // ���ڼ�λ��ʾ

              if AArea = dtaDay then  // ����ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ������
              case Count of
                1, 2:
                  begin
                    GetDate;
                    vS := NumberText(Day, Count);
                  end;
                3: vS := {$IFDEF DELPHIXE}FormatSettings.{$ENDIF}ShortDayNames[DayOfWeek(FDateTime)];
                4: vS := {$IFDEF DELPHIXE}FormatSettings.{$ENDIF}LongDayNames[DayOfWeek(FDateTime)];
              end;
              Inc(vCharOffset, System.Length(vS));

              if AArea = dtaDay then  // ���������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
              end;

              {if Count = 5 then
                AppendFormat(Pointer(FormatSettings.ShortDateFormat))
              else
              if Count > 5 then
                AppendFormat(Pointer(FormatSettings.LongDateFormat)); }
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

              if AArea = dtaHour then  // ʱ��ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ʱ����
              vS := NumberText(H, Count);
              Inc(vCharOffset, System.Length(vS));

              if AArea = dtaHour then  // ʱ�������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
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
              if AArea = dtaMinute then
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ������
              vS := NumberText(Min, Count);
              Inc(vCharOffset, System.Length(vS));

              if AArea = dtaMinute then  // ���������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
              end;
            end;
          'S':  // ��
            begin
              GetCount;
              GetTime;
              if Count > 2 then
                Count := 2;
              //AppendNumber(Sec, Count);

              if AArea = dtaSecond then  // ����ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ������
              vS := NumberText(Sec, Count);
              Inc(vCharOffset, System.Length(vS));

              if AArea = dtaSecond then  // ���������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
              end;
            end;
          'T':  // ʱ��
            begin
              GetCount;
              if Count = 1 then
                AppendFormat(Pointer({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}ShortTimeFormat))
              else
                AppendFormat(Pointer({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}LongTimeFormat));
            end;
          'Z':  // ����
            begin
              GetCount;
              GetTime;
              if Count > 3 then
                Count := 3;
              //AppendNumber(MSec, Count);

              if AArea = dtaMillisecond then  // ������ʼ����
              begin
                vS := Copy(Self.Text, 1, vCharOffset);
                Result.Left := FPaddingLeft + vCanvas.TextWidth(vS);
              end;

              // ��������
              vS := NumberText(MSec, Count);
              Inc(vCharOffset, System.Length(vS));

              if AArea = dtaMillisecond then  // �����������ڷ�Χ
              begin
                vSize := vCanvas.TextExtent(vS);
                Result.Top := (Height - vSize.cy) div 2;
                Result.Right := Result.Left + vSize.cx;
                Result.Bottom := Result.Top + vSize.cy;
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
                Inc(vCharOffset, 2);
                Inc(Format, 4);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'A/P', 3) = 0 then
              begin
                if Hour >= 12 then
                  Inc(P, 2);
                //AppendChars(P, 1);
                Inc(vCharOffset);
                Inc(Format, 2);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'AMPM', 4) = 0 then
              begin
                if Hour < 12 then
                begin
                  //AppendString(TimeAMString);
                  Inc(vCharOffset, System.Length({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}TimeAMString));
                end
                else
                begin
                  //AppendString(TimePMString);
                  Inc(vCharOffset, System.Length({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}TimePMString));
                end;
                Inc(Format, 3);
                Use12HourClock := TRUE;
              end
              else
              if StrLIComp(P, 'AAAA', 4) = 0 then
              begin
                GetDate;
                //AppendString(LongDayNames[DayOfWeek(DateTime)]);
                Inc(vCharOffset, System.Length({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}LongDayNames[DayOfWeek(FDateTime)]));
                Inc(Format, 3);
              end
              else
              if StrLIComp(P, 'AAA', 3) = 0 then
              begin
                GetDate;
                //AppendString(ShortDayNames[DayOfWeek(DateTime)]);
                Inc(vCharOffset, System.Length({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}ShortDayNames[DayOfWeek(FDateTime)]));
                Inc(Format, 2);
              end
              else
              begin
                //AppendChars(@Starter, 1);
                Inc(vCharOffset);
              end;
            end;
          'C':  // �̸�ʽ����ʱ��
            begin
              GetCount;
              AppendFormat(Pointer({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}ShortDateFormat));
              GetTime;
              if (Hour <> 0) or (Min <> 0) or (Sec <> 0) then
              begin
                //AppendChars(' ', 1);
                Inc(vCharOffset);
                AppendFormat(Pointer({$IFDEF DELPHIXE}FormatSettings.{$ENDIF}LongTimeFormat));
              end;
            end;
          '/':  // ���ڷָ�
            if {$IFDEF DELPHIXE}FormatSettings.{$ENDIF}DateSeparator <> #0 then
            begin
              //AppendChars(@DateSeparator, 1);
              Inc(vCharOffset);
            end;
          ':':  // ʱ��ָ�
            if {$IFDEF DELPHIXE}FormatSettings.{$ENDIF}TimeSeparator <> #0 then
            begin
              //AppendChars(@TimeSeparator, 1);
              Inc(vCharOffset);
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
              Inc(vCharOffset, Format - P);
              if Format^ <> #0 then
                Inc(Format);
            end;
        else
          begin
            //AppendChars(@Starter, 1);
            Inc(vCharOffset);
          end;
        end;
      end;
      Dec(vAppendLevel);
    end;
  end;
  {$ENDREGION}

begin
  SetRectEmpty(Result);

  if AArea = dtaNone then Exit;

  vCharOffset := 0;
  vAppendLevel := 0;
  vCanvas := THCStyle.CreateStyleCanvas;
  try
    Self.OwnerData.Style.TextStyles[Self.TextStyleNo].ApplyStyle(vCanvas);
    if FFormat <> '' then
      AppendFormat(PChar(FFormat))
    else
      AppendFormat('C');  // C �ö̸�ʽ��ʾ������ʱ��
  finally
    THCStyle.DestroyStyleCanvas(vCanvas);
  end;
end;

function THCDateTimePicker.InsertText(const AText: string): Boolean;
begin
end;

procedure THCDateTimePicker.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (not Self.Enabled) or ReadOnly then Exit;

  case Key of
    VK_ESCAPE:  // ȡ����������ַ���
      begin
        if FNewYear <> '' then
        begin
          FNewYear := '';
          Self.OwnerData.Style.UpdateInfoRePaint;
        end;
      end;

    VK_RETURN:
      begin
        if FActiveArea = dtaYear then
        begin
          SetInputYear;
          Self.OwnerData.Style.UpdateInfoRePaint;
        end;
      end;

    VK_LEFT:
      begin
        if FActiveArea > dtaNone then
        begin
          if FActiveArea = dtaYear then
            SetInputYear;

          FActiveArea := System.Pred(FActiveArea);
          FAreaRect := GetAreaRect(FActiveArea);
          Self.OwnerData.Style.UpdateInfoRePaint;
        end;
      end;

    VK_RIGHT:
      begin
        if FActiveArea < dtaMillisecond then
        begin
          if FActiveArea = dtaYear then
            SetInputYear;

          FActiveArea := System.Succ(FActiveArea);
          FAreaRect := GetAreaRect(FActiveArea);
          Self.OwnerData.Style.UpdateInfoRePaint;
        end;
      end;
  end;
end;

procedure THCDateTimePicker.KeyPress(var Key: Char);
var
  vNumber, vCount: Word;
  vDateTime: TDateTime;
begin
  if (not Self.Enabled) or Self.ReadOnly then Exit;

  vDateTime := FDateTime;

  if FActiveArea <> dtaNone then
  begin
    if Key in ['0'..'9'] then
    begin
      case FActiveArea of
        dtaYear:
          begin
            if System.Length(FNewYear) > 3 then
              System.Delete(FNewYear, 1, 1);
            FNewYear := FNewYear + Key;
          end;

        dtaMonth:
          begin;
            vNumber := MonthOf(vDateTime);  // ��ǰ�·�
            if vNumber > 9 then  // ��ǰ�·��Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λ�·�������0������

              vDateTime := RecodeMonth(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ�·���1λ����
            if (vNumber = 1) and FJoinKey then  // ��ǰ�·���1��������������
            begin
              if Key in ['0'..'2'] then  // 10, 11, 12
              begin
                vNumber := vNumber * 10 + StrToInt(Key);
                vDateTime := RecodeMonth(vDateTime, vNumber);  // ֱ���޸�Ϊ�¼���
              end
              else
                vDateTime := RecodeMonth(vDateTime, StrToInt(Key));
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // �·ݵ�1λ��0������

              vDateTime := RecodeMonth(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaDay:
          begin
            vNumber := DayOf(vDateTime);  // ��ǰ����
            if vNumber > 9 then  // ��ǰ�����Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λ����������0������

              vDateTime := RecodeDay(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ������1λ����
            if FJoinKey then  // ����������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              vCount := DaysInMonth(vDateTime);
              if vNumber > vCount then
                vNumber := StrToInt(Key);
              vDateTime := RecodeDay(vDateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // �·ݵ�1λ��0������

              vDateTime := RecodeDay(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaHour:
          begin
            vNumber := HourOf(vDateTime);  // ��ǰʱ
            if vNumber > 9 then  // ��ǰʱ�Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λʱ������0������

              vDateTime := RecodeHour(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰʱ��1λ����
            if FJoinKey then  // ��ǰʱ������������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              if vNumber > 23 then
                vNumber := StrToInt(Key);
              vDateTime := RecodeHour(vDateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // ʱ��1λ��0������

              vDateTime := RecodeHour(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaMinute:
          begin
            vNumber := MinuteOf(vDateTime);  // ��ǰ��
            if vNumber > 9 then  // ��ǰ���Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λʱ������0������

              vDateTime := RecodeMinute(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ����1λ����
            if FJoinKey then  // ��ǰ��������������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              if vNumber > 59 then
                vNumber := StrToInt(Key);
              vDateTime := RecodeMinute(vDateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // �ֵ�1λ��0������

              vDateTime := RecodeMinute(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaSecond:
          begin
            vNumber := SecondOf(vDateTime);  // ��ǰ��
            if vNumber > 9 then  // ��ǰ���Ѿ���2λ����
            begin
              if Key = '0' then Exit;  // 2λʱ������0������

              vDateTime := RecodeSecond(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end
            else  // ��ǰ����1λ����
            if FJoinKey then  // ��ǰ��������������
            begin
              vNumber := vNumber * 10 + StrToInt(Key);
              if vNumber > 59 then
                vNumber := StrToInt(Key);
              vDateTime := RecodeSecond(vDateTime, vNumber);  // ֱ���޸�Ϊ�¼���
            end
            else  // �����������룬�ǵ�1������
            begin
              if Key = '0' then Exit;  // ���1λ��0������

              vDateTime := RecodeSecond(vDateTime, StrToInt(Key));  // ֱ���޸�Ϊ�¼���
            end;
          end;

        dtaMillisecond: Exit;
      end;
    end;

    if FActiveArea <> dtaYear then // �����⣬��������Ҫʵʱ����
    begin
      FActiveArea := GetAreaAt(FAreaRect.Left, FAreaRect.Top);
      if FActiveArea <> dtaNone then
        FAreaRect := GetAreaRect(FActiveArea);

      FJoinKey := True;
      SetDateTime(vDateTime);
    end;

    Self.OwnerData.Style.UpdateInfoRePaint;
  end;
end;

procedure THCDateTimePicker.LoadFromStream(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);
begin
  inherited LoadFromStream(AStream, AStyle, AFileVersion);
  HCLoadTextFromStream(AStream, FFormat, AFileVersion);  // ��ȡFormat
  AStream.ReadBuffer(FDateTime, SizeOf(FDateTime));
end;

function THCDateTimePicker.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer): Boolean;
var
  vArea: TDateTimeArea;
begin
  //inherited MouseDown(Button, Shift, X, Y);
  Result := True;
  Self.Active := PtInRect(Rect(0, 0, Width, Height), Point(X, Y));

  vArea := GetAreaAt(X, Y);
  if vArea <> FActiveArea then
  begin
    if FActiveArea = dtaYear then
      SetInputYear;

    FActiveArea := vArea;
    if FActiveArea <> dtaNone then
      FAreaRect := GetAreaRect(FActiveArea);

    Self.OwnerData.Style.UpdateInfoRePaint;
  end;
end;

procedure THCDateTimePicker.ParseXml(const ANode: IHCXMLNode);
begin
  inherited ParseXml(ANode);
  FFormat := ANode.Attributes['format'];
  FDateTime := VarToDateTime(ANode.Attributes['datetime']);
end;

procedure THCDateTimePicker.SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer);
begin
  inherited SaveToStreamRange(AStream, AStart, AEnd);
  HCSaveTextToStream(AStream, FFormat);  // ��Format
  AStream.WriteBuffer(FDateTime, SizeOf(FDateTime));
end;

procedure THCDateTimePicker.SetActive(const Value: Boolean);
begin
  inherited SetActive(Value);
  if not Self.Active then
  begin
    if FActiveArea = dtaYear then
      SetInputYear;

    FActiveArea := TDateTimeArea.dtaNone;
  end;
end;

procedure THCDateTimePicker.SetDateTime(const Value: TDateTime);
begin
  if FDateTime <> Value then
  begin
    FDateTime := Value;
    inherited SetText(FormatDateTime(FFormat, FDateTime));
    FAreaRect := GetAreaRect(FActiveArea);
  end;
end;

procedure THCDateTimePicker.SetFormat(const Value: string);
begin
  if FFormat <> Value then
  begin
    FFormat := Value;
    Self.Text := FormatDateTime(FFormat, FDateTime);
    FAreaRect := GetAreaRect(FActiveArea);
  end;
end;

procedure THCDateTimePicker.SetInputYear;

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
    Result := YearOf(FDateTime);
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
    Self.DateTime := RecodeYear(FDateTime, GetYear(FNewYear));
    FNewYear := '';  // ȡ�������������
  end;
end;

procedure THCDateTimePicker.SetText(const Value: string);
begin
end;

procedure THCDateTimePicker.ToXml(const ANode: IHCXMLNode);
begin
  inherited ToXml(ANode);
  ANode.Attributes['format'] := FFormat;
  ANode.Attributes['datetime'] := DateTimeToStr(FDateTime);
end;

function THCDateTimePicker.WantKeyDown(const Key: Word;
  const Shift: TShiftState): Boolean;
begin
  Result := True;
end;

end.
