program emrUpdate;

uses
  Vcl.Forms,
  System.SysUtils,
  Dialogs,
  Winapi.Windows,
  Winapi.ShellAPI,
  Winapi.TlHelp32,
  frm_DM,
  emr_Common,
  frm_Update in 'frm_Update.pas' {frmUpdate},
  emr_UpDownLoadClient in '..\Common\emr_UpDownLoadClient.pas';

{$R *.res}

function FindMvsProcessID: DWORD;
var
  vSnapShot: DWORD;
  vPE: TProcessEntry32;
  vFound: Boolean;
begin
  Result := 0;
  vSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);  // ��ϵͳ�����еĽ����ĸ�����
  vPE.dwSize := SizeOf(TProcessEntry32);  // ��ʹ������ṹǰ�����������Ĵ�С

  // �������̿��գ�������ʾÿ�����̵���Ϣ
  vFound := Process32First(vSnapShot, vPE);
  while vFound do
  begin
    if (UpperCase(ExtractFileName(vPE.szExeFile)) = 'EMR.EXE') or (UpperCase(vPE.szExeFile) = 'EMR.EXE') then
    begin
      Result := vPE.th32ProcessID;  // �ҵ�emr.exe����ID
      Break;
    end;
    vFound := Process32Next(vSnapShot, vPE);
  end;
end;

var
  EMRProcessID: DWORD;
  AppProcess: THandle;
  vVerStr: string;
begin
  Application.Initialize;
  try
    GetLastVersion(LastVersionID, vVerStr);  // ��ȡ����˵�ǰ���µĿͻ��˰汾��
    ClientVersionID := StrToIntDef(dm.GetParamStr('VersionID'), 0);  // ���ؿͻ��˰汾��

    if ClientVersionID > LastVersionID then  // �ͻ��˰�������µĿͻ��˰汾����(������)
      raise Exception.Create('�쳣���ͻ��˰���ڷ���˰汾���������ף�')
    else
    if ClientVersionID < LastVersionID then  // ����
    begin
      EMRProcessID := FindMvsProcessID;  // ��emr.exe����ID
      if EMRProcessID > 0 then  // �ҵ�mvs.exe����ID
      begin
        AppProcess := OpenProcess(PROCESS_VM_OPERATION or Winapi.Windows.SYNCHRONIZE,FALSE, EMRProcessID);  // �򿪽��̣���ȡȨ��
        WaitForSingleObject(AppProcess, INFINITE);  // �ȴ�mvs.exe���̹ر�
      end;

      Application.CreateForm(TfrmUpdate, frmUpdate);
    end
    else
    begin
      ShowMessage('emrϵͳ��ǰ�Ѿ������°汾��');
      Exit;
    end;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  Application.Run;
  Application.Run;
end.
