{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit emr_BLLDataBase;

interface

uses
  Generics.Collections, SysUtils, emr_DataBase;

type
  TBLLDBConnection = class(TDataBase)  // ���ݿ����Ӷ���
  strict private
    FConnID: Integer;
  public
    property ConnID: Integer read FConnID write FConnID;
  end;

  TBLLDataBase = class  // ���ݿ����Ӷ��������
  strict private
    FBLLDBConnections: TObjectList<TBLLDBConnection>;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure DisConnect;
    function GetBLLDataBase(const AConnID, ADBType: Integer; const AServer: string;
      const AProt: Integer; const ADBName, AUserName, APassword: string): TBLLDBConnection;
    function NewBLLDataBase: TBLLDBConnection;
  end;

implementation

{ TBLLDataBase }

constructor TBLLDataBase.Create;
begin
  FBLLDBConnections := TObjectList<TBLLDBConnection>.Create;
end;

destructor TBLLDataBase.Destroy;
begin
  FreeAndNil(FBLLDBConnections);
  inherited;
end;

procedure TBLLDataBase.DisConnect;
var
  i: Integer;
begin
  for i := 0 to FBLLDBConnections.Count do
    FBLLDBConnections[i].DisConnect;
end;

function TBLLDataBase.GetBLLDataBase(const AConnID, ADBType: Integer; const AServer: string;
  const AProt: Integer; const ADBName, AUserName, APassword: string): TBLLDBConnection;
var
  i: Integer;
begin
  Result := nil;
  if AConnID > 0 then  // ID�������0
  begin
    for i := 0 to FBLLDBConnections.Count - 1 do  // ����ָ�������ݿ������Ѿ�������
    begin
      if FBLLDBConnections[i].ConnID = AConnID then
      begin
        Result := FBLLDBConnections[i];
        Break;
      end;
    end;
  end;
  if Result = nil then  // û�ҵ��򴴽��µ����ݿ�����
  begin
    Result := NewBLLDataBase;
    Result.DBType := TDBType(ADBType);
    Result.ConnID := AConnID;
    Result.Server := AServer;
    Result.Port := AProt;
    Result.DBName := ADBName;
    Result.UserName := AUserName;
    Result.Password := APassword;
    Result.Connect;
  end;
end;

function TBLLDataBase.NewBLLDataBase: TBLLDBConnection;
begin
  Result := TBLLDBConnection.Create(nil);
  FBLLDBConnections.Add(Result);
end;

end.
