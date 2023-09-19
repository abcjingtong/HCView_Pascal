{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_login;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, FunctionIntf, Vcl.StdCtrls, Vcl.Dialogs, CFControl, CFEdit,
  CFSafeEdit;

type
  TfrmLogin = class(TForm)
    btnOk: TButton;
    lbl1: TLabel;
    btnCancel: TButton;
    lbl2: TLabel;
    lblSet: TLabel;
    edtUserID: TCFEdit;
    edtPassword: TCFSafeEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lblSetClick(Sender: TObject);
    procedure edtPasswordKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FOnFunctionNotify: TFunctionNotifyEvent;
  public
    { Public declarations }
  end;

  procedure PluginShowLoginForm(AIFun: IFunBLLFormShow);
  procedure PluginCloseLoginForm;

var
  frmLogin: TfrmLogin;
  PlugInID: string;

implementation

uses
  PluginConst, FunctionConst, FunctionImp, emr_Common, emr_BLLInvoke,
  emr_MsgPack, emr_Entry, FireDAC.Comp.Client, frm_ConnSet, CFBalloonHint;

{$R *.dfm}

procedure PluginShowLoginForm(AIFun: IFunBLLFormShow);
//var
//  vObjectInfo: IPlugInObjectInfo;
begin
  if FrmLogin = nil then
    Application.CreateForm(Tfrmlogin, FrmLogin);

  FrmLogin.FOnFunctionNotify := AIFun.OnNotifyEvent;

  FrmLogin.ShowModal;

//  if FrmLogin.ModalResult = mrOk then
//  begin
//    vObjectInfo := TPlugInObjectInfo.Create;
//    vObjectInfo.&Object := TObject(FrmLogin.FUserID);
//    FrmLogin.FOnFunctionNotify(PlugInID, FUN_USERINFO, vObjectInfo);  // �����������¼�û���
//  end;

  FrmLogin.FOnFunctionNotify(PlugInID, FUN_BLLFORMDESTROY, nil);  // �ͷ�ҵ������Դ
end;

procedure PluginCloseLoginForm;
begin
  if FrmLogin <> nil then
    FreeAndNil(FrmLogin);
end;

procedure TfrmLogin.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmLogin.btnOkClick(Sender: TObject);
begin
  if edtPassword.TextLength < 1 then
  begin
    BalloonMessage(edtPassword, '���������룡');
    Exit;
  end;

  HintFormShow('���ڵ�¼...', procedure(const AUpdateHint: TUpdateHint)
  var
    vObjFun: IObjectFunction;
    vUserCert: TUserCert;
  begin
    vObjFun := TObjectFunction.Create;
    vUserCert := TUserCert.Create;
    try
      vUserCert.ID := edtUserID.Text;
      vUserCert.Password := MD5(edtPassword.SafeText);
      vObjFun.&Object := vUserCert;
      FOnFunctionNotify(PlugInID, FUN_LOGINCERTIFCATE, vObjFun);
      case vUserCert.State of
        cfsError: ShowMessage('��¼ʧ�ܣ���Ч���û����ߴ�������룡');
        cfsPass: Close;
        cfsConflict: ShowMessage('��¼ʧ�ܣ����ڶ����ͬ���û�������ϵ����Աȷ�ϣ�');
      end;
    finally
      FreeAndNil(vUserCert);
    end;
  end);
end;

procedure TfrmLogin.edtPasswordKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    btnOkClick(Sender);
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  PlugInID := PLUGIN_LOGIN;
  //SetWindowLong(Handle, GWL_EXSTYLE, (GetWindowLong(handle, GWL_EXSTYLE) or WS_EX_APPWINDOW));
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  if edtUserID.Text = '' then
    edtUserID.SetFocus
  else
    edtPassword.SetFocus;
end;

procedure TfrmLogin.lblSetClick(Sender: TObject);
var
  vFrmConnSet: TfrmConnSet;
begin
  vFrmConnSet := TfrmConnSet.Create(Self);
  try
    vFrmConnSet.ShowModal;
  finally
    FreeAndNil(vFrmConnSet);
  end;
end;

end.
