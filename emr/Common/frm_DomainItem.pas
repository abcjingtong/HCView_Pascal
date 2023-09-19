{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_DomainItem;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmDomainItem = class(TForm)
    lbl1: TLabel;
    edtName: TEdit;
    lbl2: TLabel;
    edtCode: TEdit;
    lbl3: TLabel;
    edtPY: TEdit;
    btnSave: TButton;
    procedure btnSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FItemID, FDomainID: Integer;
  public
    { Public declarations }
    property ItemID: Integer read FItemID write FItemID;
    property DomainID: Integer read FDomainID write FDomainID;
  end;

implementation

uses
  emr_Common, emr_BLLInvoke, FireDAC.Comp.Client;

{$R *.dfm}

procedure TfrmDomainItem.btnSaveClick(Sender: TObject);
var
  vCMD: Integer;
begin
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('������д��Ŀ���ƣ�');
    Exit;
  end;

  if FItemID > 0 then  // �޸�
    vCMD := BLL_SETDOMAINITEMINFO
  else  // ���
    vCMD := BLL_NEWDOMAINITEM;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := vCMD;

      if FItemID > 0 then  // �޸�
        ABLLServerReady.ExecParam.I['ID'] := FItemID;

      ABLLServerReady.ExecParam.I['domainid'] := FDomainID;
      ABLLServerReady.ExecParam.S['code'] := edtCode.Text;
      ABLLServerReady.ExecParam.S['devalue'] := edtName.Text;
      ABLLServerReady.ExecParam.S['py'] := edtPY.Text;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then
        ShowMessage(ABLLServer.MethodError)
      else
        ShowMessage('����ɹ���');
    end);

  if FItemID = 0 then  // �½���ر�
    Close;

  Self.ModalResult := mrOk;
end;

procedure TfrmDomainItem.FormShow(Sender: TObject);
begin
  if FItemID > 0 then  // �޸�
  begin
    BLLServerExec(
      procedure(const ABLLServerReady: TBLLServerProxy)
      begin
        ABLLServerReady.Cmd := BLL_GETDOMAINITEMINFO;  // ��ȡֵ��ѡ����Ϣ
        ABLLServerReady.ExecParam.I['ID'] := FItemID;
        ABLLServerReady.BackDataSet := True;
      end,
      procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
      begin
        if ABLLServer.MethodRunOk then  //
        begin
          if AMemTable <> nil then
          begin
            edtCode.Text := AMemTable.FieldByName('code').AsString;
            edtName.Text := AMemTable.FieldByName('devalue').AsString;
            edtPY.Text := AMemTable.FieldByName('py').AsString;
          end;
        end
        else
          ShowMessage(ABLLServer.MethodError);
      end);
  end
end;

end.
