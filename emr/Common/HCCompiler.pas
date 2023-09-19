unit HCCompiler;

interface

uses
  Classes, SysUtils, Vcl.Dialogs, Generics.Collections, PaxCompiler, PaxProgram, PaxRunner,
  HCSynEdit, SynEditTypes, PaxRegister, PaxJavaScriptLanguage, IMPORT_Classes,
  IMPORT_SysUtils, IMPORT_Dialogs, IMPORT_Variants;

const
  ProposalCommColor = '$00A00000';

type
  TProposalInfo = class(TObject)
  public
    TypeID: Integer;
    ClassNameEx: string;
    Keyword: string;
    procedure Init;
  end;

  TCplVariable = class(TObject)
    /// <summary> ��������ID </summary>
    TypeID: Integer;
    /// <summary> �����ڴ��ַ </summary>
    Address: Pointer;
    /// <summary> ������ </summary>
    FullName: string;
    /// <summary> ���SynEdit�Ĵ�����ʾ����var \column{}\style{+B}BLL\style{-B}: TBLLObj;  // ҵ�������  </summary>
    Proposal: string;
  end;

  TCplVariables = class(TObjectList<TCplVariable>)
  public
    function New(const ATypeID: Integer; const AAddress: Pointer;
      const AFullName, AProposal: string): Integer;
    function NameOf(const AName: string): Integer;
  end;

  TCplConvert = class(TObject)
  public
    /// <summary> �Ƿ�Ϊ���� </summary>
    Constant: Boolean;
    /// <summary> �Ƿ�Ϊ���·�װ��(����ԭʼ���еķ���) </summary>
    Fake: Boolean;
    /// <summary> �ڼ������� </summary>
    OverIndex: Byte;
    /// <summary> ʵ���ڴ��ַ </summary>
    Address: Pointer;
    /// <summary> ȫ������function RunScript(const ACode: string): Boolean; </summary>
    FullName: string;
    /// <summary> ���SynEdit�Ĵ�����ʾ���� procedure \column{}\style{+B}Commit\style{-B}(const AConn: Byte = 1);  \color{' + ProposalCommColor + '}// �ύ </summary>
    Proposal: string;
    /// <summary> ���ƣ���RunScript </summary>
    SimpleName: string;
    /// <summary> ��Ԫ������HCCompiler </summary>
    UnitName: string;
    /// <summary> ·������HCCompiler.TCplConvert </summary>
    //FullPath: string;
    /// <summary> ����������ƣ���TCplConvert </summary>
    ClassNameEx: string;
  end;

  TCplConverts = class(TObjectList<TCplConvert>)
  public
    function New(const AFullName, AProposal, ASimpleName, AUnitName,
      AClassName: string; const AAddress: Pointer; const AFake: Boolean = False; const AOverIndex: Byte = 0): Integer;
    function AddressOf(const AAddress: Pointer): TCplConvert;
    function ProcOf(const APath: string; const AOverIndex: Byte): TCplConvert;
  end;

  TScriptType = (stpNone, stpPascal, stpJavaScript);

  TCompilerExceptionEvnet = procedure(const E: Exception; const AModuleName: String; ASourceLine: Integer) of object;

  THCCompiler = class(TPaxCompiler)
  private
    FHasError: Boolean;
    FPaxProgram: TPaxProgram;
    FPaxLanguage: TPaxCompilerLanguage;
    FScriptType: TScriptType;
    FLastProposal: TProposalInfo;
    FOnException: TCompilerExceptionEvnet;

    procedure SetScriptType(const Value: TScriptType);
  protected
    FCompilerVariables: TCplVariables;
    FCompilerConverts: TCplConverts;
    // ����bin�ļ�ʱ�����ࡢ������������صķ���
    procedure DoMapTableNamespace(Sender: TPaxRunner; const FullName: string;
      Global: Boolean);
    procedure DoMapTableVarAddress(Sender: TPaxRunner; const FullName: string;
      Global: Boolean; var Address: Pointer);
    procedure DoMapTableProcAddress(Sender: TPaxRunner; const FullName: string;
      OverCount: Byte; Global: Boolean; var Address: Pointer);
    procedure DoMapTableClassRef(Sender: TPaxRunner; const FullName: string;
      Global: Boolean; var ClassRef: TClass);

    procedure DoProgException(Sender: TPaxRunner; E: Exception;
       const ModuleName: String; SourceLineNumber: Integer);
    procedure DoProgUnhandledException(Sender: TPaxRunner; E: Exception;
       const ModuleName: String; SourceLineNumber: Integer);
  public
    constructor CreateByScriptType(AOwner: TComponent; const AScriptType: TScriptType = stpPascal); virtual;
    destructor Destroy; override;
    procedure ResetRegister; virtual;

    /// <summary> ���ô�����ʾ </summary>
    procedure Proposal(const AWord: string; const AInsertList, AItemList: TStrings);

    /// <summary> ������ʾ�س�������ʱ�������¼� </summary>
    procedure CodeCompletion(Sender: TObject; var Value: UnicodeString;
      Shift: TShiftState; Index: Integer; EndToken: WideChar);

    /// <summary> ����ָ�����Ƶı����Ƿ��Ѿ�ע��� </summary>
    function FindRegisterVariable(const ATypeID: Integer; const AVarName: string): Boolean;
    function RunScript(const ACode: string): Boolean;
    function RunScriptBin(const AStream: TStream): Boolean;
    function CompileScript(const ACode: string): Boolean;
    procedure SaveToStream(const AStream: TStream);
    procedure LoadFromStream(const AStream: TStream);

    property ScriptType: TScriptType read FScriptType write SetScriptType;
    property OnException: TCompilerExceptionEvnet read FOnException write FOnException;
  end;

implementation

uses
  PAXCOMP_KERNEL, PAXCOMP_SYMBOL_REC, PAXCOMP_BASERUNNER, PAXCOMP_SYS;

{ THCCompiler }

procedure THCCompiler.CodeCompletion(Sender: TObject; var Value: UnicodeString;
  Shift: TShiftState; Index: Integer; EndToken: WideChar);
var
  vSynEdit: THCSynEdit;
  i, vID, vTypeID, vOwnerID: Integer;
  vKernel: TKernel;
  vSymbolRec: TSymbolRec;
  vClassName: string;
begin
  vSynEdit := Sender as THCSynEdit;
  if FCompilerVariables.NameOf(Value) >= 0 then  // ��ȫ�ֱ������ڵ�ǰ��ġ�."
  begin
    vSynEdit.BlockBegin := BufferCoord(vSynEdit.BlockBegin.Char - 1, vSynEdit.BlockBegin.Line);
    vSynEdit.BlockEnd := BufferCoord(vSynEdit.CaretX, vSynEdit.CaretY);
    Exit;
  end;

  // ��̬���ҷ������¼������ԡ��ֲ�����
  vID := Self.LookupId(Value);  // ����ID
  if vID > 0 then  // ��̬����
  begin
    vKernel := Self.GetKernelPtr;
    vTypeID := vKernel.SymbolTable[vID].TypeId;
    if vTypeID = 0 then
    begin
      vOwnerID := vKernel.SymbolTable[vID].OwnerId;
      if vOwnerID > 0 then
        vTypeID := vKernel.SymbolTable[vOwnerID].TypeId;
    end;

    for i := vTypeID + 1 to vKernel.SymbolTable.Card do
    begin
      vSymbolRec := vKernel.SymbolTable[I];
      if vSymbolRec = vKernel.SymbolTable.SR0 then
        Break;
      if vSymbolRec.Kind = kindNAMESPACE then
        Break;

      if vSymbolRec.Level <> vTypeID then
        Continue;

      if CompareStr(vSymbolRec.Name, Value) = 0 then
      begin
        if vKernel.SymbolTable.IsProcedure(vTypeID, i)
          or vKernel.SymbolTable.IsFunction(vTypeID, i)
        then
        begin
          if vSymbolRec.Count > 0 then  // �в���
            Value := Value + '()';

          Exit;
        end;
      end;
    end;

    if vKernel.SymbolTable[vID].Kind = kindVAR then  // �ֲ�����
    begin
      vSynEdit.BlockBegin := BufferCoord(vSynEdit.BlockBegin.Char - 1, vSynEdit.BlockBegin.Line);
      vSynEdit.BlockEnd := BufferCoord(vSynEdit.CaretX, vSynEdit.CaretY);
      Exit;
    end;
  end;

  // ��̬û�ҵ�
  if FLastProposal.TypeID > 0 then
  begin
    vKernel := Self.GetKernelPtr;
    for i := FLastProposal.TypeID + 1 to vKernel.SymbolTable.Card do
    begin
      vSymbolRec := vKernel.SymbolTable[I];
      if vSymbolRec = vKernel.SymbolTable.SR0 then
        Break;
      if vSymbolRec.Kind = kindNAMESPACE then
        Break;

      if vSymbolRec.Level <> FLastProposal.TypeID then
        Continue;

      if CompareStr(vSymbolRec.Name, Value) = 0 then
      begin
        if vKernel.SymbolTable.IsProcedure(FLastProposal.TypeID, i)
          or vKernel.SymbolTable.IsFunction(FLastProposal.TypeID, i)
        then
        begin
          if vSymbolRec.Count > 0 then  // �в���
            Value := Value + '()';

          Exit;
        end;
      end;
    end;
  end;
end;

function THCCompiler.CompileScript(const ACode: string): Boolean;
begin
  Result := False;

  AddCode('main', ACode);

  if Compile(FPaxProgram) then
    Result := True;
end;

constructor THCCompiler.CreateByScriptType(AOwner: TComponent;
  const AScriptType: TScriptType = stpPascal);
begin
  inherited Create(AOwner);
  FHasError := False;
  FLastProposal := TProposalInfo.Create;
  FCompilerConverts := TCplConverts.Create;
  FCompilerVariables := TCplVariables.Create;

  FScriptType := stpNone;
  FPaxProgram := TPaxProgram.Create(nil);
  FPaxProgram.OnMapTableNamespace := DoMapTableNamespace;
  FPaxProgram.OnMapTableVarAddress := DoMapTableVarAddress;
  FPaxProgram.OnMapTableProcAddress := DoMapTableProcAddress;
  FPaxProgram.OnMapTableClassRef := DoMapTableClassRef;
  FPaxProgram.OnException := DoProgException;
  FPaxProgram.OnUnhandledException := DoProgUnhandledException;

  SetScriptType(AScriptType);
end;

destructor THCCompiler.Destroy;
begin
  FreeAndNil(FPaxProgram);
  if Assigned(FPaxLanguage) then
    FPaxLanguage.Free;

  FreeAndNil(FLastProposal);
  FreeAndNil(FCompilerConverts);
  FreeAndNil(FCompilerVariables);

  inherited Destroy;
end;

procedure THCCompiler.DoMapTableClassRef(Sender: TPaxRunner;
  const FullName: string; Global: Boolean; var ClassRef: TClass);
var
  vName: string;
  vTypeID, vPos: Integer;
begin
  vName := UpperCase(FullName);
  // ȡ��������
  vPos := Pos('.', vName);
  while vPos > 0 do
  begin
    vName := Copy(vName, vPos + 1, Length(vName) - vPos);
    vPos := Pos('.', vName);
  end;

  vTypeID := Self.LookupTypeId(vName);
  if vTypeID > 0 then
    ClassRef := TKernel(Self.GetKernelPtr).SymbolTable[vTypeID].PClass;
end;

procedure THCCompiler.DoMapTableNamespace(Sender: TPaxRunner;
  const FullName: string; Global: Boolean);
begin
  //vName := LowerCase(FullName)
  //if FullName = 'emr_MsgPack' then
end;

procedure THCCompiler.DoMapTableProcAddress(Sender: TPaxRunner;
  const FullName: string; OverCount: Byte; Global: Boolean;
  var Address: Pointer);
var
  //vPath: string;
  vConvert: TCplConvert;
  vID, vTypeID, vOwnerID: Integer;
  vKernel: TKernel;
begin
  vConvert := FCompilerConverts.ProcOf(FullName, OverCount);
  if Assigned(vConvert) then
  begin
    Address := vConvert.Address;
    Exit;
  end;

  vID := Self.LookupId(FullName);
  if vID > 0 then
  begin
    vKernel := Self.GetKernelPtr;
    Address := vKernel.SymbolTable[vID].Address;
    Exit;
  end;

  {vPath := LowerCase(FullName);
  if vPath = 'classes.tmemorystream.create' then
    Address := @System.Classes.TMemoryStream.Create
  else
  if vPath = 'sysutils.quotedstr' then
    Address := @System.SysUtils.QuotedStr
  else
  if vPath = 'sysutils.format' then
    Address := @System.SysUtils.Format
  else
  if vPath = 'sysutils.formatdatetime' then
    Address := @System.SysUtils.FormatDateTime
  else
  if vPath = 'sysutils.inttostr' then
    Address := @System.SysUtils.IntToStr
  else
  if vPath = 'dialogs.showmessage' then
    Address := @Vcl.Dialogs.ShowMessage;}
end;

procedure THCCompiler.DoMapTableVarAddress(Sender: TPaxRunner;
  const FullName: string; Global: Boolean; var Address: Pointer);
var
  i: Integer;
begin
  for i := 0 to FCompilerVariables.Count - 1 do
  begin
    if CompareText(FCompilerVariables[i].FullName, FullName) = 0 then
    begin
      Address := FCompilerVariables[i].Address;
      Break;
    end;
  end;
end;

procedure THCCompiler.DoProgException(Sender: TPaxRunner; E: Exception;
  const ModuleName: String; SourceLineNumber: Integer);
begin
  FHasError := True;
  //vStackCount := Sender.GetProgPtr.GetCallStackCount;
  if Assigned(FOnException) then
    FOnException(E, ModuleName, SourceLineNumber);
end;

procedure THCCompiler.DoProgUnhandledException(Sender: TPaxRunner; E: Exception;
  const ModuleName: String; SourceLineNumber: Integer);
begin
  FHasError := True;
  if Assigned(FOnException) then
    FOnException(E, ModuleName, SourceLineNumber);
end;

function THCCompiler.FindRegisterVariable(const ATypeID: Integer;
  const AVarName: string): Boolean;
var
  vKernel: TKernel;
  vSymbolRec: TSymbolRec;
  i: Integer;
begin
  Result := False;

  vKernel := TKernel(Self.GetKernelPtr);
  for i := FirstLocalId + 1 to vKernel.SymbolTable.Card do
  begin
    vSymbolRec := vKernel.SymbolTable[i];
    if (vSymbolRec.Kind = KindVAR) and (CompareStr(vSymbolRec.Name, AVarName) = 0) then  // ע�����
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure THCCompiler.LoadFromStream(const AStream: TStream);
begin
  FPaxProgram.LoadFromStream(AStream);
end;

procedure THCCompiler.Proposal(const AWord: string; const AInsertList,
  AItemList: TStrings);
var
  i, vID, vTypeID: Integer;
  vKernel: TKernel;
  vClassName: string;
  vConvert: TCplConvert;
  vVariable: TCplVariable;
  vSymbolRec: TSymbolRec;
begin
  FLastProposal.Init;
  FLastProposal.Keyword := AWord;

  if AWord = '.' then  // ��ʾȫ�����õı���
  begin
    vKernel := Self.GetKernelPtr;

    for i := 0 to FCompilerVariables.Count - 1 do  // ע���ȫ�ֱ���
    begin
      vVariable := FCompilerVariables[i];
      AInsertList.Add(vVariable.FullName);

      if vKernel.SymbolTable[vVariable.TypeID].TypeID = 0 then  // ��������
        vClassName := vKernel.SymbolTable[vVariable.TypeID].Name
      else
        vClassName := vKernel.SymbolTable[vVariable.TypeID].PClass.ClassName;  // ����������

      {if vClassName = 'UNICODESTRING' then
        vClassName := 'string';}

      AItemList.Add('\image{0} \column{} var \column{}\style{+B}' + vVariable.FullName + '\style{-B}: ' + vClassName + '  // ' + vVariable.Proposal);
    end;

    for i := FirstLocalId + 1 to vKernel.SymbolTable.Card do
    begin
      vSymbolRec := vKernel.SymbolTable[i];
      if (not vSymbolRec.Host) and (vSymbolRec.Kind = KindVAR) then  // �ű��ڲ��ı���
      begin
        if vKernel.SymbolTable[vSymbolRec.TypeID].TypeID = 0 then  // ��������
          vClassName := vKernel.SymbolTable[vSymbolRec.TypeID].Name
        else
          vClassName := vKernel.SymbolTable[vSymbolRec.TypeID].PClass.ClassName;  // ����������

        AInsertList.Add(vSymbolRec.Name);
        AItemList.Add('\image{0} \column{} var \column{}\style{+B}' + vSymbolRec.Name + '\style{-B}: ' + vClassName + '  // �ֲ�����');
      end;
    end;
  end
  else
  begin
    vTypeID := Self.LookupTypeId(AWord);  // ���ж�д��ֱ�������� �� TDeProp
    if vTypeID > 0 then
    begin
      vKernel := TKernel(Self.GetKernelPtr);

      if vKernel.SymbolTable[vTypeID].TypeID = 0 then  // ��������
        vClassName := vKernel.SymbolTable[vTypeID].Name
      else
        vClassName := vKernel.SymbolTable[vTypeID].PClass.ClassName;  // ����������

      FLastProposal.TypeID := vTypeID;
      FLastProposal.ClassNameEx := vClassName;

      for i := 0 to FCompilerConverts.Count - 1 do
      begin
        vConvert := FCompilerConverts[i];
        if {(not vConvert.Fake) and ���صķ�����������} (CompareStr(vConvert.ClassNameEx, vClassName) = 0) then
        begin
          AInsertList.Add(vConvert.SimpleName);
          AItemList.Add(vConvert.Proposal);
        end;
      end;

      Exit;
    end;

    vID := Self.LookupId(AWord);  // �������ƻ�ȡ����ID
    if vID > 0 then
    begin
      vKernel := TKernel(Self.GetKernelPtr);

      // ���ж��ǲ�����������ĳ���͵ı���
      vSymbolRec := vKernel.SymbolTable[vID];
      if Assigned(vSymbolRec) then  // AWord������������������ĳ���ͱ���
      begin
        vTypeID := vKernel.SymbolTable[vID].TypeID;  // ȡ����
        if vTypeID > 0 then  // ������
          vClassName := vKernel.SymbolTable[vTypeID].Name
        else  // �����ͣ�����������
          vClassName := '';//vKernel.SymbolTable[vTypeID].PClass.ClassName;  // ������������
      end
      else  // �����ߵ�������
      begin
        vTypeID := vKernel.GetTypeMapRec(vID).TypeId;  // ��������ID

        if vKernel.SymbolTable[vTypeID].TypeID = 0 then  // ��������
          vClassName := vKernel.SymbolTable[vTypeID].Name
        else
          vClassName := vKernel.SymbolTable[vTypeID].PClass.ClassName;  // ������������

        vSymbolRec := vKernel.SymbolTable[vID];
      end;

      FLastProposal.TypeID := vTypeID;
      FLastProposal.ClassNameEx := vClassName;

      if vSymbolRec.Kind = kindVAR then  // �Ǳ�����Ϊɶ����������Ҳ��������������أ�
      begin
        for i := 0 to FCompilerConverts.Count - 1 do
        begin
          vConvert := FCompilerConverts[i];
          if {(not vConvert.Fake) and ���صķ�����������} (CompareStr(vConvert.ClassNameEx, vClassName) = 0) then
          begin
            AInsertList.Add(vConvert.SimpleName);
            AItemList.Add(vConvert.Proposal);
          end;
        end;
      end;
    end;
  end;
end;

procedure THCCompiler.ResetRegister;
begin
  FCompilerVariables.Clear;

  Reset;
  RegisterLanguage(FPaxLanguage);
  AddModule('main', FPaxLanguage.LanguageName);
end;

function THCCompiler.RunScript(const ACode: string): Boolean;
begin
  Result := False;
  FHasError := False;
  AddCode('main', ACode);
  //FPaxProgram.GetProgPtr.RootExceptionIsAvailableForHostApplication := True;  // ��Ӧtry finally�е��쳣
  if Compile(FPaxProgram) then
  begin
    FPaxProgram.Run;
    if not FHasError then  // FPaxProgram.GetProgPtr.HasError ExceptionRec
      Result := True;
  end;
end;

function THCCompiler.RunScriptBin(const AStream: TStream): Boolean;
var
  vRun: TBaseRunner;
begin
  Result := False;
  FHasError := False;
  AStream.Position := 0;
  //FPaxProgram.GetProgPtr.RootExceptionIsAvailableForHostApplication := True;  // ��Ӧtry finally�е��쳣
  FPaxProgram.LoadFromStream(AStream);
  FPaxProgram.MapGlobal;
  FPaxProgram.MapLocal;
  FPaxProgram.Run;

  if not FHasError then  // FPaxProgram.GetProgPtr.HasError ExceptionRec
    Result := True;
end;

procedure THCCompiler.SaveToStream(const AStream: TStream);
begin
  FPaxProgram.SaveToStream(AStream);
end;

procedure THCCompiler.SetScriptType(const Value: TScriptType);
begin
  if FScriptType <> Value then
  begin
    if Assigned(FPaxLanguage) then
      FPaxLanguage.Free;

    FScriptType := Value;
    case FScriptType of
      stpPascal: FPaxLanguage := TPaxPascalLanguage.Create(nil);
      stpJavaScript: FPaxLanguage := TPaxJavaScriptLanguage.Create(nil);
    end;

    ResetRegister;
  end;
end;

{ TCplConverts }

function TCplConverts.AddressOf(const AAddress: Pointer): TCplConvert;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Self.Count - 1 do
  begin
    if Self[i].Address = AAddress then
    begin
      Result := Self[i];
      Break;
    end;
  end;
end;

function TCplConverts.New(const AFullName, AProposal, ASimpleName,
  AUnitName, AClassName: string; const AAddress: Pointer; const AFake: Boolean = False; const AOverIndex: Byte = 0): Integer;
var
  vConvert: TCplConvert;
begin
  vConvert := TCplConvert.Create;
  vConvert.FullName := AFullName;
  vConvert.Proposal := AProposal;
  vConvert.SimpleName := ASimpleName;
  vConvert.UnitName := AUnitName;
  vConvert.ClassNameEx := AClassName;
  vConvert.Address := AAddress;
  vConvert.OverIndex := AOverIndex;
  vConvert.Fake := AFake;
  vConvert.Constant := False;
  Result := Self.Add(vConvert);
end;

function TCplConverts.ProcOf(const APath: string;
  const AOverIndex: Byte): TCplConvert;
var
  i: Integer;
  vConvert: TCplConvert;
  vPath: string;
begin
  Result := nil;
  for i := 0 to Self.Count - 1 do
  begin
    vConvert := Self[i];

    if vConvert.OverIndex = AOverIndex then
    begin
      vPath := vConvert.ClassNameEx + '.' + vConvert.SimpleName;
      if CompareText(APath, vPath) = 0 then
      begin
        Result := Self[i];
        Exit;
      end;

      vPath := vConvert.UnitName + '.' + vPath;
      if CompareText(APath, vPath) = 0 then
      begin
        Result := Self[i];
        Exit;
      end;
    end;
  end;
end;

{ TCplVariables }

function TCplVariables.NameOf(const AName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Self.Count - 1 do
  begin
    if CompareStr(Self[i].FullName, AName) = 0 then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TCplVariables.New(const ATypeID: Integer; const AAddress: Pointer;
  const AFullName, AProposal: string): Integer;
var
  vVariable: TCplVariable;
begin
  Result := -1;
  vVariable := TCplVariable.Create;
  vVariable.TypeID := ATypeID;
  vVariable.Address := AAddress;
  vVariable.FullName := AFullName;
  vVariable.Proposal := AProposal;

  Result := Self.Add(vVariable);
end;

{ TProposalInfo }

procedure TProposalInfo.Init;
begin
  TypeID := 0;
  ClassNameEx := '';;
  Keyword := '';
end;

procedure RegisterImportClass;
begin
  IMPORT_Classes.Register_Classes;
  IMPORT_SysUtils.Register_SysUtils;
  IMPORT_Dialogs.Register_Dialogs;
  IMPORT_Variants.Register_Variants;
end;

initialization
  RegisterImportClass;

end.
