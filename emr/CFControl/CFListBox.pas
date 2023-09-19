unit CFListBox;

interface

uses
  Windows, Classes, Controls, Graphics, Generics.Collections, Messages, CFControl, CFScrollBar;

type
  TDrawItemEvent = procedure(const ACanvas: TCanvas; const ARect: TRect; const AIndex: Integer) of object;
  TItemSelectChangeEvent = procedure(Sender: TObject) of object;

  TCFListBox = class(TCFTextControl)
  private
    FItems: TStrings;
    FItemHeight: Integer;
    FMouseDownCtronl: TCFCustomControl;
    FPadding: Byte;           // ����ƫ�ƶ��ٿ�ʼ��ʾ�ı�
    FZoomSelected: Boolean;

    FOnDrawItem: TDrawItemEvent;
    FOnItemSelectChange: TItemSelectChangeEvent;

    /// <summary>
    /// ��ȡ�ؼ���ǰ��������ʾ���ݵĿ��
    /// </summary>
    /// <returns>���</returns>
    function GetDataDisplayWidth: Integer;

    /// <summary>
    /// ��ȡ�ؼ���ǰ��������ʾ���ݵĸ߶�
    /// </summary>
    /// <returns>�߶�</returns>
    function GetDataDisplayHeight: Integer;

    /// <summary>
    /// ��ֱ�������¼�
    /// </summary>
    /// <param name="Sender"></param>
    /// <param name="ScrollCode">��ֱ������</param>
    /// <param name="ScrollPos"></param>
    procedure OnVScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);

    procedure OnHScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure Changed(Sender: TObject);
    procedure SetItemIndex(Value: Integer);
    function GetObject(Index: Integer): TObject;
    procedure SetObject(Index: Integer; const Value: TObject);
    procedure CalcScrollBarPosition;
  protected
    FVScrollBar, FHScrollBar: TCFScrollBar;
    FItemIndex: Integer;

    procedure DrawControl(ACanvas: TCanvas); override;
    function GetCount: Integer;
    procedure SetItems(const Value: TStrings);
    procedure SetPadding(Value: Byte);
    procedure SetItemHeight(Value: Integer);
    procedure SetZoomSelected(Value: Boolean);
    procedure CheckScrollBarVisible;

    /// <summary>
    /// �õ����ָ�ڵڼ���
    /// </summary>
    /// <param name="X">ˮƽ����</param>
    /// <param name="Y">��ֱ����</param>
    /// <param name="ARow">�ڼ���</param>
    function GetItemAt(const X, Y: Integer): Integer;
    procedure AdjustBounds; override;

    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
        MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    function IndexOf(const S: string): Integer;
    //
    procedure AddItem(Item: String; AObject: TObject);
    procedure Delete(Index: Integer);
    procedure Clear;
    //
    property Objects[Index: Integer]: TObject read GetObject write SetObject;
    property Count: Integer read GetCount;
  published
    property ItemHeight: Integer read FItemHeight write SetItemHeight;
    property Items: TStrings read FItems write SetItems;
    //property Items[Index: Integer]: Pointer read Get write Put; default;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property Padding: Byte read FPadding write SetPadding;
    property ZoomSelected: Boolean read FZoomSelected write SetZoomSelected;

    property OnDrawItem: TDrawItemEvent read FOnDrawItem write FOnDrawItem;
    property OnItemSelectChange: TItemSelectChangeEvent read FOnItemSelectChange write FOnItemSelectChange;

    property Align;
    property PopupMenu;
  end;

implementation

uses
  SysUtils;

{ TCFListBox }

procedure TCFListBox.AddItem(Item: String; AObject: TObject);
begin
  if AObject <> nil then
    FItems.AddObject(Item, AObject)
  else
    FItems.Add(Item);
  {if FItemIndex < 0 then  // ��Ӻ����Զ�ѡ������ӵ�
    FItemIndex := 0;}
  CheckScrollBarVisible;
end;

procedure TCFListBox.BeginUpdate;
begin
  inherited;
  FItems.BeginUpdate;
end;

procedure TCFListBox.CalcScrollBarPosition;
begin
  if (not Assigned(FHScrollBar)) or (not Assigned(FHScrollBar)) then Exit;

  // ����λ��
  if BorderVisible then  // ��ʾ�߿�
  begin
    FHScrollBar.Left := GBorderWidth;
    FHScrollBar.Top := Height - FHScrollBar.Height - GBorderWidth;

    FVScrollBar.Left := Width - FVScrollBar.Width - GBorderWidth;
    FVScrollBar.Top := GBorderWidth;
  end
  else  // ����ʾ�߿�
  begin
    FHScrollBar.Left := 0;
    FHScrollBar.Top := Height - FHScrollBar.Height;

    FVScrollBar.Left := Width - FVScrollBar.Width;
    FVScrollBar.Top := 0;
  end;

  // ��ֱ��������PageSize��Height
  FVScrollBar.Height := GetDataDisplayHeight;
  if FHScrollBar.Visible then  // ˮƽ��������ʾ
    FVScrollBar.PageSize := Height - FHScrollBar.Height
  else  // ˮƽ��������ʾ
    FVScrollBar.PageSize := Height;
  if BorderVisible then  // �����ʾ�߿�
    FVScrollBar.PageSize := FVScrollBar.PageSize - GBorderWidth * 2;

  // ��������PageSize��Height
  FHScrollBar.Width := GetDataDisplayWidth;
  if FVScrollBar.Visible then  // ��ֱ��������ʾ
    FHScrollBar.PageSize := Width - FVScrollBar.Width
  else  // ��ֱ����������ʾ
    FHScrollBar.PageSize := Width;
  if BorderVisible then  // �����ʾ�߿�
    FHScrollBar.PageSize := FHScrollBar.PageSize - GBorderWidth * 2;
end;

procedure TCFListBox.Changed(Sender: TObject);
begin
  CheckScrollBarVisible;
  UpdateDirectUI;
end;

procedure TCFListBox.CheckScrollBarVisible;
var
  i, vWidth: Integer;
  vReUpdate: Boolean;
  vDC: HDC;
begin
  if (not Assigned(FHScrollBar)) or (not Assigned(FHScrollBar)) then Exit;
  //if not HandleAllocated then Exit;

  vReUpdate := False;
  vWidth := 0;
  // �ж�ˮƽ�������Ƿ���ʾ
  if FItems.Count > 0 then
  begin
    vDC := GetDC(0);
    try
      Canvas.Handle := vDC;
      Canvas.Font := Font;

      for i := 0 to FItems.Count - 1 do
      begin
        if Canvas.TextWidth(FItems[i]) > vWidth then
          vWidth := Canvas.TextWidth(FItems[i]);
      end;

      Canvas.Handle := 0;
    finally
      ReleaseDC(0, vDC);
    end;
  end;

  if vWidth > GetDataDisplayWidth then
  begin
    if not FHScrollBar.Visible then
    begin
      FHScrollBar.Visible := True;
      vReUpdate := True;
    end;
  end
  else
  begin
    if FHScrollBar.Visible then
    begin
      FHScrollBar.Visible := False;
      vReUpdate := True;
    end;
  end;

  FHScrollBar.Max := vWidth;

  // �жϴ�ֱ�������Ƿ���ʾ
  FHScrollBar.Width := GetDataDisplayWidth;
  FVScrollBar.Height := GetDataDisplayHeight;
  FVScrollBar.Max := FItems.Count * FItemHeight;

  if FZoomSelected and (FItemIndex <> -1) then
    FVScrollBar.Max := FVScrollBar.Max + FItemHeight;

  if FVScrollBar.Height < FVScrollBar.Max then
  begin
    if not FVScrollBar.Visible then
    begin
      FVScrollBar.Visible := True;
      vReUpdate := True;
    end;
  end
  else
  begin
    if FVScrollBar.Visible then
    begin
      FVScrollBar.Visible := False;
      vReUpdate := True;
    end;
  end;

  if FHScrollBar.Visible then
    FHScrollBar.PageSize := GetDataDisplayWidth;

  if FVScrollBar.Visible then
    FVScrollBar.PageSize := GetDataDisplayHeight;

  if vReUpdate then
    UpdateDirectUI;
end;

procedure TCFListBox.Clear;
begin
  FItems.Clear;
end;

constructor TCFListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;
  TStringList(FItems).OnChange := Changed;

  FVScrollBar := TCFScrollBar.Create(Self);  // ������ֱ������
  FVScrollBar.Orientation := coVertical;  // ���ù�����Ϊ��ֱ����
  FVScrollBar.OnScroll := OnVScroll;  // �󶨹����¼�
  FVScrollBar.Visible := False;

  FHScrollBar := TCFScrollBar.Create(Self);  // ����ˮƽ������
  FHScrollBar.Orientation := coHorizontal;  // ���ù���������Ϊˮƽ����������
  FHScrollBar.OnScroll := OnHScroll;  // �󶨹����¼�
  FHScrollBar.Visible := False;

  FZoomSelected := False;
  FItemIndex := -1;
  FPadding := 2;
  FItemHeight := 16;
  // ���û����ĳ�ʼֵ
  Width := 120;
  Height := 150;
end;

procedure TCFListBox.Delete(Index: Integer);
var
  vItemIndex: Integer;
begin
  if (Index < 0) or (Index >= Count) then Exit;

  FItems.Delete(Index);

  vItemIndex := FItemIndex;
  if vItemIndex >= Index then  // �ڵ�ǰѡ��ǰ��ɾ����
  begin
    Dec(vItemIndex);
    if (vItemIndex < 0) and (Count > 0) then
      vItemIndex := 0;
    SetItemIndex(vItemIndex);
  end;
end;

destructor TCFListBox.Destroy;
begin
  FItems.Free;
  FVScrollBar.Free;
  FHScrollBar.Free;
  inherited;
end;

function TCFListBox.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if WheelDelta < 0 then
  begin
    if FVScrollBar.Visible then
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

procedure TCFListBox.DrawControl(ACanvas: TCanvas);
var
  vRect: TRect;

  procedure DrawBorder;
  begin
    with ACanvas do
    begin
      Pen.Color := clGray;
      MoveTo(0, 0);
      LineTo(Width - 1, 0);
      LineTo(Width - 1, Height - 1);
      LineTo(0, Height - 1);
      LineTo(0, 0);
    end;
  end;

var
  i, vTop, vLeft, vRang, vDataWidth: Integer;
  vStartRow, vEndRow: Integer;
  vGridPos, vfIndex: Single;
  vItemRect: TRect;
  //vRgn: HRGN;
  vS: string;
begin
  inherited;
  // ���������ʼλ��
  vLeft := -FHScrollBar.Position;
  if BorderVisible then
    vLeft := vLeft + GBorderWidth;
  // ��������
  // ��ۣ�����
  vRect.Left := 0;
  vRect.Top := 0;
  vRect.Right := Width;
  if FVScrollBar.Visible then
    vRect.Right := vRect.Right - FVScrollBar.Width;
  vRect.Bottom := Height;
  if FHScrollBar.Visible then
    vRect.Bottom := vRect.Bottom - FHScrollBar.Height;
  if BorderVisible then
  begin
    vRect.Right := vRect.Right - GBorderWidth;
    vRect.Bottom := vRect.Bottom - GBorderWidth;
  end;
  // ������ݿɻ�������(��ȥ������)
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := GBackColor;
  ACanvas.Pen.Color := GBackColor;
  ACanvas.Rectangle(vRect);

  if FItems.Count = 0 then
  begin
    if BorderVisible then
      DrawBorder;
    Exit;
  end;
  // ������ʼ��
  vRang := FVScrollBar.Max - FVScrollBar.Min;
  vGridPos := FVScrollBar.Position
    * (vRang - (GetDataDisplayHeight - FVScrollBar.PageSize))  // ���ݷ�Χ����Ҫ����������ʾ�Ĵ�С(������ʾ�����Ĳ���)
    / vRang;
  vfIndex := vGridPos / FItemHeight;
  vStartRow := Trunc(vfIndex);
  if FZoomSelected and (vStartRow = FItemHeight) then
    vTop := -Round(Frac(vfIndex) * 2 * FItemHeight) + GBorderWidth
  else
    vTop := -Round(Frac(vfIndex) * FItemHeight) + GBorderWidth;

  // ���������
  vfIndex := (FVScrollBar.Position + GetDataDisplayHeight) / FItemHeight;
  vEndRow := Trunc(vfIndex);
  if Frac(vfIndex) > 0 then  // �����������������һ�д���
    Inc(vEndRow);
  if vEndRow > FItems.Count - 1 then
    vEndRow := FItems.Count - 1;

  // ����Լ�����Ʒ�Χ
  vDataWidth := GetDataDisplayWidth;
  if BorderVisible then
    vRect := Bounds(GBorderWidth, GBorderWidth, vDataWidth, GetDataDisplayHeight)
  else
    vRect := Bounds(0, 0, vDataWidth, GetDataDisplayHeight);

  //vRgn := CreateRectRgnIndirect(vRect);
  //SelectClipRgn(ACanvas.Handle, vRgn);
  IntersectClipRect(ACanvas.Handle, vRect.Left, vRect.Top, vRect.Right, vRect.Bottom);
  try
    for i := vStartRow to vEndRow do
    begin
      vS := FItems[i];
      vItemRect := Bounds(vLeft, vTop, vDataWidth, FItemHeight);
      if i = FItemIndex then
      begin
        ACanvas.Brush.Color := GHightLightColor;
        if FZoomSelected then
        begin
          vItemRect.Bottom := vItemRect.Bottom + FItemHeight;
          ACanvas.Font.Size := Font.Size * 2;
        end;
        ACanvas.FillRect(vItemRect);
      end
      else
      begin
        ACanvas.Brush.Color := GBackColor;
        ACanvas.Font.Size := Font.Size;
      end;

      vItemRect.Left := vItemRect.Left + FPadding;
      ACanvas.TextOut(vLeft + FPadding, vTop, vS);
      if Assigned(FOnDrawItem) then
        FOnDrawItem(ACanvas, vItemRect, i);
      //Windows.DrawTextEx(ACanvas.Handle, PChar(vS), -1, vItemRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE, nil);
      //Windows.ExtTextOut(ACanvas.Handle, vLeft + FPadding, vTop, 0, nil, vS, Length(vS), nil);
      //ACanvas.TextRect();
      vTop := vTop + (vItemRect.Bottom - vItemRect.Top);
    end;
  finally
    SelectClipRgn(ACanvas.Handle, 0);
    //DeleteObject(vRgn);
  end;

  // ��������
  if FVScrollBar.Visible then
  begin
    i := SaveDC(ACanvas.Handle);  // ����(�豸�����Ļ���)�ֳ�
    try
      MoveWindowOrg(ACanvas.Handle, FVScrollBar.Left, FVScrollBar.Top);
      FVScrollBar.DrawTo(ACanvas);
    finally
      RestoreDC(ACanvas.Handle, i);  // �ָ�(�豸�����Ļ���)�ֳ�
    end;
  end;
  if FHScrollBar.Visible then
  begin
    i := SaveDC(ACanvas.Handle);  // ����(�豸�����Ļ���)�ֳ�
    try
      MoveWindowOrg(ACanvas.Handle, FHScrollBar.Left, FHScrollBar.Top);
      FHScrollBar.DrawTo(ACanvas);
    finally
      RestoreDC(ACanvas.Handle, i);  // �ָ�(�豸�����Ļ���)�ֳ�
    end;
  end;

  if FVScrollBar.Visible and FHScrollBar.Visible then
  begin
    // �������������ཻ�Ľ�
    ACanvas.Brush.Color := clBtnFace;
    ACanvas.FillRect(Rect(Width - FVScrollBar.Width,
                          Height - FHScrollBar.Height,
                          Width - GBorderWidth,
                          Height - GBorderWidth)
                    );
  end;
  if BorderVisible then
    DrawBorder;
end;

procedure TCFListBox.EndUpdate;
begin
  FItems.EndUpdate;
  inherited;
end;

procedure TCFListBox.AdjustBounds;
var
  vDC: HDC;
begin
  vDC := GetDC(0);
  try
    Canvas.Handle := vDC;
    Canvas.Font := Font;
    FItemHeight := Canvas.TextHeight('��') + GetSystemMetrics(SM_CYBORDER) * 4;
    Canvas.Handle := 0;
  finally
    ReleaseDC(0, vDC);
  end;

  CheckScrollBarVisible;
end;

function TCFListBox.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TCFListBox.GetDataDisplayHeight: Integer;
begin
  if FHScrollBar.Visible then
    Result := Height - FHScrollBar.Height
  else
    Result := Height;

  if BorderVisible then
    Result := Result - 2 * GBorderWidth;
end;

function TCFListBox.GetDataDisplayWidth: Integer;
begin
  if FVScrollBar.Visible then
    Result := Width - FVScrollBar.Width
  else
    Result := Width;
  if BorderVisible then
    Result := Result - 2 * GBorderWidth
end;

function TCFListBox.GetItemAt(const X, Y: Integer): Integer;
var
  i, vBottom: Integer;
  vGridPos: Single;
begin
  Result := -1;
  if Count = 0 then Exit;

  if (X > 0) and (X < GetDataDisplayWidth) and (Y > 0) and (Y < GetDataDisplayHeight) then
  begin
    vGridPos := (FVScrollBar.Position + Y)
      * (FVScrollBar.Rang - (GetDataDisplayHeight - FVScrollBar.PageSize))
      / FVScrollBar.Rang;

    if FZoomSelected then
    begin
      vBottom := 0;
      for i := 0 to Count - 1 do
      begin
        if i = FItemIndex then
          vBottom := vBottom + FItemHeight * 2
        else
          vBottom := vBottom + FItemHeight;
        if vBottom > vGridPos then
        begin
          Result := i;
          Break;
        end;
      end;
    end
    else
      Result := Trunc(vGridPos / FItemHeight);
  end;
end;

function TCFListBox.GetObject(Index: Integer): TObject;
begin
  Result := FItems.Objects[Index];
end;

function TCFListBox.IndexOf(const S: string): Integer;
begin
  Result := FItems.IndexOf(S);
end;

procedure TCFListBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vItemIndex: Integer;
begin
  inherited;
  if (X > GetDataDisplayWidth) and (Y < GetDataDisplayHeight) then
  begin
    FMouseDownCtronl := FVScrollBar;
    FVScrollBar.MouseDown(Button, Shift, X - GetDataDisplayWidth, Y);
  end
  else
  if (Y > GetDataDisplayHeight) and (X < GetDataDisplayWidth) then
  begin
    FMouseDownCtronl := FHScrollBar;
    FHScrollBar.MouseDown(Button, Shift,  X, Y - GetDataDisplayHeight);
  end
  else
  begin
    vItemIndex := GetItemAt(X, Y);
    if FItemIndex <> vItemIndex then
    begin
      SetItemIndex(vItemIndex);
      UpdateDirectUI;
    end;
    if Assigned(OnMouseDown) then
      OnMouseDown(Self, Button, Shift, X, Y);
  end;
end;

procedure TCFListBox.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FMouseDownCtronl = FVScrollBar then
    FVScrollBar.MouseMove(Shift, X - GetDataDisplayWidth, Y)
  else
  if FMouseDownCtronl = FHScrollBar then
    FHScrollBar.MouseMove(Shift, X, Y - GetDataDisplayHeight);
end;

procedure TCFListBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if FMouseDownCtronl = FVScrollBar then
    FVScrollBar.MouseUp(Button, Shift, X - GetDataDisplayWidth, Y)
  else
  if FMouseDownCtronl = FHScrollBar then
    FHScrollBar.MouseUp(Button, Shift, X, Y - GetDataDisplayHeight);
  if FMouseDownCtronl <> nil then
    FMouseDownCtronl := nil
  else
  begin
    if Assigned(OnClick) then
      OnClick(Self);
  end;
end;

procedure TCFListBox.OnHScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  UpdateDirectUI;  // �ػ�����
end;

procedure TCFListBox.OnVScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  UpdateDirectUI;  // �ػ�����
end;

procedure TCFListBox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  CalcScrollBarPosition;
  CheckScrollBarVisible;
end;

procedure TCFListBox.SetItemHeight(Value: Integer);
begin
  if FItemHeight <> Value then
  begin
    FItemHeight := Value;
    UpdateDirectUI;
  end;
end;

procedure TCFListBox.SetItemIndex(Value: Integer);
begin
  if FItemIndex <> Value then
  begin
    FItemIndex := Value;
    UpdateDirectUI;
    if Assigned(FOnItemSelectChange) then
      FOnItemSelectChange(Self);  // ����Ҫʱ����չΪ�Ƿ������л�����ǰItem
  end;
end;

procedure TCFListBox.SetItems(const Value: TStrings);
begin
  if Assigned(FItems) then
    FItems.Assign(Value)
  else
    FItems := Value;
  {if FItemIndex < 0 then
    FItemIndex := 0;}
  CheckScrollBarVisible;
end;

procedure TCFListBox.SetObject(Index: Integer; const Value: TObject);
begin
  FItems.Objects[Index] := Value;
end;

procedure TCFListBox.SetPadding(Value: Byte);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    UpdateDirectUI;
  end;
end;

procedure TCFListBox.SetZoomSelected(Value: Boolean);
begin
  if FZoomSelected <> Value then
  begin
    FZoomSelected := Value;
    CheckScrollBarVisible;
    UpdateDirectUI;
  end;
end;

end.
