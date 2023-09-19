{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_InsertDeTable;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrmInsertTable = class(TForm)
    edtRows: TEdit;
    edtCols: TEdit;
    lbl1: TLabel;
    lbl2: TLabel;
    btnOk: TButton;
    procedure btnOkClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TfrmInsertTable.btnOkClick(Sender: TObject);
var
  vRowCount, vColCount: Integer;
begin
  if not TryStrToInt(edtRows.Text, vRowCount) then
    ShowMessage('��������ȷ��������')
  else
  if not TryStrToInt(edtCols.Text, vColCount) then
    ShowMessage('��������ȷ��������')
  else
  if vRowCount < 1 then
    ShowMessage('��������Ϊ1��')
  else
  if vRowCount > 256 then
    ShowMessage('�������ܳ���256�У�')
  else
  if vColCount < 1 then
    ShowMessage('��������Ϊ1��')
  else
  if vColCount > 32 then
    ShowMessage('�������ܳ���32�У�')
  else
    Self.ModalResult := mrOk;
end;

end.
