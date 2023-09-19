{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit FunctionIntf;

interface

uses
  FunctionConst;

const
  FUN_CUSTOM = '{146E64A2-6C78-497B-B6A3-9DFBC8CE7B91}';
  FUN_PLUGIN = '{14085FF8-D940-41B6-869D-49101CFA4BF1}';

type
  ICustomFunction = interface(IInterface)  // ����ṩ�Ĺ�����Ϣ����
    [FUN_CUSTOM]
    /// <summary> ���ع��ܵ�ID,��Ψһ��ʶ </summary>
    /// <returns>ID</returns>
    function GetID: string;

    /// <summary> ���ù��ܵ�GUID </summary>
    /// <param name="Value">GUID</param>
    procedure SetID(const Value: string);

    property ID: string read GetID write SetID;
  end;

  IObjectFunction = interface(ICustomFunction)
    [FUN_OBJECT]
    function GetObject: TObject;
    procedure SetObject(const Value: TObject);
    property &Object: TObject read GetObject write SetObject;
  end;

  IPluginFunction = interface(ICustomFunction)
    [FUN_PLUGIN]
    /// <summary> �ڽ�����ʾ���ܵ������ </summary>
    function GetShowEntrance: Boolean;

    /// <summary> �����Ƿ��ڽ�����ʾ���ܵ������ </summary>
    /// <param name="ASingleton">True:��ʾ,False:����ʾ</param>
    procedure SetShowEntrance(const Value: Boolean);

    function GetName: string;
    procedure SetName(const Value: string);

    property Name: string read GetName write SetName;
    property ShowEntrance: Boolean read GetShowEntrance write SetShowEntrance;
  end;

  /// <summary> ���������������ָ�������¼� </summary>
  /// <param name="APluginID">�����ܵĲ��ID</param>
  /// <param name="AFunctionID">����Ĺ���ID</param>
  /// <param name="AData">���ܶ�Ӧ������</param>
  TFunctionNotifyEvent = procedure(const APluginID, AFunctionID: string;
    const AObjectFun: IObjectFunction);

  /// <summary> ҵ���幦�� </summary>
  IFunBLLFormShow = interface(IPluginFunction)
    [FUN_BLLFORMSHOW]
    /// <summary> ��ȡ������Application�ľ�� </summary>
    /// <returns>���</returns>
    function GetAppHandle: THandle;

    /// <summary> ������������ </summary>
    /// <param name="Value">���</param>
    procedure SetAppHandle(const Value: THandle);

    /// <summary> ���ز������������򹩲���������ܵķ��� </summary>
    /// <returns>����</returns>
    function GetOnNotifyEvent: TFunctionNotifyEvent;

    /// <summary> ������������򹩲���������ܵķ��� </summary>
    /// <param name="Value"></param>
    procedure SetOnNotifyEvent(const Value: TFunctionNotifyEvent);

    /// <summary> �������� </summary>
    property AppHandle: THandle read GetAppHandle write SetAppHandle;

    /// <summary> �����������¼� </summary>
    property OnNotifyEvent: TFunctionNotifyEvent read GetOnNotifyEvent write SetOnNotifyEvent;
  end;

implementation

end.
