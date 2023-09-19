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
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmConnSet = class(TForm)
    edtBLLServerIP: TEdit;
    edtBLLServerPort: TEdit;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    edtMsgServerIP: TEdit;
    edtMsgServerPort: TEdit;
    lbl4: TLabel;
    lbl5: TLabel;
    lbl6: TLabel;
    btnSave: TButton;
    procedure btnSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  System.IniFiles, emr_Common;

{$R *.dfm}

procedure TfrmConnSet.btnSaveClick(Sender: TObject);
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'emr.ini');
  try
    //vIniFile.WriteInteger('Client', 'TimeOut', 3000);  // 3��
    //vIniFile.WriteInteger('Client', PARAM_LOCAL_VERSIONID, 0);

    vIniFile.WriteString('BLLServer', PARAM_LOCAL_BLLHOST, edtBLLServerIP.Text);  // ҵ������
    vIniFile.WriteString('BLLServer', PARAM_LOCAL_BLLPORT, edtBLLServerPort.Text);  // ҵ�����˶˿�

    vIniFile.WriteString('MsgServer', PARAM_LOCAL_MSGHOST, edtMsgServerIP.Text);  // ��Ϣ�����
    vIniFile.WriteString('MsgServer', PARAM_LOCAL_MSGPORT, edtMsgServerPort.Text);  // ��Ϣ����˶˿�
  finally
    FreeAndNil(vIniFile);
  end;

  ShowMessage('����ɹ���');
end;

procedure TfrmConnSet.FormShow(Sender: TObject);
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'emr.ini');
  try
    edtBLLServerIP.Text := vIniFile.ReadString('BLLServer', PARAM_LOCAL_BLLHOST, '127.0.0.1');  // ҵ������
    edtBLLServerPort.Text := vIniFile.ReadString('BLLServer', PARAM_LOCAL_BLLPORT, '12830');  // ҵ�����˶˿�
    edtMsgServerIP.Text := vIniFile.ReadString('MsgServer', PARAM_LOCAL_MSGHOST, '127.0.0.1');  // ��Ϣ�����
    edtMsgServerPort.Text := vIniFile.ReadString('MsgServer', PARAM_LOCAL_MSGPORT, '12832');  // ��Ϣ����˶˿�
  finally
    FreeAndNil(vIniFile);
  end;
end;

end.
