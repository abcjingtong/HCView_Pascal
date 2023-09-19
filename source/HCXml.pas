{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-12-14            }
{                                                       }
{                     xml��ʽ����                       }
{                                                       }
{*******************************************************}

unit HCXml;

interface

uses
  Classes, Windows, Graphics, XMLDoc, XMLIntf, SysUtils;

type
  IHCXMLDocument = IXMLDocument;

  IHCXMLNode = IXMLNode;

  THCXMLDocument = class(TXMLDocument)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  function GetEncodingName(const AEncoding: TEncoding): string;
  //function GetColorHtmlRGB(const AColor: TColor): string;
  function GetXmlRN(const AText: string): string;

  /// <summary> BitmapתΪBase64�ַ� </summary>
  function GraphicToBase64(const AGraphic: TGraphic): string;
  procedure Base64ToGraphic(const ABase64: string; const AGraphic: TGraphic);
  procedure DelimitedXMLRN(const AText: string; const AStrings: TStrings);

implementation

uses
  EncdDecd, HCCommon;

function GetEncodingName(const AEncoding: TEncoding): string;
begin
  if AEncoding = TEncoding.UTF8 then
    Result := 'UTF-8'
  else
    Result := 'Unicode';
end;

function StreamToBase64(const AStream: TStream): string;
var
  vSs:TStringStream;
begin
  vSs := TStringStream.Create('');
  try
    AStream.Position := 0;
    EncodeStream(AStream, vSs);  // ���ڴ�������Ϊbase64�ַ���
    Result := vSs.DataString;
  finally
    FreeAndNil(vSs);
  end;
end;

procedure Base64ToStream(const ABase64: string; var AStream: TStream);
var
  vSs:TStringStream;
begin
  vSs := TStringStream.Create(ABase64);
  try
    DecodeStream(vSs, AStream);//��base64�ַ�����ԭΪ�ڴ���
  finally
    FreeAndNil(vSs);
  end;
end;

function GraphicToBase64(const AGraphic: TGraphic): string;
var
  vMs: TMemoryStream;
begin
  vMs := TMemoryStream.Create;
  try
    AGraphic.SaveToStream(vMs);
    Result := StreamToBase64(vMs);  // ��base64�ַ�����ԭΪ�ڴ���
  finally
    FreeAndNil(vMs);
  end;
end;

procedure Base64ToGraphic(const ABase64: string; const AGraphic: TGraphic);
var
  vMs: TStream;
begin
  vMs := TMemoryStream.Create;
  try
    Base64ToStream(ABase64, vMs);
    vMs.Position := 0;
    AGraphic.LoadFromStream(vMs);
  finally
    FreeAndNil(vMs);
  end;
end;

function GetXmlRN(const AText: string): string;
begin
  Result := StringReplace(AText, #10, #13#10, [rfReplaceAll]);
end;

procedure DelimitedXMLRN(const AText: string; const AStrings: TStrings);
var
  vPCharStart, vPCharEnd, vPtr: PChar;
  vS: string;
begin
  AStrings.BeginUpdate;
  try
    AStrings.Clear;

    vPCharStart := PChar(AText);
    vPCharEnd := vPCharStart + Length(AText);
    if vPCharStart = vPCharEnd then Exit;
    vPtr := vPCharStart;
    while vPtr < vPCharEnd do
    begin
      case vPtr^ of
        #10:
          begin
            System.SetString(vS, vPCharStart, vPtr - vPCharStart);
            AStrings.Add(vS);

            Inc(vPtr);
            vPCharStart := vPtr;
            Continue;
          end;

        {#10:
          begin
            Inc(vPtr);
            vPCharStart := vPtr;
            Continue;
          end;}
      end;

      Inc(vPtr);
    end;

    System.SetString(vS, vPCharStart, vPtr - vPCharStart);
    AStrings.Add(vS);
  finally
    AStrings.EndUpdate;
  end;
end;
//function GetColorHtmlRGB(const AColor: TColor): string;
//begin
//  Result := 'rgb(' + GetColorXmlRGB(AColor) + ')';
//end;

{ THCXMLDocument }

constructor THCXMLDocument.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParseOptions := ParseOptions + [poPreserveWhiteSpace];
end;

end.
