{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-5-4              }
{                                                       }
{           �ĵ�LineItem(ֱ��)����ʵ�ֵ�Ԫ              }
{                                                       }
{*******************************************************}

unit HCLineItem;

interface

uses
  Windows, Classes, Graphics, HCStyle, HCItem, HCRectItem, HCCustomData, HCXml,
  HCRichData, HCCommon;

type
  THCLineItem = class(THCCustomRectItem)
  private
    FLineHeight: byte;
    FLineStyle: TPenStyle;
  protected
    function GetOffsetAt(const X: Integer): Integer; override;
    procedure FormatToDrawItem(const ARichData: THCCustomData; const AItemNo: Integer); override;
    procedure DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
      const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
      const ACanvas: TCanvas; const APaintInfo: TPaintInfo); override;
  public
    constructor Create(const AOwnerData: THCCustomData; const AWidth, AHeight: Integer); override;
    procedure Assign(Source: THCCustomItem); override;

    procedure SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer); override;
    procedure LoadFromStream(const AStream: TStream; const AStyle: THCStyle;
      const AFileVersion: Word); override;
    procedure ToXml(const ANode: IHCXMLNode); override;
    procedure ParseXml(const ANode: IHCXMLNode); override;

    property LineStyle: TPenStyle read FLineStyle write FLineStyle;
    property LineHeight: byte read FLineHeight write FLineHeight;
  end;

implementation

{ THCLineItem }

procedure THCLineItem.Assign(Source: THCCustomItem);
begin
  inherited Assign(Source);
  FLineHeight := (Source as THCLineItem).LineHeight;
  FLineStyle := (Source as THCLineItem).LineStyle;
end;

constructor THCLineItem.Create(const AOwnerData: THCCustomData; const AWidth, AHeight: Integer);
begin
  inherited Create(AOwnerData);
  FLineHeight := 1;
  Width := AWidth;
  Height := AHeight;
  FLineStyle := TPenStyle.psSolid;
  StyleNo := THCStyle.Line;
end;

procedure THCLineItem.DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
  const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
  const ACanvas: TCanvas; const APaintInfo: TPaintInfo);

  procedure PaintLine;
  var
    vTop: Integer;
  begin
    vTop := (ADrawRect.Top + ADrawRect.Bottom) div 2;
    ACanvas.MoveTo(ADrawRect.Left, vTop);
    ACanvas.LineTo(ADrawRect.Right, vTop);
  end;

var
  vExtPen: HPEN;
  vOldPen: HGDIOBJ;
  vPenParams: TLogBrush;
begin
  if Self.Height > 1 then
  begin
    vPenParams.lbStyle := PenStyles[FLineStyle];
    vPenParams.lbColor := clBlack;
    vPenParams.lbHatch := 0;
    vExtPen := ExtCreatePen(PS_GEOMETRIC or PS_ENDCAP_FLAT or vPenParams.lbStyle, FLineHeight, vPenParams, 0, nil);
    vOldPen := SelectObject(ACanvas.Handle, vExtPen);
    try
      PaintLine;
    finally
      SelectObject(ACanvas.Handle, vOldPen);
      DeleteObject(vExtPen);
    end;
  end
  else
  begin
    ACanvas.Pen.Width := FLineHeight;
    ACanvas.Pen.Style := FLineStyle;
    ACanvas.Pen.Color := clBlack;
    PaintLine;
  end;
end;

procedure THCLineItem.FormatToDrawItem(const ARichData: THCCustomData;
  const AItemNo: Integer);
begin
  // ��������
  //Width := THCRichData(ARichData).Width;
  //Height := FLineHeight;
end;

function THCLineItem.GetOffsetAt(const X: Integer): Integer;
begin
  if X < Width div 2 then
    Result := OffsetBefor
  else
    Result := OffsetAfter;
end;

procedure THCLineItem.LoadFromStream(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);
begin
  inherited LoadFromStream(AStream, AStyle, AFileVersion);
  AStream.ReadBuffer(FLineHeight, SizeOf(FLineHeight));
  AStream.ReadBuffer(FLineStyle, SizeOf(FLineStyle));
end;

procedure THCLineItem.ParseXml(const ANode: IHCXMLNode);
begin
  inherited ParseXml(ANode);
  FLineHeight := ANode.Attributes['lineheight'];
  FLineStyle := TPenStyle(ANode.Attributes['linestyle']);
end;

procedure THCLineItem.SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer);
begin
  inherited SaveToStreamRange(AStream, AStart, AEnd);
  AStream.WriteBuffer(FLineHeight, SizeOf(FLineHeight));
  AStream.WriteBuffer(FLineStyle, SizeOf(FLineStyle));
end;

procedure THCLineItem.ToXml(const ANode: IHCXMLNode);
begin
  inherited ToXml(ANode);
  ANode.Attributes['lineheight'] := FLineHeight;
  ANode.Attributes['linestyle'] := Ord(FLineStyle);
end;

end.
