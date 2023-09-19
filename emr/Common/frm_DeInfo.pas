{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_DeInfo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  frm_ScriptIDE, emr_Compiler;

type
  TfrmDeInfo = class(TForm)
    pnl1: TPanel;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    lbl6: TLabel;
    lbl7: TLabel;
    lbl8: TLabel;
    lbl9: TLabel;
    cbbFrmtp: TComboBox;
    edtCode: TEdit;
    edtDefine: TEdit;
    edtDomainID: TEdit;
    edtFormat: TEdit;
    edtName: TEdit;
    edtPY: TEdit;
    edtType: TEdit;
    edtUnit: TEdit;
    lbl10: TLabel;
    btnSave: TButton;
    btnSaveClose: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnSaveCloseClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FDeID: Integer;
    FCompiler: TEmrCompiler;
    FFrmScriptIDE: TfrmScriptIDE;

    procedure DoScriptSave(Sender: TObject);
    procedure DoScriptCompile(Sender: TObject);
    procedure DoScriptCompilePreview(Sender: TObject);
  public
    { Public declarations }
    property DeID: Integer read FDeID write FDeID;
  end;

implementation

uses
  emr_Common, emr_BLLInvoke, FireDAC.Comp.Client, HCEmrElementItem;

{$R *.dfm}

function GetFrmtpText(const AFrmpt: string): string;
begin
  if AFrmpt = TDeFrmtp.Radio then
    Result := '��ѡ'
  else
  if AFrmpt = TDeFrmtp.Multiselect then
    Result := '��ѡ'
  else
  if AFrmpt = TDeFrmtp.Number then
    Result := '��ֵ'
  else
  if AFrmpt = TDeFrmtp.String then
    Result := '�ı�'
  else
  if AFrmpt = TDeFrmtp.Date then
    Result := '����'
  else
  if AFrmpt = TDeFrmtp.Time then
    Result := 'ʱ��'
  else
  if AFrmpt = TDeFrmtp.DateTime then
    Result := '����ʱ��'
  else
    Result := '';
end;

function GetFrmtp(const AText: string): string;
begin
  if AText = '��ѡ' then
    Result := TDeFrmtp.Radio
  else
  if AText = '��ѡ' then
    Result := TDeFrmtp.Multiselect
  else
  if AText = '��ֵ' then
    Result := TDeFrmtp.Number
  else
  if AText = '�ı�' then
    Result := TDeFrmtp.String
  else
  if AText = '����' then
    Result := TDeFrmtp.Date
  else
  if AText = 'ʱ��' then
    Result := TDeFrmtp.Time
  else
  if AText = '����ʱ��' then
    Result := TDeFrmtp.DateTime
  else
    Result := '';
end;

procedure TfrmDeInfo.btnSaveClick(Sender: TObject);
var
  vDomainID, vCMD: Integer;
begin
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('������д����Ԫ���ƣ�');
    Exit;
  end;

  if not TryStrToInt(edtDomainID.Text, vDomainID) then
  begin
    ShowMessage('������д��ֵ����תΪ������');
    Exit;
  end;

  if FDeID > 0 then  // �޸�
    vCMD := BLL_SETDEINFO
  else  // �½�
    vCMD := BLL_NEWDE;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := vCMD;

      if FDeID > 0 then  // �޸�
        ABLLServerReady.ExecParam.I['DeID'] := FDeID;

      ABLLServerReady.ExecParam.S['decode'] := edtCode.Text;
      ABLLServerReady.ExecParam.S['dename'] := edtName.Text;
      ABLLServerReady.ExecParam.S['py'] := edtPY.Text;
      ABLLServerReady.ExecParam.S['dedefine'] := edtDefine.Text;
      ABLLServerReady.ExecParam.S['detype'] := edtType.Text;
      ABLLServerReady.ExecParam.S['deformat'] := edtFormat.Text;
      ABLLServerReady.ExecParam.S['deunit'] := edtUnit.Text;
      ABLLServerReady.ExecParam.S['frmtp'] := GetFrmtp(cbbFrmtp.Text);
      ABLLServerReady.ExecParam.I['domainid'] := vDomainID;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then
        ShowMessage(ABLLServer.MethodError)
      else
        ShowMessage('������Ϣ�ɹ���');
    end);
end;

procedure TfrmDeInfo.btnSaveCloseClick(Sender: TObject);
begin
  btnSaveClick(Sender);
  Self.ModalResult := mrOk;
end;

procedure TfrmDeInfo.DoScriptCompile(Sender: TObject);
var
  i: Integer;
begin
  FFrmScriptIDE.ClearDebugInfo;

  FCompiler.ResetRegister;
  FCompiler.RegClassVariable(nil, nil, nil, nil);
  if not FCompiler.CompileScript(FFrmScriptIDE.Script) then
  begin
    FFrmScriptIDE.SetDebugCaption('Messages ' + 'Error(' + IntToStr(FCompiler.ErrorCount) + ')'
      + ' Warning(' + IntToStr(FCompiler.WarningCount) + ')');

    for i := 0 to FCompiler.WarningCount - 1 do
      FFrmScriptIDE.AddWarning(FCompiler.WarningLineNumber[i],
        'Warning[' + IntToStr(FCompiler.WarningLineNumber[i] + 1) + ']' + FCompiler.WarningMessage[i]);

    for i := 0 to FCompiler.ErrorCount - 1 do
      FFrmScriptIDE.AddError(FCompiler.ErrorLineNumber[i],
        'Error[' + IntToStr(FCompiler.ErrorLineNumber[i] + 1) + ']' + FCompiler.ErrorMessage[i]);
  end
  else
  begin
    FFrmScriptIDE.SetDebugCaption('Messages ' + 'Error(0)'
      + ' Warning(' + IntToStr(FCompiler.WarningCount) + ')');

    for i := 0 to FCompiler.WarningCount - 1 do
      FFrmScriptIDE.AddWarning(FCompiler.WarningLineNumber[i],
        'Warning[' + IntToStr(FCompiler.WarningLineNumber[i] + 1) + ']' + FCompiler.WarningMessage[i]);
  end;
end;

procedure TfrmDeInfo.DoScriptCompilePreview(Sender: TObject);
begin
  FCompiler.ResetRegister;
  FCompiler.RegClassVariable(nil, nil, nil, nil);
  FCompiler.CompileScript(FFrmScriptIDE.Script);
end;

procedure TfrmDeInfo.DoScriptSave(Sender: TObject);
begin
  DoScriptCompile(Sender);
  if FCompiler.ErrorCount > 0 then
  begin
    if MessageDlg('�ű������д���ȷ�����棿', mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_TABLESAVE;

      ABLLServerReady.ExecParam.S[TTableOper.Table] := 'Comm_DataElementScript';
      ABLLServerReady.ExecParam.S[TTableOper.PrimKeys] := 'DeID';  // �����������";"����
      ABLLServerReady.ExecParam.I['DeID'] := FDeID;  // ������ֵ

      ABLLServerReady.ExecParam.S[TTableOper.Fields] := 'Pascal';
      ABLLServerReady.ExecParam.S['Pascal'] := FFrmScriptIDE.Script;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then
        ShowMessage(ABLLServer.MethodError)
      else
        ShowMessage('��������Ԫ�ű���Ϣ�ɹ���');
    end);
end;

procedure TfrmDeInfo.FormCreate(Sender: TObject);
begin
  FCompiler := TEmrCompiler.CreateByScriptType(nil);
  FCompiler.ResetRegister;
  FCompiler.RegClassVariable(nil, nil, nil, nil);

  FFrmScriptIDE := TfrmScriptIDE.Create(nil);
  FFrmScriptIDE.BorderStyle := bsNone;
  FFrmScriptIDE.Align := alClient;
  FFrmScriptIDE.Parent := Self;
  FFrmScriptIDE.OnProposal := FCompiler.Proposal;
  FFrmScriptIDE.OnCodeCompletion := FCompiler.CodeCompletion;
  FFrmScriptIDE.OnSave := DoScriptSave;
  FFrmScriptIDE.OnCompile := DoScriptCompile;
  FFrmScriptIDE.OnCompilePreview := DoScriptCompilePreview;
  FFrmScriptIDE.Show;
end;

procedure TfrmDeInfo.FormDestroy(Sender: TObject);
begin
  FFrmScriptIDE.Free;
  FCompiler.Free;
end;

procedure TfrmDeInfo.FormShow(Sender: TObject);
begin
  if FDeID > 0 then  // �޸�
  begin
    Caption := '����Ԫά��-' + FDeID.ToString;

    HintFormShow('���ڻ�ȡ����Ԫ��Ϣ...', procedure(const AUpdateHint: TUpdateHint)
    begin
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_GETDEINFO;  // ��ȡ����Ԫ��Ϣ
          ABLLServerReady.ExecParam.I['DeID'] := FDeID;
          ABLLServerReady.BackDataSet := True;
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if ABLLServer.MethodRunOk then  //
          begin
            if AMemTable <> nil then
            begin
              edtCode.Text := AMemTable.FieldByName('decode').AsString;
              edtName.Text := AMemTable.FieldByName('dename').AsString;
              edtPY.Text := AMemTable.FieldByName('py').AsString;
              edtDefine.Text := AMemTable.FieldByName('dedefine').AsString;
              edtType.Text := AMemTable.FieldByName('detype').AsString;
              edtFormat.Text := AMemTable.FieldByName('deformat').AsString;
              edtUnit.Text := AMemTable.FieldByName('deunit').AsString;
              cbbFrmtp.ItemIndex := cbbFrmtp.Items.IndexOf(GetFrmtpText(AMemTable.FieldByName('frmtp').AsString));
              edtDomainID.Text := AMemTable.FieldByName('domainid').AsString;

              FFrmScriptIDE.Script := AMemTable.FieldByName('Pascal').AsString;
            end;
          end
          else
            ShowMessage(ABLLServer.MethodError);
        end);
    end);
  end
  else
    Caption := '�½�����Ԫ'
end;

end.
