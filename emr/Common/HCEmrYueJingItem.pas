{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit HCEmrYueJingItem;

interface

uses
  Windows, Classes, Controls, Graphics, HCCustomData, HCExpressItem, HCXml;

type
  TEmrYueJingItem = class(THCExpressItem)  // �¾���ʽ(�ϡ��¡������ı�����ʮ����)
  private
    function GetMenarcheAge: string;
    procedure SetMenarcheAge(const Value: string);
    function GetMenstrualDuration: string;
    procedure SetMenstrualDuration(const Value: string);
    function GetMenstrualCycle: string;
    procedure SetMenstrualCycle(const Value: string);
    function GetMenstrualPause: string;
    procedure SetMenstrualPause(const Value: string);
  public
    constructor Create(const AOwnerData: THCCustomData;
      const ALeftText, ATopText, ARightText, ABottomText: string); override;
    procedure ToXmlEmr(const ANode: IHCXMLNode);
    procedure ParseXmlEmr(const ANode: IHCXMLNode);
    /// <summary> �������� </summary>
    property MenarcheAge: string read GetMenarcheAge write SetMenarcheAge;
    /// <summary> �¾��������� </summary>
    property MenstrualDuration: string read GetMenstrualDuration write SetMenstrualDuration;
    /// <summary> �¾����� </summary>
    property MenstrualCycle: string read GetMenstrualCycle write SetMenstrualCycle;
    /// <summary> �������� </summary>
    property MenstrualPause: string read GetMenstrualPause write SetMenstrualPause;
  end;

implementation

uses
  SysUtils, HCEmrElementItem;

{ TEmrYueJingItem }

constructor TEmrYueJingItem.Create(const AOwnerData: THCCustomData;
  const ALeftText, ATopText, ARightText, ABottomText: string);
begin
  inherited Create(AOwnerData, ALeftText, ATopText, ARightText, ABottomText);
  Self.StyleNo := EMRSTYLE_YUEJING;
end;

function TEmrYueJingItem.GetMenarcheAge: string;
begin
  Result := Self.LeftText;
end;

function TEmrYueJingItem.GetMenstrualCycle: string;
begin
  Result := Self.BottomText;
end;

function TEmrYueJingItem.GetMenstrualDuration: string;
begin
  Result := Self.TopText;
end;

function TEmrYueJingItem.GetMenstrualPause: string;
begin
  Result := Self.RightText;
end;

procedure TEmrYueJingItem.ParseXmlEmr(const ANode: IHCXMLNode);
begin
  if ANode.Attributes['DeCode'] = IntToStr(EMRSTYLE_YUEJING) then
  begin
    TopText := ANode.Attributes['toptext'];
    BottomText := ANode.Attributes['bottomtext'];
    LeftText := ANode.Attributes['lefttext'];
    RightText := ANode.Attributes['righttext'];
  end;
end;

procedure TEmrYueJingItem.SetMenarcheAge(const Value: string);
begin
  Self.LeftText := Value;
end;

procedure TEmrYueJingItem.SetMenstrualCycle(const Value: string);
begin
  Self.BottomText := Value;
end;

procedure TEmrYueJingItem.SetMenstrualDuration(const Value: string);
begin
  Self.TopText := Value;
end;

procedure TEmrYueJingItem.SetMenstrualPause(const Value: string);
begin
  Self.RightText := Value;
end;

procedure TEmrYueJingItem.ToXmlEmr(const ANode: IHCXMLNode);
begin
  ANode.Attributes['DeCode'] := IntToStr(EMRSTYLE_YUEJING);
  ANode.Attributes['toptext'] := TopText;
  ANode.Attributes['bottomtext'] := BottomText;
  ANode.Attributes['lefttext'] := LeftText;
  ANode.Attributes['righttext'] := RightText
end;

end.
