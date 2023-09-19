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
{         ���ʾ������ʵ�ֵ�Ԫ hc 2019-4-23             }
{                                                       }
{     ����������Ԫ��Ϊ������Ͳ�������ṩ���º�����    }
{     1.GetPluginInfo��ȡ�����Ϣ                       }
{     2.ExecFunction���ò��ĳ����                      }
{     3.UnLoadPluginж�ز��                            }
{*******************************************************}

unit ExpFun_PluginDemo;

interface

uses
  PluginIntf, FunctionIntf;

/// <summary>
/// ���ز����Ϣ��ע�����ṩ�Ĺ���
/// </summary>
/// <param name="AIPlugin">�����Ϣ</param>
procedure GetPluginInfo(const AIPlugin: IPlugin); stdcall;

/// <summary>
/// ж�ز��
/// </summary>
/// <param name="AIPlugin">�����Ϣ</param>
procedure UnLoadPlugin(const AIPlugin: IPlugin); stdcall;

/// <summary>
/// ִ�й���
/// </summary>
/// <param name="AIService">��������</param>
procedure ExecFunction(const AIFun: ICustomFunction); stdcall;

exports
   GetPluginInfo,
   ExecFunction,
   UnLoadPlugin;

implementation

uses
  FunctionImp, PluginConst, FunctionConst, Vcl.Forms, frm_Demo;

// �����Ϣ��ע�Ṧ��
procedure GetPluginInfo(const AIPlugin: IPlugin); stdcall;
begin
  AIPlugin.Author := 'HC';  // ���ģ������
  AIPlugin.Comment := '��ʾ�������ĵ��ú��ͷ�';  // ���˵��
  AIPlugin.ID := PLUGIN_DEMO; // ���GUID����Ψһ��ʶ�����鶨�嵽PluginConst��Ԫ��0��ͷ��GUID
  AIPlugin.Name := '���������ʾ';  // ������ܻ�ҵ������
  AIPlugin.Version := '1.0.0';  // ����汾��
  //
  with AIPlugin.RegFunction(FUN_BLLFORMSHOW, '��ʾ�������') do
    ShowEntrance := True;  // �ڽ�����ʾ�������
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
    vIFun.ShowEntrance := (AIFun as IFunBLLFormShow).ShowEntrance;  // ��ʾ��ڵ㣬����Զ���������Ҫ
    vIFun.OnNotifyEvent := (AIFun as IFunBLLFormShow).OnNotifyEvent;  // �����������ͨ���˷�������

    PluginShowDemoForm(vIFun);
  end
  else
  if vID = FUN_BLLFORMDESTROY then  // ҵ����ر�
    PluginCloseDemoForm;
end;

procedure UnLoadPlugin(const AIPlugin: IPlugin); stdcall;
begin
  PluginCloseDemoForm;
end;

end.
