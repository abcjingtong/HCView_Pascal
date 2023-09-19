{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
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
    FFileName: string;  // ini�ļ�
    FIniFile: TIniFile;
    FClientParam: TClientParam;
    procedure SetFileName(const Value: string);
    /// <summary> �������� </summary>
    /// <returns>True: ��������д���</returns>
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
  if CheckRequired then  // ��������д���
  begin
    if chkRemote.Checked then  // ��������
    begin
      FIniFile.WriteBool('RemoteServer', 'active', True);
      FIniFile.WriteString('RemoteServer', 'ip', edtRemoteServer.Text);
      FIniFile.WriteString('RemoteServer', 'port', edtRemotePort.Text);
    end
    else  // �������ݿ�
    begin
      FIniFile.WriteBool('RemoteServer', 'active', False);
      FIniFile.WriteString('DataBase', 'ip', edtDBServer.Text);
      FIniFile.WriteString('DataBase', 'DBName', edtDBName.Text);
      FIniFile.WriteString('DataBase', 'Username', edtDBUserName.Text);
      FIniFile.WriteString('DataBase', 'Password', EncodeString(edtDBPassword.Text));  // ����������м���
    end;

    if edtAlias.Text <> '' then
      FIniFile.WriteString('RemoteServer', 'Alias', edtAlias.Text)  // ����
    else
      FIniFile.WriteString('RemoteServer', 'Alias', 'emrҵ��(BLL)�����');

    FIniFile.WriteBool('RemoteServer', 'AutoStart', chkAutoStart.Checked);  // ������������������

    ShowMessage('����ɹ���');
  end;
end;

procedure TfrmConnSet.btnVerityClick(Sender: TObject);
begin
  FClientParam.BLLServerIP := edtRemoteServer.Text;  // ҵ�������IP
  FClientParam.BLLServerPort := StrToInt(edtRemotePort.Text);  // ҵ��������˿�
  try
    BLLServerExec(
      procedure(const ABLLServerReady: TBLLServerProxy)
      begin
        ABLLServerReady.Cmd := BLL_SRVDT;  // ����ҵ��
        ABLLServerReady.BackDataSet := False;  // ���߷����Ҫ����ѯ���ݼ��������
      end,
      procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
      begin
        if ABLLServer.MethodRunOk then  // ִ�гɹ�
          ShowMessage('�����������ӳɹ�')
        else  // ʧ��
        begin
          ShowMessage('������������ʧ�ܣ�������' + edtRemoteServer.Text + '; �˿�=' +
             edtRemotePort.Text);
        end;
      end);
  except
    on E: Exception do
    begin
      ShowMessage('������������ʧ�ܣ�������' + edtRemoteServer.Text + '; �˿�=' +
        edtRemotePort.Text + ';' + E.Message);
    end;
  end;
end;

function TfrmConnSet.CheckRequired: Boolean;
begin
  Result := False;
  if chkRemote.Checked then  // ������������
  begin
    if edtRemoteServer.Text = '' then
    begin
      ShowMessage('����д��������IP��ַ��');
      Exit;
    end
    else
    if edtRemotePort.Text = '' then
    begin
      ShowMessage('����д���������˿ڣ�');
      Exit;
    end;
  end
  else  // �������ݿ�
  begin
    if edtDBServer.Text = '' then
    begin
      ShowMessage('����д���ݿ�IP��ַ��');
      Exit;
    end
    else
    if edtDBName.Text = '' then
    begin
      ShowMessage('����д���ݿ�����');
      Exit;
    end
    else
    if edtDBUserName.Text = '' then
    begin
      ShowMessage('����д���ݿ��û�����');
      Exit;
    end
    else
    if edtDBPassword.Text = '' then
    begin
      ShowMessage('����д���ݿ����룡');
      Exit;
    end;
  end;
  Result := True;
end;

procedure TfrmConnSet.chkRemoteClick(Sender: TObject);
begin
  if chkRemote.Checked then  // ������������
  begin
    pgc.ActivePage := tsRemote;
    edtRemoteServer.Text := FIniFile.ReadString('RemoteServer', 'ip', '');  // ��������IP
    edtRemotePort.Text := FIniFile.ReadString('RemoteServer', 'port', '');  // ���������˿�
  end
  else  // �������ݿ�
  begin
    pgc.ActivePage := tsDataBase;
    edtDBServer.Text := FIniFile.ReadString('DataBase', 'ip', '');
    edtDBName.Text := FIniFile.ReadString('DataBase', 'DBName', '');
    edtDBUserName.Text := FIniFile.ReadString('DataBase', 'Username', '');
    edtDBPassword.Text := DecodeString(FIniFile.ReadString('DataBase', 'Password', ''));  // ��Ŀ�������Ľ���
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
    ShowMessage('δ�ҵ������ļ����Ѿ����´�������' + #13#10 + FFileName);
  end;

  FIniFile := TIniFile.Create(FFileName);
  chkRemote.Checked := FIniFile.ReadBool('RemoteServer', 'active', False);  // ������������
  chkRemoteClick(chkRemote);

  edtAlias.Text := FIniFile.ReadString('RemoteServer', 'Alias', '');  // ����
  chkAutoStart.Checked := FIniFile.ReadBool('RemoteServer', 'AutoStart', False);  // ������������������
end;

end.
