{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-2-25             }
{                                                       }
{                  �ĵ����ʵ�ֵ�Ԫ                     }
{                                                       }
{*******************************************************}

unit HCRuler;

interface

uses
  Windows, Classes, Controls, Graphics, Messages, HCView, HCCommon, HCList,
  HCTableItem, HCUnitConversion;

type
  THCCustomRuler = class(TControl)
  strict private
    FMemBitmap: HBITMAP;
    FDC, FMemDC: HDC;
    FMinGraduation: Single;  // ��С�̶Ⱥ���
    FViewWidth,  // ��ʾҳ��������С(������������)
    FUpdateCount
      : Integer;
    FCanvas: TCanvas;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  protected
    Zoom, MarginLeft, MarginRight,
    PaperWidth  // ֽ�ſ�Ⱥ���
      : Single;
    MarginLeftWidth, MarginRightWidth,
    /// <summary> �����ʼλ�ã���ࣩ </summary>
    GradLeft,
    /// <summary> ��߽���λ�ã��Ҳࣩ </summary>
    GradRight,
    GradRectTop, GradRectBottom,
    ScrollOffset
      : Integer;
    PagePadding: Byte;
    GradFontColor, GradLineColor: TColor;
    procedure Resize; override;
    procedure Paint;
    /// <summary> �Ŵ� </summary>
    function ZoomIn(const Value: Integer): Integer;
    /// <summary> ��С </summary>
    function ZoomOut(const Value: Integer): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PaintToEx(const ACanvas: TCanvas); virtual;
    procedure UpdateView; overload;
    procedure UpdateView(const ARect: TRect); overload;
    /// <summary> ��ʼ�����ػ� </summary>
    procedure BeginUpdate;
    /// <summary> ���������ػ� </summary>
    procedure EndUpdate;

    property MinGraduation: Single read FMinGraduation write FMinGraduation;
    property ViewWidth: Integer read FViewWidth write FViewWidth;
  published
    property Color;
  end;

  THCViewRuler = class(THCCustomRuler)
  strict private
    FView: THCView;
  protected
    FMouseGrad: Integer;
    FKnots: THCIntegerList;
    procedure PaintTableKnot(const ACanvas: TCanvas); virtual;
    procedure DoViewResize(Sender: TObject); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Reset;
    property View: THCView read FView write FView;
  end;

  THCHorSlider = (hsdNone, hsdMarginLeft, hsdMarginRight, hsdLeftIndent,
    hsdFirstIndent, hsdLeftFirstIndent, hsdRightIndent);

  THCHorizontalRuler = class(THCViewRuler)
  strict private
    FLeftFirstIndentRect: TRect;  // ����������������������ƿ�
    FLeftIndentRgn, FFirstIndentRgn, FRightIndentRgn: HRGN;
    FSlider: THCHorSlider;
    FCellLeft, FCellRight: Integer;  // ���ĳ��Ԫ����ʼλ��
    FFirstIndent, FLeftIndent, FRightIndent: Single;
    function PtInMarginLeftGap(const X, Y: Integer): Boolean;
    function PtInMarginRightGap(const X, Y: Integer): Boolean;
  protected
    procedure PaintTableKnot(const ACanvas: TCanvas); override;
    procedure DoViewResize(Sender: TObject); override;
    procedure PaintToEx(const ACanvas: TCanvas); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  THCVerSlider = (vsdNone, vsdMarginTop, vsdMarginBottom);

  THCVerticalRuler = class(THCViewRuler)
  strict private
    FSlider: THCVerSlider;
    FCellTop, FCellBottom: Integer;  // ���ĳ��Ԫ����ʼλ��
    function PtInMarginTopGap(const X, Y: Integer): Boolean;
    function PtInMarginBottomGap(const X, Y: Integer): Boolean;
  protected
    procedure PaintTableKnot(const ACanvas: TCanvas); override;
    procedure DoViewResize(Sender: TObject); override;
    procedure PaintToEx(const ACanvas: TCanvas); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  Math, SysUtils, HCItem, HCSectionData, HCRichData, HCStyle, HCParaStyle;

{ THCRuler }

procedure THCCustomRuler.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

constructor THCCustomRuler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //FCanvas := TControlCanvas.Create;
  //TControlCanvas(FCanvas).Control := Self;
  FDC := GetDC(0);
  FMemDC := CreateCompatibleDC(FDC);
  FCanvas := TCanvas.Create;
  FCanvas.Handle := FMemDC;

  MinGraduation := 10;
  PaperWidth := 210;
  FViewWidth := 875;

  MarginLeft := 25;
  MarginRight := 20;
  Zoom := 1;
  ScrollOffset := 0;

  GradRectTop := 6;
  GradRectBottom := 17;
  GradFontColor := $262322;
  GradLineColor := $B3ABAA;

  Self.Color := clWhite;
  Width := 23;
  Height := 23;
end;

destructor THCCustomRuler.Destroy;
begin
  FCanvas.Free;
  if FMemBitmap <> 0 then
    DeleteObject(FMemBitmap);
  DeleteDC(FMemDC);
  ReleaseDC(0, FDC);
  inherited Destroy;
end;

procedure THCCustomRuler.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount = 0 then
    UpdateView;
end;

procedure THCCustomRuler.Paint;
begin
  PaintToEx(FCanvas);
end;

procedure THCCustomRuler.PaintToEx(const ACanvas: TCanvas);
var
  vGradWidth, vPageWidth, vGraCount,
  vLeft, vTop, vDev, vDevInc, vTabWidth: Integer;
  i: Integer;
  vS: string;
begin
  ACanvas.Brush.Color := Self.Color;
  ACanvas.FillRect(Rect(0, 0, Width, Height));

  vPageWidth := ZoomIn(MillimeterToPixX(PaperWidth));  // ������Χ���
  GradLeft := Max((FViewWidth - vPageWidth) div 2, ZoomIn(PagePadding)) - ScrollOffset;
  GradRight := GradLeft + vPageWidth;
  // �������ұ߿���Ŀ���д����
  MarginLeftWidth := ZoomIn(MillimeterToPixX(MarginLeft));
  MarginRightWidth := ZoomIn(MillimeterToPixX(MarginRight));
  //ACanvas.Brush.Color := $D5D1D0;
  ACanvas.Brush.Color := $958988;
  ACanvas.FillRect(Rect(GradLeft + MarginLeftWidth, GradRectTop, GradRight - MarginRightWidth, GradRectBottom));

  vGradWidth := ZoomIn(MillimeterToPixX(MinGraduation));  // ��С�̶ȿ��

  ACanvas.Pen.Color := GradLineColor;
  // ���Ʋ�����Χ���ο�
  ACanvas.MoveTo(GradLeft, GradRectTop);
  ACanvas.LineTo(GradLeft + vPageWidth, GradRectTop);
  ACanvas.LineTo(GradLeft + vPageWidth, GradRectBottom);
  ACanvas.LineTo(GradLeft, GradRectBottom);
  ACanvas.LineTo(GradLeft, GradRectTop);

  ACanvas.Font.Size := 8;
  ACanvas.Font.Name := 'Courier New';
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := GradFontColor;
  vTop := GradRectTop + (GradRectBottom - GradRectTop - ACanvas.TextExtent('1').cy) div 2;

  //======== ���ƿ̶��� ========
  vLeft := vPageWidth - MarginLeftWidth;  // ���ñ���vLeft
  vDev := vLeft mod vGradWidth;
  vGraCount := vLeft div vGradWidth;  // ��д���̶�������
  // ����̶ȵļ�� vGradWidth
  vDevInc := 0;
  while vDev > vGraCount do
  begin
    vDevInc := vDevInc + vDev div vGraCount;
    vDev := vDev mod vGraCount;
  end;
  vGradWidth := vGradWidth + vDevInc;

  // ����
  vLeft := GradLeft + MarginLeftWidth;  // ���Ŀ̶���ʼλ�ã�0�̶ȵ�λ��
  // �����̶�0
  i := 1;
  Dec(vLeft, vGradWidth);
  while vLeft >= GradLeft do
  begin
    if not Odd(i) then
    begin
      vS := FormatFloat('0.#', i * MinGraduation);
      ACanvas.TextOut(vLeft - ACanvas.TextWidth(vS) div 2, vTop, vS);
    end
    else
    begin
      ACanvas.MoveTo(vLeft, vTop + 5);
      ACanvas.LineTo(vLeft, vTop + 9);
    end;
    Dec(vLeft, vGradWidth);
    Inc(i);
  end;

  { ���� }
  vLeft := GradLeft + MarginLeftWidth;  // ���Ŀ̶���ʼλ�ã�0�̶ȵ�λ��
  // �����̶�0
  if vDev > 0 then
  begin
    Inc(vLeft, vGradWidth + 1);
    Dec(vDev);
  end
  else
    Inc(vLeft, vGradWidth);

  ACanvas.Font.Color := GradFontColor;
  for i := 1 to vGraCount - 1 do
  begin
    if not Odd(i) then
    begin
      vS := FormatFloat('0.#', i * MinGraduation);
      ACanvas.TextOut(vLeft - ACanvas.TextWidth(vS) div 2, vTop, vS);
    end
    else
    begin
      ACanvas.MoveTo(vLeft, vTop + 5);
      ACanvas.LineTo(vLeft, vTop + 9);
    end;

    if vDev > 0 then
    begin
      Inc(vLeft, vGradWidth + 1);
      Dec(vDev);
    end
    else
      Inc(vLeft, vGradWidth);
  end;

  //======== ����Tab�̶��� ========
  vTabWidth := ZoomIn(TabCharWidth);
  vLeft := vPageWidth - MarginLeftWidth - MarginRightWidth;  // ���ñ���vLeft
  vDev := vLeft mod vTabWidth;
  vGraCount := vLeft div vTabWidth;  // Tab�̶�������
  // ����̶ȵļ�� vGradWidth
  vDevInc := 0;
  while vDev > vGraCount do
  begin
    vDevInc := vDevInc + vDev div vGraCount;
    vDev := vDev mod vGraCount;
  end;
  vGradWidth := vTabWidth + vDevInc;

  vLeft := GradLeft + MarginLeftWidth - 1;  // ���Ŀ̶���ʼλ�ã�0�̶ȵ�λ��
  // �����̶�0
  if vDev > 0 then
  begin
    Inc(vLeft, vGradWidth + 1);
    Dec(vDev);
  end
  else
    Inc(vLeft, vGradWidth);

  for i := 1 to vGraCount - 1 do
  begin
    ACanvas.MoveTo(vLeft, GradRectBottom + 2);
    ACanvas.LineTo(vLeft, GradRectBottom + 5);

    if vDev > 0 then
    begin
      Inc(vLeft, vGradWidth + 1);
      Dec(vDev);
    end
    else
      Inc(vLeft, vGradWidth);
  end;
end;

procedure THCCustomRuler.Resize;
begin
  inherited Resize;
  if FMemBitmap <> 0 then
    DeleteObject(FMemBitmap);

  FMemBitmap := CreateCompatibleBitmap(FDC, Width, Height);
  SelectObject(FMemDC, FMemBitmap);

  UpdateView;
end;

procedure THCCustomRuler.UpdateView(const ARect: TRect);
var
  vRect: TRect;
begin
  if FUpdateCount > 0 then Exit;

  Paint;
  if Assigned(Parent) then
  begin
    vRect := ARect;
    vRect.Offset(Left, Top);
    InvalidateRect(Parent.Handle, vRect, False);
    UpdateWindow(Parent.Handle);
    //RedrawWindow(Parent.Handle, vRect, 0, RDW_INVALIDATE or RDW_NOERASE);
  end;
end;

procedure THCCustomRuler.UpdateView;
begin
  UpdateView(Bounds(0, 0, Width, Height));
end;

procedure THCCustomRuler.WMPaint(var Message: TWMPaint);
begin
  if (Message.DC <> 0) and not (csDestroying in ComponentState) then
  begin
    BitBlt(Message.DC, 0, 0, Width, Height, FMemDC, 0, 0, SRCCOPY);
    {FCanvas.Lock;
    try
      FCanvas.Handle := Message.DC;
      try
        Paint;
      finally
        FCanvas.Handle := 0;
      end;
    finally
      FCanvas.Unlock;
    end; }
  end;
end;

function THCCustomRuler.ZoomIn(const Value: Integer): Integer;
begin
  Result := Round(Value * Zoom);
end;

function THCCustomRuler.ZoomOut(const Value: Integer): Integer;
begin
  Result := Round(Value / Zoom);
end;

{ THCRuler }

constructor THCHorizontalRuler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCellLeft := 0;
  FCellRight := 0;
  FLeftIndentRgn := 0;
  FFirstIndentRgn := 0;
  FRightIndentRgn := 0;
end;

destructor THCHorizontalRuler.Destroy;
begin
  if FLeftIndentRgn > 0 then
    DeleteObject(FLeftIndentRgn);

  if FFirstIndentRgn > 0 then
    DeleteObject(FFirstIndentRgn);

  if FRightIndentRgn > 0 then
    DeleteObject(FRightIndentRgn);

  inherited Destroy;
end;

procedure THCHorizontalRuler.DoViewResize(Sender: TObject);
var
  vData: THCRichData;
  vItem: THCCustomItem;
  vTable: THCTableItem;
  i, vRow, vCol, vSrcCol, vCLeft, vCRight: Integer;
begin
  inherited DoViewResize(Sender);
  Self.ViewWidth := View.ViewWidth;

  Self.PaperWidth := View.ActiveSection.PaperWidth;

  vCol := View.ActiveSection.ActivePageIndex;
  Self.PagePadding := View.ActiveSection.PagePadding;
  if View.ActiveSection.SymmetryMargin and Odd(vCol) then
  begin
    Self.MarginLeft := View.ActiveSection.PaperMarginRight;
    Self.MarginRight := View.ActiveSection.PaperMarginLeft;
  end
  else
  begin
    Self.MarginLeft := View.ActiveSection.PaperMarginLeft;
    Self.MarginRight := View.ActiveSection.PaperMarginRight;
  end;

  Self.ScrollOffset := View.HScrollBar.Position - View.ClientToParent(Point(0, 0), Self.Parent).X + Left;

  FKnots.Clear;
  FCellLeft := 0;
  FCellRight := 0;
  vData := View.ActiveSection.ActiveData;
  vItem := vData.GetActiveItem;
  while (vItem <> nil) and (vItem.StyleNo = THCStyle.Table) do
  begin
    vTable := vItem as THCTableItem;
    vTable.GetEditCell(vRow, vCol);
    vCLeft := vData.DrawItems[vTable.FirstDItemNo].Rect.Left;

    FKnots.Clear;
    vCRight := vCLeft + vTable.BorderWidthPix;
    FKnots.Add(vCRight);
    for i := 0 to vTable.ColCount - 1 do
    begin
      vCRight := vCRight + vTable.ColWidth[i] + vTable.BorderWidthPix;
      FKnots.Add(vCRight);
    end;

    if vRow < 0 then
      Break;

    for i := 0 to vCol - 1 do
      vCLeft := vCLeft + vTable.ColWidth[i] + vTable.BorderWidthPix;

    vSrcCol := vCol + vTable.Cells[vRow, vCol].ColSpan;
    vCRight := vCLeft;
    for i := vCol to vSrcCol do
      vCRight := vCRight + vTable.ColWidth[i] + vTable.BorderWidthPix;

    FCellRight := FCellRight + vData.Width - (vCRight - vTable.CellHPaddingPix);
    FCellLeft := FCellLeft + vCLeft + vTable.CellHPaddingPix;

    vData := vTable.Cells[vRow, vCol].CellData;
    vItem := vData.GetActiveItem;
  end;

  FFirstIndent := View.Style.ParaStyles[View.CurParaNo].FirstIndent;
  FLeftIndent := View.Style.ParaStyles[View.CurParaNo].LeftIndent;
  FRightIndent := View.Style.ParaStyles[View.CurParaNo].RightIndent;
  Self.UpdateView;
end;

procedure THCHorizontalRuler.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if PtInMarginLeftGap(X, Y) then
  begin
    FSlider := hsdMarginLeft;
    FMouseGrad := GradLeft + MarginLeftWidth;
  end
  else
  if PtInMarginRightGap(X, Y) then
  begin
    FSlider := hsdMarginRight;
    FMouseGrad := GradRight - MarginRightWidth;
  end
  else
  if PtInRegion(FFirstIndentRgn, X, Y) then
  begin
    FSlider := hsdFirstIndent;
    FMouseGrad := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent + FFirstIndent));
  end
  else
  if PtInRegion(FLeftIndentRgn, X, Y) then
  begin
    FSlider := hsdLeftIndent;
    FMouseGrad := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent));
  end
  else
  if PtInRegion(FRightIndentRgn, X, Y) then
  begin
    FSlider := hsdRightIndent;
    FMouseGrad := GradRight - MarginRightWidth - ZoomIn(FCellRight + MillimeterToPixX(FRightIndent));
  end
  else
  if PtInRect(FLeftFirstIndentRect, Point(X, Y)) then
  begin
    FSlider := hsdLeftFirstIndent;
    FMouseGrad := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent));
  end
  else
    FSlider := hsdNone;
end;

procedure THCHorizontalRuler.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vGap: Integer;
begin
  inherited;
  if PtInMarginLeftGap(X, Y) or PtInMarginRightGap(X, Y) then
    Self.Cursor := crSizeWE
  else
    Self.Cursor := crDefault;

  if FSlider = hsdNone then Exit;

  vGap := Trunc(PixXToMillimeter(ZoomOut(X - FMouseGrad)));
  if Abs(vGap) < 1 then Exit;  // �������1�����ٱ䶯����������

  if FSlider = hsdMarginLeft then
  begin
    Self.MarginLeft := Self.MarginLeft + vGap;
    UpdateView;
    FMouseGrad := GradLeft + MarginLeftWidth;
  end
  else
  if FSlider = hsdMarginRight then
  begin
    Self.MarginRight := Self.MarginRight - vGap;
    UpdateView;
    FMouseGrad := GradRight - MarginRightWidth;
  end
  else
  if FSlider = hsdFirstIndent then
  begin
    FFirstIndent := FFirstIndent + vGap;
    UpdateView;
    FMouseGrad := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent + FFirstIndent));
  end
  else
  if FSlider = hsdLeftIndent then
  begin
    FLeftIndent := FLeftIndent + vGap;
    FFirstIndent := FFirstIndent - vGap;
    UpdateView;
    FMouseGrad := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent));
  end
  else
  if FSlider = hsdRightIndent then
  begin
    FRightIndent := FRightIndent - vGap;
    UpdateView;
    FMouseGrad := GradRight - MarginRightWidth - ZoomIn(FCellRight + MillimeterToPixX(FRightIndent));
  end
  else
  if FSlider = hsdLeftFirstIndent then
  begin
    FLeftIndent := FLeftIndent + vGap;
    UpdateView;
    FMouseGrad := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent));
  end;
end;

procedure THCHorizontalRuler.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if FSlider = hsdMarginLeft then
  begin
    View.ActiveSection.PaperMarginLeft := MarginLeft;
    View.ActiveSection.ResetMargin;  // ResetActiveSectionMargin;
  end
  else
  if FSlider = hsdMarginRight then
  begin
    View.ActiveSection.PaperMarginRight := Self.MarginRight;
    View.ActiveSection.ResetMargin;
  end
  else
  if FSlider = hsdFirstIndent then
    View.ApplyParaFirstIndent(FFirstIndent)
  else
  if FSlider = hsdLeftIndent then
  begin
    View.BeginUpdate;
    try
      Self.BeginUpdate;
      try
        View.ApplyParaFirstIndent(FFirstIndent);
        View.ApplyParaLeftIndent(FLeftIndent);
      finally
        Self.EndUpdate;
      end;
    finally
      View.EndUpdate;
    end;
  end
  else
  if FSlider = hsdRightIndent then
    View.ApplyParaRightIndent(FRightIndent)
  else
  if FSlider = hsdLeftFirstIndent then
     View.ApplyParaLeftIndent(FLeftIndent);

  FSlider := hsdNone;
end;

procedure THCHorizontalRuler.PaintTableKnot(const ACanvas: TCanvas);
var
  i, vLeft, vH: Integer;
begin
  ACanvas.Brush.Color := Self.Color;
  vLeft := GradLeft + MarginLeftWidth - 8{15 / 2 ����};
  vH := GradRectBottom - GradRectTop + 1;
  for i := 0 to FKnots.Count - 1 do
  begin
    ACanvas.Pen.Color := GradLineColor;
    ACanvas.Rectangle(Bounds(vLeft + FKnots[i], GradRectTop, 15, vH));

    ACanvas.Pen.Color := $D5D1D0;
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 2);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 2);
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 4);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 4);
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 6);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 6);
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 8);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 8);
    //
    ACanvas.Pen.Color := GradFontColor;
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 3);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 3);
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 5);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 5);
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 7);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 7);
    ACanvas.MoveTo(vLeft + FKnots[i] + 4, GradRectTop + 9);
    ACanvas.LineTo(vLeft + FKnots[i] + 11, GradRectTop + 9);
    //
    ACanvas.MoveTo(vLeft + FKnots[i] + 5, GradRectTop + 2);
    ACanvas.LineTo(vLeft + FKnots[i] + 5, GradRectBottom - 2);
    ACanvas.MoveTo(vLeft + FKnots[i] + 7, GradRectTop + 2);
    ACanvas.LineTo(vLeft + FKnots[i] + 7, GradRectBottom - 2);
    ACanvas.MoveTo(vLeft + FKnots[i] + 9, GradRectTop + 2);
    ACanvas.LineTo(vLeft + FKnots[i] + 9, GradRectBottom - 2);
  end;
end;

procedure THCHorizontalRuler.PaintToEx(const ACanvas: TCanvas);
var
  vLeft: Integer;
  vPoints: array[0..4] of TPoint;
begin
  inherited PaintToEx(ACanvas);
  if not Assigned(View) then Exit;

  PaintTableKnot(ACanvas); // �����λ��

  // ======== ������+��������������ƿ� ========
  vLeft := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent));  // ���Ŀ̶���ʼλ�ã�0�̶ȵ�λ��
  ACanvas.Brush.Color := Self.Color;
  ACanvas.Pen.Color := GradLineColor;
  FLeftFirstIndentRect := Rect(vLeft - 4, GradRectBottom, vLeft + 5, Height);
  ACanvas.Rectangle(FLeftFirstIndentRect);
  // ======== ���������ƿ� ========
  vPoints[0] := Point(vLeft - 4, GradRectBottom);
  vPoints[1] := Point(vLeft - 4, GradRectBottom - 4);
  ACanvas.MoveTo(vPoints[0].X, vPoints[0].Y);
  ACanvas.LineTo(vPoints[1].X, vPoints[1].Y);  // | ��
  // �����α߿���
  ACanvas.Brush.Color := GradLineColor;
  ACanvas.FillRect(Bounds(vLeft - 3, GradRectBottom - 4, 1, 1));
  ACanvas.FillRect(Bounds(vLeft - 2, GradRectBottom - 5, 1, 1));
  ACanvas.FillRect(Bounds(vLeft - 1, GradRectBottom - 6, 1, 1));
  ACanvas.FillRect(Bounds(vLeft, GradRectBottom - 7, 1, 1));  // / ����
  vPoints[2] := Point(vLeft, GradRectBottom - 7);

  ACanvas.FillRect(Bounds(vLeft + 1, GradRectBottom - 6, 1, 1));
  ACanvas.FillRect(Bounds(vLeft + 2, GradRectBottom - 5, 1, 1));
  ACanvas.FillRect(Bounds(vLeft + 3, GradRectBottom - 4, 1, 1));  // \  ����

  vPoints[3] := Point(vLeft + 4, GradRectBottom - 3);
  vPoints[4] := Point(vLeft + 4, GradRectBottom);
  ACanvas.MoveTo(vPoints[3].X, vPoints[3].Y);
  ACanvas.LineTo(vPoints[4].X, vPoints[4].Y);  // | ��
  // �������ڲ����
  ACanvas.Brush.Color := $D5D1D0;
  ACanvas.FillRect(Bounds(vLeft - 3, GradRectBottom - 3, 7, 3));
  ACanvas.FillRect(Bounds(vLeft - 2, GradRectBottom - 4, 5, 1));
  ACanvas.FillRect(Bounds(vLeft - 1, GradRectBottom - 5, 3, 1));
  ACanvas.FillRect(Bounds(vLeft,     GradRectBottom - 6, 1, 1));

  if FLeftIndentRgn > 0 then
    DeleteObject(FLeftIndentRgn);
  FLeftIndentRgn := CreatePolygonRgn(vPoints, 5, ALTERNATE);
  //FrameRgn(ACanvas.Handle, FLeftIndentRgn, ACanvas.Brush.Handle, 1, 1);

  // ======== �����������ƿ� ========
  //vLeft := vLeft + MillimeterToPixX(FFirstIndent); ʹ��������������FFirstIndent��Ϊ0ʱ��ֻ�϶��ı�FLeftIndentʱFFirstIndent����
  vLeft := GradLeft + MarginLeftWidth + ZoomIn(FCellLeft + MillimeterToPixX(FLeftIndent + FFirstIndent));
  vPoints[0] := Point(vLeft - 4, GradRectTop);
  vPoints[1] := Point(vLeft - 4, GradRectTop - 3);
  ACanvas.MoveTo(vPoints[0].X, vPoints[0].Y);
  ACanvas.LineTo(vPoints[1].X, vPoints[1].Y);  // |  ��
  vPoints[2] := Point(vLeft + 4, GradRectTop - 3);
  vPoints[3] := Point(vLeft + 4, GradRectTop);
  ACanvas.LineTo(vPoints[2].X, vPoints[2].Y);  // ��  ��
  ACanvas.LineTo(vPoints[3].X, vPoints[3].Y);  // |  ��
  // �����α߿���
  ACanvas.Brush.Color := GradLineColor;
  ACanvas.FillRect(Bounds(vLeft + 3, GradRectTop + 1, 1, 1));
  ACanvas.FillRect(Bounds(vLeft + 2, GradRectTop + 2, 1, 1));
  ACanvas.FillRect(Bounds(vLeft + 1, GradRectTop + 3, 1, 1));
  vPoints[4] := Point(vLeft, GradRectTop + 4);
  ACanvas.FillRect(Bounds(vPoints[4].X, vPoints[4].Y, 1, 1));  // / ����

  ACanvas.FillRect(Bounds(vLeft - 1, GradRectTop + 3, 1, 1));
  ACanvas.FillRect(Bounds(vLeft - 2, GradRectTop + 2, 1, 1));
  ACanvas.FillRect(Bounds(vLeft - 3, GradRectTop + 1, 1, 1));  // \ ����
  ACanvas.FillRect(Bounds(vPoints[4].X, vPoints[4].Y, 1, 1));

  // �������ڲ����
  ACanvas.Brush.Color := $D5D1D0;
  ACanvas.FillRect(Bounds(vLeft - 3, GradRectTop - 2, 7, 3));
  ACanvas.FillRect(Bounds(vLeft - 2, GradRectTop + 1, 5, 1));
  ACanvas.FillRect(Bounds(vLeft - 1, GradRectTop + 2, 3, 1));
  ACanvas.FillRect(Bounds(vLeft,     GradRectTop + 3, 1, 1));

  if FFirstIndentRgn > 0 then
    DeleteObject(FFirstIndentRgn);
  FFirstIndentRgn := CreatePolygonRgn(vPoints, 5, ALTERNATE);
  //FrameRgn(ACanvas.Handle, FFirstIndentRgn, ACanvas.Brush.Handle, 1, 1);

  // ======== ���������ƿ� ========
  vLeft := GradRight - MarginRightWidth - ZoomIn(FCellRight + MillimeterToPixX(FRightIndent));
  vPoints[0] := Point(vLeft - 4, GradRectBottom - 3);
  vPoints[1] := Point(vLeft - 4, GradRectBottom);
  ACanvas.MoveTo(vPoints[0].X, vPoints[0].Y);
  ACanvas.LineTo(vPoints[1].X, vPoints[1].Y);
  vPoints[2] := Point(vLeft + 4, GradRectBottom);
  vPoints[3] := Point(vLeft + 4, GradRectBottom - 4);
  ACanvas.LineTo(vPoints[2].X, vPoints[2].Y);
  ACanvas.LineTo(vPoints[3].X, vPoints[3].Y);
  // �����α߿���
  ACanvas.Brush.Color := GradLineColor;
  ACanvas.FillRect(Bounds(vLeft + 3, GradRectBottom - 4, 1, 1));
  ACanvas.FillRect(Bounds(vLeft + 2, GradRectBottom - 5, 1, 1));
  ACanvas.FillRect(Bounds(vLeft + 1, GradRectBottom - 6, 1, 1));
  vPoints[4] := Point(vLeft, GradRectBottom - 7);
  ACanvas.FillRect(Bounds(vPoints[4].X, vPoints[4].Y, 1, 1));

  ACanvas.FillRect(Bounds(vLeft - 1, GradRectBottom - 6, 1, 1));
  ACanvas.FillRect(Bounds(vLeft - 2, GradRectBottom - 5, 1, 1));
  ACanvas.FillRect(Bounds(vLeft - 3, GradRectBottom - 4, 1, 1));

  // �������ڲ����
  ACanvas.Brush.Color := $D5D1D0;
  ACanvas.FillRect(Bounds(vLeft - 3, GradRectBottom - 3, 7, 3));
  ACanvas.FillRect(Bounds(vLeft - 2, GradRectBottom - 4, 5, 1));
  ACanvas.FillRect(Bounds(vLeft - 1, GradRectBottom - 5, 3, 1));
  ACanvas.FillRect(Bounds(vLeft,     GradRectBottom - 6, 1, 1));

  if FRightIndentRgn > 0 then
    DeleteObject(FRightIndentRgn);
  FRightIndentRgn := CreatePolygonRgn(vPoints, 5, ALTERNATE);
  //FrameRgn(ACanvas.Handle, FRightIndentRgn, ACanvas.Brush.Handle, 1, 1);
end;

function THCHorizontalRuler.PtInMarginLeftGap(const X, Y: Integer): Boolean;
begin
  Result := (X > GradLeft + MarginLeftWidth - 2) and (X < GradLeft + MarginLeftWidth + 2)
    and (Y > GradRectTop + 2) and (Y < GradRectBottom - 4);
end;

function THCHorizontalRuler.PtInMarginRightGap(const X, Y: Integer): Boolean;
begin
  Result := (X > GradRight - MarginRightWidth - 2) and (X < GradRight - MarginRightWidth + 2)
    and (Y > GradRectTop) and (Y < GradRectBottom - 4);
end;

{ THCViewRuler }

constructor THCViewRuler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKnots := THCIntegerList.Create;
end;

destructor THCViewRuler.Destroy;
begin
  FreeAndNil(FKnots);
  inherited Destroy;
end;

procedure THCViewRuler.DoViewResize(Sender: TObject);
begin
  Self.Zoom := View.Zoom;
end;

procedure THCViewRuler.PaintTableKnot(const ACanvas: TCanvas);
begin
end;

procedure THCViewRuler.Reset;
begin
  DoViewResize(Self);
end;

{ THCVerticalRuler }

constructor THCVerticalRuler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCellTop := 0;
  FCellBottom := 0;
end;

destructor THCVerticalRuler.Destroy;
begin

  inherited Destroy;
end;

procedure THCVerticalRuler.DoViewResize(Sender: TObject);
var
  vData: THCRichData;
  vItem: THCCustomItem;
  vTable: THCTableItem;
  i, vPageIndex, vPageDataTop, vRow, vCol, vSrcRow, vRTop, vRBottom: Integer;
begin
  inherited DoViewResize(Sender);
  Self.ViewWidth := View.ViewHeight;
  with View.ActiveSection do
  begin
    Self.PagePadding := PagePadding;
    Self.PaperWidth := PaperHeight;
    Self.MarginLeft := PaperMarginTop;
    Self.MarginRight := PaperMarginBottom;
    vPageIndex := ActivePageIndex;
    Self.ScrollOffset := View.VScrollBar.Position + ZoomIn(View.GetSectionTopFilm(0)
      - GetPageTopFilm(vPageIndex) + PagePadding)
      - View.ClientToParent(Point(0, 0), Self.Parent).Y + Top;
  end;

  FKnots.Clear;
  vRTop := 0;
  FCellTop := 0;
  FCellBottom := 0;
  vPageDataTop := View.ActiveSection.GetPageDataFmtTop(vPageIndex);
  vData := View.ActiveSection.ActiveData;
  vItem := vData.GetActiveItem;
  while (vItem <> nil) and (vItem.StyleNo = THCStyle.Table) do
  begin
    vTable := vItem as THCTableItem;
    vTable.GetEditCell(vRow, vCol);
    if vData is THCSectionData then
      vRTop := vRTop + vData.DrawItems[vTable.FirstDItemNo].Rect.Top + View.Style.LineSpaceMin div 2 - vPageDataTop
    else
      vRTop := vRTop + vData.DrawItems[vTable.FirstDItemNo].Rect.Top + View.Style.LineSpaceMin div 2;

    FKnots.Clear;
    vRBottom := vRTop + vTable.BorderWidthPix;
    FKnots.Add(vRBottom);
    for i := 0 to vTable.RowCount - 1 do
    begin
      vRBottom := vRBottom + vTable.Rows[i].Height + vTable.Rows[i].FmtOffset + vTable.BorderWidthPix;
      FKnots.Add(vRBottom);
    end;

    if vRow < 0 then
      Break;

    for i := 0 to vRow - 1 do
      vRTop := vRTop + vTable.Rows[i].Height + vTable.Rows[i].FmtOffset + vTable.BorderWidthPix;

    vSrcRow := vRow + vTable.Cells[vRow, vCol].RowSpan;
    vRBottom := vRTop;
    for i := vRow to vSrcRow do
      vRBottom := vRBottom + vTable.Rows[i].Height + vTable.Rows[i].FmtOffset + vTable.BorderWidthPix;

    FCellBottom := FCellBottom + vData.Width - (vRBottom - vTable.CellVPaddingPix);
    FCellTop := FCellTop + vRTop + vTable.CellVPaddingPix;

    vData := vTable.Cells[vRow, vCol].CellData;
    vItem := vData.GetActiveItem;
  end;

  Self.UpdateView;
end;

procedure THCVerticalRuler.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;

  if PtInMarginTopGap(X, Y) then
  begin
    FSlider := vsdMarginTop;
    FMouseGrad := GradLeft + MarginLeftWidth;
  end
  else
  if PtInMarginBottomGap(X, Y) then
  begin
    FSlider := vsdMarginBottom;
    FMouseGrad := GradRight - MarginRightWidth;
  end
  else
    FSlider := vsdNone;
end;

procedure THCVerticalRuler.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vGap: Integer;
begin
  inherited;
  if PtInMarginTopGap(X, Y) or PtInMarginBottomGap(X, Y) then
    Self.Cursor := crSizeNS
  else
    Self.Cursor := crDefault;

  if FSlider = vsdNone then Exit;

  vGap := Trunc(PixXToMillimeter(ZoomOut(Y - FMouseGrad)));
  if Abs(vGap) < 1 then Exit;  // �������1�����ٱ䶯����������

  if FSlider = vsdMarginTop then
  begin
    Self.MarginLeft := Self.MarginLeft + vGap;
    UpdateView;
    FMouseGrad := GradLeft + MarginLeftWidth;
  end
  else
  if FSlider = vsdMarginBottom then
  begin
    Self.MarginRight := Self.MarginRight - vGap;
    UpdateView;
    FMouseGrad := GradRight - MarginRightWidth;
  end;
end;

procedure THCVerticalRuler.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if FSlider = vsdMarginTop then
  begin
    View.ActiveSection.PaperMarginTop := MarginLeft;
    View.ActiveSection.ResetMargin;  // ResetActiveSectionMargin;
  end
  else
  if FSlider = vsdMarginBottom then
  begin
    View.ActiveSection.PaperMarginBottom := Self.MarginRight;
    View.ActiveSection.ResetMargin;
  end;

  FSlider := vsdNone;
end;

procedure THCVerticalRuler.PaintTableKnot(const ACanvas: TCanvas);
var
  i, vTop, vW: Integer;
begin
  ACanvas.Brush.Color := Self.Color;
  ACanvas.Pen.Color := GradLineColor;

  vTop := GradLeft + MarginLeftWidth - 5{9 / 2 ����};
  vW := GradRectBottom - GradRectTop + 1;
  for i := 0 to FKnots.Count - 1 do
  begin
    //ACanvas.Pen.Color := GradLineColor;
    ACanvas.Rectangle(Bounds(GradRectTop, vTop + FKnots[i], vW, 9));
  end;
end;

procedure THCVerticalRuler.PaintToEx(const ACanvas: TCanvas);
var
  vGradWidth, vPageHeight, vGraCount,
  vLeft, vTop, vDev, vDevInc: Integer;
  i: Integer;
  vS: string;
  vLogFont: TLogFont;
begin
  ACanvas.Brush.Color := Self.Color;
  ACanvas.FillRect(Rect(0, 0, Width, Height));

  vPageHeight := ZoomIn(MillimeterToPixX(PaperWidth));  // ������Χ�߶�
  GradLeft := ZoomIn(PagePadding) - ScrollOffset;
  GradRight := GradLeft + vPageHeight;
  // �������ұ߿���Ŀ���д����
  MarginLeftWidth := ZoomIn(MillimeterToPixX(MarginLeft));
  MarginRightWidth := ZoomIn(MillimeterToPixX(MarginRight));
  //ACanvas.Brush.Color := $D5D1D0;
  ACanvas.Brush.Color := $958988;
  ACanvas.FillRect(Rect(GradRectTop, GradLeft + MarginLeftWidth, GradRectBottom, GradRight - MarginRightWidth));
  vGradWidth := ZoomIn(MillimeterToPixX(MinGraduation));  // ��С�̶ȿ��

  ACanvas.Pen.Color := GradLineColor;
  // ���Ʋ�����Χ���ο�
  ACanvas.MoveTo(GradRectTop, GradLeft);
  ACanvas.LineTo(GradRectTop, GradLeft + vPageHeight);
  ACanvas.LineTo(GradRectBottom, GradLeft + vPageHeight);
  ACanvas.LineTo(GradRectBottom, GradLeft);
  ACanvas.LineTo(GradRectTop, GradLeft);

  ACanvas.Font.Size := 8;
  ACanvas.Font.Name := 'Courier New';
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := GradFontColor;

  GetObject(ACanvas.Font.Handle, SizeOf(vLogFont), @vLogFont);
  vLogFont.lfEscapement := 900;
  ACanvas.Font.Handle := CreateFontIndirect(vLogFont);

  vLeft := GradRectTop + (GradRectBottom - GradRectTop - ACanvas.TextExtent('1').cy) div 2;

  //======== ���ƿ̶��� ========
  vTop := vPageHeight - MarginLeftWidth;  // ���ñ���vTop
  vDev := vTop mod vGradWidth;
  vGraCount := vTop div vGradWidth;  // ��д���̶�������
  // ����̶ȵļ�� vGradWidth
  vDevInc := 0;
  while vDev > vGraCount do
  begin
    vDevInc := vDevInc + vDev div vGraCount;
    vDev := vDev mod vGraCount;
  end;
  vGradWidth := vGradWidth + vDevInc;

  // ����
  vTop := GradLeft + MarginLeftWidth;  // ���Ŀ̶���ʼλ�ã�0�̶ȵ�λ��
  // �����̶�0
  i := 1;
  Dec(vTop, vGradWidth);
  while vTop >= GradLeft do
  begin
    if not Odd(i) then
    begin
      vS := FormatFloat('0.#', i * MinGraduation);
      ACanvas.TextOut(vLeft, vTop + ACanvas.TextWidth(vS) div 2, vS);
    end
    else
    begin
      ACanvas.MoveTo(vLeft + 5, vTop);
      ACanvas.LineTo(vLeft + 9, vTop);
    end;
    Dec(vTop, vGradWidth);
    Inc(i);
  end;

  { ���� }
  vTop := GradLeft + MarginLeftWidth;  // ���Ŀ̶���ʼλ�ã�0�̶ȵ�λ��
  // �����̶�0
  if vDev > 0 then
  begin
    Inc(vTop, vGradWidth + 1);
    Dec(vDev);
  end
  else
    Inc(vTop, vGradWidth);

  ACanvas.Font.Color := GradFontColor;
  for i := 1 to vGraCount - 1 do
  begin
    if not Odd(i) then
    begin
      vS := FormatFloat('0.#', i * MinGraduation);
      ACanvas.TextOut(vLeft, vTop + ACanvas.TextWidth(vS) div 2, vS);
    end
    else
    begin
      ACanvas.MoveTo(vLeft + 5, vTop);
      ACanvas.LineTo(vLeft + 9, vTop);
    end;

    if vDev > 0 then
    begin
      Inc(vTop, vGradWidth + 1);
      Dec(vDev);
    end
    else
      Inc(vTop, vGradWidth);
  end;

  if not Assigned(View) then Exit;

  PaintTableKnot(ACanvas); // �����λ��
end;

function THCVerticalRuler.PtInMarginBottomGap(const X, Y: Integer): Boolean;
begin
  Result := (Y > GradRight - MarginRightWidth - 2) and (Y < GradRight - MarginRightWidth + 2)
    and (X > GradRectTop) and (X < GradRectBottom);
end;

function THCVerticalRuler.PtInMarginTopGap(const X, Y: Integer): Boolean;
begin
  Result := (Y > GradLeft + MarginLeftWidth - 2) and (Y < GradLeft + MarginLeftWidth + 2)
    and (X > GradRectTop) and (X < GradRectBottom);
end;

end.
