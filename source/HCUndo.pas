{*******************************************************}
{                                                       }
{               HCView V1.1  ���ߣ���ͨ                 }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2018-5-4              }
{                                                       }
{             �ĵ��������ָ�������͵�Ԫ                }
{                                                       }
{*******************************************************}

unit HCUndo;

interface

uses
  Classes, Generics.Collections, HCCommon;

type

  { THCUndo.Data���֣�һ����Item�Լ�ʹ�� }

  THCMirrorUndoData = class(TObject)
  private
    FStream: TMemoryStream;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property Stream: TMemoryStream read FStream write FStream;
  end;

  THCBaseKeysUndoData = class(TObject)  // ��������ֵ����
  private
    A, B: Integer;
  end;

  THCCellUndoData = class(THCBaseKeysUndoData)  // ��Ԫ���ڲ�HCData�Լ�����
  public
    property Row: Integer read A write A;
    property Col: Integer read B write B;
  end;

  THCMulCellUndoData = class(THCCellUndoData);

  THCColSizeUndoData = class(THCBaseKeysUndoData)  // �ı��п�
  private
    FCol: Integer;
  public
    property Col: Integer read FCol write FCol;
    property OldWidth: Integer read A write A;
    property NewWidth: Integer read B write B;
  end;

  THCRowSizeUndoData = class(THCBaseKeysUndoData)  // �ı��и�
  private
    FRow: Integer;
  public
    property Row: Integer read FRow write FRow;
    property OldHeight: Integer read A write A;
    property NewHeight: Integer read B write B;
  end;

  THCSizeUndoData = class(THCBaseKeysUndoData)  // Item�ߴ�ı�(����RectItem)
  private
    FNewWidth, FNewHeight: Integer;
  public
    property OldWidth: Integer read A write A;
    property OldHeight: Integer read B write B;
    property NewWidth: Integer read FNewWidth write FNewWidth;
    property NewHeight: Integer read FNewHeight write FNewHeight;
  end;

  { UndoAction���� }

  THCCustomUndoAction = class(TObject)
  private
    FTag: THCAction;
    FItemNo,  // �¼�����ʱ��ItemNo
    FOffset  // �¼�����ʱ��Offset
      : Integer;
    FParaFirst: Boolean;
  public
    constructor Create; virtual;
    property ItemNo: Integer read FItemNo write FItemNo;
    property Offset: Integer read FOffset write FOffset;
    property ParaFirst: Boolean read FParaFirst write FParaFirst;
    property Tag: THCAction read FTag write FTag;
  end;

  THCTextUndoAction = class(THCCustomUndoAction)
  private
    FText: string;
  public
    property Text: string read FText write FText;
  end;

  THCSetItemTextUndoAction = class(THCTextUndoAction)
  private
    FNewText: string;
  public
    property NewText: string read FNewText write FNewText;
  end;

  /// <summary> Itemͨ������ </summary>
  TItemProperty = (uipStyleNo, uipParaNo, uipParaFirst, uipPageBreak);

  THCItemPropertyUndoAction = class(THCCustomUndoAction)
  strict private
    FItemProperty: TItemProperty;
  public
    constructor Create; override;
    property ItemProperty: TItemProperty read FItemProperty write FItemProperty;
  end;

  THCItemStyleUndoAction = class(THCItemPropertyUndoAction)
  private
    FOldStyleNo, FNewStyleNo: Integer;
  public
    constructor Create; override;
    property OldStyleNo: Integer read FOldStyleNo write FOldStyleNo;
    property NewStyleNo: Integer read FNewStyleNo write FNewStyleNo;
  end;

  THCItemParaUndoAction = class(THCItemPropertyUndoAction)
  private
    FOldParaNo, FNewParaNo: Integer;
  public
    constructor Create; override;
    property OldParaNo: Integer read FOldParaNo write FOldParaNo;
    property NewParaNo: Integer read FNewParaNo write FNewParaNo;
  end;

  THCItemParaFirstUndoAction = class(THCItemPropertyUndoAction)
  private
    FOldParaFirst, FNewParaFirst: Boolean;
  public
    constructor Create; override;
    property OldParaFirst: Boolean read FOldParaFirst write FOldParaFirst;
    property NewParaFirst: Boolean read FNewParaFirst write FNewParaFirst;
  end;

  THCItemPageBreakUndoAction = class(THCItemPropertyUndoAction)
  private
    FOldPageBreak, FNewPageBreak: Boolean;
  public
    constructor Create; override;
    property OldPageBreak: Boolean read FOldPageBreak write FOldPageBreak;
    property NewPageBreak: Boolean read FNewPageBreak write FNewPageBreak;
  end;

  THCItemUndoAction = class(THCCustomUndoAction)
  private
    FItemStream: TMemoryStream;
  public
    constructor Create; override;
    destructor Destroy; override;
    property ItemStream: TMemoryStream read FItemStream write FItemStream;
  end;

  THCItemSelfUndoAction = class(THCCustomUndoAction)
  private
    FObject: TObject;
  public
    constructor Create; override;
    destructor Destroy; override;
    property &Object: TObject read FObject write FObject;
  end;

  THCUndoActions = class(TObjectList<THCCustomUndoAction>)
  private
    //FTag: TUndoActionTag;
  public
    //property Tag: TUndoActionTag read FTag write FTag;
  end;

  { Undo���� }

  THCCustomUndo = class(TObject)
  private
    FActions: THCUndoActions;
    FIsUndo: Boolean;  // ����״̬
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property Actions: THCUndoActions read FActions write FActions;
    property IsUndo: Boolean read FIsUndo write FIsUndo;
  end;

  THCUndo = class(THCCustomUndo)
  private
    FData: TObject;  // ��Ÿ��೷������
  public
    constructor Create; override;
    function ActionAppend(const ATag: THCAction;
      const AItemNo, AOffset: Integer; const AParaFirst: Boolean): THCCustomUndoAction;
    property Data: TObject read FData write FData;
  end;

  THCDataUndo = class(THCUndo)
  private
    FCaretDrawItemNo: Integer;
  public
    property CaretDrawItemNo: Integer read FCaretDrawItemNo write FCaretDrawItemNo;
  end;

  THCEditUndo = class(THCDataUndo)
  private
    FHScrollPos, FVScrollPos: Integer;
  public
    constructor Create; override;
    property HScrollPos: Integer read FHScrollPos write FHScrollPos;
    property VScrollPos: Integer read FVScrollPos write FVScrollPos;
  end;

  THCSectionUndo = class(THCEditUndo)
  private
    FSectionIndex: Integer;
  public
    constructor Create; override;
    property SectionIndex: Integer read FSectionIndex write FSectionIndex;
  end;

  THCUndoGroupBegin = class(THCDataUndo)
  private
    FItemNo, FOffset: Integer;
  public
    property ItemNo: Integer read FItemNo write FItemNo;
    property Offset: Integer read FOffset write FOffset;
  end;

  THCUndoEditGroupBegin = class(THCUndoGroupBegin)
  private
    FHScrollPos, FVScrollPos: Integer;
  public
    constructor Create; override;
    property HScrollPos: Integer read FHScrollPos write FHScrollPos;
    property VScrollPos: Integer read FVScrollPos write FVScrollPos;
  end;

  THCSectionUndoGroupBegin = class(THCUndoEditGroupBegin)
  private
    FSectionIndex: Integer;
  public
    constructor Create; override;
    property SectionIndex: Integer read FSectionIndex write FSectionIndex;
  end;

  THCUndoGroupEnd = class(THCDataUndo)  // ���̳�THCUndoGroupBegin����ֹ is�ж�ʱ��Ϊ��THCUndoGroupBegin
  private
    FItemNo, FOffset: Integer;
  public
    property ItemNo: Integer read FItemNo write FItemNo;
    property Offset: Integer read FOffset write FOffset;
  end;

  THCUndoEditGroupEnd = class(THCUndoGroupEnd)
  private
    FHScrollPos, FVScrollPos: Integer;
  public
    constructor Create; override;
    property HScrollPos: Integer read FHScrollPos write FHScrollPos;
    property VScrollPos: Integer read FVScrollPos write FVScrollPos;
  end;

  THCSectionUndoGroupEnd = class(THCUndoEditGroupEnd)
  private
    FSectionIndex: Integer;
  public
    constructor Create; override;
    property SectionIndex: Integer read FSectionIndex write FSectionIndex;
  end;

  TUndoNewEvent = function(): THCUndo of object;
  TUndoEvent = procedure (const Sender: THCUndo) of object;
  TUndoGroupBeginEvent = function(const AItemNo, AOffset: Integer): THCUndoGroupBegin of object;
  TUndoGroupEndEvent = function(const AItemNo, AOffset: Integer): THCUndoGroupEnd of object;

  { UndoList���� }

  THCUndoList = class(TObjectList<THCUndo>)
  private
    FSeek: Integer;
    FEnable: Boolean;  // �Ƿ����ִ�г����ָ�
    FEnableStateStack: TStack<Boolean>;
    FGroupWorking: Boolean;  // �������
    FMaxUndoCount: Cardinal;  // �����ָ�������󳤶�

    // ��ǰ�鳷���ָ�ʱ������ʼ�������
    //FGroupBegin: THCUndoGroupBegin;
    //FGroupEnd: THCUndoGroupEnd;
    FGroupBeginIndex, FGroupEndIndex: Integer;

    FOnUndoNew: TUndoNewEvent;
    FOnUndoGroupStart: TUndoGroupBeginEvent;
    FOnUndoGroupEnd: TUndoGroupEndEvent;
    FOnUndo, FOnRedo, FOnUndoDestroy: TUndoEvent;

    procedure DoNewUndo(const AUndo: THCUndo);
  protected
    procedure Notify(const Value: THCUndo; Action: TCollectionNotification); override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure UndoGroupBegin(const AItemNo, AOffset: Integer);
    procedure UndoGroupEnd(const AItemNo, AOffset: Integer);
    function UndoNew: THCUndo;
    procedure Undo;
    procedure Redo;
    procedure Clear;
    procedure SaveState;
    procedure RestoreState;

    property Enable: Boolean read FEnable write FEnable;
    property MaxUndoCount: Cardinal read FMaxUndoCount write FMaxUndoCount;
    property Seek: Integer read FSeek;
    property GroupWorking: Boolean read FGroupWorking;
    property CurGroupBeginIndex: Integer read FGroupBeginIndex;
    property CurGroupEndIndex: Integer read FGroupEndIndex;
    property OnUndoNew: TUndoNewEvent read FOnUndoNew write FOnUndoNew;
    property OnUndoGroupStart: TUndoGroupBeginEvent read FOnUndoGroupStart write FOnUndoGroupStart;
    property OnUndoGroupEnd: TUndoGroupEndEvent read FOnUndoGroupEnd write FOnUndoGroupEnd;
    property OnUndoDestroy: TUndoEvent read FOnUndoDestroy write FOnUndoDestroy;

    property OnUndo: TUndoEvent read FOnUndo write FOnUndo;
    property OnRedo: TUndoEvent read FOnRedo write FOnRedo;
  end;

  TGetUndoListEvent = function (): THCUndoList of object;

implementation

{ THCCustomUndo }

constructor THCCustomUndo.Create;
begin
  FIsUndo := True;
  FActions := THCUndoActions.Create;
end;

destructor THCCustomUndo.Destroy;
begin
  FActions.Free;
  inherited;
end;

{ THCUndoList }

procedure THCUndoList.UndoGroupBegin(const AItemNo, AOffset: Integer);
var
  vUndoGroupBegin: THCUndoGroupBegin;
begin
  FGroupWorking := True;
  if Assigned(FOnUndoGroupStart) then
    vUndoGroupBegin := FOnUndoGroupStart(AItemNo, AOffset)
  else
    vUndoGroupBegin := THCUndoGroupBegin.Create;

  vUndoGroupBegin.ItemNo := AItemNo;
  vUndoGroupBegin.Offset := AOffset;

  DoNewUndo(vUndoGroupBegin);
end;

procedure THCUndoList.Clear;
begin
  inherited Clear;
  FSeek := -1;
  FGroupBeginIndex := -1;
  FGroupEndIndex := -1;
end;

constructor THCUndoList.Create;
begin
  inherited Create;
  FEnableStateStack := TStack<Boolean>.Create;
  FSeek := -1;
  FMaxUndoCount := 99;
  FEnable := True;
  FGroupBeginIndex := -1;
  FGroupEndIndex := -1;
end;

destructor THCUndoList.Destroy;
begin
  FEnableStateStack.Free;
  inherited Destroy;
end;

procedure THCUndoList.DoNewUndo(const AUndo: THCUndo);
var
  i, vIndex, vOver: Integer;
begin
  if FSeek < Self.Count - 1 then
  begin
    if FSeek >= 0 then
    begin
      if Items[FSeek].IsUndo then
        Inc(FSeek);

      Self.DeleteRange(FSeek, Self.Count - FSeek);
    end
    else
      Self.Clear;
  end;

  if (Self.Count > FMaxUndoCount) and (not FGroupWorking) then  // �����б�������������
  begin
    vOver := 0;

    if Items[0] is THCUndoGroupBegin then  // ����ɾ��
    begin
      for i := 1 to Self.Count - 1 do
      begin
        if Items[i] is THCUndoGroupEnd then
        begin
          if vOver = 0 then
          begin
            vIndex := i;
            Break;
          end
          else
            Dec(vOver);
        end
        else
        if Items[i] is THCUndoGroupBegin then
          Inc(vOver);
      end;

      Self.DeleteRange(0, vIndex + 1);
    end
    else
      Self.Delete(0);
  end;

  Self.Add(AUndo);
  FSeek := Self.Count - 1;
end;

procedure THCUndoList.UndoGroupEnd(const AItemNo, AOffset: Integer);
var
  vUndoGroupEnd: THCUndoGroupEnd;
begin
  if not (Self.Last is THCUndoGroupBegin) then  // ����û���κζ����ĳ���
  begin
    if Assigned(FOnUndoGroupEnd) then
      vUndoGroupEnd := FOnUndoGroupEnd(AItemNo, AOffset)
    else
      vUndoGroupEnd := THCUndoGroupEnd.Create;

    vUndoGroupEnd.ItemNo := AItemNo;
    vUndoGroupEnd.Offset := AOffset;

    DoNewUndo(vUndoGroupEnd);
  end
  else
  if Self.Last is THCUndoGroupBegin then
    Self.Delete(Self.Count - 1);

  FGroupWorking := False;
end;

function THCUndoList.UndoNew: THCUndo;
begin
  if Assigned(FOnUndoNew) then
    Result := FOnUndoNew
  else
    Result := THCUndo.Create;

  DoNewUndo(Result);
end;

procedure THCUndoList.Notify(const Value: THCUndo;
  Action: TCollectionNotification);
begin
  if (Action = cnRemoved) and Assigned(FOnUndoDestroy) then
    FOnUndoDestroy(Value);

  inherited Notify(Value, Action);
end;

procedure THCUndoList.Redo;

  procedure DoSeekRedoEx;
  begin
    Inc(FSeek);

    if Assigned(FOnRedo) then
      FOnRedo(Items[FSeek]);

    Items[FSeek].IsUndo := True;
  end;

var
  i, vOver, vEndIndex: Integer;
begin
  if FSeek < Self.Count - 1 then
  begin
    if Self.Items[FSeek + 1] is THCUndoGroupBegin then
    begin
      vOver := 0;
      vEndIndex := Self.Count - 1;

      // �ҽ���
      for i := FSeek + 2 to Self.Count - 1 do
      begin
        if Self.Items[i] is THCUndoGroupEnd then
        begin
          if vOver = 0 then
          begin
            vEndIndex := i;
            Break;
          end
          else
            Dec(vOver);
        end
        else
        if Items[i] is THCUndoGroupBegin then
          Inc(vOver);
      end;

      FGroupBeginIndex := FSeek + 1;
      FGroupEndIndex := vEndIndex;
      try
        FGroupWorking := True;
        while FSeek < vEndIndex do  // �������ڸ���Redo
        begin
          if FSeek = vEndIndex - 1 then  // �鴦������
            FGroupWorking := False;

          DoSeekRedoEx;
        end;
      finally
        FGroupWorking := False;
        FGroupBeginIndex := -1;
        FGroupEndIndex := -1;
      end;
    end
    else
      DoSeekRedoEx;
  end;
end;

procedure THCUndoList.RestoreState;
begin
  if FEnableStateStack.Count > 0 then
    FEnable := FEnableStateStack.Pop;
end;

procedure THCUndoList.SaveState;
begin
  FEnableStateStack.Push(FEnable);
end;

procedure THCUndoList.Undo;

  procedure DoSeekUndoEx;
  begin
    if Assigned(FOnUndo) then
      FOnUndo(Self.Items[FSeek]);

    Self.Items[FSeek].IsUndo := False;
    Dec(FSeek);
  end;

var
  i, vOver, vBeginIndex: Integer;
begin
  if FSeek >= 0 then
  begin
    if Self.Items[FSeek] is THCUndoGroupEnd then  // �鳷�������Ӻ���ǰ��1��
    begin
      vOver := 0;

      // �ҴӺ���ǰ���1��
      vBeginIndex := 0;
      for i := FSeek - 1 downto 0 do
      begin
        if Items[i] is THCUndoGroupBegin then
        begin
          if vOver = 0 then
          begin
            vBeginIndex := i;
            Break;
          end
          else
            Dec(vOver);
        end
        else
        if Items[i] is THCUndoGroupEnd then
          Inc(vOver);
      end;

      FGroupBeginIndex := vBeginIndex;
      FGroupEndIndex := FSeek;
      try
        FGroupWorking := True;
        while FSeek >= vBeginIndex do  // �������ڸ���Undo
        begin
          if FSeek = vBeginIndex then  // �鴦������
            FGroupWorking := False;

          DoSeekUndoEx;
        end;
      finally
        FGroupWorking := False;
        FGroupBeginIndex := -1;
        FGroupEndIndex := -1;
      end;
    end
    else
      DoSeekUndoEx;
  end;
end;

{ THCUndo }

function THCUndo.ActionAppend(const ATag: THCAction;
  const AItemNo, AOffset: Integer; const AParaFirst: Boolean): THCCustomUndoAction;
begin
  case ATag of
    actBackDeleteText, actDeleteText, actInsertText:
      Result := THCTextUndoAction.Create;

    actSetItemText:
      Result := THCSetItemTextUndoAction.Create;

    actDeleteItem, actInsertItem, actItemMirror:
      Result := THCItemUndoAction.Create;

    //uatItemProperty:  // ����Ҫ�ɣ����Եĸı�ֱ��Create�˸��Ե�Action����ActionAppend
    //  Result := THCItemParaFirstUndoAction.Create;

    actItemSelf:
      Result := THCItemSelfUndoAction.Create;
  else
    Result := THCCustomUndoAction.Create;
  end;

  Result.Tag := ATag;
  Result.ItemNo := AItemNo;
  Result.Offset := AOffset;
  Result.ParaFirst := AParaFirst;

  FActions.Add(Result);
end;

constructor THCUndo.Create;
begin
  inherited Create;
  FData := nil;
end;

{ THCCustomUndoAction }

constructor THCCustomUndoAction.Create;
begin
  inherited Create;
  FItemNo := -1;
  FOffset := -1;
end;

{ THCItemUndoAction }

constructor THCItemUndoAction.Create;
begin
  inherited Create;
  FItemStream := TMemoryStream.Create;
end;

destructor THCItemUndoAction.Destroy;
begin
  FItemStream.Free;
  inherited Destroy;
end;

{ THCItemPropertyUndoAction }

constructor THCItemPropertyUndoAction.Create;
begin
  inherited Create;
  Self.Tag := THCAction.actItemProperty;
end;

{ THCItemParaFirstUndoAction }

constructor THCItemParaFirstUndoAction.Create;
begin
  inherited Create;
  Self.ItemProperty := TItemProperty.uipParaFirst;
end;

{ THCItemSelfUndoAction }

constructor THCItemSelfUndoAction.Create;
begin
  inherited Create;
  Self.Tag := THCAction.actItemSelf;
  FObject := nil;
end;

destructor THCItemSelfUndoAction.Destroy;
begin
  if FObject <> nil then
    FObject.Free;
  inherited Destroy;
end;

{ THCMirrorUndoData }

constructor THCMirrorUndoData.Create;
begin
  FStream := TMemoryStream.Create;
end;

destructor THCMirrorUndoData.Destroy;
begin
  if FStream <> nil then
    FStream.Free;
  inherited Destroy;
end;

{ THCSectionUndo }

constructor THCSectionUndo.Create;
begin
  inherited Create;
  FSectionIndex := -1;
end;

{ THCSectionUndoGroupBegin }

constructor THCSectionUndoGroupBegin.Create;
begin
  inherited Create;
  FSectionIndex := -1;
end;

{ THCEditUndo }

constructor THCEditUndo.Create;
begin
  inherited Create;
  FHScrollPos := 0;
  FVScrollPos := 0;
end;

{ THCUndoEditGroupBegin }

constructor THCUndoEditGroupBegin.Create;
begin
  inherited Create;
  FHScrollPos := 0;
  FVScrollPos := 0;
end;

{ THCUndoEditGroupEnd }

constructor THCUndoEditGroupEnd.Create;
begin
  inherited Create;
  FHScrollPos := 0;
  FVScrollPos := 0;
end;

{ THCSectionUndoGroupEnd }

constructor THCSectionUndoGroupEnd.Create;
begin
  inherited Create;
  FSectionIndex := -1;
end;

{ THCItemStyleUndoAction }

constructor THCItemStyleUndoAction.Create;
begin
  inherited Create;
  Self.ItemProperty := TItemProperty.uipStyleNo;
end;

{ THCItemParaUndoAction }

constructor THCItemParaUndoAction.Create;
begin
  inherited Create;
  Self.ItemProperty := TItemProperty.uipParaNo;
end;

{ THCItemPageBreakUndoAction }

constructor THCItemPageBreakUndoAction.Create;
begin
  inherited Create;
  Self.ItemProperty := TItemProperty.uipPageBreak;
end;

end.
