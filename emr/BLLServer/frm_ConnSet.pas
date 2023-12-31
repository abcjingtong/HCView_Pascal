{*******************************************************}
{                                                       }
{         基于HCView的电子病历程序  作者：荆通          }
{                                                       }
{ 此代码仅做学习交流使用，不可用于商业目的，由此引发的  }
{ 后果请使用者承担，加入QQ群 649023932 来获取更多的技术 }
{ 交流。                                                }
{                                                       }
{*******************************************************}

unit frm_ConnSet;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, StdCtrls, ComCtrls, ExtCtrls, emr_Common;

type
  TfrmConnSet = class(TForm)
    btnSave: TButton;
    pnl1: TPanel;
    chkRemote: TCheckBox;
    pgc: TPageControl;
    tsDataBase: TTabSheet;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    edtDBServer: TEdit;
    edtDBName: TEdit;
    edtDBUserName: TEdit;
    edtDBPassword: TEdit;
    tsRemote: TTabSheet;
    lbl7: TLabel;
    lbl8: TLabel;
    edtRemoteServer: TEdit;
    edtRemotePort: TEdit;
    btnVerity: TButton;
    lbl1: TLabel;
    chkAutoStart: TCheckBox;
    edtAlias: TEdit;
    procedure btnSaveClick(Sender: TObject);
    procedure btnVerityClick(Sender: TObject);
    procedure chkRemoteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FFileName: string;  // ini文件
    FIniFile: TIniFile;
    FClientParam: TClientParam;
    procedure SetFileName(const Value: string);
    /// <summary> 检查必填项 </summary>
    /// <returns>True: 必填项填写完成</returns>
    function CheckRequired: Boolean;
  public
    { Public declarations }
    property FileName: string read FFileName write SetFileName;
  end;

implementation

uses
  Soap.EncdDecd, FireDAC.Comp.Client, emr_BLLInvoke;

{$R *.dfm}

procedure TfrmConnSet.btnSaveClick(Sender: TObject);
begin
  if CheckRequired then  // 必填项填写完成
  begin
    if chkRemote.Checked then  // 主服务器
    begin
      FIniFile.WriteBool('RemoteServer', 'active', True);
      FIniFile.WriteString('RemoteServer', 'ip', edtRemoteServer.Text);
      FIniFile.WriteString('RemoteServer', 'port', edtRemotePort.Text);
    end
    else  // 连接数据库
    begin
      FIniFile.WriteBool('RemoteServer', 'active', False);
      FIniFile.WriteString('DataBase', 'ip', edtDBServer.Text);
      FIniFile.WriteString('DataBase', 'DBName', edtDBName.Text);
      FIniFile.WriteString('DataBase', 'Username', edtDBUserName.Text);
      FIniFile.WriteString('DataBase', 'Password', EncodeString(edtDBPassword.Text));  // 保存密码进行加密
    end;

    if edtAlias.Text <> '' then
      FIniFile.WriteString('RemoteServer', 'Alias', edtAlias.Text)  // 别名
    else
      FIniFile.WriteString('RemoteServer', 'Alias', 'emr业务(BLL)服务端');

    FIniFile.WriteBool('RemoteServer', 'AutoStart', chkAutoStart.Checked);  // 启动后立即开启服务

    ShowMessage('保存成功！');
  end;
end;

procedure TfrmConnSet.btnVerityClick(Sender: TObject);
begin
  FClientParam.BLLServerIP := edtRemoteServer.Text;  // 业务服务器IP
  FClientParam.BLLServerPort := StrToInt(edtRemotePort.Text);  // 业务服务器端口
  try
    BLLServerExec(
      procedure(const ABLLServerReady: TBLLServerProxy)
      begin
        ABLLServerReady.Cmd := BLL_SRVDT;  // 调用业务
        ABLLServerReady.BackDataSet := False;  // 告诉服务端要将查询数据集结果返回
      end,
      procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
      begin
        if ABLLServer.MethodRunOk then  // 执行成功
          ShowMessage('主服务器连接成功')
        else  // 失败
        begin
          ShowMessage('主服务器连接失败，服务器' + edtRemoteServer.Text + '; 端口=' +
             edtRemotePort.Text);
        end;
      end);
  except
    on E: Exception do
    begin
      ShowMessage('主服务器连接失败，服务器' + edtRemoteServer.Text + '; 端口=' +
        edtRemotePort.Text + ';' + E.Message);
    end;
  end;
end;

function TfrmConnSet.CheckRequired: Boolean;
begin
  Result := False;
  if chkRemote.Checked then  // 连接主服务器
  begin
    if edtRemoteServer.Text = '' then
    begin
      ShowMessage('请填写主服务器IP地址！');
      Exit;
    end
    else
    if edtRemotePort.Text = '' then
    begin
      ShowMessage('请填写主服务器端口！');
      Exit;
    end;
  end
  else  // 连接数据库
  begin
    if edtDBServer.Text = '' then
    begin
      ShowMessage('请填写数据库IP地址！');
      Exit;
    end
    else
    if edtDBName.Text = '' then
    begin
      ShowMessage('请填写数据库名！');
      Exit;
    end
    else
    if edtDBUserName.Text = '' then
    begin
      ShowMessage('请填写数据库用户名！');
      Exit;
    end
    else
    if edtDBPassword.Text = '' then
    begin
      ShowMessage('请填写数据库密码！');
      Exit;
    end;
  end;
  Result := True;
end;

procedure TfrmConnSet.chkRemoteClick(Sender: TObject);
begin
  if chkRemote.Checked then  // 连接主服务器
  begin
    pgc.ActivePage := tsRemote;
    edtRemoteServer.Text := FIniFile.ReadString('RemoteServer', 'ip', '');  // 主服务器IP
    edtRemotePort.Text := FIniFile.ReadString('RemoteServer', 'port', '');  // 主服务器端口
  end
  else  // 连接数据库
  begin
    pgc.ActivePage := tsDataBase;
    edtDBServer.Text := FIniFile.ReadString('DataBase', 'ip', '');
    edtDBName.Text := FIniFile.ReadString('DataBase', 'DBName', '');
    edtDBUserName.Text := FIniFile.ReadString('DataBase', 'Username', '');
    edtDBPassword.Text := DecodeString(FIniFile.ReadString('DataBase', 'Password', ''));  // 对目标密码文解密
  end;
end;

procedure TfrmConnSet.FormCreate(Sender: TObject);
begin
  FClientParam := TClientParam.Create;
  tsDataBase.TabVisible := False;
  tsRemote.TabVisible := False;
end;

procedure TfrmConnSet.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FIniFile);
  FClientParam.Free;
end;

procedure TfrmConnSet.SetFileName(const Value: string);
begin
  if FFileName <> Value then
    FFileName := Value;

  if not FileExists(FFileName) then
  begin
    FFileName := ExtractFilePath(ParamStr(0)) + 'emrBLLServer.ini';
    ShowMessage('未找到配置文件，已经重新创建到：' + #13#10 + FFileName);
  end;

  FIniFile := TIniFile.Create(FFileName);
  chkRemote.Checked := FIniFile.ReadBool('RemoteServer', 'active', False);  // 连接主服务器
  chkRemoteClick(chkRemote);

  edtAlias.Text := FIniFile.ReadString('RemoteServer', 'Alias', '');  // 别名
  chkAutoStart.Checked := FIniFile.ReadBool('RemoteServer', 'AutoStart', False);  // 启动后立即开启服务
end;

end.
