unit CFCNMonthCalendar;

interface

uses Windows, Classes, CFMonthCalendar, Graphics;

type
  TCFCNMonthCalendar = class(TCFCustomMonthCalendar)
  private
    FOnPaintCNDate: TPaintDateEvent;

    /// <summary>
    /// ��ȡ��Ӧ��ũ������
    /// </summary>
    /// <param name="ADate">��������</param>
    /// <returns>ũ��</returns>
    function GetLunarDate(const ADate: TDate): string;

    /// <summary>
    /// ���л���ũ���ͽ���
    /// </summary>
    /// <param name="Sender"></param>
    /// <param name="ACanvas"></param>
    /// <param name="ADate">��������</param>
    /// <param name="ARect">ָ����������</param>
    procedure DoOnPaintDate(Sender: TObject; const ACanvas: TCanvas; const ADate: TDate; const ARect: TRect);

  protected
    /// <summary> ���û������� </summary>
    procedure DrawControl(ACanvas: TCanvas); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property OnPaintCNDate: TPaintDateEvent read FOnPaintCNDate write FOnPaintCNDate;
    property Date;
    property MaxDate;
    property MinDate;
  end;

implementation

uses
  hxCalendar, DateUtils, SysUtils;

{ TCFCNMonthCalendar }

var
  FJQ: Boolean;  // ����Ƿ�Ϊ����

constructor TCFCNMonthCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Self.OnPaintDate := DoOnPaintDate;
end;

destructor TCFCNMonthCalendar.Destroy;
begin

  inherited;
end;

procedure TCFCNMonthCalendar.DrawControl(ACanvas: TCanvas);
begin
  inherited;

end;

function TCFCNMonthCalendar.GetLunarDate(const ADate: TDate): string;
var
  vThxCalendar: ThxCalendar;
  vHzDate: THzDate;
begin
  FJQ := False;
  vHzDate := vThxCalendar.ToLunar(ADate);  // �õ�ũ��
  if vThxCalendar.GetJQ(ADate) <> '' then  // �������ڷ��ؽ���
  begin
    Result := vThxCalendar.GetJQ(ADate);
    FJQ := True;
  end
  else
    Result := vThxCalendar.FormatLunarDay(vHzDate.Day);
end;

procedure TCFCNMonthCalendar.DoOnPaintDate(Sender: TObject; const ACanvas: TCanvas;
  const ADate: TDate; const ARect: TRect);
var
  vS: string;
  vOldFontSize: Byte;
  vRect: TRect;
  vOldFontColor: TColor;
  vHeight: Integer;
begin
  vRect := ARect;
  vHeight := ARect.Bottom - ARect.Top;
  vRect.Bottom := vRect.Bottom - Round(vHeight * 0.55);  // ��������ڵ����򣬳�0.55��Ϊ�˹����������ũ��
  vS := FormatDateTime('D', DateOf(ADate));
  DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_BOTTOM or DT_SINGLELINE, nil);

  // ��ס֮ǰ��صĻ��������С����ɫ
  vOldFontSize := ACanvas.Font.Size;
  vOldFontColor := ACanvas.Font.Color;

  // �õ���Ӧ��ũ���ͽ�����������ʾ
  try
    vS := GetLunarDate(ADate);
    ACanvas.Font.Size := Round(vOldFontSize * 0.7);
    if FJQ then  // ������ʾΪ��ɫ
      ACanvas.Font.Color := clRed
    else  // ��ʾũ��
      ACanvas.Font.Color := clGrayText;
    // �����Ӧ��ũ��
    vRect := Rect(ARect.Left, ARect.Top + Round(vHeight * 0.55), ARect.Right, ARect.Bottom);  // ����ũ�����ֵ�����
    DrawTextEx(ACanvas.Handle, PChar(vS), -1, vRect, DT_CENTER or DT_TOP or DT_SINGLELINE, nil);
  finally
    // �ָ����ʵ�����Ĵ�С����ɫ
    ACanvas.Font.Size := vOldFontSize;
    ACanvas.Font.Color := vOldFontColor;
  end;
  if Assigned(FOnPaintCNDate) then
    FOnPaintCNDate(Self, ACanvas, ADate, ARect);
end;

end.
