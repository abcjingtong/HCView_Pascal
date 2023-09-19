{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit FunctionImp;

interface

uses
  PluginImp, FunctionConst, FunctionIntf;

type
  TObjectFunction = class(TCustomFunction, IObjectFunction)
  private
    FObject: TObject;
  public
    constructor Create; override;
    function GetObject: TObject;
    procedure SetObject(const Value: TObject);
  end;

  TFunBLLFormShow = class(TPluginFunction, IFunBLLFormShow)
  private
    FAppHandle: THandle;
    FOnNotifyEvent: TFunctionNotifyEvent;
  public
    constructor Create; override;
    { IFunBLLFormShow }
    function GetAppHandle: THandle;
    procedure SetAppHandle(const Value: THandle);
    function GetOnNotifyEvent: TFunctionNotifyEvent;
    procedure SetOnNotifyEvent(const Value: TFunctionNotifyEvent);
    property AppHandle: THandle read GetAppHandle write SetAppHandle;
    property OnNotifyEvent: TFunctionNotifyEvent read GetOnNotifyEvent write SetOnNotifyEvent;
  end;

implementation

{ TFunBLLFormShow }

constructor TFunBLLFormShow.Create;
begin
  ID := FUN_BLLFORMSHOW;
  Name := FUN_BLLFORMSHOW_NAME;
end;

function TFunBLLFormShow.GetAppHandle: THandle;
begin
  Result := FAppHandle;
end;

function TFunBLLFormShow.GetOnNotifyEvent: TFunctionNotifyEvent;
begin
  Result := FOnNotifyEvent;
end;

procedure TFunBLLFormShow.SetAppHandle(const Value: THandle);
begin
  FAppHandle := Value;
end;

procedure TFunBLLFormShow.SetOnNotifyEvent(const Value: TFunctionNotifyEvent);
begin
  FOnNotifyEvent := Value;
end;

{ TObjectFunction }

constructor TObjectFunction.Create;
begin
  ID := FUN_OBJECT;
end;

function TObjectFunction.GetObject: TObject;
begin
  Result := FObject;
end;

procedure TObjectFunction.SetObject(const Value: TObject);
begin
  FObject := Value;
end;

end.
