{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_Domain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, frm_DataElementDomain,
  Vcl.ExtCtrls;

type
  TfrmDomain = class(TForm)
    sgdDomain: TStringGrid;
    pm: TPopupMenu;
    mniNew: TMenuItem;
    mniEdit: TMenuItem;
    mniDelete: TMenuItem;
    spl1: TSplitter;
    procedure FormShow(Sender: TObject);
    procedure mniNewClick(Sender: TObject);
    procedure mniEditClick(Sender: TObject);
    procedure mniDeleteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sgdDomainClick(Sender: TObject);
  private
    { Private declarations }
    FfrmDataElementDomain: TfrmDataElementDomain;
    procedure GetAllDomain;
  public
    { Public declarations }
  end;

implementation

uses
  emr_Common, emr_BLLInvoke, FireDAC.Comp.Client, frm_DomainInfo;

{$R *.dfm}

procedure TfrmDomain.FormCreate(Sender: TObject);
begin
  FfrmDataElementDomain := TfrmDataElementDomain.Create(nil);
  FfrmDataElementDomain.BorderStyle := bsNone;
  FfrmDataElementDomain.Align := alClient;
  FfrmDataElementDomain.Parent := Self;
  FfrmDataElementDomain.Show;
end;

procedure TfrmDomain.FormShow(Sender: TObject);
begin
  sgdDomain.RowCount := 1;
  sgdDomain.Cells[0, 0] := 'ID';
  sgdDomain.Cells[1, 0] := '����';
  sgdDomain.Cells[2, 0] := '����';

  GetAllDomain;
  sgdDomainClick(Sender);
end;

procedure TfrmDomain.GetAllDomain;
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETDOMAIN;  // ��ȡֵ��
      ABLLServerReady.BackDataSet := True;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    var
      i: Integer;
    begin
      if ABLLServer.MethodRunOk then
      begin
        if AMemTable <> nil then
        begin
          sgdDomain.RowCount := AMemTable.RecordCount + 1;

          if sgdDomain.RowCount > 1 then
            sgdDomain.FixedRows := 1;

          i := 1;

          AMemTable.First;
          while not AMemTable.Eof do
          begin
            sgdDomain.Cells[0, i] := AMemTable.FieldByName('DID').AsString;
            sgdDomain.Cells[1, i] := AMemTable.FieldByName('DCode').AsString;
            sgdDomain.Cells[2, i] := AMemTable.FieldByName('DName').AsString;

            Inc(i);
            AMemTable.Next;
          end;
        end;
      end
      else
        ShowMessage(ABLLServer.MethodError);
    end);
end;

procedure TfrmDomain.mniDeleteClick(Sender: TObject);
var
  vRow, vTopRow, vDomainID: Integer;
  vDeleteOk: Boolean;
begin
  if sgdDomain.Row >= 0 then
  begin
    if MessageDlg('ȷ��Ҫɾ��ֵ��' + sgdDomain.Cells[1, sgdDomain.Row] + '���Լ����Ӧ��ѡ�ѡ�������������',
      mtWarning, [mbYes, mbNo], 0) = mrYes
    then
    begin
      SaveStringGridRow(vRow, vTopRow, sgdDomain);

      vDeleteOk := True;
      vDomainID := StrToInt(sgdDomain.Cells[0, sgdDomain.Row]);

      // ȡ���е�ѡ�����ɾ����������
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_GETDOMAINITEM;  // ��ȡֵ��ѡ��
          ABLLServerReady.ExecParam.I['domainid'] := vDomainID;
          ABLLServerReady.BackDataSet := True;
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if not ABLLServer.MethodRunOk then  // ����˷�������ִ�в��ɹ�
          begin
            ShowMessage(ABLLServer.MethodError);
            vDeleteOk := False;
          end;

          if AMemTable <> nil then
          begin
            with AMemTable do
            begin
              First;
              while not Eof do
              begin
                TBLLInvoke.DeleteDomainItemContent(AMemTable.FieldByName('ID').AsInteger,  // ɾ��ֵ��ѡ���������
                  procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
                  begin
                    if not ABLLServer.MethodRunOk then
                    begin
                      ShowMessage(ABLLServer.MethodError);
                      vDeleteOk := False;
                    end;
                  end);

                if not vDeleteOk then
                  Break;

                Next;
              end;
            end;
          end;
        end);

      if not vDeleteOk then Exit;

      // ɾ��ֵ���Ӧ������ѡ��
      TBLLInvoke.DeleteDomainAllItem(vDomainID,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if not ABLLServer.MethodRunOk then
          begin
            ShowMessage(ABLLServer.MethodError);
            vDeleteOk := False;
          end;
        end);

      if not vDeleteOk then Exit;

      // ɾ��ֵ��
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_DELETEDOMAIN;  // ɾ��ֵ��
          ABLLServerReady.ExecParam.I['DID'] := vDomainID;
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if not ABLLServer.MethodRunOk then
            ShowMessage(ABLLServer.MethodError)
          else
          begin
            ShowMessage('ɾ��ֵ��ɹ���');

            GetAllDomain;
            RestoreStringGridRow(vRow, vTopRow, sgdDomain);
          end;
        end);
    end;
  end;
end;

procedure TfrmDomain.mniEditClick(Sender: TObject);
var
  vFrmDomainInfo: TfrmDomainInfo;
  vTopRow, vRow: Integer;
begin
  if sgdDomain.Row > 0 then
  begin
    SaveStringGridRow(vRow, vTopRow, sgdDomain);

    vFrmDomainInfo := TfrmDomainInfo.Create(Self);
    try
      vFrmDomainInfo.DID := StrToInt(sgdDomain.Cells[0, sgdDomain.Row]);
      vFrmDomainInfo.edtCode.Text := sgdDomain.Cells[1, sgdDomain.Row];
      vFrmDomainInfo.edtName.Text := sgdDomain.Cells[2, sgdDomain.Row];
      vFrmDomainInfo.ShowModal;
      if vFrmDomainInfo.ModalResult = mrOk then
        GetAllDomain;

      RestoreStringGridRow(vRow, vTopRow, sgdDomain);
    finally
      FreeAndNil(vFrmDomainInfo);
    end;
  end;
end;

procedure TfrmDomain.mniNewClick(Sender: TObject);
var
  vFrmDomainInfo: TfrmDomainInfo;
begin
  vFrmDomainInfo := TfrmDomainInfo.Create(Self);
  try
    vFrmDomainInfo.DID := 0;
    vFrmDomainInfo.ShowModal;
    if vFrmDomainInfo.ModalResult = mrOk then
      GetAllDomain;
  finally
    FreeAndNil(vFrmDomainInfo);
  end;
end;

procedure TfrmDomain.sgdDomainClick(Sender: TObject);
begin
  if FfrmDataElementDomain.DomainID <> StrToInt(sgdDomain.Cells[0, sgdDomain.Row]) then
    FfrmDataElementDomain.DomainID := StrToInt(sgdDomain.Cells[0, sgdDomain.Row]);
end;

end.

