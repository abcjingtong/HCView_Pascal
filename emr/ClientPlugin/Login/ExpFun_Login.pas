{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}
{                                                       }
{           ��¼�������ʵ�ֵ�Ԫ hc 2016-6-7            }
{                                                       }
{     ����������Ԫ��Ϊ������Ͳ�������ṩ���º�����    }
{     1.GetPluginInfo��ȡ�����Ϣ                       }
{     2.ExecFunction���ò��ĳ����                      }
{*******************************************************}

unit ExpFun_Login;

interface

uses
  PluginIntf, FunctionIntf;

/// <summary> ���ز����Ϣ��ע�����ṩ�Ĺ��� </summary>
/// <param name="AIPlugin">�����Ϣ</param>
procedure GetPluginInfo(const AIPlugin: IPlugin); stdcall;

/// <summary> ж�ز�� </summary>
/// <param name="AIPlugin">�����Ϣ</param>
procedure UnLoadPlugin(const AIPlugin: IPlugin); stdcall;

/// <summary> ִ�й��� </summary>
/// <param name="AIService">��������</param>
procedure ExecFunction(const AIFun: ICustomFunction); stdcall;

exports
   GetPluginInfo,
   ExecFunction,
   UnLoadPlugin;

implementation

uses
  FunctionConst, FunctionImp, PlugInConst, frm_login, Vcl.Forms;

// �����Ϣ��ע�Ṧ��
procedure GetPluginInfo(const AIPlugin: IPlugin); stdcall;
begin
  AIPlugin.Author := 'HC';  // ���ģ������
  AIPlugin.Comment := '���ϵͳ��¼';  // ���˵��
  AIPlugin.ID := PLUGIN_LOGIN; // ���GUID����Ψһ��ʶ
  AIPlugin.Name := 'ϵͳ��¼';  // ������ܻ�ҵ������
  AIPlugin.Version := '1.0.0';  // ����汾��
  //
  with AIPlugin.RegFunction(FUN_BLLFORMSHOW, '��¼') do
    ShowEntrance := False;  // �ڽ�����ʾ�������
end;

procedure ExecFunction(const AIFun: ICustomFunction); stdcall;
var
  vID: string;
  vIFun: IFunBLLFormShow;
begin
  vID := AIFun.ID;
  if vID = FUN_BLLFORMSHOW then  // ��ʾҵ����
  begin
    vIFun := TFunBLLFormShow.Create;
    vIFun.AppHandle := (AIFun as IFunBLLFormShow).AppHandle;
    Application.Handle := vIFun.AppHandle;
    vIFun.ShowEntrance := (AIFun as IFunBLLFormShow).ShowEntrance;  // ��ʾ��ڵ�
    vIFun.OnNotifyEvent := (AIFun as IFunBLLFormShow).OnNotifyEvent;  // ����¼�

    PluginShowLoginForm(vIFun);
  end
  else
  if vID = FUN_BLLFORMDESTROY then  // ҵ����ر�
    PluginCloseLoginForm;
end;

procedure UnLoadPlugin(const AIPlugin: IPlugin); stdcall;
begin
  PluginCloseLoginForm;
end;

end.
