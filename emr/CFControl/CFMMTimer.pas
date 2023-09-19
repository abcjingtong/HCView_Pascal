unit CFMMTimer;

interface

uses
  Windows, Classes, MMSystem, TypInfo;

type
  TCFMMTimer = class(TObject)
  private
    FInternal: Cardinal;  // ��ʱ���ļ��ʱ�䣬��λΪ���룬Ĭ��Ϊ1000����
    FEnable: Boolean;  // ��ʱ���Ƿ������У�Ĭ��ΪFALSE
    FProcCallback: TFnTimeCallback;  // �ص�����ָ��
    FOnTimer: TNotifyEvent;  // ���ڻص�ʱ�����Ķ�ʱ���¼�
    FHTimerID: Integer;  // ��ʱ��IDֹͣ��ʱ��ʹ��

    procedure SetInternal(const Value: Cardinal);
    procedure SetEnable(const Value: Boolean);
  public
    property Internal: Cardinal read FInternal write SetInternal default 1000;
    property Enable: Boolean read FEnable write SetEnable default FALSE;
    property OnTimer: TNotifyEvent read FOnTimer write FOnTimer;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TCFMMTimer }

procedure DoTimer(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD_PTR) stdcall;
var
  vObj: TCFMMTimer;
begin
  vObj := TCFMMTimer(dwUser);  // dwUserʵ�����Ƕ�ʱ������ĵ�ַ ??
  if Assigned(vObj.OnTimer)then
    vObj.OnTimer(vObj);
end;

constructor TCFMMTimer.Create;
begin
  inherited Create;
  FInternal := 1000;  // Ĭ��Ϊ1��
  FEnable := False;  // ��������������ʱ��
  FOnTimer := nil;
  FProcCallback := DoTimer;  // �����еĺ���ָ��ֻ��һ������Ҫ��������dwUser�����ֲ�ͬ�Ķ������ص�
end;

destructor TCFMMTimer.Destroy;
begin
  SetEnable(False);
  inherited Destroy;
end;

procedure TCFMMTimer.SetEnable(const Value: Boolean);
begin
  if FEnable <> Value then
  begin
    FEnable := Value;
    if FEnable then
      FHTimerID := TimeSetEvent(FInternal, 0, FProcCallback, Integer(Self), 1 )  // ����Ѷ����ַ���룬�ص�ʱ���أ����һ��������ʾ���ڻص����ڶ�������0Ϊ��߾���
    else
      TimeKillEvent( FHTimerID );
  end;
end;

procedure TCFMMTimer.SetInternal(const Value: Cardinal);
begin
  if FInternal <> Value then
  begin
    FInternal := Value;
    if FEnable then  // �����ʱ���Ѿ���������������ʱ������Ҫ��ֹͣ������������ʱ��
    begin
      Enable := False;
      Enable := True;
    end;
  end;
end;

end.
