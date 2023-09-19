{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit PluginIntf;

interface

uses
  Classes, FunctionIntf;

const
  PLUGIN_INFO = '{09A9DC5B-97FC-43D1-ACFD-B1E86D878238}';

type
  IPlugin = interface(IInterface)  // �����Ϣ
    [PLUGIN_INFO]
    /// <summary> ���ز����cpi�ļ���(��·��) </summary>
    /// <returns></returns>
    function GetFileName: string;
    procedure SetFileName(const AFileName: string);

    function GetEnable: Boolean;

    /// <summary> ���ز�� </summary>
    /// <param name="AFileName">����ļ���</param>
    /// <returns>True:���سɹ�,False����ʧ��</returns>
    procedure Load;

    /// <summary> ж�ز�� </summary>
    /// <returns></returns>
    procedure UnLoad;

    procedure GetPluginInfo;

    /// <summary> ���ע��һ�������ⲿ�ṩ�Ĺ��� </summary>
    /// <param name="AID">����ΨһID</param>
    /// <param name="AName">��������</param>
    /// <returns>����ע��õĹ���</returns>
    function RegFunction(const AID, AName: string): IPluginFunction;

    /// <summary> ���ִ��һ������ </summary>
    /// <param name="AIFun">����</param>
    procedure ExecFunction(const AIFun: ICustomFunction);

    /// <summary> ���ز���ṩ�Ĺ������� </summary>
    /// <returns>��������</returns>
    function GetFunctionCount: Integer;

    /// <summary> ���ز��ָ������ </summary>
    /// <param name="AIndex"></param>
    /// <returns></returns>
    function GetFunction(const AIndex: Integer): IPluginFunction; overload;
    function GetFunction(const AID: string): IPluginFunction; overload;

    /// <summary> ���ز�������� </summary>
    /// <returns>����</returns>
    function GetAuthor: string;

    /// <summary> ָ����������� </summary>
    /// <param name="Value">����</param>
    procedure SetAuthor(const Value: string);

    /// <summary> ���ز����˵�� </summary>
    /// <returns>˵����Ϣ</returns>
    function GetComment: string;

    /// <summary> ���ò����˵�� </summary>
    /// <param name="Value">˵����Ϣ</param>
    procedure SetComment(const Value: string);

    /// <summary> ���ز����ΨһID </summary>
    /// <returns>ID</returns>
    function GetID: string;

    /// <summary> ���ò����ΨһID(GUID) </summary>
    /// <param name="Value">GUID</param>
    procedure SetID(const Value: string);

    /// <summary> ���ز���Ĺ��ܻ�ҵ������ </summary>
    /// <returns>���ܻ�ҵ������</returns>
    function GetName: string;

    /// <summary> ���ò���Ĺ��ܻ�ҵ������ </summary>
    /// <param name="Value">���ܻ�ҵ������</param>
    procedure SetName(const Value: string);

    /// <summary> ���ز���İ汾�� </summary>
    /// <returns>�汾��</returns>
    function GetVersion: string;

    /// <summary> ���ò���İ汾�� </summary>
    /// <param name="Value">�汾��</param>
    procedure SetVersion(const Value: string);

    // �ӿ�����
    property ID: string read GetID write SetID;
    property Author: string read GetAuthor write SetAuthor;
    property Comment: string read GetComment write SetComment;
    property Name: string read GetName write SetName;
    property Version: string read GetVersion write SetVersion;
    property FunctionCount: Integer read GetFunctionCount;
    property FileName: string read GetFileName write SetFileName;
    property Enable: Boolean read GetEnable;
  end;

  TPluginList = class(TList);

  IPluginManager = interface(IInterface)
    ['{3B27642C-376E-4140-B5E0-B25AD258B7FC}']

    /// <summary> ����ָ��Ŀ¼��ָ����׺�������в�� </summary>
    /// <param name="APath">·��</param>
    /// <param name="AExt">��׺��</param>
    /// <returns></returns>
    function LoadPlugins(const APath, AExt: string): Boolean;

    /// <summary> ����ָ���Ĳ�� </summary>
    /// <param name="AFileName">����ļ���</param>
    /// <returns>True�����سɹ���False������ʧ��</returns>
    function LoadPlugin(const AFileName: string): Boolean;

    function UnLoadPlugin(const APluginID: string): Boolean;

    /// <summary> ���ݲ��ID��ȡ��� </summary>
    /// <param name="APluginID">���ID</param>
    /// <returns></returns>
    function GetPluginByID(const APluginID: string): IPlugin;

    /// <summary> ���ز���б� </summary>
    /// <returns>����б�</returns>
    function PluginList: TPluginList;

    /// <summary> ������� </summary>
    /// <returns>�������</returns>
    function Count: Integer;

    /// <summary> �����в���㲥һ������ </summary>
    procedure FunBroadcast(const AFun: ICustomFunction);

    /// <summary> ж�����в�� </summary>
    /// <returns></returns>
    function UnLoadAllPlugin: Boolean;
  end;

implementation

end.
