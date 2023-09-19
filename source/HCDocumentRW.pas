{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2019-1-28             }
{                                                       }
{                �������ļ���ȡ��Ԫ                     }
{                                                       }
{*******************************************************}

unit HCDocumentRW;

interface

uses
  Classes, HCView, HCCommon;

type
  THCDocumentReader = class(TObject)
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure LoadFromStream(const AHCView: THCView; const AStream: TStream); virtual;
    procedure InsertFromStream(const AHCView: THCView; const AStream: TStream); virtual; abstract;
    procedure SaveToStream(const AHCView: THCView; const AStream: TStream); virtual; abstract;
  end;

  procedure HCViewLoadFromDocumentFile(const AHCView: THCView; const AFileName: string; const AExt: string);
  procedure HCViewSaveToDocumentFile(const AHCView: THCView; const AFileName: string; const AExt: string);
  procedure HCViewLoadFromDocumentStream(const AHCView: THCView; const AStream: TStream; const AExt: string);
  procedure HCViewSaveDocumentStream(const AHCView: THCView; const AStream: TStream; const AExt: string);

implementation

uses
  SysUtils, HCDocxRW;

const
  HCS_EXCEPTION_UNSUPPORTFILE = HC_EXCEPTION + '��֧�ֵ��ļ���ʽ��';

procedure HCViewLoadFromDocumentFile(const AHCView: THCView; const AFileName: string; const AExt: string);
var
  vStream: TStream;
  vExt: string;
begin
  AHCView.FileName := AFileName;
  vStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if AExt = '' then
      vExt := LowerCase(ExtractFileExt(AFileName)) // ��׺
    else
      vExt := AExt;

    HCViewLoadFromDocumentStream(AHCView, vStream, vExt);
  finally
    FreeAndNil(vStream);
  end;
end;

procedure HCViewSaveToDocumentFile(const AHCView: THCView; const AFileName: string; const AExt: string);
var
  vStream: TMemoryStream;
  vExt: string;
begin
  vStream := TMemoryStream.Create;
  try
    if AExt = '' then
      vExt := LowerCase(ExtractFileExt(AFileName)) // ��׺
    else
      vExt := AExt;

    HCViewSaveDocumentStream(AHCView, vStream, vExt);
    vStream.SaveToFile(AFileName);
  finally
    FreeAndNil(vStream);
  end;
end;

procedure HCViewLoadFromDocumentStream(const AHCView: THCView; const AStream: TStream; const AExt: string);
var
  vDocReader: THCDocumentReader;
begin
  if AExt = HC_EXT_DOCX then
    vDocReader := THCDocxReader.Create
  else
    raise Exception.Create(HCS_EXCEPTION_UNSUPPORTFILE);

  AStream.Position := 0;
  vDocReader.LoadFromStream(AHCView, AStream);
end;

procedure HCViewSaveDocumentStream(const AHCView: THCView; const AStream: TStream; const AExt: string);
var
  vDocReader: THCDocumentReader;
begin
  if AExt = HC_EXT_DOCX then
    vDocReader := THCDocxReader.Create
  else
    raise Exception.Create(HCS_EXCEPTION_UNSUPPORTFILE);

  vDocReader.SaveToStream(AHCView, AStream);
end;

{ THCDocumentReader }

constructor THCDocumentReader.Create;
begin

end;

destructor THCDocumentReader.Destroy;
begin

  inherited Destroy;
end;

procedure THCDocumentReader.LoadFromStream(const AHCView: THCView;
  const AStream: TStream);
begin
  AHCView.Style.States.Include(hosLoading);
  try
    InsertFromStream(AHCView, AStream);
  finally
    AHCView.Style.States.Exclude(hosLoading);
  end;
end;

end.
