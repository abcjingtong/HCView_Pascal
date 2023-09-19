unit CFDBGrid;

interface

uses
  Classes, Graphics, CFGrid, DB;

type
  TCFDBGrid = class;

  TCField = class(TCollectionItem)
  private
    /// <summary> �ֶ������� </summary>
    FTitle,
    /// <summary> �ֶ��� </summary>
    FFieldName: string;

    /// <summary> �����ֶο�� </summary>
    FWidth: Integer;
    FDataType: TFieldType;
  protected
    function GetDisplayName: string; override;

    /// <summary> �����ֶ��� </summary>
    /// <param name="Value">�ֶ���</param>
    procedure SetFieldName(const Value: string);
    function GetGrid: TCFDBGrid;

    function GetAsInteger: Longint;
    procedure SetAsInteger(Value: Longint);
    function GetAsString: string;
    procedure SetAsString(Value: string);
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    property AsInteger: Longint read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
  published
    property Title: string read FTitle write FTitle;
    property FieldName: string read FFieldName write SetFieldName;
    property DataType: TFieldType read FDataType write FDataType;
    property Width: Integer read FWidth write FWidth;
  end;

  TCFieldClass = class of TCField;

  TCGridFields = class(TCollection)
  private
    FGrid: TCFDBGrid;
    /// <summary> ��ȡָ���ֶ���Ϣ </summary>
    /// <param name="Index">�ڼ����ֶ�</param>
    /// <returns>�ֶ�</returns>
    function GetColumn(Index: Integer): TCField;

    /// <summary> �����ֶ���Ϣ </summary>
    /// <param name="Index">�ڼ����ֶ�</param>
    /// <param name="Value">�ڼ����ֶε������Ϣ</param>
    procedure SetColumn(Index: Integer; Value: TCField);
  protected
    function GetOwner: TPersistent; override;

    procedure Added(var Item: TCollectionItem); override;
    procedure Deleting(Item: TCollectionItem); override;
    /// <summary> �����ֶ���Ϣ </summary>
    /// <param name="Item">�ֶ���Ϣ</param>
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AGrid: TCFDBGrid; AItemClass: TCFieldClass);
    destructor Destroy; override;

    /// <summary> �����ֶ� </summary>
    /// <returns></returns>
    function Add: TCField;
    function IndexOf(const AFieldName: string): Integer;

    property Grid: TCFDBGrid read FGrid;
    property Items[Index: Integer]: TCField read GetColumn write SetColumn; default;
  end;

  TCFDBGrid = class(TCFGrid)
  private
    FDataSet: TDataSet;
    FFields: TCGridFields;

    /// <summary> ��ǰ����״̬ </summary>
    FSortAsc: Boolean;

    /// <summary> ���� Grid ���� </summary>
    /// <param name="Item">���µ���</param>
    procedure UpdateFields(Item: TCField);
  protected
    /// <summary> ���û������л��� </summary>
    /// <param name="ACanvas">����</param>
    procedure DrawControl(ACanvas: TCanvas); override;

    /// <summary> ������������������ </summary>
    /// <param name="Value">����</param>
    procedure SetFields(Value: TCGridFields);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function FindField(const AFieldName: string): Integer;
    /// <summary> ��ȡ������Ϣ </summary>
    /// <param name="ADataSet">������Ϣ</param>
    procedure LoadFromDataSet(const ADataSet: TDataSet);

    function FieldByName(const AFieldName: string): TCField;

    /// <summary> ��ǰ����״̬ </summary>
    property SortAsc: Boolean read FSortAsc write FSortAsc;

    property RowCount;
    property ColCount;
  published
    property Fields: TCGridFields read FFields write SetFields;
  end;

implementation

uses
  SysUtils;

{ TCFDBGrid }

function TCFDBGrid.FieldByName(const AFieldName: string): TCField;
var
  vIndex: Integer;
begin
  vIndex := FindField(AFieldName);
  if vIndex < 0 then
    raise Exception.Create('�쳣��δ�����ֶ� ' + AFieldName)
  else
    Result := FFields[vIndex];
end;

constructor TCFDBGrid.Create(AOwner: TComponent);
begin
  inherited CreateEx(AOwner, 0, 0);  // Ĭ�ϴ����� CDBGrid Ϊһ��һ��
  FFields := TCGridFields.Create(Self, TCField);
  FSortAsc := False;
end;

destructor TCFDBGrid.Destroy;
begin
  FFields.Free;
  inherited;
end;

procedure TCFDBGrid.DrawControl(ACanvas: TCanvas);
begin
  inherited DrawControl(ACanvas);
end;

function TCFDBGrid.FindField(const AFieldName: string): Integer;
begin
  Result := FFields.Indexof(AFieldName);
end;

procedure TCFDBGrid.LoadFromDataSet(const ADataSet: TDataSet);
var
  vRow, vCol: Integer;
begin
  //FColumns.Clear;  // ��� CDGrid �ϵ��ֶ���Ϣ
  FDataSet := ADataSet;  // ��Ϊmemtable��������ͼ���
  BeginUpdate;
  try
    RowCount := ADataSet.RecordCount;  // �����и�ֵΪ CDGrid ����
    if FFields.Count = 0 then
    begin
      for vCol := 0 to ADataSet.Fields.Count - 1 do  // ��������Դ���в����������ֶ���
      begin
        with FFields.Add do  // ����ֶΣ��������ֶο��������Ϣ
        begin
          Width := DefaultColWidth;
          FieldName := ADataSet.Fields[vCol].FieldName;
        end;
        //TitleText[vCol] := ADataSet.Fields[vCol].FieldName;
      end;
    end;
    vRow := 0;  // ���ó�ʼ��
    if not ADataSet.IsEmpty then  // ��������
    begin
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        for vCol := 0 to ColCount - 1 do  // ���е����ݼ���
          Cells[vRow, vCol] := ADataSet.FieldByName(FFields[vCol].FieldName).AsString;  // ���ݸ�ֵ
        Inc(vRow);
        ADataSet.Next;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TCFDBGrid.SetFields(Value: TCGridFields);
begin
  FFields.Assign(Value);
end;

procedure TCFDBGrid.UpdateFields(Item: TCField);
var
  vCol: Integer;
begin
  if csLoading in ComponentState then Exit;

  ColCount := FFields.Count;

  if Item = nil then  // �䶯�ֶ�Ϊ�յ�ʱ��������е��ֶ���Ϣ
  begin
    for vCol := 0 to FFields.Count - 1 do
      TitleText[vCol] := FFields.Items[vCol].Title;
  end
  else  // �䶯�ֶβ�Ϊ�ո��±䶯�ֶε���Ϣ
    TitleText[Item.Index] := Item.Title;

  UpdateDirectUI;
end;

{ TCGridFields }

function TCGridFields.Add: TCField;
begin
  Result := TCField(inherited Add);
end;

procedure TCGridFields.Added(var Item: TCollectionItem);
begin
  inherited;
  FGrid.ColCount := Self.Count;
end;

constructor TCGridFields.Create(AGrid: TCFDBGrid; AItemClass: TCFieldClass);
begin
  inherited Create(AItemClass);
  FGrid := AGrid;
end;

procedure TCGridFields.Deleting(Item: TCollectionItem);
begin
  inherited;
  FGrid.ColCount := Self.Count;
end;

destructor TCGridFields.Destroy;
begin

  inherited;
end;

function TCGridFields.GetColumn(Index: Integer): TCField;
begin
  Result := TCField(inherited Items[Index]);
end;

function TCGridFields.GetOwner: TPersistent;
begin
  Result := FGrid;
end;

function TCGridFields.IndexOf(const AFieldName: string): Integer;
var
  i: Integer;
  vFielName: string;
begin
  Result := -1;

  vFielName := UpperCase(AFieldName);
  for i := 0 to Count - 1 do
  begin
    if UpperCase(Items[i].FieldName) = vFielName then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TCGridFields.SetColumn(Index: Integer; Value: TCField);
begin
  Items[Index].Assign(Value);  // inherited SetItem(Index, Value);
end;

procedure TCGridFields.Update(Item: TCollectionItem);
begin
  inherited;
  FGrid.UpdateFields(TCField(Item));
end;

{ TCField }

procedure TCField.Assign(Source: TPersistent);
begin
  if Source is TCField then  // �����ֶεĿ�ȣ��ֶ������ֶα���
  begin
    FWidth := TCField(Source).Width;
    FTitle := TCField(Source).Title;
    FFieldName := TCField(Source).FieldName;
  end
  else
    inherited Assign(Source);
end;

constructor TCField.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FWidth := TCGridFields(Collection).Grid.DefaultColWidth;
end;

function TCField.GetAsInteger: Longint;
var
  vGrid: TCFDBGrid;
begin
  vGrid := GetGrid;
  TryStrToInt(vGrid.Cells[vGrid.RowIndex, vGrid.FindField(Self.FieldName)], Result);
end;

function TCField.GetAsString: string;
var
  vGrid: TCFDBGrid;
begin
  vGrid := GetGrid;
  Result := vGrid.Cells[vGrid.RowIndex, vGrid.FindField(Self.FieldName)];
end;

function TCField.GetDisplayName: string;
begin
  Result := FFieldName;
  if Result = '' then
    Result := inherited GetDisplayName;// + IntToStr(ID);
end;

function TCField.GetGrid: TCFDBGrid;
begin
  if Assigned(Collection) and (Collection is TCGridFields) then
    Result := TCGridFields(Collection).Grid
  else
    Result := nil;
end;

procedure TCField.SetAsInteger(Value: Integer);
var
  vGrid: TCFDBGrid;
begin
  vGrid := GetGrid;
  vGrid.Cells[vGrid.RowIndex, vGrid.FindField(Self.FieldName)] := IntToStr(Value);
  Changed(False);
end;

procedure TCField.SetAsString(Value: string);
var
  vGrid: TCFDBGrid;
begin
  vGrid := GetGrid;
  vGrid.Cells[vGrid.RowIndex, vGrid.FindField(Self.FieldName)] := Value;
  Changed(False);
end;

procedure TCField.SetFieldName(const Value: string);
var
  vGrid: TCFDBGrid;
begin
  if FFieldName <> Value then
  begin
    FFieldName := Value;
    if FTitle = '' then  // ����ֶα���Ϊ�գ������ֶα���ͱ�����һ��
      FTitle := Value;
    vGrid := GetGrid;
    vGrid.TitleText[Index] := FTitle;
    Changed(False);
  end;
end;

end.
