{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_Update;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Types, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  System.Generics.Collections, emr_Common, emr_UpDownLoadClient, Vcl.Grids, Vcl.ComCtrls,
  System.IOUtils;

type
  TfrmUpdate = class(TForm)
    btnOK: TButton;
    mmoUpdateExplain: TMemo;
    sgdUpdateFiles: TStringGrid;
    lblHint: TLabel;
    pb: TProgressBar;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FUpDownLoadClient: TUpDownLoadClient;
    FUpdateFiles: TObjectList<TUpdateFile>;  // ��Ÿ��µ��ļ�

    /// <summary> ��ȡ��Ҫ�����������ļ� </summary>
    /// <param name="AMinVersion">��С�汾��</param>
    procedure GetUpdateInfo(const AMinVersion: Integer);

    /// <summary>
    /// ��ȡָ���ļ��ڸ����ļ���������
    /// </summary>
    /// <param name="AFile">�ļ�</param>
    /// <returns>����</returns>
    function GetUpdateFileIndex(const AFile: TUpdateFile): Integer;

    /// <summary> ���ظ����ļ��Ƿ�ɹ� </summary>
    /// <returns>True: ���سɹ�</returns>
    function DownLoadUpdateFiles: Boolean;

    /// <summary> ����Ҫ�������ļ� </summary>
    procedure BackUpUpdateFiles;

    /// <summary> ���غõ��ļ��滻�����ļ� </summary>
    /// <returns>True: �滻�ɹ�</returns>
    function ReplaceUpdateFiles: Boolean;

    /// <summary> ���±������ݿ��г���汾�� </summary>
    /// <param name="AVersionID">�汾��</param>
    procedure UpdateVersion(const AVersionID: Integer);

    /// <summary> ɾ��ָ��ʱ��֮ǰ�ı����ļ� </summary>
    /// <param name="ADays">����</param>
    procedure DeleteBackupFilesBeforeDays(const ADays: Integer);

    /// <summary>
    /// ��ȡָ���ļ�����Gird���ڵ���
    /// </summary>
    /// <param name="AFileName">�ļ���</param>
    /// <returns>��</returns>
    function GetRowByFileName(const AFileName: string): Integer;

    /// <summary> �����µ��ļ���ʾ�ڱ���� </summary>
    procedure ShowUpdateFiles;
  public
    { Public declarations }
  end;

var
  frmUpdate: TfrmUpdate;
  ClientVersionID, LastVersionID: Integer;

implementation

uses
  System.DateUtils, emr_BLLServerProxy, emr_MsgPack, emr_BLLConst, FireDAC.Comp.Client,
  Xml.XMLDoc, Xml.XMLIntf, frm_DM;

{$R *.dfm}

procedure TfrmUpdate.BackUpUpdateFiles;
var
  vFilePath, vFileName: string;
  i: Integer;
begin
  vFilePath := ExtractFilePath(ParamStr(0)) + 'backup\' + FormatDateTime('yyyy-MM-dd hh-mm', Now);
  if not DirectoryExists(vFilePath) then  // ������ǰʱ��ı����ļ���
    CreateDirectory(PChar(vFilePath), nil);
  for i := 0 to FUpdateFiles.Count - 1 do  // �����������ļ�
  begin
    vFileName := ExtractFilePath(ParamStr(0)) + FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName;
    if not FileExists(vFileName) then  // �ļ��������򲻱���
    begin
      pb.Position := pb.Position + 1;
      Continue;
    end;

    if not DirectoryExists(PChar(ExtractFileDir(vFilePath + '\' + FUpdateFiles[i].RelativePath))) then  // �����ļ�������ļ�·������ʱ����
      CreateDirectory(PChar(ExtractFileDir(vFilePath + '\' + FUpdateFiles[i].RelativePath)), nil);

    lblHint.Caption := '���ڱ����ļ� ' + FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName;
    Application.ProcessMessages;
    if not CopyFile(PChar(vFileName), PChar(vFilePath + '\' + FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName), False) then  // �����ļ�
      ShowMessage('�����ļ�' + vFileName + 'ʧ�ܣ������Ƿ�ռ�ã�');
    pb.Position := pb.Position + 1;
  end;
end;

procedure TfrmUpdate.DeleteBackupFilesBeforeDays(const ADays: Integer);
var
  vDirectories: TStringDynArray;
  i: Integer;
  vFileName: string;
begin
  FormatSettings.DateSeparator := '-';
  vDirectories := TDirectory.GetDirectories(ExtractFilePath(ParamStr(0)) + 'backup\');
  for i := 0 to Length(vDirectories) - 1 do
  begin
    vFileName := ExtractFileName(vDirectories[i]);
    if DaysBetween(StrToDateTime(vFileName), Now) > ADays then  // ����ָ��ʱ����ɾ�������ļ���
      TDirectory.Delete(vDirectories[i]);
  end;
end;

function TfrmUpdate.DownLoadUpdateFiles: Boolean;
var
  i: Integer;
  vFileStream: TFileStream;
  vRelativeFilePath, vDecisiveFilePath: string;  // ����ļ�·��
begin
  Result := False;
  if FUpdateFiles.Count = 0 then Exit;  // û�������ļ�

  for i := 0 to FUpdateFiles.Count - 1 do  // ���������ļ�
  begin
    vRelativeFilePath := FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName;  // ��ǰ�����ļ������Update.exe��·��
    sgdUpdateFiles.Row := GetRowByFileName(vRelativeFilePath);  // �����ļ���Grid������
    lblHint.Caption := '���������ļ� ' + vRelativeFilePath;
    sgdUpdateFiles.Cells[3, sgdUpdateFiles.Row] := '��������...';
    Application.ProcessMessages;

    vDecisiveFilePath := ExtractFilePath(ParamStr(0)) + 'upgrade\' + vRelativeFilePath;  // ��ǰ�����ļ��ľ���·��
    if not DirectoryExists(ExtractFilePath(vDecisiveFilePath)) then  // ������ǰ�����ļ���
      CreateDirectory(PChar(ExtractFilePath(vDecisiveFilePath)), nil);

    vFileStream := TFileStream.Create(vDecisiveFilePath, fmCreate or fmOpenWrite);
    try
      if not FUpDownLoadClient.DownLoadFile(vRelativeFilePath, vFileStream,
        procedure(const AReciveSize, AFileSize: Integer)
        begin
          if AReciveSize <> AFileSize then  // �ļ�û��ȫ������
            sgdUpdateFiles.Cells[3, sgdUpdateFiles.Row] := '��������...' + Round(AReciveSize / AFileSize * 100).ToString + '%'
          else  // �ļ�ȫ��������
            sgdUpdateFiles.Cells[3, sgdUpdateFiles.Row] := '�����أ�������...';

          Application.ProcessMessages;
        end)
      then
      begin
        sgdUpdateFiles.Cells[3, sgdUpdateFiles.Row] := '����ʧ��:  ' + FUpDownLoadClient.CurError;
        Exit;
      end;
      pb.Position := pb.Position + 1;
    finally
      vFileStream.Free;
    end;
  end;
  Result := True;
end;

procedure TfrmUpdate.FormCreate(Sender: TObject);
begin
  FUpdateFiles := TObjectList<TUpdateFile>.Create;
  FUpDownLoadClient := TUpDownLoadClient.Create(True);
  btnOk.Enabled := False;  // ��ʼȷ����ť���ɲ���
end;

function TfrmUpdate.GetRowByFileName(const AFileName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to sgdUpdateFiles.RowCount - 1 do
  begin
    if sgdUpdateFiles.Cells[1, i] = AFileName then  // �ҵ��ļ���
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TfrmUpdate.GetUpdateFileIndex(const AFile: TUpdateFile): Integer;
var
  i: Integer;
begin
  Result := - 1;
  for i := 0 to FUpdateFiles.Count - 1 do
  begin
    if (FUpdateFiles[i].RelativePath = AFile.RelativePath)
      and (FUpdateFiles[i].FileName = AFile.FileName)
    then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TfrmUpdate.GetUpdateInfo(const AMinVersion: Integer);
begin
  FUpdateFiles.Clear;
  mmoUpdateExplain.Lines.Clear;
  BLLServerExec(
    procedure(const ABllServerReady: TBLLServerProxy)
    var
      vExecParam: TMsgPack;
    begin
      ABllServerReady.Cmd := BLL_GETUPDATEINFO;  // ��ȡҪ�������ļ�
      vExecParam := ABllServerReady.ExecParam;
      vExecParam.S['MinVersion'] := AMinVersion.ToString;
      ABllServerReady.BackDataSet := True;  // ֪ͨ�����ִ�з������ݼ�
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    var
      i, vIndex: Integer;
      vUpdateFile: TUpdateFile;
      vXml: IXMLDocument;
      vNode: IXMLNode;
    begin
      if not ABLLServer.MethodRunOk then
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;
      if AMemTable <> nil then  // �з�������
      begin
        vXml := TXMLDocument.Create(nil);
        AMemTable.First;
        while not AMemTable.Eof do  // ����ÿһ��������Ϣ
        begin
          // ����˵��
          mmoUpdateExplain.Lines.Add(AMemTable.FieldByName('Version').AsString + '�汾');
          mmoUpdateExplain.Lines.Add('  ' + AMemTable.FieldByName('Explain').AsString);
          // �ϲ������ļ�
          vXml.LoadFromXML(AMemTable.FieldByName('Files').AsString);
          if vXml.DocumentElement.LocalName = 'xml' then
          begin
            for i := 0 to vXml.DocumentElement.ChildNodes.Count - 1 do  // ���������ļ����ϲ�
            begin
              vNode := vXml.DocumentElement.ChildNodes[i];
              vUpdateFile := TUpdateFile.Create(vNode.Text,  // �����ļ���Ϣ
                vNode.Attributes['Path'], vNode.Attributes['Version'],
                vNode.Attributes['Hash'], vNode.Attributes['Size'],
                AMemTable.FieldByName('id').AsInteger,
                AMemTable.FieldByName('Enforce').AsBoolean);

              vIndex := GetUpdateFileIndex(vUpdateFile);  // �Ƿ��������ļ��б����Ѿ�����
              if vIndex < 0 then  // �����������
                FUpdateFiles.Add(vUpdateFile)
              else  // ���������
              if vUpdateFile.VerID > FUpdateFiles[vIndex].VerID then  // �汾����
                FUpdateFiles[vIndex] := vUpdateFile;
            end;
          end;

          AMemTable.Next;
        end;
      end;
    end);
end;

function TfrmUpdate.ReplaceUpdateFiles: Boolean;
var
  i, vRow: Integer;
  vUpdateFile, vReplaceFile: string;
begin
  Result := True;
  for i := 0 to FUpdateFiles.Count - 1 do
  begin
    vUpdateFile := ExtractFilePath(ParamStr(0)) + 'upgrade\' + FUpdateFiles[i].RelativePath +
      FUpdateFiles[i].FileName;
    if not FileExists(vUpdateFile) then  // �����ļ����������滻
    begin
      Result := False;
      ShowMessage('�ļ�' + vUpdateFile + '��ʧ��������������������');
      Break
    end;

    vReplaceFile := ExtractFilePath(ParamStr(0)) + FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName;  // Ҫ�滻���ļ�
    if not DirectoryExists(ExtractFilePath(vReplaceFile)) then  // ������Ҫ�滻���ļ����򴴽�
      CreateDirectory(PChar(ExtractFilePath(vReplaceFile)), nil);

    vRow := GetRowByFileName(FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName);  // ��ȡָ���ļ�����Gird���ڵ���
    sgdUpdateFiles.Row := vRow;  // ѡ�����ڸ��µ���
    sgdUpdateFiles.Cells[3, vRow] := '���ڸ���...';
    lblHint.Caption := '���ڸ����ļ� ' + FUpdateFiles[i].RelativePath + FUpdateFiles[i].FileName;

    Application.ProcessMessages;
    if CopyFile(PChar(vUpdateFile), PChar(vReplaceFile), False) then  // �滻�ļ�
    begin
      sgdUpdateFiles.Cells[3, vRow] := '�Ѹ���';
      pb.Position := pb.Position + 1;
    end
    else
    begin
      Result := False;
      sgdUpdateFiles.Cells[3, vRow] := '�滻�ļ�' + vUpdateFile + 'ʧ�ܣ�ϵͳ����' + Winapi.Windows.GetLastError.ToString;
      //ShowMessage('�滻�ļ�' + vUpdateFile + 'ʧ�ܣ������Ƿ�ռ�ã�');
    end;
  end;
end;

procedure TfrmUpdate.ShowUpdateFiles;
var
  i: Integer;
begin
  for i := 0 to FUpdateFiles.Count - 1 do  // ���������ļ�
  begin
    sgdUpdateFiles.RowCount := sgdUpdateFiles.RowCount + 1;
    sgdUpdateFiles.Cells[0, sgdUpdateFiles.RowCount - 1] := (i + 1).ToString;  // ���
    sgdUpdateFiles.Cells[1, sgdUpdateFiles.RowCount - 1] := FUpdateFiles[i].RelativePath +  // �ļ�·�� + �ļ���
      FUpdateFiles[i].FileName;
    sgdUpdateFiles.Cells[2, sgdUpdateFiles.RowCount - 1] := FormatSize('0.00', FUpdateFiles[i].Size);  // �ļ���С
    sgdUpdateFiles.Cells[3, sgdUpdateFiles.RowCount - 1] := '';  // ��ʼ״̬
  end;
end;

procedure TfrmUpdate.UpdateVersion(const AVersionID: Integer);
begin
  dm.SetParam(PARAM_LOCAL_VERSIONID, IntToStr(AVersionID));
end;

end.
