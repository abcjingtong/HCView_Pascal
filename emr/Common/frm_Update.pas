unit frm_Update;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UPClient, UPMsgPack,
  Xml.XMLDoc, Xml.XMLIntf, System.IniFiles, Vcl.StdCtrls, Vcl.Grids;

type
  TFileProcess = procedure(const APos, ASize: Cardinal) of object;

  TfrmUpdate = class(TForm)
    sgdFiles: TStringGrid;
    mmo: TMemo;
    btnDownLoad: TButton;
    chkBackup: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDownLoadClick(Sender: TObject);
  private
    { Private declarations }
    FClient: TUPClient;
    FIniFile: TIniFile;
    FVerNo,  // ���ذ汾���
    FLastVerNo,  // ���µİ汾���
    FDownFileIndex
      : Integer;

    FDownPath: string;  // �ͻ���·��(��������\)

    procedure UpdateDownLoadHint(const AIndex: Integer; const AHint: string);

    /// <summary> ��ʾ������Ϣ(�����ļ�) </summary>
    procedure ShowUpdateInfo(const AMsgPack: TUPMsgPack);

    procedure FileProcess(const APos, ASize: Cardinal);
    /// <summary> ��������Ҫ�������ļ� </summary>
    procedure DownLoadAllUpdateFile;
    /// <summary> ����ĳ��Ҫ�������ļ������ݺ��滻 </summary>
    procedure DownLoadAndUpdateAFile(const APath, AName: string;
      const AFileProc: TFileProcess);
  public
    { Public declarations }
    function CheckUpdate: Boolean;
  end;

function HCUpdate(const ABackUp: Boolean = False): Boolean;

implementation

uses
  UPCommon, Winapi.ShellAPI;

function HCUpdate(const ABackUp: Boolean = False): Boolean;
var
  vFrmUpdate: TfrmUpdate;
begin
  Result := False;

  vFrmUpdate := TfrmUpdate.Create(nil);
  try
    vFrmUpdate.chkBackup.Checked := ABackUp;
    Result := vFrmUpdate.CheckUpdate;
  finally
    FreeAndNil(vFrmUpdate);
  end;
end;

{$R *.dfm}

procedure TfrmUpdate.btnDownLoadClick(Sender: TObject);
begin
  if btnDownLoad.Tag = 0 then  // δ�������
  begin
    btnDownLoad.Enabled := False;
    chkBackup.Enabled := False;

    TThread.CreateAnonymousThread(procedure()
      begin
        DownLoadAllUpdateFile;  // ��������Ҫ�������ļ����滻

        Self.BorderIcons := Self.BorderIcons - [biSystemMenu];
        FIniFile.WriteInteger('version', 'lastverno', FLastVerNo);  // д�����°汾���
        btnDownLoad.Caption := '���';
        btnDownLoad.Tag := 1;
        btnDownLoad.Enabled := True;
      end).Start;
  end
  else  // ������ɣ�����updaterp.exe
  begin
    ShellExecute(Handle, 'open', PChar(FDownPath + '\updaterp.exe'),
      PChar(ParamStr(0)), nil, SW_SHOW);

    Self.ModalResult := mrOk;
  end;
end;

function TfrmUpdate.CheckUpdate: Boolean;
var
  vMsgPack: TUPMsgPack;
begin
  Result := False;

  FVerNo := FIniFile.ReadInteger('version', 'verno', 0);

  FClient.Host := FIniFile.ReadString('connect', 'host', '127.0.0.1');
  FClient.Port := FIniFile.ReadInteger('connect', 'port', 12840);
  FClient.ReConnectServer;  // iocp
  //FClient.Connect;  // idtcp
  if FClient.Connected then
  begin
    vMsgPack := TUPMsgPack.Create;
    try
      vMsgPack.I[MSG_CMD] := CMD_CHECKVERSION;
      vMsgPack.I[HCUP_VERNO] := FVerNo;
      FClient.PostMsgPack(vMsgPack);  // �����°汾
      FClient.ReceiveMsgPack(vMsgPack);
      if vMsgPack.I[HCUP_VERNO] <> FVerNo then  // ���°汾
      begin
        FLastVerNo := vMsgPack.I[HCUP_VERNO];
        ShowUpdateInfo(vMsgPack);
        Result := True;
      end;
    finally
      FreeAndNil(vMsgPack);
    end;
  end;
end;

procedure TfrmUpdate.DownLoadAllUpdateFile;
var
  i: Integer;
begin
  for i := 1 to sgdFiles.RowCount - 1 do
    sgdFiles.Cells[4, i] := '�ȴ�...';

  for i := 1 to sgdFiles.RowCount - 1 do
  begin
    sgdFiles.Row := i;
    FDownFileIndex := i;
    UpdateDownLoadHint(FDownFileIndex, '��������...');
    DownLoadAndUpdateAFile(sgdFiles.Cells[3, i], sgdFiles.Cells[0, i], FileProcess);
  end;

  if not FileExists(FDownPath + '\updaterp.exe') then
  begin
    mmo.Lines.Add('���������滻�ļ� updaterp.exe');
    DownLoadAndUpdateAFile('\', 'updaterp.exe', nil);
    mmo.Lines.Add('����������ɣ�');
  end;
end;

procedure TfrmUpdate.DownLoadAndUpdateAFile(const APath, AName: string;
  const AFileProc: TFileProcess);
var
  vMsgPack: TUPMsgPack;
  vStream: TMemoryStream;
  vFile: string;
  vPos, vFileSize: Cardinal;
  vRect: TRect;
begin
  vPos := 0;
  vFileSize := 0;

  vMsgPack := TUPMsgPack.Create;
  try
    vStream := TMemoryStream.Create;
    try
      while True do
      begin
        vMsgPack.Clear;
        vMsgPack.I[MSG_CMD] := CMD_DOWNLOADFILE;
        vMsgPack.S[HCUP_FILEPATH] := APath + AName;
        vMsgPack.I[HCUP_FILEPOS] := vPos;
        FClient.PostMsgPack(vMsgPack);  // �����ļ�
        //Sleep(1);
        FClient.ReceiveMsgPack(vMsgPack);

        vPos := vMsgPack.I[HCUP_FILEPOS];
        if vPos = 0 then
        begin
          mmo.Lines.Add('����ʧ�ܣ������ȱʧ�ļ���' + APath + AName);
          Exit;
        end;

        if vFileSize = 0 then
        begin
          vFileSize := vMsgPack.I[HCUP_FILESIZE];
          vStream.Size := vFileSize;
        end;

        vMsgPack.ForcePathObject(HCUP_FILE).SaveBinaryToStream(vStream);

        if Assigned(AFileProc) then
          AFileProc(vPos, vFileSize); // ���½�����ʾ

        if vPos = vFileSize then  // ��������
          Break;
      end;

      UpdateDownLoadHint(FDownFileIndex, '�����滻...');

      if not DirectoryExists(FDownPath + APath) then  // ����û�д�Ŀ¼�򴴽�
        ForceDirectories(FDownPath + APath);

      vFile := FDownPath + APath + AName;
      if vFile = ParamStr(0) then  // Ҫ�����Լ�
      begin
        FIniFile.WriteString('file', 'rp', vFile);  // ��¼��Ҫ����ռ�õ����г���
        FIniFile.WriteString('file', 'rpbackup', FDownPath + '\backup' + APath);
        vFile := vFile + '.temp';  // �����������ļ�������
      end
      else  // ���������Լ�
      if chkBackup.Checked then // ����ԭ�ļ�
      begin
        UpdateDownLoadHint(FDownFileIndex, '���ڱ���...');

        if FileExists(vFile) then
        begin
          if not DirectoryExists(FDownPath + '\backup' + APath) then  // ����û�б���Ŀ¼�򴴽�
            ForceDirectories(FDownPath + '\backup' + APath);

          MoveFile(PChar(vFile), PChar(FDownPath + '\backup' + APath + AName));  // �ƶ���������
        end;
      end;

      UpdateDownLoadHint(FDownFileIndex, '���ڱ���...');
      vStream.SaveToFile(vFile);  // ���ص����ļ����浽��Ӧλ��
      UpdateDownLoadHint(FDownFileIndex, '��ɣ�');
    finally
      FreeAndNil(vStream);
    end;
  finally
    FreeAndNil(vMsgPack);
  end;
end;

procedure TfrmUpdate.FileProcess(const APos, ASize: Cardinal);
begin
  UpdateDownLoadHint(FDownFileIndex, FormatFloat('#%', APos / ASize * 100));
end;

procedure TfrmUpdate.FormCreate(Sender: TObject);
begin
  Caption := Application.Title + '-����';

  FDownPath := ExtractFilePath(ParamStr(0));
  Delete(FDownPath, Length(FDownPath), 1);

  FIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'update.ini');

  if not FIniFile.SectionExists('version') then
  begin
    FIniFile.WriteInteger('version', 'verno', 0);
    FIniFile.WriteInteger('version', 'lastverno', 0);
  end;

  if not FIniFile.SectionExists('connect') then
  begin
    FIniFile.WriteString('connect', 'host', '127.0.0.1');
    FIniFile.WriteInteger('connect', 'port', 12840);
  end;

  FIniFile.WriteString('file', 'run', ParamStr(0));

  FClient := TUPClient.Create;

  FDownFileIndex := -1;
  sgdFiles.ColCount := 5;
  sgdFiles.ColWidths[0] := 80;
  sgdFiles.ColWidths[1] := 100;
  sgdFiles.ColWidths[2] := 100;
  sgdFiles.ColWidths[3] := 150;
  sgdFiles.ColWidths[4] := 80;
  //
  sgdFiles.Cells[0, 0] := '�ļ���';
  sgdFiles.Cells[1, 0] := '�汾';
  sgdFiles.Cells[2, 0] := '��С';
  sgdFiles.Cells[3, 0] := '�ͻ���·��';
  sgdFiles.Cells[4, 0] := '���ؽ���';
end;

procedure TfrmUpdate.FormDestroy(Sender: TObject);
begin
  FClient.Free;
  FreeAndNil(FIniFile);
end;

procedure TfrmUpdate.ShowUpdateInfo(const AMsgPack: TUPMsgPack);
var
  vXmlDoc: IXMLDocument;
  vFileNode: IXMLNode;
  vStream: TMemoryStream;
  i: Integer;
begin
  vXmlDoc := TXMLDocument.Create(nil);
  // ȡ��Ҫ�������ļ�
  vStream := TMemoryStream.Create;
  try
    AMsgPack.ForcePathObject(HCUP_UPDATEFILES).SaveBinaryToStream(vStream);
    vStream.Position := 0;
    vXmlDoc.LoadFromStream(vStream);
    //vXmlDoc.SaveToFile('c:\a.xml');
    //vXmlDoc.DocumentElement.Attributes['upfver'] = '1';
    mmo.Clear;
    mmo.Lines.Add('�汾��ţ�' + vXmlDoc.DocumentElement.Attributes['verno']);
    mmo.Lines.Add('�汾�ţ�' + vXmlDoc.DocumentElement.Attributes['version']);
    mmo.Lines.Add('����˵����' + vXmlDoc.DocumentElement.Attributes['memo']);

    sgdFiles.RowCount := vXmlDoc.DocumentElement.ChildNodes.Count + 1;
    if sgdFiles.RowCount > 1 then
      sgdFiles.FixedRows := 1;

    for i := 0 to vXmlDoc.DocumentElement.ChildNodes.Count - 1 do
    begin
      vFileNode := vXmlDoc.DocumentElement.ChildNodes[i];
      sgdFiles.Cells[0, i + 1] := vFileNode.Text;
      sgdFiles.Cells[1, i + 1] := vFileNode.Attributes['version'];
      sgdFiles.Cells[2, i + 1] := BytesToStr(vFileNode.Attributes['size']);
      sgdFiles.Cells[3, i + 1] := vFileNode.Attributes['path'];
    end;

    Self.ShowModal;
  finally
    FreeAndNil(vStream);
  end;

  FVerNo := AMsgPack.I[HCUP_VERNO];
end;

procedure TfrmUpdate.UpdateDownLoadHint(const AIndex: Integer;
  const AHint: string);
var
  vRect: TRect;
begin
  sgdFiles.Cells[4, AIndex] := AHint;
  vRect := sgdFiles.CellRect(4, AIndex);
  InvalidateRect(sgdFiles.Handle, vRect, False);
  UpdateWindow(sgdFiles.Handle);
end;

end.
