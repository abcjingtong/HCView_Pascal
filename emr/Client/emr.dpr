program emr;

{$IFDEF not DEBUG}
  {$IF CompilerVersion >= 21.0}
    {$WEAKLINKRTTI ON}
    {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$IFEND}
{$ENDIF}

uses
  System.ShareMem,
  Vcl.Forms,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  Winapi.Windows,
  Winapi.ShellAPI,
  emr_Common,
  frm_Hint,
  frm_ConnSet,
  frm_Emr in 'frm_Emr.pas' {frmEmr},
  frm_DM in '..\Common\frm_DM.pas' {dm: TDataModule},
  frm_Update in '..\Common\frm_Update.pas',
  UPCommon in '..\Common\UPCommon.pas',
  UPClient in '..\Common\UPClient.pas',
  UPMsgPack in '..\Common\UPMsgPack.pas',
  UPMsgCoder in '..\Common\UPMsgCoder.pas';

{$R *.res}

const
  STR_UNIQUE = '{CC1EB815-7992-41F5-B112-571DE13CD8DF}';

var
  vFrmHint: TfrmHint;
  vMutHandle: THandle;
  vFrmConnSet: TfrmConnSet;
begin
  vMutHandle := OpenMutex(MUTEX_ALL_ACCESS, False, STR_UNIQUE);  // �򿪻������
  if vMutHandle = 0 then
    vMutHandle := CreateMutex(nil, False, STR_UNIQUE) // �����������
  else
  begin
    ShowMessage('EMR�ͻ����Ѿ������У�');
    Exit;
  end;

  Application.Initialize;
  Application.Title := '���Ӳ���';
  Application.MainFormOnTaskbar := False;

  {$IFNDEF DEBUG}
  if HCUpdate then Exit;
  {$ENDIF};

  vFrmHint := TfrmHint.Create(nil);
  try
    vFrmHint.Show;
    vFrmHint.UpdateHint('��������EMR�ͻ��ˣ����Ժ�...');

    if not Assigned(ClientCache) then
      ClientCache := TClientCache.Create;

    GetClientParam;  // ��ȡ���ز���

    dm := Tdm.Create(nil);

    try
      vFrmHint.UpdateHint('���ڼ��ػ��棬���Ժ�...');
      ClientCache.GetCacheData;
    except
      on E: Exception do
      begin
        if MessageDlg('EMR�ͻ������������쳣�����������ý��棿' + #13#10 + #13#10
          + '�쳣��Ϣ��' + E.Message,
          TMsgDlgType.mtError, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes
        then
        begin
          FreeAndNil(vFrmHint);
          Application.CreateForm(TFrmConnSet, vFrmConnSet);
  // �����������ý���
          Application.Run;
        end;

        FreeAndNil(vFrmConnSet);
        if Assigned(ClientCache) then
          FreeAndNil(ClientCache);

        FreeAndNil(dm);

        Exit;
      end;
    end;

    vFrmHint.UpdateHint('���������������Ժ�...');
    Application.CreateForm(TfrmEmr, frmEmr);
  finally
    FreeAndNil(vFrmHint);
  end;

  if frmEmr.LoginPluginExecute then  // ��¼�ɹ�
    Application.Run;

  FreeAndNil(frmEmr);
  FreeAndNil(dm);
  if Assigned(ClientCache) then
    FreeAndNil(ClientCache);
end.
