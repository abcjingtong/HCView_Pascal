unit CFSafeEdit;

interface

uses
  Windows, Classes, Controls, CFControl, Graphics, Messages;

type
  TScrollAlign = (csaLeft, csaRight);


  TCFSafeEdit = class(TCFCustomControl)
  private
    FTopPadding,    // ��ƫ�ƶ��ٿ�ʼ��ʾ�ı�
    FLeftPadding,   // ��ƫ�ƶ��ٿ�ʼ��ʾ�ı�
    FRightPadding,  // ��ƫ�ƶ���ֹͣ��ʾ�ı�
    FMaxLength      // ��󳤶�
      : Byte;
    FDrawLeftOffs, FTextWidth: Integer;  // ����ʱ��ƫ�ƣ��ı����ݿ��
    FSafeChar: Char;
    FSafeText: string;
    FSelStart: Integer;  // ѡ�����ڵڼ������� >0 ��Ч
    FReadOnly: Boolean;
    FShowKeyBoard: Boolean;
    FBtnMouseState: TMouseState;
    FOnChange: TNotifyEvent;
    FOnKeyDown: TKeyEvent;
    /// <summary>
    /// ����λ���ڵڼ����ַ�����(>0��Ч)
    /// </summary>
    /// <param name="AX">λ��</param>
    /// <returns>�ڵڼ����ַ�����</returns>
    function GetOffsetBeforAt(const AX: Integer): Integer;
    procedure ScrollTo(const AOffset: Integer; const AAlign: TScrollAlign);
    procedure MoveCaretAfter(const AOffset: Integer);
    procedure RightKeyPress;
    procedure LeftKeyPress;
    //
    procedure SetReadOnly(Value: Boolean);
    procedure SetShowKeyBord(Value: Boolean);
    procedure AdjustBounds;
    /// <summary> ���Ƶ����� </summary>
    procedure DrawControl(ACanvas: TCanvas); override;
    //
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    //
    // ͨ��Tab�Ƴ�����
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMMouseEnter(var Msg: TMessage ); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage ); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;

    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetFocus; override;
    procedure Clear;
    function TextLength: Integer;
    //
    property RightPadding: Byte read FRightPadding write FRightPadding;
    property LeftPadding: Byte read FLeftPadding write FLeftPadding;
    property SafeText: string read FSafeText;
  published
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    //
    property MaxLength: Byte read FMaxLength write FMaxLength;
    property ShowKeyBoard: Boolean read FShowKeyBoard write SetShowKeyBord;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property Font;
  end;

implementation

{$R CFSafeEdit.RES}

uses
  SysUtils;

{ TCSafeEdit }

procedure TCFSafeEdit.ScrollTo(const AOffset: Integer; const AAlign: TScrollAlign);
var
  vS: string;
  vW, vDecW: Integer;
begin
  vS := Copy(Text, 1, AOffset);
  //vW := Canvas.TextWidth(vS);
  vW := Canvas.TextWidth(vS);
  if AAlign = csaRight then  // ���������AOffsetǡ����ʾ
  begin
    vDecW := FDrawLeftOffs + FLeftPadding + vW - (Width - FRightPadding);
    if vDecW > 0 then  // �������
    begin
      FDrawLeftOffs := FDrawLeftOffs - vDecW;
      UpdateDirectUI;
    end
    else
    if vDecW < 0 then  // û�г������
    begin
      if FDrawLeftOffs < 0 then  // �����û��ʾ������
      begin
        FDrawLeftOffs := FDrawLeftOffs - vDecW;
        if FDrawLeftOffs > 0 then
          FDrawLeftOffs := 0;
        UpdateDirectUI;
      end;
    end;
  end
  else
  begin
    vDecW := FDrawLeftOffs + vW;
    if vDecW < 0 then
    begin
      FDrawLeftOffs := FDrawLeftOffs - vDecW;
      UpdateDirectUI;
    end;
  end;
end;

procedure TCFSafeEdit.Clear;
begin
  FSafeText := '';
  Text := '';
  if Self.Focused then
  begin
    FSelStart := 0;
    MoveCaretAfter(FSelStart);
  end;
  UpdateDirectUI;
end;

procedure TCFSafeEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  AdjustBounds;
end;

procedure TCFSafeEdit.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFSafeEdit.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FBtnMouseState := FBtnMouseState - [cmsMouseIn];
  UpdateDirectUI;
end;

procedure TCFSafeEdit.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

constructor TCFSafeEdit.Create(AOwner: TComponent);
begin
  inherited;
  FTopPadding := 2;
  FLeftPadding := 2;
  FRightPadding := 2;
  FDrawLeftOffs := 0;
  FSelStart := -1;
  FMaxLength := 8;
  FSafeChar := Char($25CF);
  Text := '';  // ����win32�Դ�����Ĭ��ֵ
  FSafeText := '';
  FShowKeyBoard := True;
  FBtnMouseState := [];
  Width := 120;
  Height := 20;
  Self.Cursor := crIBeam;
end;

procedure TCFSafeEdit.DrawControl(ACanvas: TCanvas);
var  //���ư�͸����Ҫ�ı���
  vRect: TRect;
  vS: string;
  vLeft, vRight: Integer;
  //vRgn: HRGN;
  vBmp: TBitmap;
  //vIcon: HICON;
begin
  inherited DrawControl(ACanvas);

  // ��۾���
  vRect := Rect(0, 0, Width, Height);
  ACanvas.Brush.Style := bsSolid;

  if not FReadOnly then
    ACanvas.Brush.Color := GBackColor
  else
    ACanvas.Brush.Color := clInfoBk;

  if Self.Focused or (cmsMouseIn in MouseState) then
    ACanvas.Pen.Color := GBorderHotColor
  else
    ACanvas.Pen.Color := GBorderColor;

  if BorderVisible then
    ACanvas.Pen.Style := psSolid
  else
    ACanvas.Pen.Style := psClear;

  //ACanvas.RoundRect(vRect, GRoundSize, GRoundSize);
  ACanvas.Rectangle(vRect);

  // ���ÿɻ�������
  InflateRect(vRect, 0, -FTopPadding);
  vRect.Left := vRect.Left + FLeftPadding;
  vRect.Right := vRect.Right - FRightPadding;
  //vRgn := CreateRectRgnIndirect(vRect);

  if FShowKeyBoard then
  begin
    vBmp := TBitmap.Create;
    try
      vBmp.Transparent := True;

      if cmsMouseIn in FBtnMouseState then
        vBmp.LoadFromResourceName(HInstance, 'KEYBOARDHOT')
      else
        vBmp.LoadFromResourceName(HInstance, 'KEYBOARD');

      ACanvas.Draw(vRect.Right, (Height - GIconWidth) div 2, vBmp);
    finally
      FreeAndNil(vBmp);
    end;
  end;

  //SelectClipRgn(ACanvas.Handle, vRgn);  //ExtSelectClipRgn(ACanvas.Handle, vRgn)
  IntersectClipRect(ACanvas.Handle, vRect.Left, vRect.Top, vRect.Right, vRect.Bottom);
  try
    // �����ı�
    if Text <> '' then  // ������
    begin
      // �����ı�
      vRect := Bounds(0, 0, FTextWidth, Height);
      OffsetRect(vRect, FDrawLeftOffs + FLeftPadding, 0);
      vS := Text;
      ACanvas.TextRect(vRect, vS, [tfLeft, tfVerticalCenter, tfSingleLine]);
      // �����ַ�������ʾ
      {vS := IntToStr(TextLength);
      ACanvas.Font.Size := 8;
      vRect.Left := vRect.Right + 2;
      vRect.Right := vRect.Left + ACanvas.TextWidth(vS);
      vRect.Top := vRect.Top + 4;
      ACanvas.Font.Color := clMedGray;
      ACanvas.TextRect(vRect, vS, [tfLeft, tfVerticalCenter, tfSingleLine]);}
    end;
  finally
    SelectClipRgn(ACanvas.Handle, 0);  // �����������
    //DeleteObject(vRgn)
  end;
end;

procedure TCFSafeEdit.AdjustBounds;
var
  vRect: TRect;
begin
  //if not (csReading in ComponentState) then
  begin
    vRect := ClientRect;
    Canvas.Font := Font;
    vRect.Bottom := vRect.Top + Canvas.TextHeight('��') + GetSystemMetrics(SM_CYBORDER) * 4;
    FTextWidth := Canvas.TextWidth(Text);
    SetBounds(Left, Top, vRect.Right, vRect.Bottom);
  end;
end;

function TCFSafeEdit.GetOffsetBeforAt(const AX: Integer): Integer;
var
  i, vW, vRight: Integer;
begin
  Result := -1;
  //if (AX < FDrawLeftOffs) or (AX > FTextWidth) then Exit;
  if AX < FDrawLeftOffs then
  begin
    Result := 0;
    Exit;
  end;
  if AX > FTextWidth then
  begin
    Result := TextLength;
    Exit;
  end;

  //if AX < Canvas.TextWidth(Text) then  // ���ı���
  if AX < Canvas.TextWidth(Text) then
  begin
    vRight := 0;
    for i := 1 to Length(Text) do
    begin
      //vW := Canvas.TextWidth(Text[i]);
      vW := Canvas.TextWidth(Text[i]);
      if vRight + vW > AX then
      begin
        if vRight + vW div 2 > AX then
          Result := i - 1
        else
        begin
          Result := i;
          vRight := vRight + vW;
        end;
        Break;
      end
      else
        vRight := vRight + vW;
    end;
  end
  else  // �����ı���
    Result := TextLength;
end;

procedure TCFSafeEdit.KeyDown(var Key: Word; Shift: TShiftState);

  {$REGION 'DoBackKey'}
  procedure DoBackKey;
  var
    vS: string;
  begin
    if (Text <> '') and (FSelStart > 0) then
    begin
      vS := Text;
      Delete(vS, FSelStart, 1);
      Delete(FSafeText, FSelStart, 1);
      Text := vS;
      //FTextWidth := Canvas.TextWidth(Text);
      FTextWidth := Canvas.TextWidth(Text);
      Dec(FSelStart);
      if FSelStart = TextLength then  // ���������ǰɾ��
      begin
        if FDrawLeftOffs < 0 then  // ǰ����û��ʾ������
          ScrollTo(FSelStart, csaRight);
      end;
      UpdateDirectUI;
      MoveCaretAfter(FSelStart);
    end;
  end;
  {$ENDREGION}

  {$REGION 'DoDeleteKey'}
  procedure DoDeleteKey;
  var
    vS: string;
  begin
    if (Text <> '') and (FSelStart < TextLength) then
    begin
      vS := Text;
      Delete(vS, FSelStart + 1, 1);
      Delete(FSafeText, FSelStart + 1, 1);
      Text := vS;
      //FTextWidth := Canvas.TextWidth(Text);
      FTextWidth := Canvas.TextWidth(Text);
      if FSelStart = TextLength then  // ���������ǰɾ��
      begin
        if FDrawLeftOffs < 0 then  // ǰ����û��ʾ������
        begin
          ScrollTo(FSelStart, csaRight);
          MoveCaretAfter(FSelStart);;
        end;
      end;
      UpdateDirectUI;
    end;
  end;
  {$ENDREGION}

  {$REGION 'DoHomeKey'}
  procedure DoHomeKey;
  begin
    FSelStart := 0;
    FDrawLeftOffs := 0;
    UpdateDirectUI;
    MoveCaretAfter(FSelStart);;
  end;
  {$ENDREGION}

  {$REGION 'DoEndKey'}
  procedure DoEndKey;
  begin
    FSelStart := TextLength;
    ScrollTo(FSelStart, csaRight);
    MoveCaretAfter(FSelStart);;
  end;
  {$ENDREGION}

begin
  inherited;
  if FReadOnly then Exit;

  case Key of
    VK_BACK: DoBackKey;
    VK_DELETE: DoDeleteKey;
    VK_LEFT: LeftKeyPress;
    VK_RIGHT: RightKeyPress;
    VK_HOME: DoHomeKey;
    VK_END: DoEndKey;
    VK_RETURN:
      begin
        if Assigned(FOnKeyDown) then
          FOnKeyDown(Self, Key, Shift);
      end;
  end;
end;

procedure TCFSafeEdit.KeyPress(var Key: Char);
var
  vS: string;
begin
  inherited;
  if FReadOnly then Exit;
  //if Ord(Key) in [VK_BACK, VK_RETURN] then Exit;
  if ((Key < #32) or (Key = #127)) and (Ord(Key) <> VK_TAB) then Exit;;

  vS := Text;
  if Length(vS) >= FMaxLength then Exit;  

  Insert(FSafeChar, vS, FSelStart + 1);
  Insert(Key, FSafeText, FSelStart + 1);
  Text := vS;

  //FTextWidth := Canvas.TextWidth(Text);
  FTextWidth := Canvas.TextWidth(Text);

  RightKeyPress;
end;

procedure TCFSafeEdit.LeftKeyPress;
begin
  if FSelStart > 0 then
  begin
    Dec(FSelStart);
    ScrollTo(FSelStart, csaLeft);
    MoveCaretAfter(FSelStart);;
  end;
end;

procedure TCFSafeEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vS: string;
  vOffs: Integer;
  vSelStart: Integer absolute vOffs;
  vReUpdate: Boolean;
  vRect: TRect;
begin
  inherited;
  if FReadOnly then Exit;
  // �ж��Ƿ����ڰ�ť��
  vRect := Rect(Width - RightPadding, GBorderWidth, Width - GBorderWidth, Height - GBorderWidth);
  if PtInRect(vRect, Point(X, Y)) then
  begin
    FBtnMouseState := FBtnMouseState + [cmsMouseDown];
    UpdateDirectUI(vRect);
  end;

  if (X < FLeftPadding) or (X > Width - FRightPadding) then Exit;

  vReUpdate := False;

  vSelStart := GetOffsetBeforAt(X - FDrawLeftOffs - FLeftPadding);
  if FSelStart <> vSelStart then
  begin
    FSelStart := vSelStart;
    vReUpdate := True;
  end;
  // ����ʾ���Ҳ���ַ��а��¶��ʱ��������ȫ��ʾ
  vS := Copy(Text, 1, FSelStart);
  vOffs := Width - FLeftPadding - FRightPadding - //(Canvas.TextWidth(vS) + FDrawLeftOffs);
    (Canvas.TextWidth(vS) + FDrawLeftOffs);
  if vOffs < 0 then
  begin
    FDrawLeftOffs := FDrawLeftOffs + vOffs;
    vReUpdate := True;
  end;
  if vReUpdate then
    UpdateDirectUI;
  MoveCaretAfter(FSelStart);
end;

procedure TCFSafeEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vS: string;
  vSelEnd, vW: Integer;
  vReUpdate: Boolean;
  vRect: TRect;
begin
  inherited;
  if FReadOnly then Exit;
  if ssLeft in Shift then
  begin
    vReUpdate := False;
    if X > Width - FRightPadding then  // ����ڿؼ��Ҳ�
    begin
      vW := FTextWidth - (Width - FLeftPadding - FRightPadding);
      if FDrawLeftOffs + vW > 0 then  // �Ҳ�����δ��ʾ��ȫ
      begin
        Dec(FDrawLeftOffs, 5);
        if FDrawLeftOffs < -vW then
          FDrawLeftOffs := -vW;
        vReUpdate := True;
      end;
      vSelEnd := GetOffsetBeforAt(Width - FDrawLeftOffs + FLeftPadding - FRightPadding);
      vS := Copy(Text, 1, vSelEnd);
      //if Canvas.TextWidth(vS)
      if Canvas.TextWidth(vS) + FDrawLeftOffs > Width - FLeftPadding - FRightPadding then
        Dec(vSelEnd);
    end
    else
    if X < FLeftPadding then
    begin
      if FDrawLeftOffs < 0 then  // �������δ��ʾ��ȫ
      begin
        Inc(FDrawLeftOffs, 5);
        if FDrawLeftOffs > 0 then
          FDrawLeftOffs := 0;
        vReUpdate := True;
      end;
      vSelEnd := GetOffsetBeforAt({FLeftPadding - ���ַ�һ��С��FLeftPaddingʱ���㲻׼ȷ}-FDrawLeftOffs);
      vS := Copy(Text, 1, vSelEnd);
      //if Canvas.TextWidth(vS) + FDrawLeftOffs < 0 then
      if Canvas.TextWidth(vS) + FDrawLeftOffs < 0 then
        Inc(vSelEnd);
    end
    else
    begin
      vSelEnd := GetOffsetBeforAt(X - FDrawLeftOffs - FLeftPadding);
      vS := Copy(Text, 1, vSelEnd);
      //if Canvas.TextWidth(vS)
      if Canvas.TextWidth(vS) + FDrawLeftOffs + FLeftPadding > Width - FRightPadding then
        Dec(vSelEnd);
    end;

    if vSelEnd < 0 then Exit;  // ��겻��������

    if vReUpdate then
      UpdateDirectUI;
    FSelStart := vSelEnd;
    MoveCaretAfter(FSelStart);
  end
  else
  begin
    vRect := Rect(Width - RightPadding, GBorderWidth, Width - GBorderWidth, Height - GBorderWidth);
    if PtInRect(vRect, Point(X, Y)) then
    begin
      if not (cmsMouseIn in FBtnMouseState) then
      begin
        FBtnMouseState := FBtnMouseState + [cmsMouseIn];
        UpdateDirectUI(vRect);
      end;
    end
    else
    begin
      if cmsMouseIn in FBtnMouseState then
      begin
        FBtnMouseState := FBtnMouseState - [cmsMouseIn];
        UpdateDirectUI(vRect);
      end;
    end;
  end;
end;

procedure TCFSafeEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  vRect: TRect;
begin
  if cmsMouseDown in FBtnMouseState then
  begin
    FBtnMouseState := FBtnMouseState - [cmsMouseDown];
    vRect := Rect(Width - RightPadding, GBorderWidth, Width - GBorderWidth, Height - GBorderWidth);
    UpdateDirectUI(vRect);
  end
  else
    inherited;
end;

procedure TCFSafeEdit.MoveCaretAfter(const AOffset: Integer);
var
  vS: string;
  vCaretLeft, vCaretHeight: Integer;
begin
  if AOffset < 0 then Exit;
  vCaretHeight := Height - 2 * FTopPadding;
  vCaretLeft := FLeftPadding;

  if AOffset > 0 then
  begin
    vS := Copy(Text, 1, AOffset);
    vCaretLeft := vCaretLeft + Canvas.TextWidth(vS)
      + FDrawLeftOffs;
  end;

  DestroyCaret;
  CreateCaret(Handle, 0, 1, vCaretHeight);
  SetCaretPos(vCaretLeft, FTopPadding);
  ShowCaret(Handle);
end;

procedure TCFSafeEdit.RightKeyPress;
begin
  if FSelStart < TextLength then
  begin
    Inc(FSelStart);
    ScrollTo(FSelStart, csaRight);
    MoveCaretAfter(FSelStart);
  end;
end;

procedure TCFSafeEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  if FShowKeyBoard then
    FRightPadding := GIconWidth + GPadding * 2
  else
    FRightPadding := GPadding;
end;

procedure TCFSafeEdit.SetFocus;
begin
  inherited SetFocus;
  FSelStart := TextLength;
  MoveCaretAfter(FSelStart);
end;

procedure TCFSafeEdit.SetReadOnly(Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    DestroyCaret;
    UpdateDirectUI;
  end;
end;

procedure TCFSafeEdit.SetShowKeyBord(Value: Boolean);
begin
  if FShowKeyBoard <> Value then
  begin
    FShowKeyBoard := Value;
    if Value then
      FRightPadding := GIconWidth + GPadding * 2
    else
      FRightPadding := GPadding;
  end;
end;

function TCFSafeEdit.TextLength: Integer;
begin
  Result := Length(Text);
end;

procedure TCFSafeEdit.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  DestroyCaret;
end;

end.
