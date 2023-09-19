{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-8-17             }
{                                                       }
{         �ĵ�FloatLineItem(ֱ��)����ʵ�ֵ�Ԫ           }
{                                                       }
{*******************************************************}

unit HCFloatLineItem;

interface

uses
  Windows, SysUtils, Classes, Controls, Graphics, Messages, HCCustomFloatItem, HCStyle,
  HCItem, HCCustomData, HCCommon, HCXml, HCShape;

type
  THCFloatLineItem = class(THCCustomFloatItem)  // �ɸ���LineItem
  private
    FLeftTop: TPoint;
    FShapeLine: THCShapeLine;
    function GetShapeLeftTop: TPoint;
  protected
    procedure SetActive(const Value: Boolean); override;
  public
    constructor Create(const AOwnerData: THCCustomData); override;
    function PointInClient(const X, Y: Integer): Boolean; override;
    procedure Assign(Source: THCCustomItem); override;
    function MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer): Boolean; override;
    function MouseMove(Shift: TShiftState; X, Y: Integer): Boolean; override;
    function MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer): Boolean; override;
    procedure DoPaint(const AStyle: THCStyle; const ADrawRect: TRect;
      const ADataDrawTop, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
      const ACanvas: TCanvas; const APaintInfo: TPaintInfo); override;
    procedure SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer); override;
    procedure LoadFromStream(const AStream: TStream; const AStyle: THCStyle; const AFileVersion: Word); override;
    procedure ToXml(const ANode: IHCXMLNode); override;
    procedure ParseXml(const ANode: IHCXMLNode); override;
  end;

implementation

uses
  Math;

{ THCFloatLineItem }

procedure THCFloatLineItem.Assign(Source: THCCustomItem);
begin
  inherited Assign(Source);
  FShapeLine.Assign((Source as THCFloatLineItem).FShapeLine);
end;

constructor THCFloatLineItem.Create(const AOwnerData: THCCustomData);
begin
  inherited Create(AOwnerData);
  Self.StyleNo := THCStyle.FloatLine;
  Width := 100;
  Height := 70;
  FShapeLine := THCShapeLine.CreateEx(Point(0, 0), Point(Width, Height));
end;

procedure THCFloatLineItem.DoPaint(const AStyle: THCStyle;
  const ADrawRect: TRect; const ADataDrawTop, ADataDrawBottom, ADataScreenTop,
  ADataScreenBottom: Integer; const ACanvas: TCanvas;
  const APaintInfo: TPaintInfo);
begin
  FShapeLine.PaintTo(ACanvas, ADrawRect, APaintInfo);  // ��Self.DrawRect��
end;

function THCFloatLineItem.GetShapeLeftTop: TPoint;
begin
  if FShapeLine.StartPt.X < FShapeLine.EndPt.X then
    Result.X := FShapeLine.StartPt.X
  else
    Result.X := FShapeLine.EndPt.X;

  if FShapeLine.StartPt.Y < FShapeLine.EndPt.Y then
    Result.Y := FShapeLine.StartPt.Y
  else
    Result.Y := FShapeLine.EndPt.Y;
end;

procedure THCFloatLineItem.LoadFromStream(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);
var
  vX, vY: Integer;
begin
  inherited LoadFromStream(AStream, AStyle, AFileVersion);
  if AFileVersion > 26 then
    FShapeLine.LoadFromStream(AStream)
  else
  begin
    FShapeLine.Width := 1;
    FShapeLine.Color := clBlack;
    AStream.ReadBuffer(vX, SizeOf(Integer));
    AStream.ReadBuffer(vY, SizeOf(Integer));
    FShapeLine.StartPt := Point(vX, vY);
    AStream.ReadBuffer(vX, SizeOf(Integer));
    AStream.ReadBuffer(vY, SizeOf(Integer));
    FShapeLine.EndPt := Point(vX, vY);
  end;
end;

function THCFloatLineItem.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer): Boolean;
begin
  // inherited
  Result := FShapeLine.MouseDown(Button, Shift, X, Y);
  Active := FShapeLine.ActiveObj <> THCShapeLineObj.sloNone;
  if Active then
  begin
    if Button = mbLeft then
    begin
      Self.Resizing := FShapeLine.ActiveObj in [sloStart, sloEnd];
      if Self.Resizing then  // ��ʼ����
      begin
        Self.FResizeX := X;
        Self.FResizeY := Y;
        FLeftTop := GetShapeLeftTop;  // ����ǰ��Rect��LeftTop
      end
      else
      if FShapeLine.ActiveObj = sloLine then  // ������ֱ���ϣ���ק��ʼ����¼����
        FLeftTop := GetShapeLeftTop;  // �ƶ�ǰ��Rect��LeftTop
    end;
  end;
end;

function THCFloatLineItem.MouseMove(Shift: TShiftState; X, Y: Integer): Boolean;
begin
  // inherited;
  Result := FShapeLine.MouseMove(Shift, X, Y);
  if Active then
  begin
    if Self.Resizing then  // ��ק�˵�
    begin
      Self.FResizeX := X;
      Self.FResizeY := Y;
    end;
  end;

  if Result then
    GCursor := FShapeLine.Cursor;
end;

function THCFloatLineItem.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer): Boolean;

  procedure _CalcNewLeftTop;
  var
    vNewLeftTop: TPoint;
  begin
    vNewLeftTop := GetShapeLeftTop; // ���ź��Rect��LeftTop

    Self.Left := Self.Left + vNewLeftTop.X - FLeftTop.X;
    Self.Top := Self.Top + vNewLeftTop.Y - FLeftTop.Y;

    // �ߵĵ���������LeftTopΪԭ��
    FShapeLine.StartPt.Offset(-vNewLeftTop.X, -vNewLeftTop.Y);
    FShapeLine.EndPt.Offset(-vNewLeftTop.X, -vNewLeftTop.Y);
  end;

begin
  // inherited;
  if Self.Resizing then
  begin
    Self.Resizing := False;
    _CalcNewLeftTop;  // �����µ�LeftTop

    Self.Width := Abs(FShapeLine.EndPt.X - FShapeLine.StartPt.X);
    Self.Height := Abs(FShapeLine.EndPt.Y - FShapeLine.StartPt.Y);
  end
  else
  if FShapeLine.ActiveObj = THCShapeLineObj.sloLine then  // �������϶�
    _CalcNewLeftTop;  // �����µ�LeftTop

  Result := FShapeLine.MouseUp(Button, Shift, X, Y);
end;

procedure THCFloatLineItem.ParseXml(const ANode: IHCXMLNode);
begin
  inherited ParseXml(ANode);
  FShapeLine.ParseXml(ANode);
end;

function THCFloatLineItem.PointInClient(const X, Y: Integer): Boolean;
begin
  Result := FShapeLine.PointInClient(X, Y);
end;

procedure THCFloatLineItem.SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer);
begin
  inherited SaveToStreamRange(AStream, AStart, AEnd);
  FShapeLine.SaveToStream(AStream);
end;

procedure THCFloatLineItem.SetActive(const Value: Boolean);
begin
  inherited SetActive(Value);
  FShapeLine.Active := Self.Active;
end;

procedure THCFloatLineItem.ToXml(const ANode: IHCXMLNode);
begin
  inherited ToXml(ANode);
  FShapeLine.ToXml(ANode);
end;

end.
