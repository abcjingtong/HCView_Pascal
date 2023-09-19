{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_BLLServer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ExtCtrls, ComCtrls, diocp_tcp_server, emr_MsgPack,
  System.Generics.Collections, BLLClientContext, emr_Common, emr_DBL;

type
  TfrmBLLServer = class(TForm)
    mm: TMainMenu;
    mniN1: TMenuItem;
    mniStart: TMenuItem;
    mniStop: TMenuItem;
    pgc: TPageControl;
    tsState: TTabSheet;
    ts2: TTabSheet;
    pnl1: TPanel;
    chkLog: TCheckBox;
    btnClear: TButton;
    btnSave: TButton;
    mmoMsg: TMemo;
    mniN3: TMenuItem;
    mniConnect: TMenuItem;
    mniBLLSet: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mniStartClick(Sender: TObject);
    procedure mniStopClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mniBLLSetClick(Sender: TObject);
    procedure mniConnectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FAlias: string;
    /// <summary> �������� </summary>
    FRemoteServer: TRemoteServer;
    FTcpServer: TDiocpTcpServer;
    FLogLocker: TObject;
    FDBL: TDBL;
    // ҵ������ض���
    FAgentLocker: TObject;
    FAgentQueue: TQueue<TBLLAgent>;
    FAgentQueueThread: THCThread;
    /// <summary> �������÷����� </summary>
    procedure ReCreateServer;
    procedure RefreshUIState;
    //
    procedure RemoteProcessAgent(var AAgent: TBLLAgent);
    procedure ProcessAgent(var AAgent: TBLLAgent);
    //
    procedure DoAgentQueueThreadExecute(Sender: TObject);
    procedure DoContextAction(const AStream: TStream; const AContext: TIocpClientContext);
    procedure OnContextConnected(AClientContext: TIocpClientContext);
    procedure DoLog(const ALog: string);
  public
    { Public declarations }
  end;

var
  frmBLLServer: TfrmBLLServer;

implementation

uses
  uFMMonitor, BLLServerParam, DiocpError, emr_DataBase, emr_BLLDataBase,
  frm_ConnSet, frm_BLLSet, utils_zipTools, BLLCompiler, emr_BLLInvoke, System.IniFiles;

{$R *.dfm}

procedure TfrmBLLServer.btnClearClick(Sender: TObject);
begin
  mmoMsg.Clear;
end;

procedure TfrmBLLServer.DoLog(const ALog: string);
begin
  if chkLog.Checked then
  begin
    System.MonitorEnter(FLogLocker);
    try
      mmoMsg.Lines.Add(sLineBreak + '=============='
        + FormatDateTime('YYYY-MM-DD HH:mm:ss', Now)
        + '=============='
        + sLineBreak + ALog);
    finally
      System.MonitorExit(FLogLocker);
    end;
  end;
end;

procedure TfrmBLLServer.DoContextAction(const AStream: TStream; const AContext: TIocpClientContext);
var
  vBLLAgent: TBLLAgent;
begin
  System.MonitorEnter(FAgentLocker);
  try
    vBLLAgent := TBLLAgent.Create(AStream, AContext);
    FAgentQueue.Enqueue(vBLLAgent);  // �������
  finally
    System.MonitorExit(FAgentLocker);
  end;
end;

procedure TfrmBLLServer.DoAgentQueueThreadExecute(Sender: TObject);
var
  vAgent: TBLLAgent;
begin
  if FAgentQueue.Count = 0 then Exit;

  System.MonitorEnter(FAgentLocker);  // ������
  try
    vAgent := FAgentQueue.Dequeue;  // �Ӷ���ȡ������

    if FRemoteServer <> nil then  // ���������
      RemoteProcessAgent(vAgent)  // ��������˴���
    else  // �Ҿ����������
      ProcessAgent(vAgent);
  finally
    System.MonitorExit(FAgentLocker);  // ������
  end;
end;

procedure TfrmBLLServer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FTcpServer.Active then
  begin
    if MessageDlg('ȷ��Ҫֹͣ���ر�emrҵ�����ˣ��رպ�ͻ��˲��ܴ���ҵ��',
      mtWarning, [mbYes, mbNo], 0) = mrYes
    then
    begin
      FTcpServer.SafeStop;
      CanClose := True;
    end
    else
      CanClose := False;
  end;
end;

procedure TfrmBLLServer.FormCreate(Sender: TObject);
var
  FHandle: Cardinal;
begin
  pgc.ActivePageIndex := 0;
  FRemoteServer := nil;
  FLogLocker := TObject.Create;
  FTcpServer := TDiocpTcpServer.Create(Self);
  FTcpServer.CreateDataMonitor;  // �������м�����
  FTcpServer.WorkerCount := 3;
  FTcpServer.RegisterContextClass(TBLLClientContext);
  FTcpServer.OnContextConnected := OnContextConnected;
  TFMMonitor.CreateAsChild(tsState, FTcpServer);
  //
  FAgentQueue := TQueue<TBLLAgent>.Create;
  FAgentLocker := TObject.Create;
  FAgentQueueThread := THCThread.Create;
  FAgentQueueThread.OnExecute := DoAgentQueueThreadExecute;
  //
//  FBLLQueue := TQueue<TBLLAgent>.Create;
//  FBLLLocker := TObject.Create;
//  FBLLQueueThread := THCThread.Create;
//  FBLLQueueThread.OnExecute := DoBLLQueueThreadExecute;
  //
  FDBL := TDBL.Create;
  FDBL.OnExecuteLog := DoLog;
end;

procedure TfrmBLLServer.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FTcpServer);
  FreeAndNil(BLLServerParams);
  FreeAndNil(FDBL);

  if not FAgentQueueThread.Suspended then
  begin
    FAgentQueueThread.Terminate;
    FAgentQueueThread.WaitFor;
  end;
  FreeAndNil(FAgentQueueThread);
  FreeAndNil(FAgentQueue);
  FreeAndNil(FAgentLocker);
  FreeAndNil(FLogLocker);
end;

procedure TfrmBLLServer.FormShow(Sender: TObject);
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'emrBLLServer.ini');
  try
    FAlias := vIniFile.ReadString('RemoteServer', 'Alias', 'emrҵ��(BLL)�����');  // ����

    if vIniFile.ReadBool('RemoteServer', 'AutoStart', False) then  // ������������������
      mniStartClick(Sender);
  finally
    FreeAndNil(vIniFile);
  end;

  RefreshUIState;
end;

procedure TfrmBLLServer.mniConnectClick(Sender: TObject);
var
  vfrmConnSet: TfrmConnSet;
begin
  vfrmConnSet := TfrmConnSet.Create(Self);
  try
    if FileExists(ExtractFilePath(ParamStr(0)) + 'emrBLLServer.ini') then
      vfrmConnSet.FileName := ExtractFilePath(ParamStr(0)) + 'emrBLLServer.ini'
    else
      vfrmConnSet.FileName := '';

    vfrmConnSet.ShowModal;
    if FTcpServer.Active then  // ����������
      ReCreateServer;  // �������������÷����
  finally
    FreeAndNil(vfrmConnSet);
  end;
end;

procedure TfrmBLLServer.mniBLLSetClick(Sender: TObject);
var
  vFrmBLLSet: TfrmBLLSet;
begin
  vFrmBLLSet := TfrmBLLSet.Create(nil);
  try
    vFrmBLLSet.ShowModal;
  finally
    FreeAndNil(vFrmBLLSet);
  end;
end;

procedure TfrmBLLServer.mniStartClick(Sender: TObject);
begin
  try
    ReCreateServer;  // ���÷�����

    pgc.ActivePageIndex := 1;  // �л������ҳ������ͻ������Ӻ���治���л�bug
    FTcpServer.Port := 12830;
    FTcpServer.Active := true;

    if FAgentQueueThread.Suspended then
      FAgentQueueThread.Suspended := False;

    RefreshUIState;
  except
    on E: Exception do
    begin
      Caption := '����ʧ�ܣ�' + E.Message;
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    end;
  end;
end;

procedure TfrmBLLServer.mniStopClick(Sender: TObject);
begin
  FTcpServer.SafeStop;
  FAgentQueueThread.Suspended := True;
  System.MonitorEnter(FAgentLocker);
  try
    FAgentQueue.Clear;
  finally
    System.MonitorExit(FAgentLocker);
  end;

  RefreshUIState;
end;

procedure TfrmBLLServer.OnContextConnected(AClientContext: TIocpClientContext);
begin
  TBLLClientContext(AClientContext).OnContextAction := DoContextAction;
end;

procedure TfrmBLLServer.ProcessAgent(var AAgent: TBLLAgent);
var
  vStream: TMemoryStream;
begin
  try
    vStream := TMemoryStream.Create;
    try
      AAgent.Stream.Position := 0;
      TZipTools.UnZipStream(AAgent.Stream, vStream);  // ��ѹ��
      vStream.Position := 0;
      FDBL.MsgPack.DecodeFromStream(vStream);  // ���
      FDBL.ExecuteMsgPack;  // ִ��
      vStream.Clear;
      FDBL.MsgPack.EncodeToStream(vStream);  // ���
      vStream.Position := 0;
      TZipTools.ZipStream(vStream, AAgent.Stream);  // ѹ������
      AAgent.Stream.Position := 0;
      TBLLClientContext(AAgent.Context).SendStream(AAgent.Stream);  // ���͵��ͻ���
    finally
      vStream.Free;
    end;
  finally
    FreeAndNil(AAgent);
  end;
end;

procedure TfrmBLLServer.ReCreateServer;
begin
  if BLLServerParams = nil then
    BLLServerParams := TBLLServerParams.Create(ExtractFilePath(ParamStr(0)) + 'emrBLLServer.ini');

  if BLLServerParams.RemoteActive then  // ָ�����ⲿ��������
  begin
    if FRemoteServer = nil then  // δ�������ⲿ������
      FRemoteServer := TRemoteServer.CreateEx(BLLServerParams.RemoteBLLIP, BLLServerParams.RemoteBLLPort);

    if FDBL.DB.Connected then
      FDBL.DB.DisConnect;
  end
  else  // ������Ϊ��������
  begin
    if not FDBL.DB.Connected then
    begin
      FDBL.DB.DBType := dbSqlServer;
      FDBL.DB.Server := BLLServerParams.DataBaseServer;
      FDBL.DB.DBName := BLLServerParams.DataBaseName;
      FDBL.DB.Username := BLLServerParams.DataBaseUsername;
      FDBL.DB.Password := BLLServerParams.DataBasePassword;
      FDBL.DB.Connect;
    end;

    FreeAndNil(FRemoteServer);
  end;
end;

procedure TfrmBLLServer.RefreshUIState;
begin
  mniStart.Enabled := not FTcpServer.Active;
  if FTcpServer.Active then
    Caption := FAlias + '[����]' + FTcpServer.DefaultListenAddress + ' �˿�:' + IntToStr(FTcpServer.Port)
  else
    Caption := FAlias + '[ֹͣ]';

  mniStop.Enabled := FTcpServer.Active;
  mniBLLSet.Enabled := mniStop.Enabled;
end;

procedure TfrmBLLServer.RemoteProcessAgent(var AAgent: TBLLAgent);
var
  vMsgPack: TMsgPack;
  vStream: TMemoryStream;
  vCMD: Integer;
  vDBLSrvProxy: TBLLServerProxy;
  vErrorInfo: string;
begin
  vMsgPack := TMsgPack.Create;
  try
    vStream := TMemoryStream.Create;
    try
      AAgent.Stream.Position := 0;
      TZipTools.UnZipStream(AAgent.Stream, vStream);  // ��ѹ��
      vStream.Position := 0;
      vMsgPack.DecodeFromStream(vStream);  // �����н��
      vCMD := vMsgPack.I[BLL_CMD];

      try
        vDBLSrvProxy := TBLLServerProxy.CreateEx(FRemoteServer.Host, FRemoteServer.Port);
        try
          vDBLSrvProxy.ReConnectServer;
          if vDBLSrvProxy.Active then  // ������ӳɹ�
          begin
            if not vDBLSrvProxy.DispatchPack(vMsgPack) then
            begin
              vErrorInfo := GetDiocpErrorMessage(vDBLSrvProxy.ErrCode);
              if vErrorInfo = '' then
                vErrorInfo := SysErrorMessage(GetLastError);
              vMsgPack.Clear;
              vMsgPack.ForcePathObject(BLL_CMD).AsInteger := vCMD;
              vMsgPack.ForcePathObject(BACKRESULT).AsBoolean := False;
              vMsgPack.ForcePathObject(BACKMSG).AsString := vErrorInfo;
              DoLog('�����ⲿ�������' + vCMD.ToString + '��' + vErrorInfo);
            end;
          end;
        finally
          FreeAndNil(vDBLSrvProxy);
        end;
      except  // �����쳣��Ϣ
        on E:Exception do
        begin
          vMsgPack.Clear;
          vMsgPack.ForcePathObject(BLL_CMD).AsInteger := vCMD;
          vMsgPack.ForcePathObject(BACKRESULT).AsBoolean := False;
          vMsgPack.ForcePathObject(BACKMSG).AsString := E.Message;
          DoLog('�����ⲿ�������' + vCMD.ToString + '��' + E.Message);
        end;
      end;

      // ׼���������ú�����ݽ��
      vStream.Clear;
      vMsgPack.EncodeToStream(vStream);  // �������
      vStream.Position := 0;
      TZipTools.ZipStream(vStream, AAgent.Stream);  // ѹ������
      AAgent.Stream.Position := 0;
      TBLLClientContext(AAgent.Context).SendStream(AAgent.Stream);  // ���͵��ͻ���
    finally
      FreeAndNil(vStream);
    end;
  finally
    FreeAndNil(vMsgPack);
    FreeAndNil(AAgent);
  end;
end;

end.
