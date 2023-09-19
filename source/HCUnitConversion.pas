{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2019-2-25             }
{                                                       }
{                       ��λת��                        }
{                                                       }
{*******************************************************}

unit HCUnitConversion;

interface

uses
  Windows;

  /// <summary> �תΪ���� </summary>
  function TwipToPixel(const AValue: Single; const ADpi: Single): Cardinal;
  /// <summary> ����תΪ� </summary>
  function PixelToTwip(const AValue, ADpi: Cardinal): Cardinal;
  /// <summary> �תΪ���� </summary>
  function TwipToMillimeter(const AValue: Single): Single;
  /// <summary> ����תΪ� </summary>
  function MillimeterToTwip(const AValue: Single): Single;
  /// <summary> ˮƽ����תΪ���� </summary>
  function PixXToMillimeter(const AValue: Integer): Single;
  /// <summary> ����תΪˮƽ���� </summary>
  function MillimeterToPixX(const AValue: Single): Cardinal;
  /// <summary> ��ֱ����תΪ���� </summary>
  function PixYToMillimeter(const AValue: Integer): Single;
  /// <summary> ����תΪ��ֱ���� </summary>
  function MillimeterToPixY(const AValue: Single): Cardinal;
  /// <summary> ��ת���أ�1��=1/72Ӣ�� </summary>
  function PtToPixel(const APt: Single; const ADpi: Cardinal): Cardinal;
  function PixelToPt(const APix, ADPI: Integer): Single;
  function TwipToPt(const AValue: Single): Single;

var
  /// <summary> ˮƽ1����dpi�� </summary>
  PixelsPerMMX: Single;
  /// <summary> ��ֱ1����dpi�� </summary>
  PixelsPerMMY: Single;
  /// <summary> �ֺ���Ҫ���ŵı��� </summary>
  FontSizeScale: Single;
  /// <summary> ˮƽ1Ӣ���Ӧ�������� </summary>
  PixelsPerInchX: Integer;
  /// <summary> ��ֱ1Ӣ���Ӧ�������� </summary>
  PixelsPerInchY: Integer;

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

initialization
  vDC := CreateCompatibleDC(0);
  try
    PixelsPerInchX := GetDeviceCaps(vDC, LOGPIXELSX);  // ÿӢ��ˮƽ�߼���������1Ӣ��dpi��
    PixelsPerInchY := GetDeviceCaps(vDC, LOGPIXELSY);  // ÿӢ��ˮƽ�߼���������1Ӣ��dpi��
  finally
    DeleteDC(vDC);
  end;

  FontSizeScale := 72 / PixelsPerInchX;

  // 1Ӣ��25.4����   FPixelsPerInchX
  PixelsPerMMX := PixelsPerInchX / 25.4;  // 1���׶�Ӧ���� = 1Ӣ��dpi�� / 1Ӣ���Ӧ����
  PixelsPerMMY := PixelsPerInchY / 25.4;  // 1���׶�Ӧ���� = 1Ӣ��dpi�� / 1Ӣ���Ӧ����

end.
