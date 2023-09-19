unit CFListView;

interface

uses
  Windows, Classes, Types, Messages, Graphics, Controls, Generics.Collections,
  pngimage, CFControl, CFScrollBar;

type
  TCFListView = class;
  TListViewGroup = class;

  TCustomListViewItem = class(TObject)
  private
    FListView: TCFListView;
    FGroup: TListViewGroup;
    FParent: TCustomListViewItem;
    FTitle: string;
    FObject: TObject;
    FState: TMouseState;
  protected
    function GetHeight: Integer; virtual;
    /// <summary> ����Ŀ���� </summary>
    procedure Draw(const ACanvas: TCanvas; const ADspLeft, ATop, ADspRight, ADspBottom: Integer); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property Title: string read FTitle write FTitle;
    property ObjectEx: TObject read FObject;
    property Parent: TCustomListViewItem read FParent write FParent;
  end;

  TListViewItem = class;

  TListViewGroup = class(TCustomListViewItem)
  private
    FExpand: Boolean;  // ״̬��չ�����۵�
    FChilds: TObjectList<TCustomListViewItem>;
    /// <summary> ����Ŀ���� </summary>
    procedure Draw(const ACanvas: TCanvas; const ADspLeft, ATop, ADspRight, ADspBottom: Integer); override;
    procedure AddChild(const AItem: TCustomListViewItem);
  protected
    function GetHeight: Integer; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    property Childs: TObjectList<TCustomListViewItem> read FChilds;
  end;

  TListViewItem = class(TCustomListViewItem)
  private
    FImagePng: TPngImage;
    FText: string;
  protected
    /// <summary> ��ȡ��Ŀ�е�ͼƬ </summary>
    function GetImagePng: TPngImage;

    /// <summary> ������Ŀ�е����� </summary>
    procedure SetText(Value: string);
    function GetHeight: Integer; override;
  public
    //constructor Create; virtual;
    destructor Destroy; override;

    /// <summary> ����Ŀ���� </summary>
    procedure Draw(const ACanvas: TCanvas; const ADspLeft, ATop, ADspRight, ADspBottom: Integer); override;

    property ImagePng: TPngImage read GetImagePng;
    property Text: string read FText write SetText;
  end;

  TOnItemDraw = procedure(Sender: TCustomListViewItem; const ACanvas: TCanvas;
    const ADspLeft, ATop, ADspRight, ADspBottom: Integer; var ADefaultDraw: Boolean) of object;

  TCFListView = class(TCFTextControl)
  private                        
    FItems: TObjectList<TCustomListViewItem>;
    FVScrollBar: TCFScrollBar;

    FGroupHeight,
    FItemHeight: Integer;

    /// <summary> ��ǰѡ�е���Ŀ </summary>
    FSelected: TCustomListViewItem;

    /// <summary> ��ǰ����ƶ�������Ŀ </summary>
    FMouseMove: TCustomListViewItem;

    /// <summary> ����ƶ�������Ŀ </summary>
    //FMouseMoveIndex: Integer;

    /// <summary> ��갴�µ����ĸ������� </summary>
    FMouseDownCtronl: TCFCustomControl;
    
    /// <summary> ����м�����ƽ��ʱ��ʼ���� </summary>
    FMovePt: TPoint;

    FAutoFreeObject: Boolean;  // �Զ��ͷ�Item�����Ķ���

    FOnItemDraw: TOnItemDraw;  // �ⲿ����Item�����¼�(��ʱ�������ɸ�Item���л���)

    function PtInVScrollBar(const X: Integer): Boolean;

    procedure Changed(Sender: TObject);

    /// <summary> ��ȡ��Ŀ���� </summary>
    function GetItem(Index: Integer): TCustomListViewItem;

    /// <summary> ��ֱ������ </summary>
    procedure OnVScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);

    /// <summary> �������������ʾλ�� </summary>
    procedure CalcScrollBarDspPosition;

    /// <summary> ��ȡչʾ�ĵ�һ����Ŀ�����һ����Ŀ </summary>
    procedure GetFirstItemsDisplay(var AStartItem, AEndItem, ADrawTop: Integer);

    /// <summary> ���������Ƿ���ʾ </summary>
    procedure CheckScrollBarVisible;

    /// <summary> ��ȡ���ݵĸ߶� </summary>
    function GetDataHeight: Integer;

    /// <summary> ��ȡ����ʾ���ݵ��ұ� </summary>
    function GetDataDisplayRight: Integer;

    /// <summary> ��ȡ����ʾ���ݵĵײ� </summary>
    function GetDataDisplayBottom: Integer;

    /// <summary> ��ȡ����ʾ���ݵĸ߶� </summary>
    function GetDataDisplayHeight: Integer;

    /// <summary>
    /// ��ȡָ��λ�õ�Item
    /// </summary>
    /// <param name="X">����Item���������X����</param>
    /// <param name="Y">����Item���������Y����</param>
    /// <returns></returns>
    function GetItemAt(const X, Y: Integer): TCustomListViewItem;

    /// <summary> ��ȡָ����Ŀ������ </summary>
    function GetItemDisplayRect(const AItem: TCustomListViewItem): TRect;
  protected
    /// <summary> ���Ƶ����� </summary>
    procedure DrawControl(ACanvas: TCanvas); override;
    procedure AdjustBounds; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    /// <summary> ������Ŀ�ĸ� </summary>
    procedure SetItemHeight(Value: Integer);

    /// <summary> ��ȡ������Ŀ </summary>
    function GetItemCount: Integer;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
        MousePos: TPoint): Boolean; override;
    procedure CMMouseLeave(var Msg: TMessage ); message CM_MOUSELEAVE;
  public  
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;     
    /// <summary> ����� </summary>
    function AddGroup(const ATitle: string): TListViewGroup;
    /// <summary> �����Ŀ </summary>
    function AddItem(const ATitle, AText: string; const AGroup: TListViewGroup; AObject: Pointer = nil): TListViewItem;
    procedure Clear;
    property ItemCount: Integer read GetItemCount;
    property Items[Index: Integer]: TCustomListViewItem read GetItem; default;
    property Selected: TCustomListViewItem read FSelected;
  published
    property GroupHeight: Integer read FGroupHeight write FGroupHeight;
    property ItemHeight: Integer read FItemHeight write SetItemHeight;
    property AutoFreeObject: Boolean read FAutoFreeObject write FAutoFreeObject;
    property OnItemDraw: TOnItemDraw read FOnItemDraw write FOnItemDraw;

    property Align;
    property OnClick;
    property OnDBlClick;
  end;

implementation

{$R CFListView.RES}

{ TListViewItem }

destructor TListViewItem.Destroy;
begin
  if FImagePng <> nil then
    FImagePng.Free;
  inherited Destroy;
end;

procedure TListViewItem.Draw(const ACanvas: TCanvas; const ADspLeft, ATop,
  ADspRight, ADspBottom: Integer);
var
  vLeft, vTop, vFontSize, vTitleHeight, vTextHeight: Integer;
  vDefaultDraw: Boolean;
begin
  { ���Ʊ��� }
  if cmsMouseDown in FState then  // �����Ŀѡ��
    ACanvas.Brush.Color := GDownColor
  else
  if cmsMouseIn in FState then  // ����ƶ�������Ŀ
    ACanvas.Brush.Color := GHotColor
  else
    ACanvas.Brush.Color := GBackColor;

  ACanvas.FillRect(Rect(ADspLeft, ATop, ADspRight, ATop + FListView.ItemHeight));

  { �ؼ�����Item�¼� }
  if Assigned(FListView.OnItemDraw) then  // ListView�ؼ�����Item�¼�
  begin
    vDefaultDraw := True;
    FListView.OnItemDraw(Self, ACanvas, ADspLeft, ATop, ADspRight, ADspBottom, vDefaultDraw);
    if not vDefaultDraw then Exit;
  end;

  { ����ͼƬ }
  if FImagePng <> nil then  // �����ͼƬ
  begin
    ACanvas.Draw(ADspLeft + GRoundSize, ATop + (FListView.ItemHeight - FImagePng.Height) div 2, FImagePng);  // ��ͼƬ
    vLeft := ADspLeft + GRoundSize + FImagePng.Width + GPadding;  // �Ȼ�ͼƬ��֮��Ҫ�����������
  end
  else
    vLeft := ADspLeft + GRoundSize;

  vTextHeight := ACanvas.TextHeight('��');  // ����ĸ߶�

  vFontSize := ACanvas.Font.Size;  // ����Ĵ�С
  ACanvas.Font.Size := vFontSize + 2;
  vTitleHeight := ACanvas.TextHeight('��');  // ����ĸ߶�

  ACanvas.Font.Color := clBlack;  // �������ɫ
  vTop := ATop + (FListView.ItemHeight - vTitleHeight - vTextHeight - GPadding) div 2;  // ����ĸ߶�
  ACanvas.TextOut(vLeft, vTop, FTitle);  // ����ֱ���

  // �������
  vTop := vTop + vTitleHeight + GPadding;
  ACanvas.Font.Size := vFontSize;
  ACanvas.Font.Color := clMedGray;
  ACanvas.TextOut(vLeft, vTop, FText);
  // ��ͬ��Ŀ֮��ļ����
  {vTop := ATop + FListView.ItemHeight;
  ACanvas.Pen.Color := GLineColor;
  ACanvas.MoveTo(vLeft, vTop);
  ACanvas.LineTo(ADspRight, vTop);}  // -1��������ƶ�ʱһ�����ص�ƫ�FillRect��ƫ�һ������
end;

function TListViewItem.GetHeight: Integer;
begin
  Result := FListView.ItemHeight;
end;

function TListViewItem.GetImagePng: TPngImage;
begin
  if FImagePng = nil then  // ͼƬ��Ϊ�գ����д�����Ϊ��Ŀ���ͼƬ
    FImagePng := TPngImage.Create;
  Result := FImagePng;
end;

procedure TListViewItem.SetText(Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    FListView.UpdateDirectUI;  { TODO : Լ�����Ƶ�ǰItem�������� }
  end;
end;

{ TCFListView }

function TCFListView.AddGroup(const ATitle: string): TListViewGroup;
begin
  Result := TListViewGroup.Create;
  Result.FListView := Self;
  Result.Title := ATitle;
  FItems.Add(Result);
  CalcScrollBarDspPosition;
  CheckScrollBarVisible;
end;

function TCFListView.AddItem(const ATitle, AText: string; const AGroup: TListViewGroup;
  AObject: Pointer = nil): TListViewItem;
begin
  Result := TListViewItem.Create;
  Result.FListView := Self;
  Result.Title := ATitle;  // �����Ŀ�ı���
  Result.Text := AText;  // �����Ŀ������
  Result.FObject := AObject;
  if AGroup <> nil then
  begin
    AGroup.AddChild(Result);
    Result.Parent := AGroup;
  end
  else
    FItems.Add(Result);
  CalcScrollBarDspPosition;
  CheckScrollBarVisible;
end;

procedure TCFListView.AdjustBounds;
var
  vNewWidth, vNewHeight: Integer;
begin
  if not (csReading in ComponentState) then
  begin
    if Width < 120 then
      vNewWidth := 120
    else
      vNewWidth := Width;
    if Height < 100 then
      vNewHeight := 100
    else
      vNewHeight := Height;
    SetBounds(Left, Top, vNewWidth, vNewHeight);
  end;
end;

procedure TCFListView.CalcScrollBarDspPosition;
begin
  if BorderVisible then  // �߿����
  begin
    FVScrollBar.Left := Width - FVScrollBar.Width - GBorderWidth;  // �����������
    FVScrollBar.Top := GBorderWidth;
    FVScrollBar.Height := Height - 2 * GBorderWidth;
  end
  else  // �߿򲻴���
  begin
    FVScrollBar.Left := Width - FVScrollBar.Width;
    FVScrollBar.Top := 0;
    FVScrollBar.Height := Height;
  end;
end;

procedure TCFListView.Changed(Sender: TObject);
begin
  CalcScrollBarDspPosition;
  CheckScrollBarVisible;
  UpdateDirectUI;
end;

procedure TCFListView.CheckScrollBarVisible;
var
  vMax,  // �����������ֵ
  vHeight  // ��չʾ���ݵĸ߶�
    : Integer;
  vVisible: Boolean;
begin
  vVisible := False;
  vMax := GetDataHeight;
  vHeight := Height;
  if BorderVisible then  // ����߿����
    vHeight := Height - 2 * GBorderWidth;
  vVisible := vMax > vHeight;  // ������ݵĸ߶ȴ�����չʾ���ݵĸ߶ȣ���ʾ������
  // ���ù����������ֵ�ͷ�ҳ������ֵ
  FVScrollBar.Max := vMax;
  FVScrollBar.PageSize := vHeight;

  if vVisible then  // ��Ҫ��ʾ
  begin
    if FVScrollBar.Visible then  // ��ǰ�Ѿ���ʾ�����´�����λ�ã�����vMax�͵���ǰ�б䶯����Ӱ����ʾ״̬�������
      FVScrollBar.Position := FVScrollBar.Position
    else
      FVScrollBar.Visible := True;
  end
  else
    FVScrollBar.Visible := False;

  UpdateDirectUI;
end;

procedure TCFListView.Clear;
begin
  FItems.Clear;
end;

procedure TCFListView.CMMouseLeave(var Msg: TMessage);
var
  vRect: TRect;
begin
  inherited;
  if FMouseMove <> nil then
  begin
    FMouseMove.FState := FMouseMove.FState - [cmsMouseIn];
    vRect := GetItemDisplayRect(FMouseMove);
    UpdateDirectUI(vRect);
    FMouseMove := nil;
  end;
end;

constructor TCFListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGroupHeight := 20;
  FItemHeight := 50;
  FAutoFreeObject := True;
  //FMouseMoveIndex := -1;
  FItems := TObjectList<TCustomListViewItem>.Create;

  FVScrollBar := TCFScrollBar.Create(Self);  // ������ֱ������
  FVScrollBar.Orientation := coVertical;  // ���ù�����Ϊ��ֱ����
  FVScrollBar.OnScroll := OnVScroll;  // �󶨹����¼�
  FVScrollBar.Visible := False;
end;

destructor TCFListView.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TCFListView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if WheelDelta < 0 then
  begin
    if FVScrollBar.Visible then  // ���ڹ���������
    begin
      if FVScrollBar.Position < FVScrollBar.Max - FVScrollBar.PageSize then
      begin
        FVScrollBar.Position := FVScrollBar.Position + WHEEL_DELTA;
        UpdateDirectUI;
        Result := True;
      end;
    end;
  end
  else
  begin
    if FVScrollBar.Visible then
    begin
      if FVScrollBar.Position > FVScrollBar.Min then
      begin
        FVScrollBar.Position := FVScrollBar.Position - WHEEL_DELTA;
        UpdateDirectUI;
        Result := True;
      end;
    end;
  end;
  inherited;
end;

procedure TCFListView.DrawControl(ACanvas: TCanvas);
var
  i, vDrawTop, vDspLeft, vDspRight, vDspBottom, vStartItem, vEndItem: Integer;
  //vbGroup: Boolean;
begin
  ACanvas.Brush.Color := GBackColor;
  vDspRight := GetDataDisplayRight;
  vDspBottom := GetDataDisplayHeight;
  ACanvas.FillRect(Rect(0, 0, vDspRight, GetDataDisplayBottom));  // ��䱳��

  // ��������
  if BorderVisible then  // �߿����
    vDspLeft := GBorderWidth
  else  // �߿򲻴���
    vDspLeft := 0;

  if FItems.Count <> 0 then  // ����Ŀ����
  begin
    GetFirstItemsDisplay(vStartItem, vEndItem, vDrawTop);  // �������Ե�һ�������һ������ΪGroup��Group��������һ��Item
    vDrawTop := vDrawTop - FVScrollBar.Position;
    for i := vStartItem to vEndItem do  // ������Ŀ
    begin
      FItems[i].Draw(ACanvas, vDspLeft, vDrawTop, vDspRight, vDspBottom);  // ����Ŀ
      vDrawTop := vDrawTop + FItems[i].GetHeight;
    end;
  end;

  // ��������
  if FVScrollBar.Visible then
  begin
    ACanvas.Refresh;
    i := SaveDC(ACanvas.Handle);  // ����(�豸�����Ļ���)�ֳ�
    try
      MoveWindowOrg(ACanvas.Handle, FVScrollBar.Left, FVScrollBar.Top);
      FVScrollBar.DrawTo(ACanvas);
    finally
      RestoreDC(ACanvas.Handle, i);  // �ָ�(�豸�����Ļ���)�ֳ�
    end;
  end;

  // ���Ʊ߿�
  if BorderVisible then
  begin
    with ACanvas do
    begin
      Pen.Color := GBorderColor;
      MoveTo(0, 0);
      LineTo(Width - 1, 0);
      LineTo(Width - 1, Height - 1);
      LineTo(0, Height - 1);
      LineTo(0, 0);
    end;
  end;
end;

function TCFListView.GetDataDisplayBottom: Integer;
begin
  Result := Height;
  if BorderVisible then  // �����ʾ�߿�
    Result := Result - GBorderWidth;  // ��ȥ�±߿�
end;

function TCFListView.GetDataDisplayHeight: Integer;
begin
  Result := GetDataDisplayBottom;
  if BorderVisible then  // �����ʾ�߿�
    Result := Result - GBorderWidth;  // ��ȥ�ϱ߿�
end;

function TCFListView.GetDataDisplayRight: Integer;
begin
  Result := Width;
  if FVScrollBar.Visible then
    Result := Result - FVScrollBar.Width;
  if BorderVisible then  // �����ʾ�߿�
    Result := Result - GBorderWidth;  // ��ȥ�±߿�
end;

function TCFListView.GetDataHeight: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FItems.Count - 1 do
    Result := Result + FItems[i].GetHeight;  // ���ݵĸ߶�
end;

procedure TCFListView.GetFirstItemsDisplay(var AStartItem, AEndItem, ADrawTop: Integer);
var
  vVPos: Single;
  i, vHeight: Integer;
begin
  if FItems.Count = 0 then Exit;
  AStartItem := -1;
  AEndItem := -1;
  ADrawTop := 0;
  vVPos := 0;

  if FVScrollBar.Rang > 0 then
    vVPos := FVScrollBar.Position
      * (FVScrollBar.Rang - (GetDataDisplayHeight - FVScrollBar.PageSize))  // ���ݷ�Χ����Ҫ����������ʾ�Ĵ�С(������ʾ�����Ĳ���)
      / FVScrollBar.Rang;

  // ��ȡ��ʼ��
  if BorderVisible then  // ����б߿�
    vHeight := GBorderWidth
  else
    vHeight := 0;
  ADrawTop := vHeight;

  for i := 0 to FItems.Count - 1 do
  begin
    vHeight := vHeight + FItems[i].GetHeight;
    if vHeight > vVpos then
    begin
      AStartItem := i;
      Break;
    end;
    ADrawTop := vHeight;  // ���㿪ʼ���������е���ʼλ��
  end;

  // ��ȡ������
  AEndItem := FItems.Count - 1;
  vVPos := vVPos + GetDataDisplayHeight;
  vHeight := ADrawTop;
  for i := AStartItem to FItems.Count - 1 do
  begin
    vHeight := vHeight + FItems[i].GetHeight;
    if vHeight > vVpos then
    begin
      AEndItem := i;
      Break;
    end;
  end;
end;

function TCFListView.GetItem(Index: Integer): TCustomListViewItem;
begin
  Result := FItems[Index];  // ��ȡ��Ŀ
end;

function TCFListView.GetItemAt(const X, Y: Integer): TCustomListViewItem;
var
  vPt: TPoint;
  vWidth: Integer;

  function FindItemAt(var ATop: Integer; const AItems: TObjectList<TCustomListViewItem>): TCustomListViewItem;
  var
    i, vHeight: Integer;
    vGroup: TListViewGroup;
  begin
    Result := nil;
    for i := 0 to AItems.Count - 1 do  // �õ�����ָ������Ŀ
    begin
      vHeight := AItems[i].GetHeight;
      if PtInRect(Bounds(0, ATop, vWidth, vHeight), vPt) then  // ��Ŀ��ָ��������
      begin
        Result := AItems[i];
        Break;
      end
      else
        ATop := ATop + vHeight;
    end;

    if (Result <> nil) and (Result is TListViewGroup) then  // �����������
    begin
      vGroup := Result as TListViewGroup;
      if vGroup.FExpand and  // ������Item�������ڣ���չ������Item
        (not PtInRect(Bounds(0, ATop, vWidth, FGroupHeight), vPt))
      then
      begin
        ATop := ATop + FGroupHeight;
        Result := FindItemAt(ATop, vGroup.Childs);
      end;
    end;
  end;

var
  vTop: Integer;

begin
  Result := nil;
  vPt := Point(X, Y);
  vWidth := GetDataDisplayRight;
  {if BorderVisible then  // �߿����
    vTop := GBorderWidth
  else}  // �߿򲻴���
  vTop := 0;
  Result := FindItemAt(vTop, FItems);
end;

function TCFListView.GetItemCount: Integer;
begin
  Result := FItems.Count;  // ��ȡ��Ŀ������Ŀ
end;

function TCFListView.GetItemDisplayRect(const AItem: TCustomListViewItem): TRect;

  function GetItemTop(var vTop: Integer; const AItems: TObjectList<TCustomListViewItem>): Boolean;
  var
    i, vHeight: Integer;
    vGroup: TListViewGroup;
  begin
    Result := False;
    for i := 0 to AItems.Count - 1 do  // �õ�����ָ������Ŀ
    begin
      if AItems[i] = AItem then Exit(True);

      if AItems[i] is TListViewGroup then
      begin
        vGroup := AItems[i] as TListViewGroup;
        if vGroup.FExpand then
        begin
          vTop := vTop + FGroupHeight;
          Result := GetItemTop(vTop, vGroup.Childs);
          if Result then Exit;

          Continue;
        end;
      end;
      vTop := vTop + AItems[i].GetHeight;
    end;
  end;

var
  vTop: Integer;
begin
  if BorderVisible then  // �߿����
    vTop := GBorderWidth
  else
    vTop := 0;

  if GetItemTop(vTop, FItems) then
  begin
    Result := Bounds(0, vTop, GetDataDisplayRight, AItem.GetHeight);  // ������Ŀ������
    if FVScrollBar.Visible then  // ����߿���ڣ�����ƫ��
      OffsetRect(Result, 0, -FVScrollBar.Position);
  end;
end;

procedure TCFListView.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vRect: TRect;
  vOldSelected: TCustomListViewItem;
begin
  inherited;
  FMouseDownCtronl := nil;
  if Button = mbMiddle then  // ����м�����ƽ�ƿ�ʼ
  begin
    FMovePt := Point(X, Y);
    Windows.SetCursor(LoadCursor(0, IDC_HAND));
    Exit;
  end;

  if PtInVScrollBar(X) then
  begin
    FVScrollBar.MouseDown(Button, Shift, X + FVScrollBar.Width - Width, Y);
    FMouseDownCtronl := FVScrollBar;
    Exit;
  end;

  vOldSelected := FSelected;
  FSelected := GetItemAt(X, Y + FVScrollBar.Position);  // ����������ѡ�е���Ŀ�иı�
  if FSelected <> vOldSelected then  // ԭ��ѡ�еĺ�����������ȥ����Ŀ��ͬ
  begin
    // �޸�ԭ����Ŀ��״̬
    if vOldSelected <> nil then
    begin
      vOldSelected.FState := vOldSelected.FState - [cmsMouseDown];
      if vOldSelected is TListViewItem then
      begin
        vRect := GetItemDisplayRect(vOldSelected);
        UpdateDirectUI(vRect);
      end;
    end;
    // �޸�����Ŀ��״̬
    if FSelected <> nil then
    begin
      FSelected.FState := FSelected.FState + [cmsMouseDown];
      if FSelected is TListViewItem then
      begin
        vRect := GetItemDisplayRect(FSelected);
        UpdateDirectUI(vRect);
      end;
    end;
  end;
  if FSelected = nil then
  begin
    if ssLeft in Shift then  // and (Parent.HandleAllocated)
    Begin
      ReleaseCapture;
      SendMessage(Parent.Handle, WM_SYSCOMMAND, $F011, 0);  {����3�� $F011-$F01F ֮����ɶ����ƶ��ؼ�}
    end;
  end;
end;

procedure TCFListView.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vOldMoveItem: TCustomListViewItem;
  vRect: TRect;
begin
  inherited;
  if Shift = [ssMiddle] then  // ����м䰴��
  begin
    FVScrollBar.Position := FVScrollBar.Position + (FMovePt.Y - Y);
    FMovePt.X := X;
    FMovePt.Y := Y;
    Windows.SetCursor(LoadCursor(0, IDC_HAND));
    UpdateDirectUI;
    Exit;
  end;

  if PtInVScrollBar(X) or (FMouseDownCtronl = FVScrollBar) then
    FVScrollBar.MouseMove(Shift, X + FVScrollBar.Width - Width, Y);

  vOldMoveItem := FMouseMove;
  FMouseMove := GetItemAt(X, Y + FVScrollBar.Position);
  if FMouseMove <> vOldMoveItem then
  begin
    if vOldMoveItem <> nil then
    begin
      vOldMoveItem.FState := vOldMoveItem.FState - [cmsMouseIn];
      vRect := GetItemDisplayRect(vOldMoveItem);
      UpdateDirectUI(vRect);
    end;
    if FMouseMove <> nil then
    begin
      FMouseMove.FState := FMouseMove.FState + [cmsMouseIn];
      vRect := GetItemDisplayRect(FMouseMove);
      UpdateDirectUI(vRect);
    end;
  end;
end;

procedure TCFListView.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vUpItem: TCustomListViewItem;
begin
  inherited;
  if Button = mbMiddle then
  begin
    Windows.SetCursor(LoadCursor(0, IDC_ARROW));
    Exit;
  end;

  if FMouseDownCtronl <> nil then
  begin
    FMouseDownCtronl := nil;
    Exit;
  end;

  if PtInVScrollBar(X) then
  begin
    FVScrollBar.MouseUp(Button, Shift, X + FVScrollBar.Width - Width, Y);
    Exit;
  end;

  vUpItem := GetItemAt(X, Y + FVScrollBar.Position);  // ����������ѡ�е���Ŀ�иı�
  if FSelected = vUpItem then
  begin
    if FSelected is TListViewGroup then
    begin
      (FSelected as TListViewGroup).FExpand := not (FSelected as TListViewGroup).FExpand;
      CheckScrollBarVisible;
    end;
  end;
end;

procedure TCFListView.OnVScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin 
  UpdateDirectUI;  // �ػ�����
end;

function TCFListView.PtInVScrollBar(const X: Integer): Boolean;
begin
  Result := False;
  if FVScrollBar.Visible then  // �������������
  begin
    if BorderVisible then  // ����߿����
    begin
      if (X > Width - GBorderWidth - FVScrollBar.Width) and (X < Width - GBorderWidth)  then  // ������ڹ�������Χ��
        Result := True;
    end
    else  // �߿򲻴���
    begin
      if (X > Width - FVScrollBar.Width) and (X < Width)  then  // ������ڹ�������Χ��
        Result := True;
    end;
  end;
end;

procedure TCFListView.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  if HandleAllocated then
  begin
    CheckScrollBarVisible;
    CalcScrollBarDspPosition;
  end;
end;

procedure TCFListView.SetItemHeight(Value: Integer);
begin
  if FItemHeight <> Value then
  begin
    FItemHeight := Value;
    UpdateDirectUI;
  end;
end;

{ TCustomListViewItem }

constructor TCustomListViewItem.Create;
begin
end;

destructor TCustomListViewItem.Destroy;
begin
  if (FListView.FAutoFreeObject) and (FObject <> nil) then
    FObject.Free;
  inherited;
end;

procedure TCustomListViewItem.Draw(const ACanvas: TCanvas; const ADspLeft, ATop,
  ADspRight, ADspBottom: Integer);
begin
end;

function TCustomListViewItem.GetHeight: Integer;
begin
end;

{ TListViewGroup }

procedure TListViewGroup.AddChild(const AItem: TCustomListViewItem);
begin
  FChilds.Add(AItem);
  AItem.FGroup := Self;
end;

constructor TListViewGroup.Create;
begin
  inherited;
  FChilds := TObjectList<TCustomListViewItem>.Create;
end;

destructor TListViewGroup.Destroy;
begin
  FChilds.Free;
  inherited;
end;

procedure TListViewGroup.Draw(const ACanvas: TCanvas; const ADspLeft, ATop,
  ADspRight, ADspBottom: Integer);
var
  vRect: TRect;
  //vIcon: HICON;
  vBmp: TBitmap;
  i, vTop: Integer;
  vDefaultDraw: Boolean;
begin
  if ATop >= ADspBottom then Exit;
  { ���Ʊ��� }
  vRect := Rect(ADspLeft, ATop, ADspRight, ATop + FListView.GroupHeight);
  {if i = FItemIndex then  // �����Ŀѡ��
    ACanvas.Brush.Color := GDownColor
  else}
  if cmsMouseIn in FState then  // ����ƶ�������Ŀ
    ACanvas.Brush.Color := GBorderHotColor
  else
    ACanvas.Brush.Color := GBackColor;

  ACanvas.FillRect(vRect);

  { �ؼ�����Item�¼� }
  if Assigned(FListView.OnItemDraw) then  // ListView�ؼ�����Item�¼�
  begin
    vDefaultDraw := True;
    FListView.OnItemDraw(Self, ACanvas, ADspLeft, ATop, ADspRight, ADspBottom, vDefaultDraw);
    if not vDefaultDraw then Exit;
  end;

  vBmp := TBitmap.Create;
  try
    vBmp.Transparent := True;

    if FExpand then  // չ��
      vBmp.LoadFromResourceName(HInstance, 'EXPAND')  // LoadIcon(HInstance, 'EXPAND')
    else
      vBmp.LoadFromResourceName(HInstance, 'UNEXPAND');

    //DrawIconEx(ACanvas.Handle, ADspLeft, ATop + (FListView.GroupHeight - GIconWidth) div 2, vIcon, GIconWidth, GIconWidth, 0, 0, DI_NORMAL);
    ACanvas.Draw(ADspLeft, ATop + (FListView.GroupHeight - GIconWidth) div 2, vBmp);
  finally
    vBmp.Free;
  end;

  ACanvas.Font.Color := clBlack;  // �������ɫ
  vRect := Bounds(ADspLeft + GIconWidth, ATop, FListView.Width - GIconWidth, FListView.GroupHeight);
  ACanvas.TextRect(vRect, FTitle, [tfSingleLine, tfLeft, tfVerticalCenter]);  // �������

  vTop := ATop + FListView.GroupHeight;
  if FExpand then
  begin
    for i := 0 to FChilds.Count - 1 do
    begin
      if vTop >= ADspBottom then
        Break;
      FChilds[i].Draw(ACanvas, ADspLeft, vTop, ADspRight, ADspBottom);
      vTop := vTop + FChilds[i].GetHeight;
    end;
  end;
end;

function TListViewGroup.GetHeight: Integer;
var
  i: Integer;
begin
  Result := FListView.GroupHeight;
  if FExpand then
  begin
    for i := 0 to FChilds.Count - 1 do
      Result := Result + FChilds[i].GetHeight;
  end;
end;

end.
