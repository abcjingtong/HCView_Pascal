{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_DM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Comp.UI;

type
  Tdm = class(TDataModule)
    conn: TFDConnection;
    fdgxwtcrsr: TFDGUIxWaitCursor;
    fdphysqltdrvrlnk: TFDPhysSQLiteDriverLink;
    qryTemp: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetPatListInfo;
    procedure OpenSql(const ASql: string);
    procedure ExecSql(const ASql: string);
    /// <summary> ��ȡָ���ı��ر����� </summary>
    procedure GetCacheTable(const ATableName: string);
    function GetParamStr(const AName: string): string;
    function GetParamInt(const AName: string; const ADefValue: Integer): Integer;
    function SetParam(const AName, AValue: string): Boolean;
  end;

var
  dm: Tdm;

implementation

uses
  emr_Common;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ Tdm }

procedure Tdm.DataModuleCreate(Sender: TObject);
var
  vDBPath: string;
begin
  vDBPath := ClientCache.RunPath + 'clt.db';
  if FileExists(vDBPath) then
    conn.ConnectionString := 'DriverID=SQLite;Password=emr171212.;Database=' + vDBPath
  else  // �������ݿ�
  begin
    conn.Params.Add('DriverID=SQLite');
    conn.Params.Add('Database=' + vDBPath);
    conn.Params.Add('Password=emr171212.');
  end;

  // �жϲ������Ƿ���ڣ��������򴴽�
  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''params''');
  if qryTemp.FieldByName('tbcount').AsInteger = 0 then  // ������params��
  begin
    conn.ExecSQL('CREATE TABLE params (' +
      'name nvarchar(20) primary key, ' +      // ������(����)
      'value nvarchar(255))');      // ����ֵ
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_MSGHOST, '']));  // ��Ϣ������
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_BLLHOST, '']));  // ҵ�������
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_MSGPORT, '']));  // ��Ϣ�˿�
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_BLLPORT, '']));  // ҵ��˿�
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', %d)', [PARAM_LOCAL_VERSIONID, 0]));  // �汾��
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_UPDATEHOST, '']));  // ���·�����
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', %d)', [PARAM_LOCAL_UPDATEPORT, '']));  // ���·������˿�
  end;

  // ��������
  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''Comm_Dic_DataElementMacro''');
  if qryTemp.FieldByName('tbcount').AsInteger <> 0 then  // ����params��
    conn.ExecSQL('drop table Comm_Dic_DataElementMacro');

  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''Comm_DataElementMacro''');
  if qryTemp.FieldByName('tbcount').AsInteger = 0 then  // ������
  begin
    {conn.ExecSQL('CREATE TABLE Comm_DataElementMacro (' +
      'id int not null primary key, DeID int not null, MacroType int not null, MacroField nvarchar(200) not null)');
    conn.ExecSQL(Format('INSERT INTO Comm_DataElementMacro (id, DeID, MacroType, MacroField) VALUES (%d, %d, %d, ''%s'')', [1, 748, 1, 'name']));}
  end
  else
    conn.ExecSQL('drop table Comm_DataElementMacro');

  //conn.ExecSQL('drop table clientcache');
  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''clientcache''');
  if qryTemp.FieldByName('tbcount').AsInteger = 0 then  // ������clientcache��
  begin
    conn.ExecSQL('CREATE TABLE clientcache (' +
      'id int not null primary key, ' +  // ���
      'tbName nvarchar(32) not null, ' +  // ����
      'dataVer int not null)');  // ���ݰ汾
  end;
end;

procedure Tdm.ExecSql(const ASql: string);
begin
  qryTemp.ExecSQL(ASql);
end;

procedure Tdm.GetCacheTable(const ATableName: string);
begin
  qryTemp.Open(Format('SELECT * FROM %s', [ATableName]));
end;

function Tdm.GetParamInt(const AName: string;
  const ADefValue: Integer): Integer;
var
  vsValue: string;
begin
  vsValue := GetParamStr(AName);
  Result := StrToIntDef(vsValue, ADefValue);
end;

function Tdm.GetParamStr(const AName: string): string;
begin
  qryTemp.Open(Format('SELECT value FROM params WHERE name=''%s''',[AName]));
  Result := qryTemp.FieldByName('value').AsString;
  qryTemp.Close;
end;

procedure Tdm.GetPatListInfo;
begin
  qryTemp.Open('SELECT id, col, colname, left, top, right, bottom, fontsize, visible, sys FROM pat_list');
end;

procedure Tdm.OpenSql(const ASql: string);
begin
  //qryTemp.Open(ASql);
  qryTemp.Close;
  qryTemp.SQL.Text := ASql;
  qryTemp.Open;
end;

function Tdm.SetParam(const AName, AValue: string): Boolean;
begin
  qryTemp.Open('SELECT COUNT(*) AS fieldcount FROM params WHERE name=:a', [AName]);
  if qryTemp.FieldByName('fieldcount').AsInteger > 0 then
    Result := conn.ExecSQL('UPDATE [params] SET value=:b WHERE name=:a', [AValue, AName]) = 1
  else
    Result := conn.ExecSQL('INSERT INTO [params] (value, name) VALUES (:a, :b)', [AValue, AName]) = 1;
end;

end.
