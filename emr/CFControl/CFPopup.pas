unit CFPopup;

interface

uses
  Windows, Classes, Controls, CFControl, Graphics, Messages;

type
  TCFCustomPopup = class(TComponent)
  private
    FPopupWindow: HWND;
    FAlignment: TAlignment;
    FOnPopupClose: TNotifyEvent;
    FRemoveMessageOnClose,  // ����ڷ�Popup����ر�ʱ���Ƿ��Ƴ���Ϣ(�����ݵ����λ�ÿؼ���)
    FOpened: Boolean;
  protected
    procedure RegFormClass;
    procedure CreateHandle;
    function GetWidth: Integer; virtual;
    procedure DoPopupMessage(const Msg: TMsg); virtual;
    procedure WndProc(var Message: TMessage); virtual;
    property PopupWindow: HWND read FPopupWindow;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Popup(X, Y: Integer); overload; virtual;
    procedure Popup(APt: TPoint); overload; virtual;
    procedure Popup(const AControl: TControl); overload; virtual;
    procedure UpdatePopup; virtual;
    procedure ClosePopup(const ACancel: Boolean); virtual;

    property Width: Integer read GetWidth;
    property Opened: Boolean read FOpened;
  published
    property Alignment: TAlignment read FAlignment write FAlignment default taRightJustify;
    property RemoveMessageOnClose: Boolean read FRemoveMessageOnClose write FRemoveMessageOnClose;
    property OnPopupClose: TNotifyEvent read FOnPopupClose write FOnPopupClose;
  end;

  TDrawEvent = procedure(const ADC: HDC; const AClentRect: TRect) of object;

  TCFPopup = class(TCFCustomPopup)
  private
    FPopupControl: TCFCustomControl;
    FOnDrawWindow: TDrawEvent;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    procedure SetSize(const AWidth, AHeight: Integer);
    property PopupControl: TCFCustomControl read FPopupControl write FPopupControl;
    //
    property OnDrawWindow: TDrawEvent read FOnDrawWindow write FOnDrawWindow;
  end;

  TCFWinPopup = class(TCFCustomPopup)
  private
    FPopupControl: TWinControl;
    FPopupControlOldParent: THandle;
  protected
    procedure DoPopupMessage(const Msg: TMsg); override;
    procedure WndProc(var Message: TMessage); override;
  public
    procedure Popup(X, Y: Integer); override;
    property PopupControl: TWinControl read FPopupControl write FPopupControl;
  end;

implementation

uses
  Forms, SysUtils;

type
  TApplicationAccess = class(TApplication);

var
  ApplicationCallWndProcHook: HHOOK = 0;
  //OldWndProc: Pointer;

{ TCFCustomPopup }

{function WndProc(hWnd: HWND; Msg: Windows.UINT; WParam: WPARAM; LParam: LPARAM): LRESULT stdcall;
begin
  SetWindowLong(hwnd, GWL_WNDPROC, Longint(OldWndProc));
  Result := 1;
end;}

function ApplicationCallWndProcHookProc(Code: Integer;
  WParam, LParam: Longint): Longint stdcall;

  {procedure LockMessage(AWnd: HWND);
  begin
    OldWndProc := Pointer(GetWindowLong(AWnd, GWL_WNDPROC));
    SetWindowLong(AWnd, GWL_WNDPROC, Longint(@WndProc));
  end;}

  procedure RemoveHooks;
  begin
    if ApplicationCallWndProcHook <> 0 then
    begin
      UnhookWindowsHookEx(ApplicationCallWndProcHook);
      ApplicationCallWndProcHook := 0;
    end;
  end;

begin
// ��ʱȥ��Hook
//  if Windows.PCWPStruct(LParam)^.message = WM_ACTIVATEAPP then
//  begin
//    if Windows.PCWPStruct(LParam)^.wParam = 0 then
//    begin
//      SendMessage(FPopupWindow, WM_NCACTIVATE, 0, 0);  // ���20160708001��PM_NOREMOVE��ɵ����������������ť�Ҽ��ر�ʱ���رգ��������Źرյ�����
//      RemoveHooks;
//    end;
//  end
//  {else
//  if Windows.PCWPStruct(LParam)^.message = CM_DEACTIVATE then
//  begin
//    LockMessage(Windows.PCWPStruct(LParam)^.hwnd);
//  end};
//
//  Result := CallNextHookEx(ApplicationCallWndProcHook, Code, WParam, LParam);
end;

procedure TCFCustomPopup.ClosePopup(const ACancel: Boolean);
begin
  // �ȴ����¼��ٹر�Popup��������о���Ӧ����
  if (not ACancel) and Assigned(FOnPopupClose) then
    FOnPopupClose(Self);

  ShowWindow(FPopupWindow, SW_HIDE);
  FOpened := False;
end;

constructor TCFCustomPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRemoveMessageOnClose := False;
  FPopupWindow := 0;
  FOpened := False;
  RegFormClass;
  CreateHandle;
end;

procedure TCFCustomPopup.CreateHandle;
var
  vClassName: string;
begin
  if not IsWindow(FPopupWindow) then  // �����ʾ����û�д���
  begin
    vClassName := ClassName;
    FPopupWindow := CreateWindowEx(
        WS_EX_TOPMOST or WS_EX_TOOLWINDOW,  // ���㴰��
        PChar(vClassName),
        nil,
        WS_POPUP,  // ����ʽ����,֧��˫��
        0, 0, 100, 100, 0, 0, HInstance, nil);

    SetWindowLong(FPopupWindow, GWL_WNDPROC, Longint(MakeObjectInstance(WndProc)));  // ���ں����滻Ϊ�෽��
  end;
end;

destructor TCFCustomPopup.Destroy;
begin
  if IsWindow(FPopupWindow) then
    DestroyWindow(FPopupWindow);

  inherited;
end;

procedure TCFCustomPopup.DoPopupMessage(const Msg: TMsg);
begin
end;

function TCFCustomPopup.GetWidth: Integer;
var
  vRect: TRect;
begin
  GetWindowRect(FPopupWindow, vRect);
  Result := vRect.Right - vRect.Left;
end;

procedure TCFCustomPopup.Popup(APt: TPoint);
begin
  Popup(APt.X, APt.Y);
end;

procedure TCFCustomPopup.Popup(const AControl: TControl);
var
  vRect: TRect;
  vW: Integer;
  vPt: TPoint;
begin
  //GetWindowRect((AControl as TWinControl).Handle, vRect)
  if AControl is TCFCustomControl then  // ���Զ���ؼ�����һ�Զ���ؼ����ڲ�Ƕ�׿ؼ�ʱ��ת����Դ��������
  begin
    vPt := Point(0, 0);
    vPt := (AControl as TCFCustomControl).ClientToScreen(vPt);
    vRect := Bounds(vPt.X, vPt.Y, AControl.Width, AControl.Height);
  end
  else
  if AControl.Parent <> nil then
  begin
    vRect := AControl.BoundsRect;
    ClientToScreen(AControl.Parent.Handle, vRect.TopLeft);
    ClientToScreen(AControl.Parent.Handle, vRect.BottomRight);
  end;

  case FAlignment of
    taLeftJustify:
      Popup(vRect.Left, vRect.Bottom);

    taRightJustify:
      Popup(vRect.Right - Width, vRect.Bottom);

    taCenter:
      begin
        vW := (Width - (vRect.Right - vRect.Left)) div 2;
        Popup(vRect.Left - vW, vRect.Bottom);
      end;
  end;
end;

procedure TCFCustomPopup.RegFormClass;
var
  vWndCls: TWndClassEx;
  vClassName: string;
begin
  vClassName := ClassName;
  if not GetClassInfoEx(HInstance, PChar(vClassName), vWndCls) then
  begin
    vWndCls.cbSize        := SizeOf(TWndClassEx);
    vWndCls.lpszClassName := PChar(vClassName);
    vWndCls.style         := CS_VREDRAW or CS_HREDRAW
      or CS_DROPSHADOW or CS_DBLCLKS;  // ͨ������ʽʵ�ִ��ڱ߿���ӰЧ����ֻ����ע�ᴰ����ʱʹ�ô����ԣ�ע����ͨ��SetClassLong(Handle, GCL_STYLE, GetClassLong(Handle, GCL_STYLE) or CS_DROPSHADOW);������

    vWndCls.hInstance     := HInstance;
    vWndCls.lpfnWndProc   := @DefWindowProc;
    vWndCls.cbClsExtra    := 0;
    vWndCls.cbWndExtra    := SizeOf(DWord) * 2;
    vWndCls.hIcon         := LoadIcon(hInstance,MakeIntResource('MAINICON'));
    vWndCls.hIconSm       := LoadIcon(hInstance,MakeIntResource('MAINICON'));
    vWndCls.hCursor       := LoadCursor(0, IDC_ARROW);
    vWndCls.hbrBackground := GetStockObject(white_Brush);
    vWndCls.lpszMenuName  := nil;

    if RegisterClassEx(vWndCls) = 0 then
      raise Exception.Create('�쳣��ע����' + vClassName + '����!');
  end;
end;

procedure TCFCustomPopup.UpdatePopup;
var
  vRect: TRect;
begin
  if IsWindowVisible(FPopupWindow) then
  begin
    GetClientRect(FPopupWindow, vRect);
    InvalidateRect(FPopupWindow, vRect, False);
  end;
end;

procedure TCFCustomPopup.WndProc(var Message: TMessage);
begin
  //Message.Result := 0;

  case Message.Msg of
    //WM_SETCURSOR:
    //  StripSetCursor(AWnd, lParam);
    //WM_ERASEBKGND:  // ֪ͨ�Ѿ��ػ�������
    //  Result := 1;
    //WM_CAPTURECHANGED:
    //  ShowWindow(AWnd, SW_HIDE);
         //WM_LBUTTONUP, WM_RBUTTONUP, WM_MBUTTONUP, WM_DESTROY:
    WM_MOUSEACTIVATE:
      Message.Result := MA_NOACTIVATE;
    WM_NCACTIVATE:
      begin
        FOpened := False;
        Message.Result := 1;
      end
  else
    Message.Result := DefWindowProc(FPopupWindow, Message.Msg, Message.WParam, Message.LParam);
  end;
end;

procedure TCFCustomPopup.Popup(X, Y: Integer);
var
  vMsg: TMsg;
  vBound: TRect;

  function IsFPopupWindow(Wnd: HWnd): Boolean;
  begin
    while (Wnd <> 0) and (Wnd <> FPopupWindow) do
      Wnd := GetParent(Wnd);
    Result := Wnd = FPopupWindow;
  end;

  {$REGION 'MessageLoop'}
  procedure MessageLoop;
  begin
    try
      repeat
        if not FOpened then Exit;

        if PeekMessage(vMsg, 0, 0, 0, PM_NOREMOVE) then  // 20160708001 �Բ鿴�ķ�ʽ��ϵͳ�л�ȡ��Ϣ�����Բ�����Ϣ��ϵͳ���Ƴ�
        begin
          case vMsg.message of
            WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK, WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
            WM_NCRBUTTONDOWN, WM_NCRBUTTONDBLCLK, WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
            WM_NCMBUTTONDOWN, WM_NCMBUTTONDBLCLK, WM_MBUTTONDOWN, WM_MBUTTONDBLCLK:
              begin
                if IsFPopupWindow(vMsg.hwnd) then  // �ڵ��������ϵ��
                begin
                  GetWindowRect(FPopupWindow, vBound);
                  if not PtInRect(vBound, vMsg.pt) then  // ���ڴ���������
                  begin
                    if FRemoveMessageOnClose then
                      PeekMessage(vMsg, 0, 0, 0, PM_REMOVE);  // �˳����Ƴ���ǰ������Ϣ(���Popup������İ�ťʱ�ر�Popup���岻ִ�а�ť�¼�)��ֹ��Ϊ�ر�Popup����������

                    Break;
                  end;
                end
                else  // �����ڵ��������ϵ��
                begin
                  if FRemoveMessageOnClose then
                    PeekMessage(vMsg, 0, 0, 0, PM_REMOVE);  // �˳����Ƴ���ǰ������Ϣ(���Popup������İ�ťʱ�ر�Popup���岻ִ�а�ť�¼�)��ֹ��Ϊ�ر�Popup����������

                  Break;
                end;
                //if vMsg.hwnd = FPopupWindow then  // ���� TCPopup��û��ʵ�ʵ�Control����FPopupWindow�ϵ����
                //  Break;
                //PeekMessage(vMsg, 0, vMsg.message, vMsg.message, PM_REMOVE);
                //SendMessage(FPopupWindow, vMsg.Message, vMsg.WParam, vMsg.LParam);
              end;

            {WM_LBUTTONUP:
              begin
                if IsFPopupWindow(vMsg.hwnd) then
                begin
                  //PeekMessage(vMsg, 0, 0, 0, PM_REMOVE);
                  //SendMessage(FPopupWindow, vMsg.Message, vMsg.WParam, vMsg.LParam);
                end;
              end;}

            WM_MOUSEWHEEL:  // ��������Ӧ���й����¼�
              begin
                PeekMessage(vMsg, 0, 0, 0, PM_REMOVE);
                SendMessage(FPopupWindow, vMsg.Message, vMsg.WParam, vMsg.LParam);
                Continue;
              end;

            WM_KEYFIRST..WM_KEYLAST:
              begin
                PeekMessage(vMsg, 0, 0, 0, PM_REMOVE);
                SendMessage(FPopupWindow, vMsg.Message, vMsg.WParam, vMsg.LParam);
                Continue;
              end;

            //WM_C_KILLPOPUP: Exit;  // �ⲿ���͹ر�Popu��Ϣ

            WM_KILLFOCUS:
              Exit;

            CM_DEACTIVATE, WM_ACTIVATEAPP:
              Break;
          end;
            Application.HandleMessage;
        end
        else
          TApplicationAccess(Application).Idle(vMsg);

        DoPopupMessage(vMsg);
      until Application.Terminated;
    finally
      if FOpened then
        ClosePopup(True);
    end;
  end;
  {$ENDREGION}

  {$REGION 'ͨ���ؼ������ȡ�ؼ�ʵ������ʱδʹ��'}
  {
    ---------------ͨ���ؼ������ȡ�ؼ�ʵ������ʱδʹ��--------------------------------
    ---------------ԭ����� Classes.pas ��Ԫ��13045�� <Delphi7>------------------------
    ---------------ԭ����� Classes.pas ��Ԫ��11613�� <Delphi2007>---------------------
    ---------------ԭ����� Classes.pas ��Ԫ��13045�� <Delphi2010>---------------------
    ---------------ԭ����� Classes.pas ��Ԫ��13512�� <DelphiXE>-----------------------
  }
  function GetInstanceFromhWnd(const hWnd: Cardinal): TWinControl;
  type
    PObjectInstance = ^TObjectInstance;

    TObjectInstance = packed record
      Code: Byte;            { ����ת $E8 }
      Offset: Integer;       { CalcJmpOffset(Instance, @Block^.Code); }
      Next: PObjectInstance; { MainWndProc ��ַ }
      Self: Pointer;         { �ؼ������ַ }
    end;
  var
    wc: PObjectInstance;
  begin
    Result := nil;
    wc := Pointer(GetWindowLong(hWnd, GWL_WNDPROC));
    if wc <> nil then
    begin
      Result := wc.Self;
    end;
  end;
  {$ENDREGION}

var
  vW, vH: Integer;
  vMonitor: TMonitor;
begin
  GetWindowRect(FPopupWindow, vBound);
  vW := vBound.Right - vBound.Left;
  vH := vBound.Bottom - vBound.Top;

  vMonitor := Screen.MonitorFromPoint(Point(X, Y));

  if vMonitor <> nil then
  begin
    if X + vW > vMonitor.WorkareaRect.Right then
      X := vMonitor.WorkareaRect.Right - vW;
    if Y + vH > vMonitor.WorkareaRect.Bottom then
      Y := vMonitor.WorkareaRect.Bottom - vH;

    if X < vMonitor.WorkareaRect.Left then
      X := vMonitor.WorkareaRect.Left;
    if Y < vMonitor.WorkareaRect.Top then
      Y := vMonitor.WorkareaRect.Top;
  end
  else // Monitor is nil, use Screen object instead
  begin
    if X + vW > Screen.WorkareaRect.Right then
      X := Screen.WorkareaRect.Right - vW;
    if Y + vH > Screen.WorkareaRect.Bottom then
      Y := vBound.Top - vH;

    if X < Screen.WorkareaRect.Left then
      X := Screen.WorkareaRect.Left;
    if Y < Screen.WorkareaRect.Top then
      Y := Screen.WorkareaRect.Top;
  end;
  //
  MoveWindow(FPopupWindow, X, Y, vW, vH, True);
  ShowWindow(FPopupWindow, SW_SHOWNOACTIVATE);  // SW_SHOWNOACTIVATE SW_SHOW
  FOpened := True;
  {��ʱȥ��Hook
  if FPopupWindow <> 0 then
    ApplicationCallWndProcHook := SetWindowsHookEx(WH_CALLWNDPROC, ApplicationCallWndProcHookProc, 0, GetCurrentThreadId);}
  SetCapture(FPopupWindow);
  try
    MessageLoop;
  finally
    ReleaseCapture;
  end;
end;

{ TCFWinPopup }

procedure TCFWinPopup.DoPopupMessage(const Msg: TMsg);
var
  vWnd: HWND;
begin
  if Assigned(FPopupControl) then
  begin
//    vWnd := Msg.hwnd;
    if vWnd = FPopupControl.Handle then
      FPopupControl.Perform(Msg.message, Msg.wParam, Msg.lParam)
//    else
//    begin
//      while (vWnd <> 0) and (vWnd <> FPopupControl.Handle) do
//        vWnd := GetParent(vWnd);
//
//      if vWnd = FPopupControl.Handle then
//        FPopupControl.Perform(Msg.message, Msg.wParam, Msg.lParam);
//    end;
  end;
end;

procedure TCFWinPopup.Popup(X, Y: Integer);
var
  vPopupControlBounds: TRect;
  vW, vH: Integer;
begin
  if FPopupControl is TWinControl then
  begin
    if FPopupControl.HandleAllocated then
      GetWindowRect(FPopupControl.Handle, vPopupControlBounds)
    else
      vPopupControlBounds := FPopupControl.BoundsRect;
  end;

  vW := vPopupControlBounds.Right - vPopupControlBounds.Left;
  vH := vPopupControlBounds.Bottom - vPopupControlBounds.Top;

  if FPopupControl.Parent.Handle <> FPopupWindow then
  begin
    FPopupControlOldParent := GetParent(FPopupControl.Handle);
    SetParent(FPopupControl.Handle, FPopupWindow);
    SetWindowPos(FPopupControl.Handle, 0, 0, 0, vW, vH, SWP_NOZORDER);
  end
  else
    FPopupControlOldParent := 0;

  MoveWindow(FPopupWindow, 0, 0, vW, vH, True);

  inherited Popup(X, Y);
end;

procedure TCFWinPopup.WndProc(var Message: TMessage);
//var
//  vDC: HDC;
//  ps: TPaintStruct;
//  vSaveIndex: Integer;
//  vCanvas: TCanvas;
begin
  inherited;

//  if FPopupControl <> nil then
//  begin
//    case Message.Msg of
////      WM_MOUSEMOVE:
////        FPopupControl.Perform(Message.Msg, Message.WParam, message.LParam);
//      {WM_PAINT:
//        begin
//          vDC := TWMPaint(Message).DC;
//          if vDC = 0 then
//          begin
//            vDC := BeginPaint(FPopupWindow, ps);
//            try
//              vCanvas := TCanvas.Create;
//              vCanvas.Handle := vDC;
//              vSaveIndex := SaveDC(vDC);
//              try
//                MoveWindowOrg(vDC, 0, 0);
//                IntersectClipRect(vDC, 0, 0, FPopupControl.Width, FPopupControl.Height);
//
//                vCanvas.Brush.Color := clRed;
//                vCanvas.FillRect(Rect(0, 0, FPopupControl.Width, FPopupControl.Height));
//
//                //FPopupControl.PaintTo(vCanvas.Handle, 0, 0);
//              finally
//                RestoreDC(vDC, vSaveIndex);
//                vCanvas.Handle := 0;
//                vCanvas.Free;
//              end;
//            finally
//              EndPaint(FPopupWindow, ps);
//            end;
//          end
//          else
//          begin
//              MoveToEx(vDC, 0, 0, nil);
//              LineTo(vDC, FPopupControl.Width, FPopupControl.Height);
//              FPopupControl.PaintTo(vDC, 0, 0);
//          end;
//        end;}
//    end;
//  end;
end;

{ TCFPopup }

procedure TCFPopup.SetSize(const AWidth, AHeight: Integer);
var
  vRect: TRect;
begin
  if GetWindowRect(FPopupWindow, vRect) then
    MoveWindow(FPopupWindow, vRect.Left, vRect.Top, AWidth, AHeight, False);
end;

procedure TCFPopup.WndProc(var Message: TMessage);
var
  vFormDC, vMemDC: HDC;
  vMemBitmap, vOldBitmap: HBITMAP;
  ps: TPaintStruct;
  vClientRect: TRect;
begin
  if FPopupControl <> nil then
  begin
    case Message.Msg of
      WM_PAINT:
        begin
          if Assigned(FOnDrawWindow) then
          begin
            // ˫�����ͼ
            vFormDC := BeginPaint(FPopupWindow, ps);
            try
              GetClientRect(FPopupWindow, vClientRect);

              vMemBitmap := CreateCompatibleBitmap(vFormDC, ps.rcPaint.Right - ps.rcPaint.Left,
                ps.rcPaint.Bottom - ps.rcPaint.Top);
              try
                vMemDC := CreateCompatibleDC(vFormDC);
                vOldBitmap := SelectObject(vMemDC, vMemBitmap);
                try
                  FOnDrawWindow(vMemDC, vClientRect);
                  BitBlt(vFormDC, PS.rcPaint.Left, PS.rcPaint.Top,
                    PS.rcPaint.Right - PS.rcPaint.Left,
                    PS.rcPaint.Bottom - PS.rcPaint.Top,
                    vMemDC,
                    PS.rcPaint.Left, PS.rcPaint.Top,
                    SRCCOPY);
                finally
                  SelectObject(vMemDC, vOldBitmap);
                end;
              finally
                DeleteDC(vMemDC);
                DeleteObject(vMemBitmap);
              end;
            finally
              EndPaint(FPopupWindow, ps);
            end;
          end;
        end;

      WM_LBUTTONDOWN:
        begin
          // ���ֱ��Perform��ϢWM_LBUTTONDOWN�����ϵͳ��Ϊ���ڵ����
          // FPopupControl(DirectUIʱΪFPopupControl���ڴ���)�ϣ�����
          // Popup��Ϣѭ���д�����WM_LBUTTONUP����FPopupControl(�����ڵĴ���)������
          // �������ܴ����˴���WM_LBUTTONDOWN�¼�
          FPopupControl.Perform(WM_CF_LBUTTONDOWN, Message.WParam, Message.LParam);
        end;

      WM_ACTIVATEAPP:
        begin
          if FOpened and (Message.WParam = 0) then  // ��FOpened������ر�ʱ�ٴ�ִ�д˴�CloseUp������
            ClosePopup(True);
        end;

      WM_LBUTTONDBLCLK:
        FPopupControl.Perform(WM_CF_LBUTTONDBLCLK, Message.WParam, Message.LParam);

      WM_LBUTTONUP:
        FPopupControl.Perform(WM_CF_LBUTTONUP, Message.WParam, Message.LParam);

      WM_MOUSEWHEEL:
        FPopupControl.Perform(Message.Msg, Message.WParam, Message.LParam);

      WM_MOUSEMOVE:
        FPopupControl.Perform(WM_CF_MOUSEMOVE, Message.WParam, Message.LParam);
    end;
  end;
  inherited;
end;

end.
