{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_Emr;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FunctionIntf, PluginIntf,
  emr_Common, CFControl, CFListView, Vcl.StdCtrls,
  Vcl.XPMan, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.AppEvnts;

type
  TfrmEmr = class(TForm)
    lstPlugin: TCFListView;
    xpmnfst: TXPManifest;
    appEvents: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lstPluginDBlClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure appEventsIdle(Sender: TObject; var Done: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure appEventsMessage(var Msg: tagMSG; var Handled: Boolean);
  private
    { Private declarations }
    FPluginManager: IPluginManager;
    FUserInfo: TUserInfo;

    function Frame_CreateCacheTable(const ATableName, AFields: string; const ADelIfExists: Boolean = True): Boolean;
    /// <summary> �ӷ����ͬ������� </summary>
    procedure Frame_SyncCacheTable;

    /// <summary> �г����в�� </summary>
    procedure LoadPluginList;

    // ����ص��¼� ע���PluginFunctionIntf��TFunctionNotifyEvent����һ��
    procedure DoPluginFunction(const APluginID, AFunctionID: string; const AObjFun: IObjectFunction);
  public
    { Public declarations }
    function LoginPluginExecute: Boolean;
  end;

  /// <summary> ����б���Ŀ��Ϣ </summary>
  TFunInfo = class(TObject)
    PlugInID: string;  // ��Ӧ�Ĳ��
    Fun: Pointer;  // ��Ӧ�Ĺ���
    //BuiltIn: Boolean;  // ���ò��
  end;

  /// <summary> ��ȡ���ز��� </summary>
  procedure GetClientParam;

var
  frmEmr: TfrmEmr;

implementation

uses
  frm_DM, PluginImp, FunctionImp, FunctionConst, PluginConst, emr_BLLInvoke,
  emr_MsgPack, System.IniFiles, CFBalloonHint;

{$R *.dfm}

// ����ص��¼� ע���PluginFunctionIntf��TFunctionNotifyEvent����һ��
procedure PluginFunction(const APluginID, AFunID: string; const AObjFun: IObjectFunction);
begin
  frmEmr.DoPluginFunction(APluginID, AFunID, AObjFun);
end;

procedure GetClientParam;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'emr.ini');
  try
    ClientCache.ClientParam.TimeOut := vIniFile.ReadInteger('Client', 'TimeOut', 3000);  // 3��
    ClientCache.ClientParam.VersionID := vIniFile.ReadInteger('Client', PARAM_LOCAL_VERSIONID, 0);

    ClientCache.ClientParam.BLLServerIP := vIniFile.ReadString('BLLServer', PARAM_LOCAL_BLLHOST, '127.0.0.1');  // ҵ������
    ClientCache.ClientParam.BLLServerPort := vIniFile.ReadInteger('BLLServer', PARAM_LOCAL_BLLPORT, 12830);  // ҵ�����˶˿�

    ClientCache.ClientParam.MsgServerIP := vIniFile.ReadString('MsgServer', PARAM_LOCAL_MSGHOST, '127.0.0.1');  // ��Ϣ�����
    ClientCache.ClientParam.MsgServerPort := vIniFile.ReadInteger('MsgServer', PARAM_LOCAL_MSGPORT, 12832);  // ��Ϣ����˶˿�
  finally
    FreeAndNil(vIniFile);
  end;
end;

procedure TfrmEmr.appEventsIdle(Sender: TObject; var Done: Boolean);
//var
//  vIFun: ICustomFunction;
begin
//  vIFun := TCustomFunction.Create;
//  vIFun.ID := FUN_APPEVENTSIDLE;
//  FPluginManager.FunBroadcast(vIFun);
end;

procedure TfrmEmr.appEventsMessage(var Msg: tagMSG; var Handled: Boolean);
var
  i: Integer;
  vIFun: IObjectFunction;
  vEventMessage: TEventMessage;
begin
  vIFun := TObjectFunction.Create;
  vIFun.ID := FUN_APPONMESSAGE;
  vEventMessage := TEventMessage.Create;
  try
    vEventMessage.Msg := Msg;
    vEventMessage.Handled := Handled;

    vIFun.&Object := vEventMessage;

    for i := FPluginManager.Count - 1 downto 0 do
    begin
      if IPlugin(FPluginManager.PluginList[i]).GetFunction(FUN_APPONMESSAGE) <> nil then
        IPlugin(FPluginManager.PluginList[i]).ExecFunction(vIFun);
    end;

    Handled := vEventMessage.Handled;
  finally
    vEventMessage.Free;
  end;
end;

procedure TfrmEmr.DoPluginFunction(const APluginID, AFunctionID: string;
  const AObjFun: IObjectFunction);
var
  vIPlugin: IPlugin;
  vIFun: ICustomFunction;
  vUserCert: TUserCert;
begin
  vIPlugin := FPluginManager.GetPluginByID(APluginID);  // ��ȡ��Ӧ�Ĳ��
  if Assigned(vIPlugin) then  // ��Ч���
  begin
    if AFunctionID = FUN_LOGINCERTIFCATE then  // �����֤
    begin
      vUserCert := TUserCert((AObjFun as IObjectFunction).&object);
      TBLLInvoke.Certification(vUserCert);
      if vUserCert.State = cfsPass then
        FUserInfo.ID := vUserCert.ID;
    end
    else
    if AFunctionID = FUN_USERINFO then  // ��ȡ��ǰ�û���Ϣ
    begin
      if APluginID = PLUGIN_LOGIN then
        FUserInfo.ID := string((AObjFun as IObjectFunction).&object)
      else
        (AObjFun as IObjectFunction).&Object := FUserInfo;
    end
    else
    if AFunctionID = FUN_MAINFORMHIDE then  // ����������
    begin
      // ��ʹ��Hide��Visible=False��ֹ����д����������InitializeNewForm-
      // Screen.AddForm(Self)-Application.UpdateVisible;����������������ť��ʾ
      ShowWindow(Handle, SW_HIDE);
      //ShowWindow(Application.Handle, SW_HIDE);
    end
    else
    if AFunctionID = FUN_MAINFORMSHOW then  // ��ʾ������
    begin
      ShowWindow(Handle, SW_SHOW);
      //ShowWindow(Application.Handle, SW_SHOW);
    end
    else
    if AFunctionID = FUN_CLIENTCACHE then  // ��ȡ�ͻ��˻������
      (AObjFun as IObjectFunction).&Object := ClientCache
    else
    if AFunctionID = FUN_REFRESHCLIENTCACHE then  // ���»�ȡ�ͻ��˻���
      ClientCache.GetCacheData
    else
    if AFunctionID = FUN_LOCALDATAMODULE then  // ��ȡ�������ݿ����DataModule
      (AObjFun as IObjectFunction).&Object := dm
    else  // δ֪��ֱ�ӻص������
    begin
      vIFun := TCustomFunction.Create;
      vIFun.ID := AFunctionID;
      vIPlugin.ExecFunction(vIFun);
    end;
  end
  else
    BalloonMessage('�������ʧ�ܣ���IDΪ"' + APluginID + '"�Ĳ����');
end;

procedure TfrmEmr.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('ȷ��Ҫ�ر�emr�ͻ��ˣ�', mtWarning, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmEmr.FormCreate(Sender: TObject);
begin
  FUserInfo := TUserInfo.Create;
  FPluginManager := TPluginManager.Create;
  LoadPluginList;  // ��ȡ���в����Ϣ
end;

procedure TfrmEmr.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FUserInfo);  // Ϊʲô��FPluginManager := nil;��FreeAndNil(FUserInfo);�����˳�������أ�
end;

procedure TfrmEmr.FormShow(Sender: TObject);
begin
  Frame_SyncCacheTable;  // ���ػ����
end;

function TfrmEmr.Frame_CreateCacheTable(const ATableName, AFields: string; const ADelIfExists: Boolean = True): Boolean;
begin
  Result := False;

  if ADelIfExists then
  begin
    // �����Ѿ��л����ʱ��Ҫ��ɾ��
    dm.qryTemp.Open(Format('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''%s''',
      [ATableName]));
    if dm.qryTemp.FieldByName('tbcount').AsInteger = 1 then  // �����Ѿ��л������
      dm.ExecSql('DROP TABLE ' + ATableName);  // ���±�����֮ǰ��ɾ��������
  end;

  // �ӷ���˲�ѯ��Ҫ����ı��ֶ�����
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    var
      vReplaceParam: TMsgPack;
    begin
      ABLLServerReady.Cmd := BLL_EXECSQL;
      vReplaceParam := ABLLServerReady.ReplaceParam;
      vReplaceParam.S['Sql'] := 'SELECT ' + AFields + ' FROM ' + ATableName;
      ABLLServerReady.BackDataSet := True;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)

      {$REGION ' GetCreateTableSql ���ɴ������ر���� '}
      function GetCreateTableSql: string;
      var
        i: Integer;
        vField: string;
      begin
        Result := '';
        for i := 0 to AMemTable.FieldDefs.Count - 1 do
        begin
          vField := AMemTable.Fields[i].FieldName;  // �ֶ���
          case AMemTable.Fields[i].DataType of  // �ֶ�����
            ftSmallint: vField := vField + ' smallint';

            ftInteger, ftAutoInc: vField := vField + ' int';

            ftCurrency: vField := vField + ' money';

            ftFloat: vField := vField + ' float';

            ftLargeint: vField := vField + ' bigint';

            ftBoolean: vField := vField + ' bit';

            ftDate: vField := vField + ' date';

            ftSingle: vField := vField + ' real';

            ftString:  vField := vField + ' varchar(' + (AMemTable.Fields[i].DataSize - 1).ToString + ')';

            ftWideString: vField := vField + ' nvarchar(' + (AMemTable.Fields[i].DataSize / 2 - 1).ToString + ')';
          else
            vField := vField + ' nvarchar(50)';
          end;
          if AMemTable.Fields[i].ReadOnly then  // �ֶ�������
            vField := vField + ' primary key';
          if Result = '' then
            Result := vField
          else
            Result := Result + ', ' + vField;
        end;
        Result := 'CREATE TABLE ' + ATableName + ' (' + Result + ')';
      end;
      {$ENDREGION}

    begin
      if not ABLLServer.MethodRunOk then
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      dm.conn.ExecSQL(GetCreateTableSql);  // �������ر�

      if AMemTable <> nil then  // ����˱�������
      begin
        dm.qryTemp.Open('SELECT * FROM ' + ATableName);  // �򿪱��ػ����
        dm.qryTemp.CopyDataSet(AMemTable);  // ��������
      end;
    end);

  Result := True;
end;

procedure TfrmEmr.Frame_SyncCacheTable;
begin
  HintFormShow('���ڸ��»����...', procedure(const AUpdateHint: TUpdateHint)
  begin
    BLLServerExec(
      procedure(const ABLLServerReady: TBLLServerProxy)
      begin
        ABLLServerReady.Cmd := BLL_GETCLIENTCACHE;  // ��ȡ����˻������Ϣ
        ABLLServerReady.BackDataSet := True;
      end,
      procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
      var
        vTableName: string;
        vHasCache: Boolean;
      begin
        if not ABLLServer.MethodRunOk then
        begin
          ShowMessage(ABLLServer.MethodError);
          Exit;
        end;

        if AMemTable <> nil then  // �л������Ϣ
        begin
          AMemTable.First;
          while not AMemTable.Eof do
          begin
            vTableName := AMemTable.FieldByName('tbName').AsString;  // ��������

            AUpdateHint('���»���� ' + vTableName);

            if not AMemTable.FieldByName('Used').AsBoolean then  // ��ʹ�õĻ����
            begin
              // ɾ�������Ѿ��еĻ����
              dm.qryTemp.Open(Format('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''%s''',
                [vTableName]));
              if dm.qryTemp.FieldByName('tbcount').AsInteger = 1 then  // �����Ѿ��л������
                dm.ExecSql('DROP TABLE ' + vTableName);  // ɾ��
              // ɾ��������е���Ϣ
              dm.ExecSql(Format('DELETE FROM clientcache WHERE id = %d',
                [AMemTable.FieldByName('id').AsInteger]));
            end
            else
            begin
              dm.qryTemp.Open(Format('SELECT id, tbName, dataVer FROM clientcache WHERE id = %d',
                [AMemTable.FieldByName('id').AsInteger]));  // ��ȡ�����ÿ��������ڱ��ص���Ϣ

              vHasCache := dm.qryTemp.RecordCount > 0;  // ���ػ�����˱�

              if dm.qryTemp.FieldByName('dataVer').AsInteger <> AMemTable.FieldByName('dataVer').AsInteger then  // ���ذ汾С�ڷ���˻򱾵�û�иû����
              begin
                if Frame_CreateCacheTable(vTableName, AMemTable.FieldByName('tbField').AsString) then  // ���±��ػ�������ݳɹ����¼���ػ������Ϣ
                begin
                  if vHasCache then  // ���ػ�����˱�
                  begin
                    dm.ExecSql(Format('UPDATE clientcache SET dataVer = %d WHERE id = %d',
                      [AMemTable.FieldByName('dataVer').AsInteger,
                       AMemTable.FieldByName('id').AsInteger]));
                  end
                  else  // ����û�л�����˱�
                  begin
                    dm.ExecSql(Format('INSERT INTO clientcache (id, tbName, dataVer) VALUES (%d, ''%s'', %d)',
                      [AMemTable.FieldByName('id').AsInteger,
                       vTableName,
                       AMemTable.FieldByName('dataVer').AsInteger]));
                  end;
                end;
              end;
            end;

            AMemTable.Next;
          end;
        end;
      end);
  end);
end;

procedure TfrmEmr.LoadPluginList;
var
  i, j: Integer;
  vIPlugin: IPlugin;
  vIFun: IPluginFunction;
  vFunInfo: TFunInfo;
  vListViewItem: TListViewItem;
  vRunPath: string;
begin
  // �������ò��
  vRunPath := ExtractFilePath(ParamStr(0));
  lstPlugin.BeginUpdate;
  try
    lstPlugin.Clear;
    FPluginManager.LoadPlugins(vRunPath + 'plugin', '.cpi');

    for i := 0 to FPluginManager.Count - 1 do
    begin
      vIPlugin := IPlugin(FPluginManager.PluginList[i]);
      //HintForm.ShowHint(vIPlugin.Name + '��' + vIPlugin.Comment, i);
      //
      for j := 0 to vIPlugin.FunctionCount - 1 do
      begin
        vIFun := vIPlugin.GetFunction(j);
        if vIFun.ShowEntrance then
        begin
          vFunInfo := TFunInfo.Create;
          //vFunInfo.BuiltIn := False;
          vFunInfo.PlugInID := vIPlugin.ID;
          vFunInfo.Fun := Pointer(vIPlugin.GetFunction(j));
          vListViewItem := lstPlugin.AddItem(vIPlugin.Name, vIPlugin.Comment
            + '(' + vIPlugin.Version + ')', nil, vFunInfo);

          if FileExists(vRunPath + 'image\' + vIPlugin.ID + '.png') then
            vListViewItem.ImagePng.LoadFromFile(vRunPath + 'image\' + vIPlugin.ID + '.png');
        end;
      end;
    end;
  finally
    lstPlugin.EndUpdate;
  end;
end;

function TfrmEmr.LoginPluginExecute: Boolean;
var
  vIPlugin: IPlugin;
  vIFunBLLFormShow: IFunBLLFormShow;
begin
  Result := False;
  FUserInfo.ID := '';
  vIPlugin := FPluginManager.GetPluginByID(PLUGIN_LOGIN);
  if Assigned(vIPlugin) then  // �е�¼���
  begin
    vIFunBLLFormShow := TFunBLLFormShow.Create;
    vIFunBLLFormShow.AppHandle := Application.Handle;
    vIFunBLLFormShow.OnNotifyEvent := @PluginFunction;
    vIPlugin.ExecFunction(vIFunBLLFormShow);
    Result := FUserInfo.ID <> '';
  end
  else
    ShowMessage('δ�ҵ���¼�����');
end;

procedure TfrmEmr.lstPluginDBlClick(Sender: TObject);
var
  vIPlugin: IPlugin;
  vIFunSelect: IPluginFunction;
  vIFun: IFunBLLFormShow;
begin
  if lstPlugin.Selected = nil then Exit;

  vIPlugin := FPluginManager.GetPluginByID(TFunInfo(lstPlugin.Selected.ObjectEx).PlugInID);
  if Assigned(vIPlugin) then  // �в��
  begin
    HintFormShow('���ڼ���... ' + vIPlugin.Name, procedure(const AUpdateHint: TUpdateHint)
    begin
      vIFunSelect := IPluginFunction(TFunInfo(lstPlugin.Selected.ObjectEx).Fun);  // ��ȡ�������
      if vIFunSelect <> nil then
      begin
        if vIFunSelect.ID = FUN_BLLFORMSHOW then
        begin
          vIFun := TFunBLLFormShow.Create;
          vIFun.AppHandle := Application.Handle;
          //(vIFun as IDBLFormFunction).UserID := FUserID;
        end
        else
          raise Exception.Create('�쳣����ʶ��Ĺ���ID[������lstEntPlugsDBlClick]��');

        AUpdateHint('����ִ��... ' + vIPlugin.Name + '-' + vIFun.Name);
        vIFun.ShowEntrance := vIFunSelect.ShowEntrance;
        vIFun.OnNotifyEvent := @PluginFunction;
        vIPlugin.ExecFunction(vIFun);
      end;
    end);
  end;
end;

end.
