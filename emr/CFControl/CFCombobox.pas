unit CFCombobox;

interface

uses
  Windows, Classes, Controls, CFControl, Graphics, Messages, CFEdit, CFPopup, CFListBox;

type
  TCFComListBox = class(TCFListBox)
  private
    /// <summary>
    /// ���ش�ֱ�����������ListBox������
    /// </summary>
    /// <returns></returns>
    function GetVScrollBarBound: TRect;
    // ��Ϊ�ӿؼ�ʱʹ�õ��Զ�����Ϣ
    procedure WMCFMOUSEMOVE(var Message: TMessage); message WM_CF_MOUSEMOVE;
    procedure WMCFLBUTTONDOWN(var Message: TMessage); message WM_CF_LBUTTONDOWN;
    procedure WMCFLBUTTONUP(var Message: TMessage); message WM_CF_LBUTTONUP;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TCloseUpEvent = procedure(const AItemIndex, AItemX, AItemY: Integer; var ACanCloseUp: Boolean) of Object;

  TComboBoxStyle = (csDropDown, csDropDownList);//csSimple, csOwnerDrawFixed, csOwnerDrawVariable;
  TCFCombobox = class(TCFEdit)
  private
    FButtonRect: TRect;
    FPopup: TCFPopup;
    FListBox: TCFComListBox;
    FDropDownCount: Byte;
    FOnCloseUp: TCloseUpEvent;
    FBtnMouseState: TMouseState;
    FStyle: TComboBoxStyle;

    procedure PopupItem;
    function GetDropHeight: Integer;
    function GetDropDownFont: TFont;
    procedure SetDropDownFont(Value: TFont);
    procedure DoOnPopupClose(Sender: TObject);
    procedure DoOnPopupDrawWindow(const ADC: HDC; const AClentRect: TRect);
    function GetPopupWidth: Integer;
    procedure SetPopupWidth(const Value: Integer);
    function GetPopupHeight: Integer;
    procedure SetPopupHeight(const Value: Integer);
  protected
    procedure DrawControl(ACanvas: TCanvas); override;
    function GetItems: TStrings;
    procedure SetItems(const Value: TStrings);
    procedure SetDropDownCount(Value: Byte);
    function GetItemHeight: Integer;
    procedure SetItemHeight(Value: Integer);
    procedure SetOnDrawItemEvent(Value: TDrawItemEvent);
    function GetOnDrawItemEvent: TDrawItemEvent;
    function GetItemIndex: Integer;
    procedure SetItemIndex(Value: Integer);
    function GetZoomSelected: Boolean;
    procedure SetZoomSelected(Value: Boolean);
    procedure SetStyle(Value: TComboBoxStyle);
    //
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseEnter(var Msg: TMessage ); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage ); message CM_MOUSELEAVE;
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    // ֧�ֵ��������б�ʹ�õ��¼�����Ϣ
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMCFLBUTTONDOWN(var Message: TMessage); message WM_CF_LBUTTONDOWN;
    procedure WMCFLBUTTONUP(var Message: TMessage); message WM_CF_LBUTTONUP;
    procedure WMCFMOUSEMOVE(var Message: TMessage); message WM_CF_MOUSEMOVE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Delete(Index: Integer);
    procedure Clear;
  published
    property ItemHeight: Integer read GetItemHeight write SetItemHeight;
    property Items: TStrings read GetItems write SetItems;
    property DropDownCount: Byte read FDropDownCount write SetDropDownCount default 8;
    property DropDownFont: TFont read GetDropDownFont write SetDropDownFont;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property Style: TComboBoxStyle read FStyle write SetStyle default csDropDown;
    property ZoomSelected: Boolean read GetZoomSelected write SetZoomSelected;
    property PopupWidth: Integer read GetPopupWidth write SetPopupWidth;
    property PopupHeight: Integer read GetPopupHeight write SetPopupHeight;

    property OnDrawItem: TDrawItemEvent read GetOnDrawItemEvent write SetOnDrawItemEvent;
    property OnCloseUp: TCloseUpEvent read FOnCloseUp write FOnCloseUp;
  end;

implementation

{$R CFCombobox.res}

{ TCFCombobox }

procedure TCFCombobox.Clear;
begin
  FListBox.Clear;
end;

procedure TCFCombobox.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFCombobox.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

constructor TCFCombobox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Self.ParentFont := False;
  FListBox := TCFComListBox.Create(Self);
  FListBox.Parent := Self;
  FListBox.Visible := False;
  //FListBox.BorderVisible := False;
  FDropDownCount := 8;
  FBtnMouseState := [];
  RightPadding := GIconWidth + 2 * GSpace;
  Width := Width + GIconWidth;
end;

procedure TCFCombobox.Delete(Index: Integer);
begin
  if FListBox.Count > 0 then
  begin
    FListBox.Delete(Index);
    FListBox.Height := GetDropHeight;
    FPopup.SetSize(FListBox.Width, FListBox.Height);
    FPopup.UpdatePopup;
  end;
end;

destructor TCFCombobox.Destroy;
begin
  FListBox.Free;
  inherited;
end;

procedure TCFCombobox.DoOnPopupDrawWindow(const ADC: HDC;
  const AClentRect: TRect);
var
  vCanvas: TCanvas;
begin
  vCanvas := TCanvas.Create;
  try
    vCanvas.Handle := ADC;
    FListBox.DrawTo(vCanvas);
    vCanvas.Handle := 0;
  finally
    vCanvas.Free;
  end;
end;

procedure TCFCombobox.DoOnPopupClose(Sender: TObject);
begin
  if FListBox.ItemIndex < 0 then Exit;

  Text := FListBox.Items[FListBox.ItemIndex];
  UpdateDirectUI;
end;

procedure TCFCombobox.DrawControl(ACanvas: TCanvas);

  procedure DrawDownArrow;
  var
    //vIcon: HICON;
    vBmp: TBitmap;
    vRect: TRect;
    //Details: TThemedElementDetails;  // uses Themes
  begin
    if cmsMouseDown in FBtnMouseState then
    begin
      ACanvas.Pen.Color := GBorderHotColor;
      ACanvas.MoveTo(FButtonRect.Left, FButtonRect.Top);
      ACanvas.LineTo(FButtonRect.Left, FButtonRect.Bottom);

      vRect := FButtonRect;
      ACanvas.Brush.Color := $00E5C27F;
      ACanvas.FillRect(vRect);
    end
    else
    if cmsMouseIn in FBtnMouseState then
    begin
      ACanvas.Pen.Color := GBorderColor;
      ACanvas.MoveTo(FButtonRect.Left, FButtonRect.Top);
      ACanvas.LineTo(FButtonRect.Left, FButtonRect.Bottom);

      {if ThemeServices.ThemesEnabled then
      begin
        Details := ThemeServices.GetElementDetails(tcDropDownButtonHot); // ���ﻭ����ť���� Hot ״̬�µ�����
        //PerformEraseBackground(Self, Canvas.Handle);  // ��������ťʱ�ı���
        ThemeServices.DrawElement(ACanvas.Handle, Details, vRect);
        ThemeServices.DrawText(ACanvas.Handle, Details, Caption, vRect,
          DT_EXPANDTABS or DT_VCENTER or DT_CENTER or DT_SINGLELINE, 0);
      end;}

      vRect := FButtonRect;
      ACanvas.Brush.Color := GHotColor;
      //ACanvas.Brush.Color := $00FCE5BC;
      ACanvas.FillRect(vRect);
    end;

    vBmp := TBitmap.Create;
    try
      vBmp.Transparent := True;
      vBmp.LoadFromResourceName(HInstance, 'DROPDOWN');
      ACanvas.Draw(Width - RightPadding + GSpace, (Height - GIconWidth) div 2, vBmp);
    finally
      vBmp.Free;
    end;
    //vIcon := LoadIcon(HInstance, 'DROPDOWN');
    //DrawIconEx(ACanvas.Handle, Width - RightPadding + GSpace, (Height - GIconWidth) div 2,
    //  vIcon, GIconWidth, GIconWidth, 0, 0, DI_NORMAL);
  end;

begin
  inherited DrawControl(ACanvas);
  DrawDownArrow;
end;

function TCFCombobox.GetDropDownFont: TFont;
begin
  Result := FListBox.Font;
end;

function TCFCombobox.GetDropHeight: Integer;
begin
  if FDropDownCount > FListBox.Count then
  begin
    Result := FListBox.Count * FListBox.ItemHeight;
    if FListBox.ZoomSelected and (FListBox.ItemIndex >= 0) then
      Result := Result + FListBox.ItemHeight;
  end
  else
    Result := FDropDownCount * FListBox.ItemHeight;

  if FListBox.BorderVisible then
    Result := Result + GBorderWidth * 2
end;

function TCFCombobox.GetItemHeight: Integer;
begin
  Result := FListBox.ItemHeight;
end;

function TCFCombobox.GetItemIndex: Integer;
begin
  Result := FListBox.ItemIndex;
end;

function TCFCombobox.GetItems: TStrings;
begin
  Result := FListBox.Items;
end;

function TCFCombobox.GetOnDrawItemEvent: TDrawItemEvent;
begin
  Result := FListBox.OnDrawItem;
end;

function TCFCombobox.GetPopupHeight: Integer;
begin
  Result := FListBox.Height;
end;

function TCFCombobox.GetPopupWidth: Integer;
begin
  Result := FListBox.Width;
end;

function TCFCombobox.GetZoomSelected: Boolean;
begin
  Result := FListBox.ZoomSelected;
end;

procedure TCFCombobox.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if ReadOnly then Exit;

  if FStyle = csDropDownList then Exit;

  // �����������MouseDown�У�ʵ�ֵ�������ʾʱ�ٵ����ťִ�йرյ�����
  if PtInRect(FButtonRect, Point(X, Y)) then
  begin
    FBtnMouseState := FBtnMouseState + [cmsMouseDown];
    UpdateDirectUI(FButtonRect);
  end
  else
    inherited;
end;

procedure TCFCombobox.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if PtInRect(FButtonRect, Point(X, Y)) then
  begin
    if Self.Cursor <> crDefault then
      Self.Cursor := crDefault;

    if not (cmsMouseIn in FBtnMouseState) then
    begin
      FBtnMouseState := FBtnMouseState + [cmsMouseIn];
      UpdateDirectUI(FButtonRect);
    end;
  end
  else
  begin
    if FStyle = csDropDownList then
      Self.Cursor := crDefault
    else
      Self.Cursor := crIBeam;

    if cmsMouseIn in FBtnMouseState then
    begin
      FBtnMouseState := FBtnMouseState - [cmsMouseIn];
      UpdateDirectUI(FButtonRect);
    end;
  end;
end;

procedure TCFCombobox.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if ReadOnly then Exit;

  if (FStyle = csDropDownList) or (cmsMouseDown in FBtnMouseState) then
  begin
    FBtnMouseState := FBtnMouseState - [cmsMouseDown];
    UpdateDirectUI(FButtonRect);
    PopupItem;
  end
  else
    inherited;
end;

procedure TCFCombobox.PopupItem;
begin
  FPopup := TCFPopup.Create(Self);
  try
    FPopup.PopupControl := Self;
    FPopup.OnDrawWindow := DoOnPopupDrawWindow;
    FPopup.OnPopupClose := DoOnPopupClose;

    FListBox.Height := GetDropHeight;
    FPopup.SetSize(FListBox.Width, FListBox.Height);
    FPopup.Popup(Self);
  finally
    FPopup.Free;
  end;
end;

procedure TCFCombobox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  FButtonRect := Bounds(Width - RightPadding, 0, RightPadding, Height);
  if BorderVisible then
    InflateRect(FButtonRect, -GBorderWidth, -GBorderWidth);

  if Assigned(FListBox) then
    FListBox.Width := Width;
end;

procedure TCFCombobox.SetDropDownCount(Value: Byte);
begin
  if Value < 5 then Exit;
  if FDropDownCount <> Value then
    FDropDownCount := Value;
end;

procedure TCFCombobox.SetDropDownFont(Value: TFont);
begin
  FListBox.Font := Value;
end;

procedure TCFCombobox.SetItemHeight(Value: Integer);
begin
  if FListBox.ItemHeight <> Value then
    FListBox.ItemHeight := Value;
end;

procedure TCFCombobox.SetItemIndex(Value: Integer);
begin
  FListBox.ItemIndex := Value;
  if FListBox.ItemIndex >= 0 then
    Text := FListBox.Items[FListBox.ItemIndex];
end;

procedure TCFCombobox.SetItems(const Value: TStrings);
begin
  FListBox.Items := Value;
end;

procedure TCFCombobox.SetOnDrawItemEvent(Value: TDrawItemEvent);
begin
  FListBox.OnDrawItem := Value;
end;

procedure TCFCombobox.SetPopupHeight(const Value: Integer);
begin
  FListBox.Height := Value;
end;

procedure TCFCombobox.SetPopupWidth(const Value: Integer);
begin
  FListBox.Width := Value;
end;

procedure TCFCombobox.SetStyle(Value: TComboBoxStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;

    if FStyle = csDropDownList then
      Color := GTitleBackColor
    else
      Color := GBackColor;

    UpdateDirectUI;
  end;
end;

procedure TCFCombobox.SetZoomSelected(Value: Boolean);
begin
  FListBox.ZoomSelected := Value;
end;

procedure TCFCombobox.WMCFLBUTTONDOWN(var Message: TMessage);
begin
  FListBox.Perform(Message.Msg, Message.WParam, Message.LParam);
end;

procedure TCFCombobox.WMCFLBUTTONUP(var Message: TMessage);
var
  vCanClose: Boolean;
begin
  if FListBox.Perform(Message.Msg, Message.WParam, Message.LParam) = 1 then
  begin
    vCanClose := True;
    if Assigned(FOnCloseUp) then
      FOnCloseUp(ItemIndex, Message.LParam and $FFFF, Message.LParam shr 16, vCanClose);
    if vCanClose then
      FPopup.ClosePopup(False);
  end;
end;

procedure TCFCombobox.WMCFMOUSEMOVE(var Message: TMessage);
var
  vItemIndex: Integer;
begin
  vItemIndex := ItemIndex;
  if FListBox.Perform(Message.Msg, Message.WParam, Message.LParam) = 1 then
  begin
    if (vItemIndex < 0) or (ItemIndex < 0) then  // ��ûѡ�л���ѡ�У����ѡ�л���ûѡ�ж���Ҫ���¼���ListBox�߶�
    begin
      FListBox.Height := GetDropHeight;
      FPopup.SetSize(FListBox.Width, FListBox.Height);
    end;
    FPopup.UpdatePopup;
  end;
end;

procedure TCFCombobox.WMLButtonDblClk(var Message: TWMLButtonDblClk);
begin
  if FStyle <> csDropDownList then
    inherited;
end;

procedure TCFCombobox.WMMouseWheel(var Message: TWMMouseWheel);
begin
  if Assigned(FPopup) and FPopup.Opened then
  begin
    if FListBox.Perform(Message.Msg, Message.WheelDelta, Message.YPos shl 16 + Message.XPos) = 1 then
      FPopup.UpdatePopup;
  end
  else
   inherited;
end;

{ TCFComListBox }

constructor TCFComListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FVScrollBar.Width := 10;
end;

function TCFComListBox.GetVScrollBarBound: TRect;
begin
  if FVScrollBar.Visible then
    Result := Bounds(Width - FVScrollBar.Width, 0, FVScrollBar.Width, FVScrollBar.Height)
  else
    SetRectEmpty(Result);
end;

procedure TCFComListBox.WMCFLBUTTONDOWN(var Message: TMessage);
begin
  MouseDown(mbLeft, KeysToShiftState(Message.WParam) + MouseOriginToShiftState, Message.LParam and $FFFF, Message.LParam shr 16);
end;

procedure TCFComListBox.WMCFLBUTTONUP(var Message: TMessage);
var
  vRect: TRect;
  X, Y: Integer;
begin
  vRect := GetVScrollBarBound;
  X := Message.LParam and $FFFF;
  Y := Message.LParam shr 16;
  if PtInRect(vRect, Point(X, Y)) then  // �ڴ�ֱ����������
    Message.Result := 0
  else
    Message.Result := 1;
end;

procedure TCFComListBox.WMCFMOUSEMOVE(var Message: TMessage);
var
  vShift: TShiftState;
  X, Y: Integer;
  vItemIndex: Integer;
  vRect: TRect;
begin
  X := Message.LParam and $FFFF;
  Y := Message.LParam shr 16;
  vRect := GetVScrollBarBound;

  if PtInRect(vRect, Point(X, Y)) then  // �ڴ�ֱ����������
  begin
    vShift := [];
    if Message.WParam and MK_LBUTTON <> 0 then
    begin
      Include(vShift, ssLeft);
      Message.Result := 1;
    end;

    MouseMove(vShift, X, Y);
  end
  else  // ���ڴ�ֱ����������
  begin
    vItemIndex := GetItemAt(X, Y);
    if vItemIndex <> FItemIndex then  // ���������ƶ����ƶ����µ�Item��
    begin
      FItemIndex := vItemIndex;
      CheckScrollBarVisible;

      Message.Result := 1;
    end
  end;
end;

end.
