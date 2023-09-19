unit CFButton;

interface

uses
  Windows, Classes, Controls, Graphics, Messages, CFControl;

type
  TCFButton = class(TCFTextControl)
  private
    { Private declarations }
    FModalResult: TModalResult;
  protected
    { Protected declarations }
    /// <summary>
    /// ����
    /// </summary>
    /// <param name="ACanvas">���ֻ���</param>
    procedure DrawControl(ACanvas: TCanvas); override;

    /// <summary> �����¼� </summary>
    procedure Click; override;

    /// <summary> ����Ĭ�ϴ�С�ͷ�Χ </summary>
    procedure AdjustBounds; override;

    /// <summary>
    /// ����ģʽ���
    /// </summary>
    /// <param name="Value">ģʽ</param>
    procedure SetModalResult(Value: TModalResult);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    /// <summary> ������� </summary>
    procedure CMMouseEnter(var Msg: TMessage ); message CM_MOUSEENTER;

    /// <summary> ����Ƴ� </summary>
    procedure CMMouseLeave(var Msg: TMessage ); message CM_MOUSELEAVE;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
  published
    { Published declarations }
    /// <summary> ��ť��ģʽ���(ȷ�����رյ�) </summary>
    property ModalResult: TModalResult read FModalResult write SetModalResult default 0;
    property Caption;
    property Alpha;
    property OnClick;
  end;

implementation

uses
  CFColorUtils;

{ TCFButton }

procedure TCFButton.AdjustBounds;
var
  DC: HDC;
  vNewHeight, vNewWidth: Integer;
begin
  if not (csReading in ComponentState) then  // ������ؼ���ʼ����״̬
  begin
    DC := GetDC(0);  // ��ʱDC
    try
      Canvas.Handle := DC;
      Canvas.Font := Font;
      vNewHeight := Canvas.TextHeight('��') + GetSystemMetrics(SM_CYBORDER) * 4;
      vNewWidth := Canvas.TextWidth(Caption) + GetSystemMetrics(SM_CYBORDER) * 8;
      Canvas.Handle := 0;
    finally
      ReleaseDC(0, DC);
    end;
    if vNewHeight < 25 then
      vNewHeight := 25;
    if vNewWidth < Width then
    begin
      vNewWidth := Width;
      if vNewWidth < 75 then
        vNewWidth := 75;
    end;

    SetBounds(Left, Top, vNewWidth, vNewHeight);
  end;
end;

procedure TCFButton.Click;
begin
  if Assigned(OnClick) then  // �и�ֵ�����¼�
    inherited
  else
  begin
    {case FModalResult of
      mrClose: PostMessage(GetUIHandle, WM_CLOSE, 0, 0);  // �رյ�ǰ����
    end;}
  end;
end;

procedure TCFButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  UpdateDirectUI;
end;

constructor TCFButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 75;
  Height := 25;
end;

procedure TCFButton.DrawControl(ACanvas: TCanvas);
var
  vRect: TRect;
  vText: string;
  vBackColor: TColor;
  // ���ư�͸����Ҫ�ı���
//  vMemDC: HDC;
//  vMemBitmap, vOldBitmap: HBITMAP;
//  vCanvas: TCanvas;
//  vBlendFunction: TBlendFunction;
  //vRgn: HRGN;
  //vPng: TPngImage;
  //AGraphics: TdxGPGraphics;
  //vPen: TdxGPPen;
  //vRgn: HRGN;
  //vBmp: TBitmap;
begin
  inherited DrawControl(ACanvas);

  case FModalResult of  // ������ɫ
    mrClose:
      vBackColor := GAlertColor;
  else
    vBackColor := GAreaBackColor;
  end;

  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := GetBorderColor(vBackColor);
  if cmsMouseIn in MouseState then  // ����ڿؼ���
  begin
    if cmsMouseDown in MouseState then  // ��갴��
      ACanvas.Brush.Color := GetDownColor(vBackColor)
    else
      ACanvas.Brush.Color := GetHotColor(vBackColor);
  end
  else  // ��ͨ״̬
    ACanvas.Brush.Color := vBackColor;

  vRect := Rect(0, 0, Width, Height);
  if RoundCorner > 0 then
    ACanvas.RoundRect(vRect, GRoundSize, GRoundSize)
  else
    ACanvas.FillRect(vRect);

  vText := Caption;
  ACanvas.TextRect(vRect, vText, [tfSingleLine, tfCenter,tfVerticalCenter]);

{$REGION '����͸���Ȼ��ƴ���'}
//  if AAlpha <> 255 then
//  begin
//    // ��ʹ��GDI��Ϊ��dll�г�ʼ��gdiʱ���治��ʾ
//    vMemBitmap := CreateCompatibleBitmap(ACanvas.Handle, Width, Height);
//    try
//      vMemDC := CreateCompatibleDC(ACanvas.Handle);
//      vOldBitmap := SelectObject(vMemDC, vMemBitmap);
//      BitBlt(vMemDC, 0, 0, Width, Height, ACanvas.Handle, X, Y, SRCCOPY);  // ����ԭͼ��λ�õ�ͼ��
//      try
//        vCanvas := TCanvas.Create;
//        vCanvas.Handle := vMemDC;
//        DrawTo(vCanvas, 0, 0, 255);
//
//        vBlendFunction.BlendOp := AC_SRC_OVER;
//        vBlendFunction.BlendFlags := 0;
//        vBlendFunction.AlphaFormat := AC_SRC_OVER;  // Դλͼ������32λ��
//        vBlendFunction.SourceConstantAlpha := AAlpha; // ͸����
//        Windows.AlphaBlend(ACanvas.Handle,
//                           X,
//                           Y,
//                           Width,
//                           Height,
//                           vMemDC,
//                           0,
//                           0,
//                           Width,
//                           Height,
//                           vBlendFunction
//                           );
//      finally
//        SelectObject(vMemDC, vOldBitmap)
//      end;
//    finally
//      vCanvas.Free;
//      DeleteDC(vMemDC);
//      DeleteObject(vMemBitmap);
//    end;
//
//{ʹ��bmp���
//    vBmp := TBitmap.Create;
//    vBmp.SetSize(Width, Height);
//    BitBlt(vBmp.Canvas.Handle, 0, 0, Width, Height, ACanvas.Handle, X, Y, SRCCOPY);
//    DrawTo(vBmp.Canvas, 0, 0, 255);
//    //vBmp.SaveToFile('C:\a.BMP');
//
//
//    vBlendFunction.BlendOp := AC_SRC_OVER;
//    vBlendFunction.BlendFlags := 0;
//    vBlendFunction.AlphaFormat := AC_SRC_OVER;  // Դλͼ������32λ��
//    vBlendFunction.SourceConstantAlpha := AAlpha; // ͸����
//
//    Windows.AlphaBlend(ACanvas.Handle,
//                       X,
//                       Y,
//                       Width,
//                       Height,
//                       vBmp.Canvas.Handle,
//                       0,
//                       0,
//                       Width,
//                       Height,
//                       vBlendFunction
//                       );
//
//    vBmp.Free;}
//
//
////    vRgn := CreateRoundRectRgn(X, Y, Width, Height, 5, 5);
////    SelectClipRgn(ACanvas.Handle, vRgn);
////    AlphaBlend(ACanvas.Handle, X, Y, Width, Height, Canvas.Handle, 0, 0, Width, Height, vBlendFunction);
////    SelectClipRgn(ACanvas.Handle, 0);
////    DeleteObject(vRgn);
////    vPng := TPngImage.CreateBlank(6,  // COLOR_RGBALPHA
////      8, 500, 500);
////    BitBlt(vPng.Canvas.Handle, X, Y, Width, Height, ACanvas.Handle, 0, 0, SRCCOPY);
////    vPng.SaveToFile('c:\a.png');
////
////
////    vBmp := TBitmap.Create;
////    vBmp.SetSize(500, 500);
////    BitBlt(vBmp.Canvas.Handle, X, Y, Width, Height, ACanvas.Handle, 0, 0, SRCCOPY);
////    vBmp.SaveToFile('c:\a.bmp');
////    vBmp.Free;
////
////    vPng := TPngImage.Create;
////    vPng.LoadFromFile('E:\�ο�����\MedPlatform_V2\Source\Resource\1.png');
////    DrawTo(vPng.Canvas, 0, 0, 255);
////    vPng.SaveToFile('c:\1.png');
////    ACanvas.Draw(X, Y, vPng);
////    vPng.Free;
//
////    Rgn := CreateRoundRectRgn(X, Y, X + Width, Y + Height, 5, 5);
////    SelectClipRgn(ACanvas.Handle, Rgn);
////    DeleteObject(Rgn);
////
////    vBlendFunction.BlendOp := AC_SRC_OVER;
////    vBlendFunction.BlendFlags := 0;
////    vBlendFunction.AlphaFormat := AC_SRC_ALPHA;  // Դλͼ������32λ��
////    vBlendFunction.SourceConstantAlpha := AAlpha; // ͸����
////    //BitBlt(ACanvas.Handle, X, Y, Width, Height, Canvas.Handle, 0, 0, SRCCOPY);
////    Windows.AlphaBlend(ACanvas.Handle,
////                       X,
////                       Y,
////                       Width,
////                       Height,
////                       Canvas.Handle,
////                       0,
////                       0,
////                       Width,
////                       Height,
////                       vBlendFunction
////                       );
////     SelectClipRgn(ACanvas.Handle, 0);  // �����������
//{    vMemBitmap := CreateCompatibleBitmap(ACanvas.Handle, Width, Height);
//    try
//      vMemDC := CreateCompatibleDC(ACanvas.Handle);
//      vOldBitmap := SelectObject(vMemDC, vMemBitmap);
//      try
//        vCanvas := TCanvas.Create;
//        vCanvas.Handle := vMemDC;
//        vCanvas.Brush.Color := 1;
//        vCanvas.FillRect(Rect(0, 0, Width, Height));
//        DrawTo(vCanvas, 0, 0, 255);
//        TransparentBlt(ACanvas.Handle, X, Y, Width, Height, vMemDC, 0, 0, Width, Height, 1);
////        vRect := Rect(X, Y, X + Width, Y + Height);
////        vText := Caption;
////        ACanvas.TextRect(vRect, vText, [tfSingleLine, tfCenter,tfVerticalCenter]);
////        vBlendFunction.BlendOp := AC_SRC_OVER;
////        vBlendFunction.BlendFlags := 0;
////        vBlendFunction.AlphaFormat := AC_SRC_OVER;  // Դλͼ������32λ��
////        vBlendFunction.SourceConstantAlpha := AAlpha; // ͸����
////        Windows.AlphaBlend(ACanvas.Handle,
////                           X,
////                           Y,
////                           Width,
////                           Height,
////                           vMemDC,
////                           0,
////                           0,
////                           Width,
////                           Height,
////                           vBlendFunction
////                           );
//        //vPng.Free;
//      finally
//        SelectObject(vMemDC, vOldBitmap)
//      end;
//    finally
//      vCanvas.Free;
//      DeleteDC(vMemDC);
//      DeleteObject(vMemBitmap);
//    end; }
//  end
//  else
//  begin
//    ACanvas.Pen.Width := 1;
//    ACanvas.Pen.Color := FBorderColor;
//    if FMouseEnter then
//    begin
//      if cbsMouseDown in MouseState then
//        ACanvas.Brush.Color := FDownColor
//      else
//        ACanvas.Brush.Color := FHotColor;
//    end
//    else
//      ACanvas.Brush.Color := Color;
//    vRect := Rect(X, Y, X + Width, Y + Height);
//    //vRgn := CreateRectRgnIndirect(BoundsRect);
//    //SelectClipRgn(ACanvas.Handle, vRgn);
//    //try
//      ACanvas.RoundRect(vRect, GRoundSize, GRoundSize);
//      vText := Caption;
//      ACanvas.TextRect(vRect, vText, [tfSingleLine, tfCenter,tfVerticalCenter]);
//    //finally
//    //  SelectClipRgn(ACanvas.Handle, 0);
//    //  DeleteObject(vRgn);
//    //end;
//  end;
{$ENDREGION}
end;

procedure TCFButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  UpdateDirectUI;
end;

procedure TCFButton.SetModalResult(Value: TModalResult);
begin
  if FModalResult <> Value then
  begin
    FModalResult := Value;
    case Value of  // ������ʾ�ı�
      //mrNone;
      mrOk: Caption := 'ȷ ��';
      mrCancel: Caption := 'ȡ ��';
      mrAbort: Caption := '�� ֹ';
      mrRetry: Caption := '�� ��';
      mrIgnore: Caption := '�� ��';
      mrYes: Caption := '��';
      mrNo: Caption := '��';
      mrAll: Caption := 'ȫ ��';
      mrNoToAll: Caption := 'ȫ����';
      mrYesToAll: Caption := 'ȫ����';
      mrClose: Caption := '�� ��';
    end;
    UpdateDirectUI;
  end;
end;

end.
