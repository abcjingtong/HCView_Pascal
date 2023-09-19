{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-5-4              }
{                                                       }
{                �ı����HCItem���൥Ԫ                 }
{                                                       }
{*******************************************************}

unit HCTextItem;

interface

uses
  Windows, Classes, SysUtils, Graphics, HCStyle, HCItem, HCXml, HCCommon;

type
  THCTextItemClass = class of THCTextItem;

  THCTextItem = class(THCCustomItem)
  private
    FText, FHyperLink: string;
    //FOwnerData: THCCustomData;
  protected
    function GetText: string; override;
    procedure SetText(const Value: string); override;
    function GetHyperLink: string; override;
    procedure SetHyperLink(const Value: string); override;
    function GetLength: Integer; override;
  public
    constructor CreateByText(const AText: string); virtual;
    function TextEffective: string; virtual;
    function SubStringEffective(const AStartOffs, ALength: Integer): string; virtual;
    procedure Assign(Source: THCCustomItem); override;
    function BreakByOffset(const AOffset: Integer): THCCustomItem; override;
    function CanConcatItems(const AItem: THCCustomItem): Boolean; override;
    function AcceptAction(const AOffset: Integer; const ARestrain: Boolean; const AAction: THCAction): Boolean; override;
    // ����Ͷ�ȡ
    procedure SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer); override;
    procedure LoadFromStream(const AStream: TStream; const AStyle: THCStyle;
      const AFileVersion: Word); override;

    function ToHtml(const APath: string): string; override;
    procedure ToXml(const ANode: IHCXMLNode); override;
    procedure ParseXml(const ANode: IHCXMLNode); override;

    /// <summaryy ����һ�����ı� </summary>
    /// <param name="AStartOffs">���Ƶ���ʼλ��(����0)</param>
    /// <param name="ALength">����ʼλ�����Ƶĳ���</param>
    /// <returns>�ı�����</returns>
    function SubString(const AStartOffs, ALength: Integer): string;
    //property OwnerData: THCCustomData read FOwnerData write FOwnerData;
  end;

var
  HCDefaultTextItemClass: THCTextItemClass = THCTextItem;

implementation

uses
  HCTextStyle;

{ THCTextItem }

function THCTextItem.CanConcatItems(const AItem: THCCustomItem): Boolean;
begin
  Result := inherited CanConcatItems(AItem);
  if Result then
    Result := FHyperLink = AItem.HyperLink;
end;

constructor THCTextItem.CreateByText(const AText: string);
begin
  Create;  // ������� inherited Create; �����THCCustomItem��Create������TEmrTextItem����CreateByTextʱ����ִ���Լ���Create
  FText := AText;
  FHyperLink := '';
end;

function THCTextItem.AcceptAction(const AOffset: Integer;
  const ARestrain: Boolean; const AAction: THCAction): Boolean;
begin
  Result := inherited AcceptAction(AOffset, ARestrain, AAction);
  if Result and (FHyperLink <> '') and (AAction = THCAction.actConcatText) then
    Result := False;
end;

procedure THCTextItem.Assign(Source: THCCustomItem);
begin
  inherited Assign(Source);
  FText := (Source as THCTextItem).Text;
  FHyperLink := (Source as THCTextItem).HyperLink;
end;

function THCTextItem.BreakByOffset(const AOffset: Integer): THCCustomItem;
begin
  if (AOffset >= Length) or (AOffset <= 0) then
    Result := nil
  else
  begin
    Result := inherited BreakByOffset(AOffset);
    Result.Text := Self.SubString(AOffset + 1, Length - AOffset);
    Delete(FText, AOffset + 1, Length - AOffset);  // ��ǰItem��ȥ������ַ���
  end;
end;

function THCTextItem.GetHyperLink: string;
begin
  Result := FHyperLink;
end;

function THCTextItem.GetLength: Integer;
begin
  Result := System.Length(FText);
end;

function THCTextItem.GetText: string;
begin
  Result := FText;
end;

function THCTextItem.SubString(const AStartOffs, ALength: Integer): string;
begin
  Result := Copy(FText, AStartOffs, ALength);
end;

function THCTextItem.SubStringEffective(const AStartOffs, ALength: Integer): string;
begin
  Result := Self.SubString(AStartOffs, ALength);
end;

procedure THCTextItem.LoadFromStream(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);
var
  vSize: Word;
  vDSize: DWORD;
  vBuffer: TBytes;
begin
  inherited LoadFromStream(AStream, AStyle, AFileVersion);
  if AFileVersion < 11 then  // ����65536������ַ�����
  begin
    AStream.ReadBuffer(vSize, SizeOf(Word));
    vDSize := vSize;
  end
  else
    AStream.ReadBuffer(vDSize, SizeOf(DWORD));

  if vDSize > 0 then
  begin
    SetLength(vBuffer, vDSize);
    AStream.Read(vBuffer[0], vDSize);

    if AFileVersion > 24 then
      FText := TEncoding.Unicode.GetString(vBuffer)
    else
      FText := StringOf(vBuffer);
  end;

  if AFileVersion > 34 then
    HCLoadTextFromStream(AStream, FHyperLink, AFileVersion)
  else
    FHyperLink := '';
end;

procedure THCTextItem.ParseXml(const ANode: IHCXMLNode);
begin
  inherited ParseXml(ANode);
  if ANode.HasAttribute('link') then
    FHyperLink := ANode.Attributes['link'];

  FText := ANode.Text;
end;

procedure THCTextItem.SaveToStreamRange(const AStream: TStream; const AStart, AEnd: Integer);
var
  vS: string;
  vBuffer: TBytes;
  vSize: DWORD;
begin
  inherited SaveToStreamRange(AStream, AStart, AEnd);
  vS := SubString(AStart + 1, AEnd - AStart);
  //if (vS = '') and (not Self.ParaFirst) then
  //  raise Exception.Create(HCS_EXCEPTION_SAVENULLTEXT);

  //  DWORD��С������HCSaveTextToStream(AStream, vS);
  vBuffer := TEncoding.Unicode.GetBytes(vS);
  if System.Length(vBuffer) > HC_TEXTMAXSIZE then
    raise Exception.Create(HCS_EXCEPTION_TEXTOVER);

  vSize := System.Length(vBuffer);
  AStream.WriteBuffer(vSize, SizeOf(vSize));
  if vSize > 0 then
    AStream.WriteBuffer(vBuffer[0], vSize);

  HCSaveTextToStream(AStream, FHyperLink);
end;

procedure THCTextItem.SetHyperLink(const Value: string);
begin
  FHyperLink := Value;
end;

procedure THCTextItem.SetText(const Value: string);
begin
  //if Value <> '' then  // ����ж��ˣ���Ӱ��ձ�Ϊ���ַ���ĳ���ʱ�ĸ�ֵ
  FText := HCDeleteBreak(Value);
end;

function THCTextItem.TextEffective: string;
begin
  Result := Self.GetText;
end;

function THCTextItem.ToHtml(const APath: string): string;
begin
  Result := '<a class="fs' + IntToStr(StyleNo) + '">' + Text + '</a>';
end;

procedure THCTextItem.ToXml(const ANode: IHCXMLNode);
begin
  inherited ToXml(ANode);
  if FHyperLink <> '' then
    ANode.Attributes['link'] := FHyperLink;

  ANode.Text := FText;
end;

end.
