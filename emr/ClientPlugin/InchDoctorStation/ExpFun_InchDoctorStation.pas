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
{     סԺҽ��վ�������ʵ�ֵ�Ԫ hc 2016-6-7            }
{                                                       }
{     ����������Ԫ��Ϊ������Ͳ�������ṩ���º�����    }
{     1.GetPluginInfo��ȡ�����Ϣ                       }
{     2.ExecFunction���ò��ĳ����                      }
{     3.UnLoadPluginж�ز��                            }
{*******************************************************}

unit ExpFun_InchDoctorStation;

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
  FunctionImp, PluginConst, FunctionConst, Vcl.Forms, frm_InchDoctorStation;

// �����Ϣ��ע�Ṧ��
procedure GetPluginInfo(const AIPlugin: IPlugin); stdcall;
begin
  AIPlugin.Author := 'HC';  // ���ģ������
  AIPlugin.Comment := '���סԺҽ��վҵ��';  // ���˵��
  AIPlugin.ID := PLUGIN_INCHDOCTORSTATION; // ���GUID����Ψһ��ʶ
  AIPlugin.Name := 'סԺҽ��վ';  // ������ܻ�ҵ������
  AIPlugin.Version := '1.0.0';  // ����汾��
  //
  with AIPlugin.RegFunction(FUN_BLLFORMSHOW, 'סԺҽ��վ') do
    ShowEntrance := True;  // �ڽ�����ʾ�������

  AIPlugin.RegFunction(FUN_APPONMESSAGE, '��Ϣѭ��');  // ��Ϣѭ�������������밴;�ż���ѡ��
end;

procedure ExecFunction(const AIFun: ICustomFunction); stdcall;
var
  vID: string;
begin
  vID := AIFun.ID;
  if vID = FUN_BLLFORMSHOW then  // ��ʾҵ����
  begin
    Application.Handle := (AIFun as IFunBLLFormShow).AppHandle;
    PluginShowInchDoctorStationForm(AIFun as IFunBLLFormShow);
  end
  else
  if vID = FUN_APPONMESSAGE then
  begin
    if Assigned(FrmInchDoctorStation) then
      FrmInchDoctorStation.OnMessage(AIFun as IObjectFunction)
  end
  else
  if vID = FUN_BLLFORMDESTROY then  // ҵ����ر�
    PluginCloseInchDoctorStationForm;
end;

procedure UnLoadPlugin(const AIPlugin: IPlugin); stdcall;
begin
  PluginCloseInchDoctorStationForm;
end;

end.
