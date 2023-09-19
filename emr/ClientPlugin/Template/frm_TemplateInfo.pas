{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_TemplateInfo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmTemplateInfo = class(TForm)
    lbl1: TLabel;
    edtTName: TEdit;
    btnSave: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    { Private declarations }
    FTempID: Integer;
    FTempName: string;
  public
    { Public declarations }
    property TempID: Integer read FTempID write FTempID;
    property TempName: string read FTempName write FTempName;
  end;

implementation

uses
  emr_Common, emr_BLLInvoke, FireDAC.Comp.Client;

{$R *.dfm}

procedure TfrmTemplateInfo.btnSaveClick(Sender: TObject);
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_SETTEMPLATEINFO;  // ����ģ����Ϣ
      ABLLServerReady.ExecParam.I['id'] := FTempID;
      ABLLServerReady.ExecParam.ForcePathObject('tname').AsString := Trim(edtTName.Text);
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if ABLLServer.MethodRunOk then  // ��ȡ�ɹ�
      begin
        FTempName := Trim(edtTName.Text);
        ShowMessage('�޸ĳɹ���');
      end
      else
        ShowMessage(ABLLServer.MethodError);
    end);
end;

procedure TfrmTemplateInfo.FormShow(Sender: TObject);
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETTEMPLATEINFO;  // ��ȡģ����Ϣ
      ABLLServerReady.ExecParam.I['id'] := FTempID;
      ABLLServerReady.AddBackField('tname');
      ABLLServerReady.AddBackField('desid');
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if ABLLServer.MethodRunOk then  // ��ȡ�ɹ�
      begin
        FTempName := ABLLServer.BackField('tname').AsString;
        edtTName.Text := FTempName;
        Self.Caption := FTempName;
      end
      else
        ShowMessage(ABLLServer.MethodError);
    end);
end;

end.
