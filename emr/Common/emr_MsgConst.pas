{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit emr_MsgConst;

interface

const
  MSG_CMD = 'm.cmd';
  MSG_DEVICETYPE = 'm.dc';
  MSG_STRING = 'm.str';
  BLL_CMD = 'b.cmd';
  { ��Ϣָ���� }
  CMD_KEEPALIVE = 1;  // ������
  CMD_DIOCP = 1000;  // �ֽ�� 1000 ���·����DIOCPͨѶ�����1000������ҵ��ʹ��

  CMD_MSG = CMD_DIOCP + 1;  // ���ͼ�ʱ��Ϣ
  CMD_LOGIN = CMD_DIOCP + 2;  // ��¼
  CMD_LOGOUT = CMD_DIOCP + 3;  // �ǳ�
  CMD_DOWNLOAD = CMD_DIOCP + 4;  // ��������
  CMD_UPLOAD = CMD_DIOCP + 5;  // �ϴ�����

  CMD_SERVER = 2000;
  CMD_SRV_CLOSE = CMD_SERVER + 1;  // ����˹ر�
  CMD_SRV_ENFORCELOGOUT = CMD_SERVER + 2;  // �����ǿ��Ҫ��ͻ�������
  CMD_SRV_BLL = CMD_SERVER + 3;  // ҵ������
  CMD_BLL_COLLECTORDATA = CMD_SRV_BLL + 1;  // �ɼ�������������

  { �������� }
  SRVDT = 'p.srvdt';    // ����˵�ǰʱ��
  TOID = 'p.toid';      // ��ϢĿ����ID to work number
  FROMID = 'p.fromid';  // ��Ϣ��Դ��ID
  TOCLIENTTYPE = 'p.tocct';  // ��ϢĿ��ͻ������ͣ�TClientTypeö�� �������û����ɼ��豸��
  FROMCLIENTTYPE = 'p.fromcct';  //  ��Ϣ��Դ�ͻ�������

  ITEMTYPE = 'i.type';
  ITEMVALUE = 'i.val';
  ITEMPATNO = 'i.pno';
type
  /// <summary> �豸���� </summary>
  TDeviceType = (
    /// <summary> ���豸 </summary>
    cdtNone,
    /// <summary> PC </summary>
    cdtPC,
    /// <summary> �ƶ��豸 </summary>
    cdtMobile
    );

  TClientType = (
    /// <summary> ������ </summary>
    cctNone,
    /// <summary> ���� </summary>
    cctLSD,
    /// <summary> �û� </summary>
    cctUser,
    /// <summary> ���ݲɼ��� </summary>
    cctCollector
  );

implementation

end.
