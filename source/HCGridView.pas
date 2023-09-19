{*******************************************************}
{                                                       }
{             HCGridView V1.1  ���ߣ���ͨ               }
{                                                       }
{      ��������ѭBSDЭ�飬����Լ���QQȺ 649023932      }
{            ����ȡ����ļ������� 2019-4-28             }
{                                                       }
{                 ������ݰ�ҳ���ֿؼ�                  }
{                                                       }
{*******************************************************}

unit HCGridView;

interface

uses
  Windows, Classes, Controls, Graphics, SysUtils, Generics.Collections, Messages,
  HCScrollBar, HCRichScrollBar, HCViewData, HCTableItem, HCTableRow, HCTableCell,
  HCTableCellData, HCStyle, HCItem, HCRectItem, HCCommon, HCUndo, HCPage, HCParaStyle,
  HCTextStyle, HCUnitConversion, HCView, HCCustomData, HCAnnotateData, HCSection,
  HCSectionData, HCXml;

type
  THCGridData = class(THCPageData)
  public
    procedure GetCaretInfo(const AItemNo, AOffset: Integer; var ACaretInfo: THCCaretInfo); override;
    /// <summary> ���ù��λ�õ�ָ����Itemָ��λ�� </summary>
    /// <param name="AItemNo">ָ��ItemNo</param>
    /// <param name="AOffset">ָ��λ��</param>
    /// <param name="ANextWhenMid">�����λ��ǰ���DrawItem���÷��У�True����һ��DrawItemǰ�棬False��ǰһ������</param>
    procedure ReSetSelectAndCaret(const AItemNo, AOffset: Integer;
      const ANextWhenMid: Boolean = False); override;
  end;

  THCGridPaintEvent = procedure(const ACanvas: TCanvas; const ARect: TRect) of object;

  THCCustomGridView = class(TCustomControl)
  strict private
    FFileName, FPageNoFormat: string;
    FBitmap: TBitmap;
    /// <summary> �Ƿ�ԳƱ߾� </summary>
    FSymmetryMargin: Boolean;
    FPageNoVisible: Boolean;  // �Ƿ���ʾҳ��
    FPaper: THCPaper;
    FPaperOrientation: TPaperOrientation;
    FStyle: THCStyle;
    FCaret: THCCaret;
    FHeader: THCHeaderData;
    FFooter: THCFooterData;
    FPage: THCGridData;
    FTable: THCTableItem;
    FUndoList: THCUndoList;
    FHScrollBar: THCScrollBar;
    FVScrollBar: THCRichScrollBar;
    FAnnotatePre: THCAnnotatePre;  // ��ע����
    FViewWidth, FViewHeight, FUpdateCount,
    FHeaderOffset  // ҳü����ƫ��
      : Integer;

    FZoom: Single;
    FIsChanged: Boolean;
    FOnVerScroll, FOnHorScroll, FOnCaretChange, FOnChange, FOnChangeSwitch,
      FOnZoomChange : TNotifyEvent;
    FOnPaintBackground: THCGridPaintEvent;

    function DoUndoNew: THCUndo;
    function DoUndoGroupBegin(const AItemNo, AOffset: Integer): THCUndoGroupBegin;
    function DoUndoGroupEnd(const AItemNo, AOffset: Integer): THCUndoGroupEnd;
    procedure DoUndo(const Sender: THCUndo);
    procedure DoRedo(const Sender: THCUndo);
    //
    procedure DoDataChanged(Sender: TObject);
    procedure DoHorScroll(Sender: TObject; ScrollCode: TScrollCode;
      const ScrollPos: Integer);
    procedure DoVerScroll(Sender: TObject; ScrollCode: TScrollCode;
      const ScrollPos: Integer);
    function GetHorOffset: Integer;
    function GetVerOffset: Integer;
    procedure SetIsChanged(const Value: Boolean);
    procedure GetViewWidth;
    procedure GetViewHeight;
    procedure CalcScrollRang;
    function GetViewRect: TRect;
    function GetCellPaintBK: THCCellPaintEvent;
    procedure SetCellPaintBK(const Value: THCCellPaintEvent);
    function GetCurStyleNo: Integer;
    function GetCurParaNo: Integer;
    procedure SetPageNoFormat(const Value: string);
    procedure SetZoom(const Value: Single);
    procedure UpdateView; overload;
    procedure UpdateView(const ARect: TRect); overload;
    procedure DoCaretChange;
    procedure DoMapChanged;
    procedure DoAnnotatePreUpdateView(Sender: TObject);
    procedure DoDataInsertAnnotate(const AData: THCCustomData; const ADataAnnotate: THCDataAnnotate);
    procedure DoDataRemoveAnnotate(const AData: THCCustomData; const ADataAnnotate: THCDataAnnotate);
    procedure DoDataDrawItemAnnotate(const AData: THCCustomData; const ADrawItemNo: Integer;
      const ADrawRect: TRect; const ADataAnnotate: THCDataAnnotate);
    /// <summary> ���»�ȡ���λ�� </summary>
    procedure ReBuildCaret;
    procedure CheckUpdateInfo;
    /// <summary> ɾ����ʹ�õ��ı���ʽ </summary>
    procedure _DeleteUnUsedStyle;
    //
    procedure SaveAsSection(const AStream: TStream;
      const ASaveParts: TSectionAreas = [saHeader, saPage, saFooter]);
    procedure LoadAsSection(const AStream: TStream; const AStyle: THCStyle;
      const AFileVersion: Word);
    procedure SectionsToXml(const ANode: IHCXMLNode);
    procedure SectionsParseXml(const ANode: IHCXMLNode);
    procedure PaintTo(const ACanvas: TCanvas; const APaintInfo: TSectionPaintInfo);
    function ChangeByAction(const AFunction: THCFunction): Boolean;
  protected
    procedure CreateWnd; override;
    procedure WndProc(var Message: TMessage); override;
    /// <summary> ��ӦTab���ͷ���� </summary>
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMERASEBKGND(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    // �������뷨���������
    procedure WMImeComposition(var Message: TMessage); message WM_IME_COMPOSITION;
    // Imm
    procedure UpdateImmPosition;
    //
    procedure Resize; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;

    procedure DoChange; virtual;

    /// <summary> �����ĵ�ǰ�����¼������ڶ����������� </summary>
    procedure DoSaveStreamBefor(const AStream: TStream); virtual;

    /// <summary> �����ĵ��󴥷��¼������ڶ����������� </summary>
    procedure DoSaveStreamAfter(const AStream: TStream); virtual;

    /// <summary> ��ȡ�ĵ�ǰ�����¼�������ȷ�϶����������� </summary>
    procedure DoLoadStreamBefor(const AStream: TStream; const AFileVersion: Word); virtual;

    /// <summary> ��ȡ�ĵ��󴥷��¼�������ȷ�϶����������� </summary>
    procedure DoLoadStreamAfter(const AStream: TStream; const AFileVersion: Word); virtual;

    procedure Paint; override;

    procedure DoCellPaintData(const Sender: TObject; const ATableRect, ACellRect: TRect;
      const ARow, ACol, ACellDataDrawTop, ADataDrawBottom, ADataScreenTop,
      ADataScreenBottom: Integer; const ACanvas: TCanvas; const APaintInfo: TPaintInfo); virtual;

    // ֽ����Ϣ
    function GetPaperSize: Integer;
    procedure SetPaperSize(const Value: Integer);
    // �߾���Ϣ
    function GetPaperWidth: Single;
    function GetPaperHeight: Single;
    function GetPaperMarginTop: Single;
    function GetPaperMarginLeft: Single;
    function GetPaperMarginRight: Single;
    function GetPaperMarginBottom: Single;

    procedure SetPaperWidth(const Value: Single);
    procedure SetPaperHeight(const Value: Single);
    procedure SetPaperMarginTop(const Value: Single);
    procedure SetPaperMarginLeft(const Value: Single);
    procedure SetPaperMarginRight(const Value: Single);
    procedure SetPaperMarginBottom(const Value: Single);
    procedure SetPaperOrientation(const Value: TPaperOrientation);
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateEx(AOwner: TComponent; const ARowCount, AColCount: Integer);
    destructor Destroy; override;
    function ContentHeight: Integer;
    function ContentWidth: Integer;
    /// <summary> ��ҳ����������߶ȣ���ҳ���ҳü��ҳ�ź󾻸� </summary>
    function GetPageHeight: Integer;
    function GetPageWidth: Integer;
    function GetHeaderAreaHeight: Integer;
    procedure FormatData;
    procedure ReFormatActiveItem;
    procedure ReFormatActiveParagraph;
    procedure ResetRowCol(const ARowCount, AColCount: Cardinal);
    /// <summary> �Ŵ���ͼ </summary>
    function ZoomIn(const Value: Integer): Integer;

    /// <summary> ��С��ͼ </summary>
    function ZoomOut(const Value: Integer): Integer;
    /// <summary> ��ʼ�������� </summary>
    procedure BeginUpdate;
    /// <summary> ������������ </summary>
    procedure EndUpdate;
    procedure DisSelect;
    /// <summary> ȫ�����(�������ҳü��ҳ�š�ҳ���Item��DrawItem) </summary>
    procedure Clear;
    function MergeSelectCells: Boolean;
    function DeleteCurCol: Boolean;
    function DeleteCurRow: Boolean;
    function InsertColBefor(const ACount: Byte): Boolean;
    function InsertColAfter(const ACount: Byte): Boolean;
    function InsertRowAfter(const ACount: Byte): Boolean;
    function InsertRowBefor(const ACount: Byte): Boolean;

    /// <summary> ����һ��Item </summary>
    function InsertItem(const AItem: THCCustomItem): Boolean; overload;

    /// <summary> ��ָ����λ�ò���һ��Item </summary>
    function InsertItem(const AIndex: Integer; const AItem: THCCustomItem): Boolean; overload;
    function InsertTable(const ARowCount, AColCount: Integer): Boolean;
    function InsertImage(const AImage: TGraphic): Boolean;
    function InsertGifImage(const AFile: string): Boolean;
    /// <summary> ����ˮƽ�� </summary>
    function InsertLine(const ALineHeight: Integer): Boolean;
    function TopLevelData: THCCustomData;
      /// <summary> �޸ĵ�ǰ������ڶ�ˮƽ���뷽ʽ </summary>
    procedure ApplyParaAlignHorz(const AAlign: TParaAlignHorz);

    /// <summary> �޸ĵ�ǰ������ڶδ�ֱ���뷽ʽ </summary>
    procedure ApplyParaAlignVert(const AAlign: TParaAlignVert);

    /// <summary> �޸ĵ�ǰ������ڶα���ɫ </summary>
    procedure ApplyParaBackColor(const AColor: TColor);

    /// <summary> �޸ĵ�ǰ������ڶ��м�� </summary>
    procedure ApplyParaLineSpace(const ASpaceMode: TParaLineSpaceMode; const ASpace: Single = 1);

    /// <summary> �޸ĵ�ǰ������ڶ������� </summary>
    procedure ApplyParaLeftIndent(const Add: Boolean = True); overload;
    /// <summary> �޸ĵ�ǰ������ڶ������� </summary>
    procedure ApplyParaLeftIndent(const AIndent: Single); overload;

    /// <summary> �޸ĵ�ǰ������ڶ������� </summary>
    procedure ApplyParaRightIndent(const AIndent: Single);

    /// <summary> �޸ĵ�ǰ������ڶ��������� </summary>
    procedure ApplyParaFirstIndent(const AIndent: Single);

    /// <summary> �޸ĵ�ǰѡ���ı�����ʽ </summary>
    procedure ApplyTextStyle(const AFontStyle: THCFontStyle);

    /// <summary> �޸ĵ�ǰѡ���ı������� </summary>
    procedure ApplyTextFontName(const AFontName: TFontName);

    /// <summary> �޸ĵ�ǰѡ���ı����ֺ� </summary>
    procedure ApplyTextFontSize(const AFontSize: Single);

    /// <summary> �޸ĵ�ǰѡ���ı�����ɫ </summary>
    procedure ApplyTextColor(const AColor: TColor);

    /// <summary> �޸ĵ�ǰѡ���ı��ı�����ɫ </summary>
    procedure ApplyTextBackColor(const AColor: TColor);

    /// <summary> �޸ĵ�ǰ��Ԫ���ݶ��뷽ʽ </summary>
    procedure ApplyTableCellAlign(const AAlign: THCContentAlign);

    procedure CloneToHCView(const AHCView: THCView);

    // �����ĵ�
    /// <summary> �ĵ�����Ϊhcf��ʽ </summary>
    procedure SaveToFile(const AFileName: string; const AQuick: Boolean = False);

    /// <summary> ��ȡhcf�ļ� </summary>
    procedure LoadFromFile(const AFileName: string);

    /// <summary> �ĵ����浽�� </summary>
    procedure SaveToStream(const AStream: TStream; const AQuick: Boolean = False);

    /// <summary> ��ȡ�ļ��� </summary>
    procedure LoadFromStream(const AStream: TStream);

    /// <summary> �ĵ�����Ϊxml��ʽ </summary>
    procedure SaveToXml(const AFileName: string; const AEncoding: TEncoding);

    /// <summary> ��ȡxml��ʽ </summary>
    procedure LoadFromXml(const AFileName: string);

    /// <summary> �ĵ�����ΪPDF��ʽ </summary>
    procedure SaveToPDF(const AFileName: string);

    /// <summary> ����Ϊhtml��ʽ </summary>
    /// <param name="ASeparateSrc">True��ͼƬ�ȱ��浽�ļ��У�False��base64��ʽ�洢��ҳ����</param>
    procedure SaveToHtml(const AFileName: string; const ASeparateSrc: Boolean = False);

    /// <summary> ���� </summary>
    procedure Undo;

    /// <summary> ���� </summary>
    procedure Redo;

    // ��ӡ
    /// <summary> ʹ��Ĭ�ϴ�ӡ����ӡ����ҳ </summary>
    /// <returns>��ӡ���</returns>
    function Print: TPrintResult; overload;

    /// <summary> ʹ��ָ���Ĵ�ӡ����ӡ����ҳ </summary>
    /// <param name="APrinter">ָ����ӡ��</param>
    /// <param name="ACopies">��ӡ����</param>
    /// <returns>��ӡ���</returns>
    function Print(const APrinter: string; const ACopies: Integer = 1): TPrintResult; overload;

    /// <summary> ʹ��ָ���Ĵ�ӡ����ӡָ��ҳ </summary>
    /// <param name="APrinter">ָ����ӡ��</param>
    /// <param name="ACopies">��ӡ����</param>
    /// <param name="APages">Ҫ��ӡ��ҳ�������</param>
    /// <returns>��ӡ���</returns>
    function Print(const APrinter: string; const ACopies: Integer;
      const APages: array of Integer): TPrintResult; overload;

    procedure ResetMargin;

    /// <summary> ��ǰ�ĵ����� </summary>
    property FileName: string read FFileName write FFileName;

    // ����
    // ҳ��
    property PaperSize: Integer read GetPaperSize write SetPaperSize;
    property PaperWidth: Single read GetPaperWidth write SetPaperWidth;
    property PaperHeight: Single read GetPaperHeight write SetPaperHeight;
    property PaperMarginTop: Single read GetPaperMarginTop write SetPaperMarginTop;
    property PaperMarginLeft: Single read GetPaperMarginLeft write SetPaperMarginLeft;
    property PaperMarginRight: Single read GetPaperMarginRight write SetPaperMarginRight;
    property PaperMarginBottom: Single read GetPaperMarginBottom write SetPaperMarginBottom;
    property PaperOrientation: TPaperOrientation read FPaperOrientation write SetPaperOrientation;
    //
//    property PageWidthPix: Integer read GetPageWidthPix;
//    property PageHeightPix: Integer read GetPageHeightPix;
//    property PageMarginTopPix: Integer read GetPageMarginTopPix;
//    property PageMarginLeftPix: Integer read GetPageMarginLeftPix;
//    property PageMarginRightPix: Integer read GetPageMarginRightPix;
//    property PageMarginBottomPix: Integer read GetPageMarginBottomPix;

    /// <summary> �Ƿ�ԳƱ߾� </summary>
    property SymmetryMargin: Boolean read FSymmetryMargin write FSymmetryMargin;
    property PageNoVisible: Boolean read FPageNoVisible write FPageNoVisible;
    /// <summary> ҳ��ĸ�ʽ </summary>
    property PageNoFormat: string read FPageNoFormat write SetPageNoFormat;
    property HorOffset: Integer read GetHorOffset;
    property VerOffset: Integer read GetVerOffset;
    property Style: THCStyle read FStyle;
    property AnnotatePre: THCAnnotatePre read FAnnotatePre;

    property Header: THCHeaderData read FHeader;
    property Footer: THCFooterData read FFooter;
    property Page: THCGridData read FPage;

    /// <summary> ��ǰ��괦���ı���ʽ </summary>
    property CurStyleNo: Integer read GetCurStyleNo;
    /// <summary> ��ǰ��괦�Ķ���ʽ </summary>
    property CurParaNo: Integer read GetCurParaNo;
    /// <summary> ����ֵ </summary>
    property Zoom: Single read FZoom write SetZoom;
    /// <summary> ��ǰ�ĵ��Ƿ��б仯 </summary>
    property IsChanged: Boolean read FIsChanged write SetIsChanged;
    //
    property OnPaintBackground: THCGridPaintEvent read FOnPaintBackground write FOnPaintBackground;

    /// <summary> ��Ԫ����Ʊ��� </summary>
    property OnCellPaintBK: THCCellPaintEvent read GetCellPaintBK write SetCellPaintBK;
    /// <summary> ��ֱ����������ʱ���� </summary>
    property OnVerScroll: TNotifyEvent read FOnVerScroll write FOnVerScroll;

    /// <summary> ˮƽ����������ʱ���� </summary>
    property OnHorScroll: TNotifyEvent read FOnHorScroll write FOnHorScroll;

    /// <summary> ���λ�øı�ʱ���� </summary>
    property OnCaretChange: TNotifyEvent read FOnCaretChange write FOnCaretChange;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChangeSwitch: TNotifyEvent read FOnChangeSwitch write FOnChangeSwitch;
    /// <summary> �ĵ�Zoom���ű仯�󴥷� </summary>
    property OnZoomChanged: TNotifyEvent read FOnZoomChange write FOnZoomChange;
  end;

  THCGridView = class(THCCustomGridView)
  public
    property Color;
    property OnMouseWheel;
    property PopupMenu;
  end;

implementation

uses
  Math, Imm;

{ THCCustomGridView }

constructor THCCustomGridView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FZoom := 1;
  FFileName := '';
  FPageNoVisible := True;
  FPageNoFormat := '%d/%d';
  FHeaderOffset := 20;
  FSymmetryMargin := True;  // �Գ�ҳ�߾� debug
  FPaper := THCPaper.Create;
  FPaperOrientation := TPaperOrientation.cpoPortrait;
  FBitmap := TBitmap.Create;
  Self.Color := clWhite;
  FUpdateCount := 0;

  FUndoList := THCUndoList.Create;
  FUndoList.OnUndo := DoUndo;
  FUndoList.OnRedo := DoRedo;
  FUndoList.OnUndoNew := DoUndoNew;
  FUndoList.OnUndoGroupStart := DoUndoGroupBegin;
  FUndoList.OnUndoGroupEnd := DoUndoGroupEnd;

  FAnnotatePre := THCAnnotatePre.Create;
  FAnnotatePre.OnUpdateView := DoAnnotatePreUpdateView;

  FStyle := THCStyle.CreateEx(True, True);
  FStyle.ShowParaLastMark := False;
  FStyle.LineSpaceMin := 0;
  //FStyle.OnInvalidateRect := DoStyleInvalidateRect;

  FPage := THCGridData.Create(FStyle);
  FPage.Width := FPaper.WidthPix;
  FPage.OnRemoveAnnotate := DoDataRemoveAnnotate;
  FPage.OnInsertAnnotate := DoDataInsertAnnotate;
  FPage.OnDrawItemAnnotate := DoDataDrawItemAnnotate;

  FTable := THCTableItem.Create(FPage, 1, 1, FPage.Width);
  FTable.ParaFirst := True;
  FTable.OnCellPaintData := DoCellPaintData;

  FPage.Items[0] := FTable;
  FPage.Width := FPage.Width;
  FPage.ReFormat;
  //FTable.FormatToDrawItem(FData, 0);

  FHeader := THCHeaderData.Create(FStyle);
  //SetDataProperty(FHeader);

  FFooter := THCFooterData.Create(FStyle);
  //SetDataProperty(FFooter);
  //
  FHScrollBar := THCScrollBar.Create(Self);
  FHScrollBar.OnScroll := DoHorScroll;
  FHScrollBar.Parent := Self;

  FVScrollBar := THCRichScrollBar.Create(Self);
  FVScrollBar.Orientation := TOrientation.oriVertical;
  FVScrollBar.OnScroll := DoVerScroll;
  FVScrollBar.Parent := Self;

  FIsChanged := False;
end;

constructor THCCustomGridView.CreateEx(AOwner: TComponent; const ARowCount,
  AColCount: Integer);
begin
  Create(AOwner);
  ReSetRowCol(ARowCount, AColCount);
end;

procedure THCCustomGridView.CreateWnd;
begin
  inherited CreateWnd;
  if not (csDesigning in ComponentState) then
  begin
    if Assigned(FCaret) then
      FreeAndNil(FCaret);

    FCaret := THCCaret.Create(Handle);
  end;
end;

procedure THCCustomGridView.ApplyParaAlignHorz(const AAlign: TParaAlignHorz);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyParaAlignHorz(AAlign);
    end);
end;

procedure THCCustomGridView.ApplyParaAlignVert(const AAlign: TParaAlignVert);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyParaAlignVert(AAlign);
    end);
end;

procedure THCCustomGridView.ApplyParaBackColor(const AColor: TColor);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyParaBackColor(AColor);
    end);
end;

procedure THCCustomGridView.ApplyParaFirstIndent(const AIndent: Single);
begin
  ChangeByAction(function(): Boolean
  begin
    FPage.ApplyParaFirstIndent(AIndent);
  end);
end;

procedure THCCustomGridView.ApplyParaLeftIndent(const AIndent: Single);
begin
  ChangeByAction(function(): Boolean
    var
      vPageWidth: Single;
    begin
      if AIndent < 0 then
        FPage.ApplyParaLeftIndent(0)
      else
      begin
        vPageWidth := FPaper.Width - FPaper.MarginLeft - FPaper.MarginRight;
        if AIndent > vPageWidth - 5 then
          FPage.ApplyParaLeftIndent(vPageWidth - 5)
        else
          FPage.ApplyParaLeftIndent(AIndent);
      end;
    end);
end;

procedure THCCustomGridView.ApplyParaLeftIndent(const Add: Boolean);
var
  vIndent, vPageWidth: Single;
begin
  ChangeByAction(function(): Boolean
    begin
      if Add then
        vIndent := FStyle.ParaStyles[CurParaNo].LeftIndent + PixXToMillimeter(TabCharWidth)
      else
        vIndent := FStyle.ParaStyles[CurParaNo].LeftIndent - PixXToMillimeter(TabCharWidth);

      if vIndent < 0 then
        FPage.ApplyParaLeftIndent(0)
      else
      begin
        vPageWidth := FPaper.Width - FPaper.MarginLeft - FPaper.MarginRight;
        if vIndent > vPageWidth - 5 then
          FPage.ApplyParaLeftIndent(vPageWidth - 5)
        else
          FPage.ApplyParaLeftIndent(vIndent);
      end;
    end);
end;

procedure THCCustomGridView.ApplyParaLineSpace(
  const ASpaceMode: TParaLineSpaceMode; const ASpace: Single = 1);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyParaLineSpace(ASpaceMode, ASpace);
    end);
end;

procedure THCCustomGridView.ApplyParaRightIndent(const AIndent: Single);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyParaRightIndent(AIndent);
    end);
end;

procedure THCCustomGridView.ApplyTableCellAlign(const AAlign: THCContentAlign);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyTableCellAlign(AAlign);
    end);
end;

procedure THCCustomGridView.ApplyTextBackColor(const AColor: TColor);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyTextBackColor(AColor);
    end);
end;

procedure THCCustomGridView.ApplyTextColor(const AColor: TColor);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyTextColor(AColor);
    end);
end;

procedure THCCustomGridView.ApplyTextFontName(const AFontName: TFontName);
begin
  ChangeByAction(function(): Boolean
  begin
    FPage.ApplyTextFontName(AFontName);
  end);
end;

procedure THCCustomGridView.ApplyTextFontSize(const AFontSize: Single);
begin
  ChangeByAction(function(): Boolean
  begin
    FPage.ApplyTextFontSize(AFontSize);
  end);
end;

procedure THCCustomGridView.ApplyTextStyle(const AFontStyle: THCFontStyle);
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ApplyTextStyle(AFontStyle);
    end);
end;

procedure THCCustomGridView.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure THCCustomGridView.CalcScrollRang;
begin
  FVScrollBar.Max := ContentHeight;
  FHScrollBar.Max := ContentWidth;
end;

function THCCustomGridView.ChangeByAction(
  const AFunction: THCFunction): Boolean;
begin
  Result := False;

  if not FPage.CanEdit then Exit;
  if (FPage.SelectInfo.StartItemNo < 0)
    or (FPage.SelectInfo.StartItemOffset <> OffsetInner)
  then
    Exit;


  Result := AFunction;  // ����䶯
  DoDataChanged(Self);
end;

procedure THCCustomGridView.CheckUpdateInfo;
begin
  if FUpdateCount > 0 then Exit;

  if Assigned(FCaret) and FStyle.UpdateInfo.ReCaret then
  begin
    ReBuildCaret;
    FStyle.UpdateInfo.ReCaret := False;

    UpdateImmPosition;
  end;

  if FStyle.UpdateInfo.RePaint then
  begin
    FStyle.UpdateInfo.RePaint := False;
    UpdateView;
  end;
end;

procedure THCCustomGridView.Clear;
begin
  FStyle.Initialize;  // ������ʽ����ֹData��ʼ��ΪEmptyDataʱ��Item��ʽ��ֵΪCurStyleNo
  FUndoList.SaveState;
  try
    FUndoList.Enable := False;
    FHeader.Clear;
    FFooter.Clear;
    FPage.Clear;
    FUndoList.Clear;
  finally
    FUndoList.RestoreState;
  end;
  FHScrollBar.Position := 0;
  FVScrollBar.Position := 0;
  FStyle.UpdateInfoRePaint;
  FStyle.UpdateInfoReCaret;
  DoMapChanged;
end;

procedure THCCustomGridView.CloneToHCView(const AHCView: THCView);
var
  vStream: TMemoryStream;
begin
  vStream := TMemoryStream.Create;
  try
    Self.SaveToStream(vStream);
    vStream.Position := 0;
    AHCView.LoadFromStream(vStream);
    AHCView.Style.LineSpaceMin := 0;
    AHCView.FormatData;
  finally
    FreeAndNil(vStream);
  end;
end;

function THCCustomGridView.ContentHeight: Integer;
begin
  Result := FPage.Height;
end;

function THCCustomGridView.ContentWidth: Integer;
begin
  Result := FPage.Width;

  if FAnnotatePre.Visible then
    Result := Result + AnnotationWidth;
end;

function THCCustomGridView.DeleteCurCol: Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.ActiveTableDeleteCurCol;
    end);
end;

function THCCustomGridView.DeleteCurRow: Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.ActiveTableDeleteCurRow;
    end);
end;

destructor THCCustomGridView.Destroy;
begin
  //FreeAndNil(FTable);
  FreeAndNil(FPage);
  FreeAndNil(FHeader);
  FreeAndNil(FFooter);
  FreeAndNil(FBitmap);
  FreeAndNil(FHScrollBar);
  FreeAndNil(FVScrollBar);
  FreeAndNil(FStyle);
  FreeAndNil(FCaret);
  FreeAndNil(FPaper);
  FreeAndNil(FAnnotatePre);

  inherited Destroy;
end;

procedure THCCustomGridView.DisSelect;
begin
  FPage.DisSelect;
end;

procedure THCCustomGridView.DoAnnotatePreUpdateView(Sender: TObject);
begin
  if FAnnotatePre.Visible then
  begin
    FStyle.UpdateInfoRePaint;
    DoMapChanged;
  end
  else
    UpdateView;
end;

procedure THCCustomGridView.DoCaretChange;
begin
  if Assigned(FOnCaretChange) then
    FOnCaretChange(Self);
end;

procedure THCCustomGridView.DoCellPaintData(const Sender: TObject;
  const ATableRect, ACellRect: TRect; const ARow, ACol, ACellDataDrawTop,
  ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
  const ACanvas: TCanvas; const APaintInfo: TPaintInfo);
var
  i, vTop: Integer;
  vCellData: THCTableCellData;
begin
  if ACol = 3 then
  begin
    //vTop := ACellDataDrawTop;
    vCellData := (Sender as THCTableItem).Cells[ARow, ACol].CellData;
    for i := 1 to vCellData.DrawItems.Count - 1 do
    begin
      vTop := ACellDataDrawTop + vCellData.DrawItems[i].Rect.Top;
      if vTop < ADataScreenTop then
        Continue;

      if vTop > ADataScreenBottom then
        Break;

      ACanvas.MoveTo(ATableRect.Left, vTop);
      ACanvas.LineTo(ACellRect.Right, vTop);
    end;
  end;
end;

procedure THCCustomGridView.DoChange;
begin
  SetIsChanged(True);
  DoMapChanged;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure THCCustomGridView.DoDataChanged(Sender: TObject);
begin
  SetIsChanged(True);
  DoMapChanged;
  if Assigned(FOnChange) then
    FOnChange(Sender);
end;

procedure THCCustomGridView.DoDataDrawItemAnnotate(const AData: THCCustomData;
  const ADrawItemNo: Integer; const ADrawRect: TRect;
  const ADataAnnotate: THCDataAnnotate);
var
  vDrawAnnotate: THCDrawAnnotate;
begin
  vDrawAnnotate := THCDrawAnnotate.Create;
  //vAnnotate.Section := Sender;
  vDrawAnnotate.Data := AData;
  vDrawAnnotate.DrawRect := ADrawRect;
  vDrawAnnotate.DataAnnotate := ADataAnnotate;
  FAnnotatePre.AddDrawAnnotate(vDrawAnnotate);
end;

procedure THCCustomGridView.DoDataInsertAnnotate(const AData: THCCustomData;
  const ADataAnnotate: THCDataAnnotate);
begin
  FAnnotatePre.InsertDataAnnotate(ADataAnnotate);
end;

procedure THCCustomGridView.DoDataRemoveAnnotate(const AData: THCCustomData;
  const ADataAnnotate: THCDataAnnotate);
begin
  FAnnotatePre.RemoveDataAnnotate(ADataAnnotate);
end;

procedure THCCustomGridView.DoHorScroll(Sender: TObject;
  ScrollCode: TScrollCode; const ScrollPos: Integer);
begin
  FStyle.UpdateInfoRePaint;
  FStyle.UpdateInfoReCaret(False);
  CheckUpdateInfo;
  if Assigned(FOnHorScroll) then
    FOnHorScroll(Self);
end;

procedure THCCustomGridView.DoLoadStreamAfter(const AStream: TStream;
  const AFileVersion: Word);
begin
end;

procedure THCCustomGridView.DoLoadStreamBefor(const AStream: TStream;
  const AFileVersion: Word);
begin
end;

procedure THCCustomGridView.DoMapChanged;
begin
  if FUpdateCount = 0 then
  begin
    CalcScrollRang;
    CheckUpdateInfo;
  end;
end;

function THCCustomGridView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if ssCtrl in Shift then
    FHScrollBar.Position := FHScrollBar.Position - WheelDelta
  else
    FVScrollBar.Position := FVScrollBar.Position - WheelDelta;

  Result := True;
end;

procedure THCCustomGridView.DoRedo(const Sender: THCUndo);
begin
  FHScrollBar.Position := (Sender as THCUndoEditGroupEnd).HScrollPos;
  FVScrollBar.Position := (Sender as THCUndoEditGroupEnd).VScrollPos;

  FPage.Redo(Sender);
end;

procedure THCCustomGridView.DoSaveStreamAfter(const AStream: TStream);
begin
end;

procedure THCCustomGridView.DoSaveStreamBefor(const AStream: TStream);
begin
end;

procedure THCCustomGridView.DoUndo(const Sender: THCUndo);
begin
  FHScrollBar.Position := (Sender as THCUndoEditGroupBegin).HScrollPos;
  FVScrollBar.Position := (Sender as THCUndoEditGroupBegin).VScrollPos;

  FPage.Undo(Sender);
end;

function THCCustomGridView.DoUndoGroupBegin(const AItemNo,
  AOffset: Integer): THCUndoGroupBegin;
begin
  Result := THCUndoEditGroupBegin.Create;
  (Result as THCUndoEditGroupBegin).HScrollPos := FHScrollBar.Position;
  (Result as THCUndoEditGroupBegin).VScrollPos := FVScrollBar.Position;
  Result.Data := FPage;
  Result.CaretDrawItemNo := -1;
end;

function THCCustomGridView.DoUndoGroupEnd(const AItemNo,
  AOffset: Integer): THCUndoGroupEnd;
begin
  Result := THCUndoEditGroupEnd.Create;
  (Result as THCUndoEditGroupEnd).HScrollPos := FHScrollBar.Position;
  (Result as THCUndoEditGroupEnd).VScrollPos := FVScrollBar.Position;
  Result.Data := FPage;
  Result.CaretDrawItemNo := -1;
end;

function THCCustomGridView.DoUndoNew: THCUndo;
begin
  Result := THCEditUndo.Create;
  (Result as THCEditUndo).HScrollPos := FHScrollBar.Position;
  (Result as THCEditUndo).VScrollPos := FVScrollBar.Position;
  Result.Data := FPage;
end;

procedure THCCustomGridView.DoVerScroll(Sender: TObject;
  ScrollCode: TScrollCode; const ScrollPos: Integer);
begin
  FStyle.UpdateInfoRePaint;
  FStyle.UpdateInfoReCaret(False);
  CheckUpdateInfo;
  if Assigned(FOnVerScroll) then
    FOnVerScroll(Self);
end;

procedure THCCustomGridView.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  DoMapChanged;
end;

procedure THCCustomGridView.FormatData;
begin
  FHeader.ReFormat;
  FFooter.ReFormat;

  FPage.DisSelect;
  FPage.ReFormat;
end;

function THCCustomGridView.GetCellPaintBK: THCCellPaintEvent;
begin
  Result := FTable.OnCellPaintBK;
end;

function THCCustomGridView.GetCurParaNo: Integer;
begin
  Result := FPage.CurParaNo;
end;

function THCCustomGridView.GetCurStyleNo: Integer;
begin
  Result := FPage.CurStyleNo;
end;

function THCCustomGridView.GetHeaderAreaHeight: Integer;
begin
  Result := FHeaderOffset + FHeader.Height;
  if Result < FPaper.MarginTopPix then
    Result := FPaper.MarginTopPix;
end;

function THCCustomGridView.GetHorOffset: Integer;
begin
  Result := FHScrollBar.Position;
end;

function THCCustomGridView.GetPageHeight: Integer;
begin
  Result := FPaper.HeightPix - GetHeaderAreaHeight - FPaper.MarginBottomPix;
end;

function THCCustomGridView.GetPageWidth: Integer;
begin
  Result := FPaper.WidthPix - FPaper.MarginLeftPix - FPaper.MarginRightPix;
end;

function THCCustomGridView.GetPaperHeight: Single;
begin
  Result := FPaper.Height;
end;

function THCCustomGridView.GetPaperMarginBottom: Single;
begin
  Result := FPaper.MarginBottom;
end;

function THCCustomGridView.GetPaperMarginLeft: Single;
begin
  Result := FPaper.MarginLeft;
end;

function THCCustomGridView.GetPaperMarginRight: Single;
begin
  Result := FPaper.MarginRight;
end;

function THCCustomGridView.GetPaperMarginTop: Single;
begin
  Result := FPaper.MarginTop;
end;

function THCCustomGridView.GetPaperSize: Integer;
begin
  Result := FPaper.Size;
end;

function THCCustomGridView.GetPaperWidth: Single;
begin
  Result := FPaper.Width;
end;

function THCCustomGridView.GetVerOffset: Integer;
begin
  Result := FVScrollBar.Position;
end;

procedure THCCustomGridView.GetViewHeight;
begin
  if FHScrollBar.Visible then
    FViewHeight := Height - FHScrollBar.Height
  else
    FViewHeight := Height;
end;

function THCCustomGridView.GetViewRect: TRect;
begin
  Result := Bounds(0, 0, FViewWidth, FViewHeight);
end;

procedure THCCustomGridView.GetViewWidth;
begin
  if FVScrollBar.Visible then
    FViewWidth := Width - FVScrollBar.Width
  else
    FViewWidth := Width;
end;

function THCCustomGridView.InsertColAfter(const ACount: Byte): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.TableInsertColAfter(ACount);
    end);
end;

function THCCustomGridView.InsertColBefor(const ACount: Byte): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.TableInsertColBefor(ACount);
    end);
end;

function THCCustomGridView.InsertGifImage(const AFile: string): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      FPage.InsertGifImage(AFile);
    end);
end;

function THCCustomGridView.InsertImage(const AImage: TGraphic): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      FPage.InsertImage(AImage);
    end);
end;

function THCCustomGridView.InsertItem(const AItem: THCCustomItem): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.InsertItem(AItem);
    end);
end;

function THCCustomGridView.InsertItem(const AIndex: Integer;
  const AItem: THCCustomItem): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.InsertItem(AIndex, AItem);
    end);
end;

function THCCustomGridView.InsertLine(const ALineHeight: Integer): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.InsertLine(ALineHeight);
    end);
end;

function THCCustomGridView.InsertRowAfter(const ACount: Byte): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.TableInsertRowAfter(ACount);
    end);
end;

function THCCustomGridView.InsertRowBefor(const ACount: Byte): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.TableInsertRowBefor(ACount);
    end);
end;

function THCCustomGridView.InsertTable(const ARowCount,
  AColCount: Integer): Boolean;
begin
  Result := ChangeByAction(function(): Boolean
    begin
      Result := FPage.InsertTable(ARowCount, AColCount);
    end);
end;

procedure THCCustomGridView.KeyDown(var Key: Word; Shift: TShiftState);
var
  vOldKey: Word;
begin
  inherited KeyDown(Key, Shift);
  if IsKeyDownEdit(Key) and (not FPage.CanEdit) then Exit;

  if IsKeyDownWant(Key) then
  begin
    case Key of
      VK_BACK, VK_DELETE, VK_RETURN, VK_TAB:
        begin
          vOldKey := Key;
          ChangeByAction(function(): Boolean
            begin
              FPage.KeyDown(vOldKey, Shift);
            end);
          Key := vOldKey;
        end;

      VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END:
        begin
          FPage.KeyDown(Key, Shift);
          //SetActivePageIndex(GetPageIndexByCurrent);  // ����������ƶ���������ҳ
          CheckUpdateInfo;
        end;
    end;
  end;
end;

procedure THCCustomGridView.KeyPress(var Key: Char);
var
  vOldKey: Char;
begin
  inherited KeyPress(Key);
  if not FPage.CanEdit then Exit;

  if IsKeyPressWant(Key) then
  begin
    vOldKey := Key;
    ChangeByAction(function (): Boolean
      begin
        FPage.KeyPress(vOldKey);
      end);
    Key := vOldKey;
  end;
end;

procedure THCCustomGridView.LoadAsSection(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);
var
  vDataSize: Int64;
  vArea: Boolean;
  vLoadParts: TSectionAreas;
begin
  AStream.ReadBuffer(vDataSize, SizeOf(vDataSize));

  AStream.ReadBuffer(FSymmetryMargin, SizeOf(FSymmetryMargin));  // �Ƿ�Գ�ҳ�߾�

  if AFileVersion > 11 then
  begin
    AStream.ReadBuffer(FPaperOrientation, SizeOf(FPaperOrientation));  // ֽ�ŷ���
    AStream.ReadBuffer(FPageNoVisible, SizeOf(FPageNoVisible));  // �Ƿ���ʾҳ��
  end;

  FPaper.LoadToStream(AStream, AFileVersion);  // ҳ�����
  FPage.Width := GetPageWidth;

  // �ĵ�������Щ����������
  vLoadParts := [];
  AStream.ReadBuffer(vArea, SizeOf(vArea));
  if vArea then
    vLoadParts := vLoadParts + [saHeader];
  AStream.ReadBuffer(vArea, SizeOf(vArea));
  if vArea then
    vLoadParts := vLoadParts + [saFooter];
  AStream.ReadBuffer(vArea, SizeOf(vArea));
  if vArea then
    vLoadParts := vLoadParts + [saPage];

  if saHeader in vLoadParts then
  begin
    AStream.ReadBuffer(FHeaderOffset, SizeOf(FHeaderOffset));
    FHeader.Width := FPage.Width;
    FHeader.LoadFromStream(AStream, FStyle, AFileVersion);
  end;

  if saFooter in vLoadParts then
  begin
    FFooter.Width := FPage.Width;
    FFooter.LoadFromStream(AStream, FStyle, AFileVersion);
  end;

  if saPage in vLoadParts then
    FPage.LoadFromStream(AStream, FStyle, AFileVersion);
end;

procedure THCCustomGridView.LoadFromFile(const AFileName: string);
var
  vStream: TStream;
begin
  FFileName := AFileName;
  vStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(vStream);
  finally
    FreeAndNil(vStream);
  end;
end;

procedure THCCustomGridView.LoadFromStream(const AStream: TStream);
var
  vFileExt: string;
  vVersion: Word;
  vLang, vByte: Byte;
begin
  Self.BeginUpdate;
  try
    // ��������ָ�����
    FUndoList.Clear;
    FUndoList.SaveState;
    try
      FUndoList.Enable := False;
      Self.Clear;

      AStream.Position := 0;
      _LoadFileFormatAndVersion(AStream, vFileExt, vVersion, vLang);  // �ļ���ʽ�Ͱ汾
      if vFileExt <> HC_EXT then
        raise Exception.Create('����ʧ�ܣ�����' + HC_EXT + '�ļ���');
      if vVersion > HC_FileVersionInt then
        raise Exception.Create('����ʧ�ܣ���ǰGridView���֧�ְ汾Ϊ'
          + IntToStr(HC_FileVersionInt) + '���ļ����޷��򿪰汾Ϊ'
          + IntToStr(vVersion) + '���ļ���');

      DoLoadStreamBefor(AStream, vVersion);  // ��������ǰ�¼�
      FStyle.LoadFromStream(AStream, vVersion);

      AStream.ReadBuffer(vByte, 1);  // ������

      LoadAsSection(AStream, FStyle, vVersion);
      //FData.LoadFromStream(AStream, FStyle, vVersion);
      DoLoadStreamAfter(AStream, vVersion);

      FormatData;
      DoMapChanged;
    finally
      FUndoList.RestoreState;
    end;
  finally
    Self.EndUpdate;
  end;
end;

procedure THCCustomGridView.LoadFromXml(const AFileName: string);
var
  vXml: IHCXMLDocument;
  vNode: IHCXMLNode;
  vVersion: string;
  vLang: Byte;
  i: Integer;
begin
  Self.BeginUpdate;
  try
    // ��������ָ�����
    FUndoList.Clear;
    FUndoList.SaveState;
    try
      FUndoList.Enable := False;
      Self.Clear;

      vXml := THCXMLDocument.Create(nil);
      vXml.LoadFromFile(AFileName);
      if vXml.DocumentElement.LocalName = 'HCGridView' then
      begin
        if vXml.DocumentElement.Attributes['EXT'] <> HC_EXT then Exit;

        vVersion := vXml.DocumentElement.Attributes['ver'];
        vLang := vXml.DocumentElement.Attributes['lang'];

        for i := 0 to vXml.DocumentElement.ChildNodes.Count - 1 do
        begin
          vNode := vXml.DocumentElement.ChildNodes[i];
          if vNode.NodeName = 'style' then
            FStyle.ParseXml(vNode)
          else
          if vNode.NodeName = 'sections' then
            SectionsParseXml(vNode.ChildNodes[0]);
        end;

        FormatData;
        DoMapChanged;
      end;
    finally
      FUndoList.RestoreState;
    end;
  finally
    Self.EndUpdate;
  end;
end;

function THCCustomGridView.MergeSelectCells: Boolean;
begin
  Result := FPage.MergeTableSelectCells;
  DoDataChanged(Self);
end;

procedure THCCustomGridView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FAnnotatePre.DrawCount > 0 then  // ����ע������
    FAnnotatePre.MouseDown(ZoomOut(X), ZoomOut(Y));

  FPage.MouseDown(Button, Shift, X + FHScrollBar.Position, Y + FVScrollBar.Position);
  CheckUpdateInfo;
end;

procedure THCCustomGridView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);

  GCursor := crDefault;
  FPage.MouseMove(Shift, X + FHScrollBar.Position, Y + FVScrollBar.Position);
  if FStyle.UpdateInfo.Selecting then
    FStyle.UpdateInfoReCaret;

  if FStyle.UpdateInfo.DragingSelected then
    Cursor := GCursor  // �ŵ�OnDrag���ǲ��ǾͲ�������Screen�˻�������Self.DragKind��
  else
    Cursor := GCursor;

  CheckUpdateInfo;
end;

procedure THCCustomGridView.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);;
  FPage.MouseUp(Button, Shift, X + FHScrollBar.Position, Y + FVScrollBar.Position);
  CheckUpdateInfo;

  FStyle.UpdateInfo.Selecting := False;
  FStyle.UpdateInfo.DragingSelected := False;
end;

procedure THCCustomGridView.Paint;
begin
  inherited Paint;
  BitBlt(Canvas.Handle, 0, 0, FViewWidth, FViewHeight,
    FBitmap.Canvas.Handle, 0, 0, SRCCOPY);

  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(Bounds(FVScrollBar.Left, FHScrollBar.Top, FVScrollBar.Width, FHScrollBar.Height));
end;

procedure THCCustomGridView.PaintTo(const ACanvas: TCanvas;
  const APaintInfo: TSectionPaintInfo);
var
  vRect: TRect;
  i, vTop, vPageWidth, vPageHeight, vBs, vYs: Integer;
  vLeft: Integer absolute vTop;
begin
  if APaintInfo.Print and (FAnnotatePre.DrawCount > 0) then  // ��ӡ�ǵ�����ƣ�����ÿһҳǰ���
    FAnnotatePre.ClearDrawAnnotate;

  vRect := GetViewRect;
  if Assigned(FOnPaintBackground) then
    FOnPaintBackground(ACanvas, vRect)
  else
  begin
    ACanvas.Brush.Color := Self.Color;
    ACanvas.FillRect(vRect);
  end;

  //OffsetRect(vRect, -FHScrollBar.Position, -FVScrollBar.Position);
  //FTable.PaintTo(FStyle, vRect, 0, FTable.Height, 0, FViewHeight, ACanvas, APaintInfo);
  FPage.PaintData(-FHScrollBar.Position, -FVScrollBar.Position, FPage.Width - FHScrollBar.Position,
    FPage.Height, 0, FViewHeight, 0, ACanvas, APaintInfo);

  if not APaintInfo.Print then  // �Ǵ�ӡʱ����ҳ��߽�
  begin
    // ��ֱ�߽�
    vPageHeight := GetPageHeight;
    vBs := (FVScrollBar.Position + FViewHeight) div vPageHeight;
    vYs := (FVScrollBar.Position + FViewHeight) mod vPageHeight;

    vTop := FViewHeight - vYs;
    ACanvas.Pen.Color := clGray;
    ACanvas.Pen.Style := psDashDotDot;
    if vTop > 0 then
    begin
      ACanvas.MoveTo(0, vTop);
      ACanvas.LineTo(FViewWidth, vTop);
    end;

    for i := vBs downto 2 do
    begin
      vTop := vTop - vPageHeight;
      if vTop < 0 then
        Break;

      ACanvas.MoveTo(0, vTop);
      ACanvas.LineTo(FViewWidth, vTop);
    end;

    // ˮƽ�߽�
    vPageWidth := FPaper.WidthPix - FPaper.MarginLeftPix - FPaper.MarginRightPix;
    vBs := (FHScrollBar.Position + FViewWidth) div vPageWidth;
    vYs := (FHScrollBar.Position + FViewWidth) mod vPageWidth;

    vLeft := FViewWidth - vYs;
    if vLeft > 0 then
    begin
      ACanvas.MoveTo(vLeft, 0);
      ACanvas.LineTo(vLeft, FViewHeight);
    end;

    for i := vBs downto 2 do
    begin
      vLeft := vLeft - vPageWidth;
      if vLeft < 0 then
        Break;

      ACanvas.MoveTo(vLeft, 0);
      ACanvas.LineTo(vLeft, FViewHeight);
    end;
  end;

  if FAnnotatePre.Visible then  // ��ǰҳ����ע��������ע
    FAnnotatePre.PaintDrawAnnotate(Self, vRect, ACanvas, APaintInfo);

  if FTable.FixRow >= 0 then  // �������п�ҳ�������������Ҫ�����������������ֻҪLeft<0�Ϳ��Ի�����
  begin
    vTop := FTable.Rows[FTable.FixRow].FmtOffset;
    for i := 0 to FTable.FixRow - 1 do
      vTop := vTop + FTable.Rows[i].Height + FTable.Rows[i].FmtOffset;

    if vTop - FVScrollBar.Position < 0 then
    begin
      FTable.PaintFixRows(-FHScrollBar.Position, 0, FViewHeight, ACanvas, APaintInfo);
      // ��Ϊ�������ҳ���������1����ƫ�ƣ���Ҫ�����������ʾ����
      vTop := FTable.GetFixRowHeight;
      ACanvas.Pen.Color := clBlack;
      if APaintInfo.Print then
      begin
        ACanvas.Pen.Width := Max(1, HCUnitConversion.PtToPixel(FTable.BorderWidthPt, APaintInfo.DPI));
        APaintInfo.DrawNoScaleLine(ACanvas, 0, vTop, FPage.Width, vTop);
      end
      else
      begin
        ACanvas.Pen.Width := FTable.BorderWidthPix + 2;
        ACanvas.MoveTo(0, vTop);
        ACanvas.LineTo(FPage.Width, vTop);
      end;
    end;
  end;
end;

function THCCustomGridView.Print(const APrinter: string;
  const ACopies: Integer): TPrintResult;
var
  vHCView: THCView;
begin
  Result := TPrintResult.prError;

  vHCView := THCView.Create(nil);
  try
    CloneToHCView(vHCView);
    Result := vHCView.Print(APrinter, ACopies);
  finally
    FreeAndNil(vHCView);
  end;
end;

function THCCustomGridView.Print(const APrinter: string; const ACopies: Integer;
  const APages: array of Integer): TPrintResult;
var
  vHCView: THCView;
begin
  Result := TPrintResult.prError;

  vHCView := THCView.Create(nil);
  try
    CloneToHCView(vHCView);
    Result := vHCView.Print(APrinter, ACopies, APages);
  finally
    FreeAndNil(vHCView);
  end;
end;

function THCCustomGridView.Print: TPrintResult;
begin
  Result := Print('');
end;

procedure THCCustomGridView.ReBuildCaret;
var
  vCaretInfo: THCCaretInfo;
begin
  if not Assigned(FCaret) then Exit;

  if not Self.Focused then
  begin
    FCaret.Hide;
    Exit;
  end;

  if (not FStyle.UpdateInfo.DragingSelected) and FPage.SelectExists then
  begin
    FCaret.Hide;
    Exit;
  end;

  vCaretInfo.X := 0;
  vCaretInfo.Y := 0;
  vCaretInfo.Height := 0;
  vCaretInfo.Visible := True;

  FPage.GetCaretInfoCur(vCaretInfo);  // FTable.GetCaretInfo(vCaretInfo);

  if not vCaretInfo.Visible then
  begin
    FCaret.Hide;
    Exit;
  end;

  FCaret.X := vCaretInfo.X - FHScrollBar.Position;
  FCaret.Y := vCaretInfo.Y - FVScrollBar.Position;
  FCaret.Height := vCaretInfo.Height;
  FCaret.Show;

  DoCaretChange;
end;

procedure THCCustomGridView.Redo;
begin
  if FUndoList.Enable then  // �ָ����̲�Ҫ�����µ�Redo
  begin
    try
      FUndoList.Enable := False;

      BeginUpdate;
      try
        FUndoList.Redo;
      finally
        EndUpdate;
      end;
    finally
      FUndoList.Enable := True;
    end;
  end;
end;

procedure THCCustomGridView.ReFormatActiveItem;
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ReFormatActiveItem;
    end);
end;

procedure THCCustomGridView.ReFormatActiveParagraph;
begin
  ChangeByAction(function(): Boolean
    begin
      FPage.ReFormatActiveParagraph;
    end);
end;

procedure THCCustomGridView.ResetMargin;
begin
  FPage.Width := GetPageWidth;

  FHeader.Width := FPage.Width;
  FFooter.Width := FPage.Width;

  FormatData;
  FStyle.UpdateInfoRePaint;
  FStyle.UpdateInfoReCaret(False);

  DoChange;
end;

procedure THCCustomGridView.ResetRowCol(const ARowCount, AColCount: Cardinal);
begin
  FTable.ResetRowCol(FPage.Width, ARowCount, AColCount);
  //FPage.Width := FTable.GetFormatWidth;
  FPage.ReFormat;
  FStyle.UpdateInfoReCaret;
  DoMapChanged;
end;

procedure THCCustomGridView.Resize;
begin
  inherited Resize;
  GetViewWidth;
  GetViewHeight;
  FBitmap.SetSize(FViewWidth, FViewHeight);

  FVScrollBar.Left := Width - FVScrollBar.Width;
  FVScrollBar.Height := Height - FHScrollBar.Height;

  FHScrollBar.Top := Height - FHScrollBar.Height;
  FHScrollBar.Width := Width - FVScrollBar.Width;

  CalcScrollRang;

  FStyle.UpdateInfoRePaint;
  if FCaret <> nil then
    FStyle.UpdateInfoReCaret(False);
  CheckUpdateInfo;
end;

procedure THCCustomGridView.SaveAsSection(const AStream: TStream;
  const ASaveParts: TSectionAreas = [saHeader, saPage, saFooter]);
var
  vBegPos, vEndPos: Int64;
  vArea: Boolean;
begin
  vBegPos := AStream.Position;
  AStream.WriteBuffer(vBegPos, SizeOf(vBegPos));  // ���ݴ�Сռλ������Խ��
  //
  if ASaveParts <> [] then
  begin
    AStream.WriteBuffer(FSymmetryMargin, SizeOf(FSymmetryMargin));  // �Ƿ�Գ�ҳ�߾�

    AStream.WriteBuffer(FPaperOrientation, SizeOf(FPaperOrientation));  // ֽ�ŷ���
    AStream.WriteBuffer(FPageNoVisible, SizeOf(FPageNoVisible));  // �Ƿ���ʾҳ��

    FPaper.SaveToStream(AStream);  // ҳ�����

    vArea := saHeader in ASaveParts;  // ��ҳü
    AStream.WriteBuffer(vArea, SizeOf(vArea));

    vArea := saFooter in ASaveParts;  // ��ҳ��
    AStream.WriteBuffer(vArea, SizeOf(vArea));

    vArea := saPage in ASaveParts;  // ��ҳ��
    AStream.WriteBuffer(vArea, SizeOf(vArea));

    if saHeader in ASaveParts then  // ��ҳü
    begin
      AStream.WriteBuffer(FHeaderOffset, SizeOf(FHeaderOffset));
      FHeader.SaveToStream(AStream);
    end;

    if saFooter in ASaveParts then  // ��ҳ��
      FFooter.SaveToStream(AStream);

    if saPage in ASaveParts then  // ��ҳ��
      FPage.SaveToStream(AStream);
  end;
  //
  vEndPos := AStream.Position;
  AStream.Position := vBegPos;
  vBegPos := vEndPos - vBegPos - SizeOf(vBegPos);
  AStream.WriteBuffer(vBegPos, SizeOf(vBegPos));  // ��ǰ�����ݴ�С
  AStream.Position := vEndPos;
end;

procedure THCCustomGridView.SaveToFile(const AFileName: string;
  const AQuick: Boolean = False);
var
  vStream: TStream;
begin
  vStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(vStream, AQuick);
  finally
    FreeAndNil(vStream);
  end;
end;

procedure THCCustomGridView.SaveToHtml(const AFileName: string;
  const ASeparateSrc: Boolean);
var
  vHtmlTexts: TStrings;
  vPath: string;
begin
  _DeleteUnUsedStyle;
  FStyle.GetHtmlFileTempName(True);
  if ASeparateSrc then
    vPath := ExtractFilePath(AFileName)
  else
    vPath := '';

  vHtmlTexts := TStringList.Create;
  try
    vHtmlTexts.Add('<!DOCTYPE HTML>');
    vHtmlTexts.Add('<html>');
    vHtmlTexts.Add('<head>');
    vHtmlTexts.Add('<title>');
    vHtmlTexts.Add('</title>');

    vHtmlTexts.Add(FStyle.ToCSS);

    vHtmlTexts.Add('</head>');

    vHtmlTexts.Add('<body>');
    vHtmlTexts.Add(FPage.ToHtml(vPath));

    vHtmlTexts.Add('</body>');
    vHtmlTexts.Add('</html>');

    vHtmlTexts.SaveToFile(AFileName);
  finally
    FreeAndNil(vHtmlTexts);
  end;
end;

procedure THCCustomGridView.SaveToPDF(const AFileName: string);
var
  vHCView: THCView;
begin
  vHCView := THCView.Create(nil);
  try
    CloneToHCView(vHCView);
    vHCView.SaveToPDF(AFileName);
  finally
    FreeAndNil(vHCView);
  end;
end;

procedure THCCustomGridView.SaveToStream(const AStream: TStream;
  const AQuick: Boolean = False);
var
  vByte: Byte;
begin
  _SaveFileFormatAndVersion(AStream);  // �ļ���ʽ�Ͱ汾
  DoSaveStreamBefor(AStream);

  if not AQuick then
    _DeleteUnUsedStyle;  // ɾ����ʹ�õ���ʽ(�ɷ��Ϊ�����õĴ��ˣ�����ʱItem��StyleNoȡ����)

  FStyle.SaveToStream(AStream);

  vByte := 1;  // ������
  AStream.WriteBuffer(vByte, 1);
  SaveAsSection(AStream);  // ������
  DoSaveStreamAfter(AStream);
end;

procedure THCCustomGridView.SaveToXml(const AFileName: string;
  const AEncoding: TEncoding);
var
  vXml: IHCXMLDocument;
  vNode: IHCXMLNode;
begin
  _DeleteUnUsedStyle;

  vXml := THCXMLDocument.Create(nil);
  vXml.Active := True;
  vXml.Version := '1.0';
  vXml.Encoding := GetEncodingName(AEncoding);

  vXml.DocumentElement := vXml.CreateNode('HCGridView');
  vXml.DocumentElement.Attributes['EXT'] := HC_EXT;
  vXml.DocumentElement.Attributes['ver'] := HC_FileVersion;
  vXml.DocumentElement.Attributes['lang'] := HC_PROGRAMLANGUAGE;

  vNode := vXml.DocumentElement.AddChild('style');
  FStyle.ToXml(vNode);  // ��ʽ��

  vNode := vXml.DocumentElement.AddChild('sections');
  vNode.Attributes['count'] := 1;  // ������

  SectionsToXml(vNode.AddChild('sc'));

  vXml.SaveToFile(AFileName);
end;

procedure THCCustomGridView.SectionsParseXml(const ANode: IHCXMLNode);

  procedure GetXmlPaper_;
  var
    vsPaper: TStringList;
  begin
    vsPaper := TStringList.Create;
    try
      vsPaper.Delimiter := ',';
      vsPaper.DelimitedText := ANode.Attributes['pagesize'];
      FPaper.Size := StrToInt(vsPaper[0]);  // ֽ�Ŵ�С
      FPaper.Width := StrToFloat(vsPaper[1]);  // ֽ�ſ��
      FPaper.Height := StrToFloat(vsPaper[2]);  // ֽ�Ÿ߶�
    finally
      FreeAndNil(vsPaper);
    end;
  end;

  procedure GetXmlPaperMargin_;
  var
    vsMargin: TStringList;
  begin
    vsMargin := TStringList.Create;
    try
      vsMargin.Delimiter := ',';
      vsMargin.DelimitedText := ANode.Attributes['margin'];  // �߾�
      FPaper.MarginLeft := StrToInt(vsMargin[0]);
      FPaper.MarginTop := StrToFloat(vsMargin[1]);
      FPaper.MarginRight := StrToFloat(vsMargin[2]);
      FPaper.MarginBottom := StrToFloat(vsMargin[3]);
    finally
      FreeAndNil(vsMargin);
    end;
  end;

var
  i: Integer;
begin
  FSymmetryMargin := ANode.Attributes['symmargin'];  // �Ƿ�Գ�ҳ�߾�
  FPaperOrientation := TPaperOrientation(ANode.Attributes['ori']);  // ֽ�ŷ���

  FPageNoVisible := ANode.Attributes['pagenovisible'];  // �Ƿ�Գ�ҳ�߾�
  GetXmlPaper_;
  GetXmlPaperMargin_;

  for i := 0 to ANode.ChildNodes.Count - 1 do
  begin
    if ANode.ChildNodes[i].NodeName = 'header' then
    begin
      FHeaderOffset := ANode.ChildNodes[i].Attributes['offset'];
      FHeader.ParseXml(ANode.ChildNodes[i]);
    end
    else
    if ANode.ChildNodes[i].NodeName = 'footer' then
      FFooter.ParseXml(ANode.ChildNodes[i])
    else
    if ANode.ChildNodes[i].NodeName = 'page' then
      FPage.ParseXml(ANode.ChildNodes[i]);
  end;
end;

procedure THCCustomGridView.SectionsToXml(const ANode: IHCXMLNode);
var
  vNode: IHCXMLNode;
begin
  ANode.Attributes['symmargin'] := FSymmetryMargin; // �Ƿ�Գ�ҳ�߾�
  ANode.Attributes['ori'] := Ord(FPaperOrientation);  // ֽ�ŷ���
  ANode.Attributes['pagenovisible'] := FPageNoVisible;  // �Ƿ���ʾҳ��

  ANode.Attributes['pagesize'] :=  // ֽ�Ŵ�С
    IntToStr(FPaper.Size)
    + ',' + FormatFloat('0.#', FPaper.Width)
    + ',' + FormatFloat('0.#', FPaper.Height) ;

  ANode.Attributes['margin'] :=  // �߾�
    FormatFloat('0.#', FPaper.MarginLeft) + ','
    + FormatFloat('0.#', FPaper.MarginTop) + ','
    + FormatFloat('0.#', FPaper.MarginRight) + ','
    + FormatFloat('0.#', FPaper.MarginBottom);

  // ��ҳü
  vNode := ANode.AddChild('header');
  vNode.Attributes['offset'] := FHeaderOffset;
  FHeader.ToXml(vNode);

  // ��ҳ��
  vNode := ANode.AddChild('footer');
  FFooter.ToXml(vNode);

  // ��ҳ��
  vNode := ANode.AddChild('page');
  FPage.ToXml(vNode);
end;

procedure THCCustomGridView.SetCellPaintBK(const Value: THCCellPaintEvent);
begin
  FTable.OnCellPaintBK := Value;
end;

procedure THCCustomGridView.SetIsChanged(const Value: Boolean);
begin
  if FIsChanged <> Value then
  begin
    FIsChanged := Value;
    if Assigned(FOnChangeSwitch) then
      FOnChangeSwitch(Self);
  end;
end;

procedure THCCustomGridView.SetPageNoFormat(const Value: string);
begin
  if FPageNoFormat <> Value then
  begin
    FPageNoFormat := Value;
    UpdateView;
  end;
end;

procedure THCCustomGridView.SetPaperOrientation(const Value: TPaperOrientation);
var
  vfW: Single;
begin
  if FPaperOrientation <> Value then
  begin
    FPaperOrientation := Value;

    vfW := FPaper.Width;
    FPaper.Width := FPaper.Height;
    FPaper.Height := vfW;
  end;
end;

procedure THCCustomGridView.SetPaperHeight(const Value: Single);
begin
  FPaper.Height := Value;
end;

procedure THCCustomGridView.SetPaperMarginBottom(const Value: Single);
begin
  FPaper.MarginBottom := Value;
end;

procedure THCCustomGridView.SetPaperMarginLeft(const Value: Single);
begin
  FPaper.MarginLeft := Value;
end;

procedure THCCustomGridView.SetPaperMarginRight(const Value: Single);
begin
  FPaper.MarginRight := Value;
end;

procedure THCCustomGridView.SetPaperMarginTop(const Value: Single);
begin
  FPaper.MarginTop := Value;
end;

procedure THCCustomGridView.SetPaperSize(const Value: Integer);
begin
  FPaper.Size := Value;
end;

procedure THCCustomGridView.SetPaperWidth(const Value: Single);
begin
  FPaper.Width := Value;
end;

procedure THCCustomGridView.SetZoom(const Value: Single);
var
  vValue: Single;
begin
  if Value < 0.25 then
    vValue := 0.25
  else
  if Value > 5 then
    vValue := 5
  else
    vValue := Value;
  if FZoom <> vValue then
  begin
    Self.SetFocus;
    FZoom := vValue;
    FStyle.UpdateInfoRePaint;
    FStyle.UpdateInfoReCaret(False);
    if Assigned(FOnZoomChange) then
      FOnZoomChange(Self);

    DoMapChanged;
    //DoViewResize;
  end;
end;

function THCCustomGridView.TopLevelData: THCCustomData;
begin
  Result := FPage.GetTopLevelData;
  if Result = FPage then
    Result := nil;
end;

procedure THCCustomGridView.Undo;
begin
  if FUndoList.Enable then  // �������̲�Ҫ�����µ�Undo
  begin
    try
      FUndoList.Enable := False;

      BeginUpdate;
      try
        FUndoList.Undo;
      finally
        EndUpdate;
      end;
    finally
      FUndoList.Enable := True;
    end;
  end;
end;

procedure THCCustomGridView.UpdateImmPosition;
var
  vhIMC: HIMC;
  vCF: TCompositionForm;
begin
  vhIMC := ImmGetContext(Handle);
  try
    vCF.ptCurrentPos := Point(FCaret.X, FCaret.Y + 5);
    vCF.dwStyle := CFS_RECT;
    vCF.rcArea := ClientRect;
    ImmSetCompositionWindow(vhIMC, @vCF);
  finally
    ImmReleaseContext(Handle, vhIMC);
  end;
end;

procedure THCCustomGridView.UpdateView(const ARect: TRect);
var
  vPaintInfo: TSectionPaintInfo;
begin
  FBitmap.Canvas.Lock;
  try
    IntersectClipRect(FBitmap.Canvas.Handle, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    vPaintInfo := TSectionPaintInfo.Create;
    try
      vPaintInfo.ScaleX := FZoom;
      vPaintInfo.ScaleY := FZoom;
      vPaintInfo.Zoom := FZoom;
      vPaintInfo.WindowWidth := FViewWidth;
      vPaintInfo.WindowHeight := FViewHeight;

      PaintTo(FBitmap.Canvas, vPaintInfo);
    finally
      vPaintInfo.Free;
    end;
  finally
    FBitmap.Canvas.Unlock;
  end;

  if HandleAllocated then
  begin
    BitBlt(Canvas.Handle, ARect.Left, ARect.Top,
      ARect.Right - ARect.Left, ARect.Bottom - ARect.Top,
      FBitmap.Canvas.Handle, ARect.Left, ARect.Top, SRCCOPY);
    InvalidateRect(Self.Handle, ARect, False);
  end;
end;

procedure THCCustomGridView.UpdateView;
begin
  UpdateView(GetViewRect);
end;

procedure THCCustomGridView.WMERASEBKGND(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure THCCustomGridView.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTTAB or DLGC_WANTARROWS;
end;

procedure THCCustomGridView.WMImeComposition(var Message: TMessage);
var
  vhIMC: HIMC;
  vSize: Integer;
  vBuffer: TBytes;
  vS: string;
begin
  if (Message.LParam and GCS_RESULTSTR) <> 0 then  // ���뷨֪ͨ��Ҫ���ձ��û�ѡ����ַ�
  begin
    vhIMC := ImmGetContext(Handle);
    if vhIMC <> 0 then
    begin
      try
        vSize := ImmGetCompositionString(vhIMC, GCS_RESULTSTR, nil, 0);  // ��ǰ���յ��ַ��������С
        if vSize > 0 then  // �������ַ�
        begin
          SetLength(vBuffer, vSize);
          ImmGetCompositionString(vhIMC, GCS_RESULTSTR, vBuffer, vSize);
          vS := WideStringOf(vBuffer);
          if vS <> '' then
          begin
            ChangeByAction(function(): Boolean
              begin
                FPage.InsertText(vS);
              end);
          end;
        end;
      finally
        ImmReleaseContext(Handle, vhIMC);
      end;
    end;
  end;
end;

procedure THCCustomGridView.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  if Message.FocusedWnd <> Self.Handle then
    FCaret.Hide;
end;

procedure THCCustomGridView.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  FStyle.UpdateInfoReCaret(False);
  FStyle.UpdateInfoRePaint;
  FStyle.UpdateInfoReScroll;
  CheckUpdateInfo;
end;

procedure THCCustomGridView.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
    WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
    WM_MBUTTONDOWN, WM_MBUTTONDBLCLK:
      begin
        if not (csDesigning in ComponentState) and not Focused then
          Self.SetFocus;
      end;
  end;

  inherited WndProc(Message);
end;

function THCCustomGridView.ZoomIn(const Value: Integer): Integer;
begin
  Result := Round(Value * FZoom);
end;

function THCCustomGridView.ZoomOut(const Value: Integer): Integer;
begin
  Result := Round(Value / FZoom);
end;

procedure THCCustomGridView._DeleteUnUsedStyle;
var
  i, vUnCount: Integer;
begin
  for i := 0 to FStyle.TextStyles.Count - 1 do
  begin
    FStyle.TextStyles[i].CheckSaveUsed := False;
    FStyle.TextStyles[i].TempNo := THCStyle.Null;
  end;
  for i := 0 to FStyle.ParaStyles.Count - 1 do
  begin
    FStyle.ParaStyles[i].CheckSaveUsed := False;
    FStyle.ParaStyles[i].TempNo := THCStyle.Null;
  end;

  FPage.MarkStyleUsed(True);

  vUnCount := 0;
  for i := 0 to FStyle.TextStyles.Count - 1 do
  begin
    if FStyle.TextStyles[i].CheckSaveUsed then
      FStyle.TextStyles[i].TempNo := i - vUnCount
    else
      Inc(vUnCount);
  end;

  vUnCount := 0;
  for i := 0 to FStyle.ParaStyles.Count - 1 do
  begin
    if FStyle.ParaStyles[i].CheckSaveUsed then
      FStyle.ParaStyles[i].TempNo := i - vUnCount
    else
      Inc(vUnCount);
  end;

  FPage.MarkStyleUsed(False);

  for i := FStyle.TextStyles.Count - 1 downto 0 do
  begin
    if not FStyle.TextStyles[i].CheckSaveUsed then
      FStyle.TextStyles.Delete(i);
  end;

  for i := FStyle.ParaStyles.Count - 1 downto 0 do
  begin
    if not FStyle.ParaStyles[i].CheckSaveUsed then
      FStyle.ParaStyles.Delete(i);
  end;
end;

{ THCGridData }

procedure THCGridData.GetCaretInfo(const AItemNo, AOffset: Integer;
  var ACaretInfo: THCCaretInfo);
begin
  if AOffset <> OffsetInner then
    ACaretInfo.Visible := False
  else
    inherited GetCaretInfo(AItemNo, AOffset, ACaretInfo);
end;

procedure THCGridData.ReSetSelectAndCaret(const AItemNo, AOffset: Integer;
  const ANextWhenMid: Boolean);
begin
  inherited ReSetSelectAndCaret(0, OffsetInner);
end;

end.
