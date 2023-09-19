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
    function OpenSql(const ASql: string): TFDQuery;
    function ExecSql(const ASql: string): Boolean;
  end;

var
  dm: Tdm;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ Tdm }

procedure Tdm.DataModuleCreate(Sender: TObject);
var
  vDBPath: string;
begin
  vDBPath := ExtractFilePath(ParamStr(0)) + 'upServer.db';
  if FileExists(vDBPath) then
    conn.ConnectionString := 'DriverID=SQLite;Password=up190512.;Database=' + vDBPath
  else  // �������ݿ�
  begin
    conn.Params.Add('DriverID=SQLite');
    conn.Params.Add('Database=' + vDBPath);
    conn.Params.Add('Password=up190512.');
  end;

  // �ж�������Ϣ���Ƿ���ڣ��������򴴽�
  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''UpdateInfo''');
  if qryTemp.FieldByName('tbcount').AsInteger = 0 then  // ������params��
  begin
    conn.ExecSQL('CREATE TABLE UpdateInfo (' +
      'verno integer primary key AutoIncRement, ' +  // �汾���
      'version nvarchar(20), ' +  // �汾��
      'memo nvarchar(255), ' +  // �汾˵��
      'files nvarchar(1024))');  // �����ļ�xml��ʽ
  end;
end;

function Tdm.ExecSql(const ASql: string): Boolean;
begin
  Result := qryTemp.ExecSQL(ASql) > 0;
end;

function Tdm.OpenSql(const ASql: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := conn;
  //qryTemp.Open(ASql);
  Result.Close;
  Result.SQL.Text := ASql;
  Result.Open;
end;

end.
