{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_Consultation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmConsultation = class(TForm)
    btnApply: TButton;
    procedure btnApplyClick(Sender: TObject);
  private
    { Private declarations }
    /// <summary> �½��������� </summary>
    procedure NewConsultation;
    /// <summary> �½�����������Ϣ </summary>
    procedure NewConsultationInvitee;
  public
    { Public declarations }
  end;

var
  frmConsultation: TfrmConsultation;

implementation

{$R *.dfm}

procedure TfrmConsultation.btnApplyClick(Sender: TObject);
begin
  NewConsultation;
  NewConsultationInvitee;
end;

procedure TfrmConsultation.NewConsultation;
begin

end;

procedure TfrmConsultation.NewConsultationInvitee;
begin

end;

end.
