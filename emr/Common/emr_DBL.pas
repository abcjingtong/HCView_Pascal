{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit emr_DBL;

interface

uses
  Winapi.Windows, Classes, SysUtils, DB, Provider, FireDAC.Comp.Client, FireDAC.Stan.Intf,
  FireDAC.Stan.StorageBin, emr_DataBase, emr_BLLDataBase, emr_MsgPack,
  BLLCompiler;

Type
  TExecutelog = procedure(const ALog: string) of object;

  TDBL = class(TObject)  // DataBase Logic
  private
    FDB: TDataBase;
    FBLLDB: TBLLDataBase;
    FMsgPack: TMsgPack;
    // ҵ��ű���Ҫ�ı���
    FBLLObj: TBLLObj;
    FScriptBin: TMemoryStream;
    FCompiler: TBLLCompiler;
    //
    FOnExecuteLog: TExecuteLog;
    procedure DoCompilerException(const E: Exception; const ModuleName: String; SourceLineNumber: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExecuteMsgPack;
    property DB: TDataBase read FDB;
    property MsgPack: TMsgPack read FMsgPack;
    property OnExecuteLog: TExecutelog read FOnExecuteLog write FOnExecuteLog;
  end;

implementation

uses
  emr_MsgConst;

{ TBLLServerMethod }

constructor TDBL.Create;
begin
  FDB := TDataBase.Create(nil);
  FBLLDB := TBLLDataBase.Create;
  FMsgPack := TMsgPack.Create;
  FBLLObj := TBLLObj.Create;
  FCompiler := TBLLCompiler.CreateByScriptType(nil);
  FCompiler.ResetRegister;
  FCompiler.RegClassVariable(@FMsgPack, @FBLLObj);
  FCompiler.OnException := DoCompilerException;

  FScriptBin := TMemoryStream.Create;
end;

destructor TDBL.Destroy;
begin
  FreeAndNil(FDB);
  FreeAndNil(FBLLDB);
  FreeAndNil(FMsgPack);
  FreeAndNil(FCompiler);
  FreeAndNil(FBLLObj);
  FreeAndNil(FScriptBin);
  inherited Destroy;
end;

procedure TDBL.DoCompilerException(const E: Exception; const ModuleName: String;
  SourceLineNumber: Integer);
begin
  FBLLObj.ErrorInfo := '�ű������쳣��' + E.Message
    + sLineBreak + 'ģ��' + ModuleName + '�������У�' + IntToStr(SourceLineNumber + 1) // + FCompiler.Modules[ModuleName][SourceLineNumber]
    + sLineBreak + '��ջ��' + E.StackTrace;
end;

procedure TDBL.ExecuteMsgPack;

  function IsSelectSql(const ASql: string): Boolean;
  begin
    Result := LowerCase(Copy(TrimLeft(ASql), 1, 6)) = 'select';
  end;

  function IsInsertSql(const ASql: string): Boolean;
  begin
    Result := LowerCase(Copy(TrimLeft(ASql), 1, 6)) = 'insert';
  end;

  procedure DoBackErrorMsg(const AMsg: string);
  begin
    FMsgPack.Clear;  // ���ͻ��˵���ʱ�����Ĳ���ֵ����������ٲ���Ҫ�Ļش�������
    FMsgPack.S[BLL_METHODMSG] := AMsg;
    if Assigned(FOnExecuteLog) then
      FOnExecuteLog(AMsg);
  end;

var
  vQuery: TFDQuery;
  vBLLDataBase: TDataBase;
  vBLLDataBaseID: Integer;
  vFrameSql: string;

  function CheckBllDataBase: Boolean;
  begin
    Result := False;
    try
      if vBLLDataBaseID > 0 then
      begin
        vFrameSql := Format('SELECT dbtype, server, port, dbname, username, paw FROM frame_blldbconn WHERE id=%d',
          [vBLLDataBaseID]);
        vQuery.Close;
        vQuery.SQL.Text := vFrameSql;
        vQuery.Open;

        vBLLDataBase := FBLLDB.GetBLLDataBase(vBLLDataBaseID,
          vQuery.FieldByName('dbtype').AsInteger,
          vQuery.FieldByName('server').AsString,
          vQuery.FieldByName('port').AsInteger,
          vQuery.FieldByName('dbname').AsString,
          vQuery.FieldByName('username').AsString,
          vQuery.FieldByName('paw').AsString);
      end
      else
        vBLLDataBase := FDB;

      Result := True;
    except
      on E: Exception do
        DoBackErrorMsg(Format('�쳣(�����)��û���ҵ�ConnIDΪ %d ��ҵ������������Ϣ', [vBLLDataBaseID])
          + sLineBreak + '��䣺' + vFrameSql + sLineBreak + '������Ϣ��' + E.Message);
    end;
  end;

var
  //vData: OleVariant;
  vDeviceType: TDeviceType;
  i, j, vCMD, vVer, vRecordCount, vIDENTITY: Integer;
  vProvider: TDataSetProvider;
  vExecParams, vReplaceParams, vBatchData, vBackParam: TMsgPack;
  vBLLSql, vBLLScript, vBLLInfo: string;
  vMemStream: TMemoryStream;
  vMemTable: TFDMemTable;
  vBlobField: TBlobField;
  vTick: Cardinal;
  vScriptRunOk: Boolean;
begin
  FMsgPack.Result := False;

  vCMD := FMsgPack.ForcePathObject(BLL_CMD).AsInteger;
  vDeviceType := TDeviceType(FMsgPack.I[BLL_DEVICE]);
  vVer := FMsgPack.I[BLL_VER];
  vBLLScript := '';
  vBLLInfo := '[' + vCMD.ToString + ']';
  vQuery := FDB.GetQuery;
  try
    // ȡҵ����䲢��ѯ
    vFrameSql := Format('SELECT dbconnid, sqltext, name, script, scriptbin FROM frame_bllsql WHERE bllid = %d AND ver = %d',
      [vCMD, vVer]);

    vQuery.Close;
    vQuery.SQL.Text := vFrameSql;

    try
      vQuery.Open;
    except
      on E: Exception do
      begin
        DoBackErrorMsg('�쳣(�����)��ȡҵ' + vBLLInfo
          + sLineBreak + '��䣺' + vFrameSql + sLineBreak + '������Ϣ��' + E.Message);

        Exit;
      end;
    end;

    if vQuery.RecordCount = 1 then  // ��ѯ��Ψһ
    begin
      try
        vBLLInfo := vBLLInfo + vQuery.FieldByName('name').AsString;  // ҵ������
        // ȡ�����ҵ������ݿ����Ӷ���
        vBLLDataBaseID := vQuery.FieldByName('dbconnid').AsInteger;
        vBLLSql := vQuery.FieldByName('sqltext').AsString;
        vBLLScript := vQuery.FieldByName('script').AsString;

        if vBLLScript <> '' then
        begin
          vBlobField := vQuery.FieldByName('scriptbin') as TBlobField;
          FScriptBin.SetSize(vBlobField.BlobSize);
          FScriptBin.Position := 0;
          vBlobField.SaveToStream(FScriptBin);
          //vQuery.FieldByName('scriptbin').GetData(FScriptBin.Memory, False);
        end;

        if CheckBllDataBase then
        begin
          vFrameSql := '';
          vQuery.Close;
          vQuery.Connection := vBLLDataBase.Connection;

          vRecordCount := 0;
          vIDENTITY := 0;

          if vBLLScript <> '' then
          begin
            FBLLObj.DB := FDB;
            FBLLObj.BLLDB := vBLLDataBase;
            FBLLObj.BLLQuery := vQuery;
            FBLLObj.DebugInfoClear;

            vScriptRunOk := False;
            vTick := GetTickCount;
            // ��ֹ�ű����ô���򿪺󽫱�������Ϊnil�������ʹ�ýű����ô������ȥ����2�У��� 20190719001
            FCompiler.ResetRegister;
            FCompiler.RegClassVariable(@FMsgPack, @FBLLObj);

            try
              if FScriptBin.Size = 0 then
              //if True then
              begin
                // 20190719001
                //FCompiler.ResetRegister;
                //FCompiler.RegClassVariable(@FMsgPack, @FBLLObj);
                vScriptRunOk := FCompiler.RunScript(vBLLScript);
              end
              else
                vScriptRunOk := FCompiler.RunScriptBin(FScriptBin);
            except
              // ������Ϣͨ�� DoCompilerException ���ݸ� BLLObj.ErrorInfo��
            end;

            if not vScriptRunOk then  // �ű����г���
            begin
              vBLLInfo := vBLLInfo + ' ʧ�ܣ�';
              if FBLLObj.ErrorInfo <> '' then
                vBLLInfo := vBLLInfo + sLineBreak + '�쳣��' + FBLLObj.ErrorInfo;

              if FCompiler.ErrorCount > 0 then
              begin
                vBLLInfo := vBLLInfo + sLineBreak + 'ҵ��ű��� ' + IntToStr(FCompiler.ErrorCount) + ' ������';
                for i := 0 to FCompiler.ErrorCount - 1 do
                begin
                  vBLLInfo := vBLLInfo + sLineBreak + '  '
                    + IntToStr(FCompiler.ErrorLineNumber[i] + 1) + '�У�'
                    + FCompiler.ErrorMessage[i] + '[' + FCompiler.ErrorLine[i] + ']';
                end;
              end;

              DoBackErrorMsg(vBLLInfo);
            end
            else  // �ű����гɹ�
            begin
              vTick := GetTickCount - vTick;

              if FScriptBin.Size = 0 then
                vBLLInfo := vBLLInfo + ' �ɹ�(�ű�)����ʱ��' + IntToStr(vTick) + 'ms'
              else
                vBLLInfo := vBLLInfo + ' �ɹ�(Bin)����ʱ��' + IntToStr(vTick) + 'ms';

              if FBLLObj.DebugInfo.Count > 0 then
                vBLLInfo := vBLLInfo + sLineBreak + '������Ϣ��' + sLineBreak + FBLLObj.DebugInfo.Text;

              if Assigned(FOnExecuteLog) then  // �����־
                FOnExecuteLog(vBLLInfo);
            end;

            FMsgPack.ForcePathObject(BLL_EXECPARAM).Clear;  // ���ͻ��˵���ʱ�����Ĳ���ֵ����������ٲ���Ҫ�Ļش�������
            FMsgPack.ForcePathObject(BLL_METHODRESULT).AsBoolean := vScriptRunOk  // �ͻ��˵����Ƿ�ɹ�
          end
          else
          {$REGION 'ִ��SQL���'}
          begin
            if FMsgPack.B[BLL_BATCH] then  // ��������
            begin
              vBatchData := FMsgPack.ForcePathObject(BLL_BATCHDATA);
              vMemStream := TMemoryStream.Create;
              try
                vMemTable := TFDMemTable.Create(nil);
                try
                  vBatchData.SaveBinaryToStream(vMemStream);
                  vMemStream.Position := 0;
                  vMemTable.LoadFromStream(vMemStream, TFDStorageFormat.sfBinary);

                  if vMemTable.RecordCount > 0 then  // ����ִ��
                  begin
                    vQuery.SQL.Text := vBLLSql;
                    vQuery.Params.ArraySize := vMemTable.RecordCount;
                    for i := 0 to vMemTable.RecordCount - 1 do
                    begin
                      for j := 0 to vQuery.Params.Count - 1 do
                      begin
                        vQuery.Params[j].Values[i] :=
                          vMemTable.SourceView.Rows[i].GetData(vQuery.Params[j].Name);
                      end;
                    end;

                    if FMsgPack.B[BLL_TRANS] then  // ʹ������
                    begin
                      vQuery.Connection.StartTransaction;  // ��ʼһ������
                      try
                        vQuery.Execute(vQuery.Params.ArraySize);
                        vQuery.Connection.Commit;  // �ύ����
                      except
                        on E: Exception do
                        begin
                          vQuery.Connection.Rollback;  // ����ع�
                          DoBackErrorMsg('�쳣�ع�(�����)��ִ�з��� ' + vBLLInfo
                            + sLineBreak + '��䣺' + vBLLSql + sLineBreak + '������Ϣ��' + E.Message);
                          Exit;
                        end;
                      end;
                    end
                    else  // ��ʹ������
                      vQuery.Execute(vQuery.Params.ArraySize);

                    if Assigned(FOnExecuteLog) then
                    begin
                      FOnExecuteLog(vBLLInfo + sLineBreak + '��䣺' + vBLLSql + sLineBreak + '��������'
                        + vQuery.RowsAffected.ToString + '������');
                    end;
                  end;
                finally
                  FreeAndNil(vMemTable);
                end;
              finally
                FreeAndNil(vMemStream);
              end;
            end
            else  // ��������
            begin
              // ����Sql����е��滻����
              vReplaceParams := FMsgPack.ForcePathObject(BLL_REPLACEPARAM);
              for i := 0 to vReplaceParams.Count - 1 do
                vBLLSql := StringReplace(vBLLSql, '{' + vReplaceParams[i].NameEx + '}', vReplaceParams[i].AsString, [rfIgnoreCase]);

              // ����Sql����е��ֶβ���
              vQuery.SQL.Text := vBLLSql;
              if vQuery.Params.Count > 0 then  // ���ֶβ���
              begin
                vExecParams := FMsgPack.ForcePathObject(BLL_EXECPARAM);
                for i := 0 to vQuery.Params.Count - 1 do
                begin
                  case vExecParams.ForcePathObject(vQuery.Params[i].Name).DataType of
                    mptString, mptInteger, mptBoolean, mptDouble, mptSingle:
                      vFrameSql := vFrameSql + sLineBreak + vQuery.Params[i].Name
                        + ' = ' + vExecParams.ForcePathObject(vQuery.Params[i].Name).AsString;

                    mptDateTime:
                      vFrameSql := vFrameSql + sLineBreak + vQuery.Params[i].Name + ' = '
                        + FormatDateTime('YYYY-MM-DD HH:mm:ss', vExecParams.ForcePathObject(vQuery.Params[i].Name).AsDateTime);

                    mptBinary:
                      vFrameSql := vFrameSql + sLineBreak + vQuery.Params[i].Name + ' = [������]';
                  else
                    vFrameSql := vFrameSql + sLineBreak + vQuery.Params[i].Name + ' = [����ȷ�Ĳ���ֵ(�ա�δ֪)]';
                  end;

                  vQuery.Params[i].Value := vExecParams.ForcePathObject(vQuery.Params[i].Name).AsVariant;
                end;
              end;

              if Assigned(FOnExecuteLog) then
              begin
                if vFrameSql <> '' then
                  FOnExecuteLog(vBLLInfo + sLineBreak + '��䣺' + vBLLSql + sLineBreak + '������' + vFrameSql)
                else
                  FOnExecuteLog(vBLLInfo + sLineBreak + '��䣺' + vBLLSql);
              end;

              if IsSelectSql(vBLLSql)
                or FMsgPack.B[BLL_BACKDATASET]
                or (FMsgPack.O[BLL_BACKFIELD] <> nil)
              then  // ��ѯ��
              begin
                vQuery.Open;
                vRecordCount := vQuery.RecordCount;
              end
              else  // ������
              begin
                if FMsgPack.B[BLL_TRANS] then  // ʹ������
                begin
                  vQuery.Connection.StartTransaction;  // ��ʼһ������
                  try
                    vQuery.ExecSQL;
                    vQuery.Connection.Commit;  // �ύ����
                  except
                    on E: Exception do
                    begin
                      vQuery.Connection.Rollback;  // ����ع�
                      DoBackErrorMsg('�쳣�ع�(�����)��ִ�з��� ' + vBLLInfo
                        + sLineBreak + '��䣺' + vBLLSql + sLineBreak + '������' + vFrameSql + sLineBreak + '������Ϣ��' + E.Message);
                      Exit;
                    end;
                  end;
                end
                else
                  vQuery.ExecSQL;

                vRecordCount := vQuery.RowsAffected;

                if (vBLLDataBase.DBType = TDBType.dbSqlServer) and IsInsertSql(vBLLSql) then
                begin
                  vQuery.Close;
                  vQuery.SQL.Clear;
                  vQuery.SQL.Text := 'SELECT SCOPE_IDENTITY() AS id';
                  vQuery.Open();
                  if not vQuery.IsEmpty then
                    vIDENTITY := vQuery.FieldByName('id').AsInteger;
                end;
              end;
            end;

            // ����ͻ�����Ҫ���ص����ݼ���ָ���ֶ�
            if FMsgPack.B[BLL_BACKDATASET] then  // �ͻ�����Ҫ�������ݼ�
            begin
              vMemStream := TMemoryStream.Create;
              try
                vQuery.SaveToStream(vMemStream, TFDStorageFormat.sfBinary);
                FMsgPack.ForcePathObject(BLL_DATASET).LoadBinaryFromStream(vMemStream);
              finally
                FreeAndNil(vMemStream);
              end;
            end
            else
            if (FMsgPack.O[BLL_BACKFIELD] <> nil) and (vRecordCount > 0) then  // �ͻ�����Ҫ����ָ���ֶ�
            begin
              vBackParam := FMsgPack.ForcePathObject(BLL_BACKFIELD);
              for i := 0 to vBackParam.Count - 1 do
                vBackParam.Items[i].AsVariant := vQuery.FieldByName(vBackParam.Items[i].NameLower).AsVariant;
            end;

            { �������ִ�н�������� }
            // �ȷ���Э�鶨��õ�
            FMsgPack.ForcePathObject(BLL_EXECPARAM).Clear;  // ���ͻ��˵���ʱ�����Ĳ���ֵ����������ٲ���Ҫ�Ļش�������
            FMsgPack.ForcePathObject(BLL_METHODRESULT).AsBoolean := True;  // �ͻ��˵��óɹ�
            FMsgPack.ForcePathObject(BLL_RECORDCOUNT).AsInteger := vRecordCount;
            if vIDENTITY > 0 then
              FMsgPack.ForcePathObject(BLL_INSERTINDENT).AsInteger := vIDENTITY;
          end;
          {$ENDREGION}
        end;
      except
        on E: Exception do
        begin
          if vBLLScript <> '' then
            DoBackErrorMsg('�쳣(�����)��ִ�нű�����'
              + sLineBreak + '    ' + vBLLInfo + '��' + E.Message)
          else
            DoBackErrorMsg('�쳣(�����)��ִ�з��� ' + vBLLInfo
              + sLineBreak + '��䣺' + vBLLSql + sLineBreak + '������' + vFrameSql + sLineBreak + '������Ϣ��' + E.Message);
        end;
      end;
    end
    else  // û�ҵ�ҵ���Ӧ�����
      DoBackErrorMsg('(�����)ҵ��' + vBLLInfo + '��Ӧִ����䲻���ڻ��ж���'
        + sLineBreak + '�汾��' + vVer.ToString);
  finally
    vQuery.Free;
  end;

  FMsgPack.Result := True;
end;

end.
