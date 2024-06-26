{*******************************************************}
{                                                       }
{               HCView V1.1  作者：荆通                 }
{                                                       }
{      本代码遵循BSD协议，你可以加入QQ群 649023932      }
{            来获取更多的技术交流 2019-2-25             }
{                                                       }
{                       单位转换                        }
{                                                       }
{*******************************************************}

unit HCUnitConversion;

interface

uses
  Windows;

  /// <summary> 缇转为像素 </summary>
  function TwipToPixel(const AValue: Single; const ADpi: Single): Cardinal;
  /// <summary> 像素转为缇 </summary>
  function PixelToTwip(const AValue, ADpi: Cardinal): Cardinal;
  /// <summary> 缇转为毫米 </summary>
  function TwipToMillimeter(const AValue: Single): Single;
  /// <summary> 毫米转为缇 </summary>
  function MillimeterToTwip(const AValue: Single): Single;
  /// <summary> 水平像素转为毫米 </summary>
  function PixXToMillimeter(const AValue: Integer): Single;
  /// <summary> 毫米转为水平像素 </summary>
  function MillimeterToPixX(const AValue: Single): Cardinal;
  /// <summary> 垂直像素转为毫米 </summary>
  function PixYToMillimeter(const AValue: Integer): Single;
  /// <summary> 毫米转为垂直像素 </summary>
  function MillimeterToPixY(const AValue: Single): Cardinal;
  /// <summary> 磅转像素，1磅=1/72英寸 </summary>
  function PtToPixel(const APt: Single; const ADpi: Cardinal): Cardinal;
  function PixelToPt(const APix, ADPI: Integer): Single;
  function TwipToPt(const AValue: Single): Single;
  /// <summary> 96英寸下的像素转实际DPI下的像素值 </summary>
  function Pix96ToLogic(const APix: Integer): Integer;
  /// <summary> pt缩放到96英寸下的pt </summary>
  function PtTo96(const APt: Single): Single;

var
  /// <summary> 水平1毫米dpi数 </summary>
  PixelsPerMMX: Single;
  /// <summary> 垂直1毫米dpi数 </summary>
  PixelsPerMMY: Single;
  /// <summary> 字号需要缩放的比例 </summary>
  FontSizeScale: Single;
  /// <summary> 水平1英寸对应的像素数 </summary>
  PixelsPerInchX: Integer;
  /// <summary> 垂直1英寸对应的像素数 </summary>
  PixelsPerInchY: Integer;
  DPIScale: Single = 1;

implementation

var
  vDC: HDC;

function TwipToPixel(const AValue: Single; const ADpi: Single): Cardinal;
begin
  Result := Round(AValue * ADpi / 1440);
end;

function TwipToPt(const AValue: Single): Single;
begin
  Result := AValue / 1440 * 72
end;

function PixelToTwip(const AValue, ADpi: Cardinal): Cardinal;
begin
  Result := Round(AValue * 1440 / ADpi);
end;

function TwipToMillimeter(const AValue: Single): Single;
begin
  Result := AValue * 25.4 / 1440;
end;

function MillimeterToTwip(const AValue: Single): Single;
begin
  Result := AValue * 1440 / 25.4;
end;

function PixXToMillimeter(const AValue: Integer): Single;
begin
  Result := AValue / PixelsPerMMX;
end;

function PixYToMillimeter(const AValue: Integer): Single;
begin
  Result := AValue / PixelsPerMMY;
end;

function MillimeterToPixX(const AValue: Single): Cardinal;
begin
  Result := Round(AValue * PixelsPerMMX);
end;

function MillimeterToPixY(const AValue: Single): Cardinal;
begin
  Result := Round(AValue * PixelsPerMMY);
end;

function PtToPixel(const APt: Single; const ADPI: Cardinal): Cardinal;
begin
  Result := Round(APt * ADPI / 72);
end;

function PixelToPt(const APix, ADPI: Integer): Single;
begin
  Result := APix / ADPI * 72;
end;

function Pix96ToLogic(const APix: Integer): Integer;
begin
  Result := Round(APix * DPIScale);
end;

function PtTo96(const APt: Single): Single;
begin
  Result := APt / DPIScale;
end;

initialization
  vDC := CreateCompatibleDC(0);
  try
    PixelsPerInchX := GetDeviceCaps(vDC, LOGPIXELSX);  // 每英寸水平逻辑像素数，1英寸dpi数
    PixelsPerInchY := GetDeviceCaps(vDC, LOGPIXELSY);  // 每英寸水平逻辑像素数，1英寸dpi数
    DPIScale := GetDeviceCaps(vDC, LOGPIXELSX) / HCDefaultDPI;
  finally
    DeleteDC(vDC);
  end;

  FontSizeScale := 72 / PixelsPerInchX;

  // 1英寸25.4毫米   FPixelsPerInchX
  PixelsPerMMX := PixelsPerInchX / 25.4;  // 1毫米对应像素 = 1英寸dpi数 / 1英寸对应毫米
  PixelsPerMMY := PixelsPerInchY / 25.4;  // 1毫米对应像素 = 1英寸dpi数 / 1英寸对应毫米

end.
