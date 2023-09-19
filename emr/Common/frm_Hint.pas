{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_Hint;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.GIFImg,
  Vcl.ExtCtrls, GDIPOBJ, GDIPAPI;

type
  TUpdateThread = class(TThread)
  private
    FOnExecute: TNotifyEvent;
  protected
    procedure DoOnExecute;
    procedure Execute; override;
  public
    constructor Create;
    property OnExecute: TNotifyEvent read FOnExecute write FOnExecute;
  end;

  TfrmHint = class(TForm)
    lblHint: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FGPImage: TGPBitmap;
    FGPGraphics: TGPGraphics;
    FFrameCount, FFrameIndex: Integer;
    FFrameTimeArr: array of Cardinal;
    FUpdateThread: TUpdateThread;
    procedure DoUpdateThreadExecute(Sender: TObject);
    procedure WndProc(var Message: TMessage); override;
  public
    { Public declarations }
    procedure UpdateHint(const AHint: string);
  end;

implementation

{$R *.dfm}

{ TfrmHint }

procedure TfrmHint.DoUpdateThreadExecute(Sender: TObject);
var
  vHeight, vTop: Integer;
{  vBitmap: TBitmap;
  SavePal, SourcePal: HPALETTE;}
begin
  if Self.Visible then
  begin
    {// Draw new frame on buffer
    SourcePal := TGIFImage(imgWait.Picture.Graphic).Images[FWaitImageIndex].Palette;
    if (SourcePal = 0) then
      SourcePal := SystemPalette16; // This should never happen

    vBitmap := TBitmap.Create;
    vBitmap.SetSize(imgWait.Width, imgWait.Height);

    vBitmap.Canvas.Brush.Color := TGIFImage(imgWait.Picture.Graphic).BackgroundColor;
    vBitmap.Canvas.Brush.Style := bsSolid;
    vBitmap.Canvas.FillRect(vBitmap.Canvas.ClipRect);

    SavePal := SelectPalette(vBitmap.Handle, SourcePal, False);
    try
      RealizePalette(vBitmap.Canvas.Handle);
      TGIFImage(imgWait.Picture.Graphic).Images[FWaitImageIndex].Draw(
        vBitmap.Canvas, vBitmap.Canvas.ClipRect, True, False);

    finally
      if (SavePal <> 0) then
        SelectPalette(vBitmap.Handle, SavePal, False);
    end;

    Canvas.StretchDraw(imgWait.BoundsRect, vBitmap);

    vBitmap.Free; }

    if Assigned(FGPImage) and HandleAllocated then
    begin
      FGPImage.SelectActiveFrame(FrameDimensionTime, FFrameIndex);
      try
        {Canvas.Brush.Color := Color;
        Canvas.Brush.Style := bsSolid;
        Canvas.FillRect(Bounds(Width - FGPImage.GetWidth, 0, FGPImage.GetWidth, FGPImage.GetHeight));}

        vHeight := FGPImage.GetHeight;
        vTop := (ClientHeight - vHeight) div 2;  // ֻ����С�ڴ���߶ȵ����

        FGPGraphics := TGPGraphics.Create(Canvas.Handle);
        FGPGraphics.DrawImage(FGPImage, Width - FGPImage.GetWidth, vTop, FGPImage.GetWidth, vHeight);
      finally
        FreeAndNil(FGPGraphics);
      end;

      Sleep(FFrameTimeArr[FFrameIndex] * 10);

      Inc(FFrameIndex);
      if FFrameIndex > FFrameCount - 1 then
        FFrameIndex := 0;
    end;
  end;
end;

procedure TfrmHint.FormCreate(Sender: TObject);
var
//  vDimensionsCount: Integer;
//  vDimensionsIDs: PGUID;
  vPropertyItem: PPropertyItem;
  vPropertySize: Integer;
{type
  ArrDimensions = array of TGUID;}
begin
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  //SetWindowLong(Handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE);

  if FileExists(ExtractFilePath(ParamStr(0)) + 'image\WAITEGIF.GIF') then
  begin
    FGPImage := TGPBitmap.Create(ExtractFilePath(ParamStr(0)) + 'image\WAITEGIF.GIF');

    {vDimensionsCount := FGPImage.GetFrameDimensionsCount;
    GetMem(vDimensionsIDs, vDimensionsCount * SizeOf(TGUID));
    try
      FGPImage.GetFrameDimensionsList(vDimensionsIDs, vDimensionsCount);
      FFrameCount := FGPImage.GetFrameCount(ArrDimensions(vDimensionsIDs)[0]);
    finally
      FreeMem(vDimensionsIDs);
    end;}

    { ��ȡ Gif ������ʱ������, ����һ�� Cardinal ���� }
    vPropertySize := FGPImage.GetPropertyItemSize(PropertyTagFrameDelay);
    GetMem(vPropertyItem, vPropertySize);
    try
      FGPImage.GetPropertyItem(PropertyTagFrameDelay, vPropertySize, vPropertyItem);

      FFrameCount := vPropertyItem.Length div 4;  // ֡����

      { ���Ƶ���Ҫ������ }
      SetLength(FFrameTimeArr, FFrameCount);
      CopyMemory(FFrameTimeArr, vPropertyItem.Value, vPropertyItem.Length);
    finally
      FreeMem(vPropertyItem);
    end;
  end;
end;

procedure TfrmHint.FormDestroy(Sender: TObject);
begin
  Application.ProcessMessages;  // ����release�汾����ʱ����(ԭ�����)

  if Assigned(FUpdateThread) then
  begin
    FUpdateThread.Terminate;  // �����߳�׼��ֹͣ
    WaitForSingleObject(FUpdateThread.Handle, INFINITE);  // = WAIT_OBJECT_0  // �ȴ��߳�ֹͣ
  end;

  FreeAndNil(FGPGraphics);
  FreeAndNil(FGPImage);
  SetLength(FFrameTimeArr, 0);
end;

procedure TfrmHint.FormShow(Sender: TObject);
begin
  if Assigned(FGPImage) then
  begin
    FUpdateThread := TUpdateThread.Create;  // �����߳�
    FUpdateThread.OnExecute := DoUpdateThreadExecute;
    FUpdateThread.Resume;
  end;

  FFrameIndex := 0;
  Self.Update;
  //Application.ProcessMessages;
end;

procedure TfrmHint.UpdateHint(const AHint: string);
begin
  {lblHint.Caption := AHint;
  //Application.ProcessMessages;
  Self.Update;}

  lblHint.Caption := AHint;
  if HandleAllocated then
    lblHint.Update;
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  //Application.ProcessMessages;
end;

procedure TfrmHint.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_MOUSEACTIVATE then
  begin
    Message.Result := MA_NOACTIVATE;
    Exit;
  end
  else
  if Message.Msg = WM_NCACTIVATE then
  begin
    if (Message.WParam and $FFFF) <> WA_INACTIVE then
    begin
      if Message.LParam = 0 then
        SetActiveWindow(Message.LParam)
      else
        SetActiveWindow(0);
    end;
  end;

  inherited WndProc(Message);
end;

{ TUpdateThread }

constructor TUpdateThread.Create;
begin
  inherited Create;
end;

procedure TUpdateThread.DoOnExecute;
begin
  if Assigned(FOnExecute) then
    FOnExecute(Self);
end;

procedure TUpdateThread.Execute;
begin
  inherited;
  while not Terminated do
  begin
    DoOnExecute;  // Synchronize �����߳���ִ��DoTimer�¼�
    Sleep(0);
  end;
end;

end.
