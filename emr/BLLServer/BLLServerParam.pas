{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit BLLServerParam;

interface

{ ��Ϊ�м������ʱ������Ҫ���ӵ������������� }

uses
  IniFiles;

type
  TIniFileEvent = reference to procedure(const AIniFile: TIniFile);

  TBLLServerParams = class(TObject)  // ҵ�����˲���(��Winƽ̨ʹ��)
  private
    FFileName: string;
    FRemoteActive: Boolean;
    FRemoteBLLIP: string;
    FRemoteBLLPort: Word;
    FDataBaseServer: string;
    FDataBaseName: string;
    FDataBaseUsername: string;
    FDataBasePassword: string;
  protected
    procedure SetRemoteActive(const Value: Boolean);
    procedure SetRemoteBLLIP(const Value: string);
    procedure SetRemoteBLLPort(const Value: Word);
    procedure SetDataBaseServer(const Value: string);
    procedure SetDataBaseName(const Value: string);
    procedure SetDataBaseUsername(const Value: string);
    procedure SetDataBasePassword(const Value: string);
  public
    constructor Create(const AFileName: string);
    // Զ�̷�����
    property RemoteActive: Boolean read FRemoteActive write SetRemoteActive;
    property RemoteBLLIP: string read FRemoteBLLIP write SetRemoteBLLIP;
    property RemoteBLLPort: Word read FRemoteBLLPort write SetRemoteBLLPort;
    // ���ݿ�
    property DataBaseServer: string read FDataBaseServer write SetDataBaseServer;
    property DataBaseName: string read FDataBaseName write SetDataBaseName;
    property DataBaseUsername: string read FDataBaseUsername write SetDataBaseUsername;
    property DataBasePassword: string read FDataBasePassword write SetDataBasePassword;

    /// <summary> ��ȡ��д��Ini�ļ� </summary>
    /// <param name="AIniFileEvent">����Ini�ļ�</param>
    procedure ReadOrWriteIniFile(const AIniFileEvent: TIniFileEvent);

  end;

var
  BLLServerParams: TBLLServerParams;

implementation

uses
  SysUtils, Soap.EncdDecd;

{ TBLLServerParams }

constructor TBLLServerParams.Create(const AFileName: string);
begin
  inherited Create;
  if not FileExists(AFileName) then
    raise Exception.Create('�쳣��δ�ҵ������ļ�' + AFileName)
  else
  begin
    FFileName := AFileName;
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        FRemoteActive := AIniFile.ReadBool('RemoteServer', 'active', False);
        FRemoteBLLIP := AIniFile.ReadString('RemoteServer', 'ip', '');
        FRemoteBLLPort := AIniFile.ReadInteger('RemoteServer', 'port', 12726);
        FDataBaseServer := AIniFile.ReadString('DataBase', 'ip', '');
        FDataBaseName := AIniFile.ReadString('DataBase', 'DBName', '');
        FDataBaseUsername := AIniFile.ReadString('DataBase', 'Username', '');
        FDataBasePassword := DecodeString(AIniFile.ReadString('DataBase', 'Password', ''));  // ����
      end);
  end;
end;

procedure TBLLServerParams.SetDataBaseName(const Value: string);
begin
  if FDataBaseName <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteString('DataBase', 'DBName', Value);
      end);
    FDataBaseName := Value;
  end;
end;

procedure TBLLServerParams.SetDataBasePassword(const Value: string);
begin
  if FDataBasePassword <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteString('DataBase', 'Password', Value);  // ����
      end);
    FDataBasePassword := Value;
  end;
end;

procedure TBLLServerParams.SetDataBaseServer(const Value: string);
begin
  if FDataBaseServer <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteString('DataBase', 'ip', Value);
      end);
    FDataBaseServer := Value;
  end;
end;

procedure TBLLServerParams.SetDataBaseUsername(const Value: string);
begin
  if FDataBaseUsername <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteString('DataBase', 'Username', Value);
      end);
    FDataBaseUsername := Value;
  end;
end;

procedure TBLLServerParams.SetRemoteActive(const Value: Boolean);
begin
  if FRemoteActive <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteBool('RemoteServer', 'active', Value);
      end);
    FRemoteActive := Value;
  end;
end;

procedure TBLLServerParams.SetRemoteBLLIP(const Value: string);
begin
  if FRemoteBLLIP <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteString('RemoteServer', 'ip', Value);
      end);
    FRemoteBLLIP := Value;
  end;
end;

procedure TBLLServerParams.SetRemoteBLLPort(const Value: Word);
begin
  if FRemoteBLLPort <> Value then
  begin
    ReadOrWriteIniFile(
      procedure(const AIniFile: TIniFile)
      begin
        AIniFile.WriteInteger('RemoteServer', 'port', Value);
      end);
    FRemoteBLLPort := Value;
  end;
end;

procedure TBLLServerParams.ReadOrWriteIniFile(const AIniFileEvent: TIniFileEvent);
var
  vIni: TIniFile;
begin
  vIni := TIniFile.Create(FFileName);
  try
    AIniFileEvent(vIni);
  finally
    vIni.Free;
  end;
end;

end.
