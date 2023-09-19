{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_DomainInfo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmDomainInfo = class(TForm)
    lbl1: TLabel;
    lbl2: TLabel;
    edtName: TEdit;
    edtCode: TEdit;
    btnSave: TButton;
    procedure btnSaveClick(Sender: TObject);
  private
    { Private declarations }
    FDID: Integer;
  public
    { Public declarations }
    property DID: Integer read FDID write FDID;
  end;

implementation

uses
  emr_Common, emr_BLLInvoke, FireDAC.Comp.Client;

{$R *.dfm}

procedure TfrmDomainInfo.btnSaveClick(Sender: TObject);
var
  vCMD: Integer;
begin
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('��������дֵ�����ƣ�');
    Exit;
  end;

  if FDID > 0 then  // �޸�
    vCMD := BLL_SETDOMAIN
  else  // ���
    vCMD := BLL_NEWDOMAIN;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := vCMD;

      if FDID > 0 then  // �޸�
        ABLLServerReady.ExecParam.I['DID'] := FDID;

      ABLLServerReady.ExecParam.S['DCode'] := edtCode.Text;
      ABLLServerReady.ExecParam.S['DName'] := edtName.Text;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then
        ShowMessage(ABLLServer.MethodError)
      else
        ShowMessage('����ɹ���');
    end);

  if FDID = 0 then  // �½���ر�
    Close;

  Self.ModalResult := mrOk;
end;

end.
