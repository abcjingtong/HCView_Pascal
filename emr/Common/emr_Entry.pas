{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit emr_Entry;

interface

const
  PatientCount = 'PatientCount';
  PatientCountToday = 'PatientCountToday';
  ShowPhone = 'ShowPhone';
  BoolTrue = 'True';
  BoolFalse = 'False';
  Key_Value = 'Value';

  // ����ע���Сд���޸ĺ�Ҫ����sqlite���ж�Ӧ���ֶδ�Сдһ��
  // ���ز���
  PARAM_LOCAL_MSGHOST = 'MsgHost';    // ��Ϣ������IP
  PARAM_LOCAL_MSGPORT = 'MsgPort';    // ��Ϣ�������˿�
  PARAM_LOCAL_BLLHOST = 'BLLHost';    // ҵ�������IP
  PARAM_LOCAL_BLLPORT = 'BLLPort';    // ҵ��������˿�
  PARAM_LOCAL_UPDATEHOST = 'UpdateHost';  // ���·�����IP
  PARAM_LOCAL_UPDATEPORT = 'UpdatePort';  // ���·������˿�
  PARAM_LOCAL_DEPTID = 'DeptID';  // ����ID
  PARAM_LOCAL_VERSIONID = 'VersionID';  // �汾��
  PARAM_LOCAL_PLAYSOUND = 'PlaySound';  // �����������
  // ����˲���
  PARAM_GLOBAL_HOSPITAL = 'Hospital';  // ҽԺ

  Location = 'Location';  // ��λ
  Camera = 'Camera';  // ����

type
  TUser = class
  public
    /// <summary> ID </summary>
    const ID = 'UserID';
    /// <summary> ���� </summary>
    const NameEx = 'UserName';
    /// <summary> ����ID </summary>
    const DeptID = 'DeptID';
    /// <summary> ������ </summary>
    const DeptName = 'DeptName';
    /// <summary> ���� </summary>
    const Password = 'PAW';
  end;

  TPatient = class
  public
    /// <summary> סԺ�� </summary>
    const InpNo = 'InpNo';
    /// <summary> ���� </summary>
    const NameEx = 'name';
    /// <summary> �Ա� </summary>
    const Sex = 'Sex';
    /// <summary> ���� </summary>
    const Age = 'Age';
    /// <summary> ���� </summary>
    const BedNo = 'BedNo';
    /// <summary> ����ID </summary>
    const DeptID = 'DeptID';
    /// <summary> �������� </summary>
    const DeptName = 'DeptName';
    /// <summary> ��� </summary>
    const Diagnosis = 'Diagnosis';
    /// <summary> ��ϵ�绰 </summary>
    const LinkPhone = 'LinkPhone';
    /// <summary> ������ </summary>
    const CareLevel = 'CareLevel';
    /// <summary> ����״̬ </summary>
    const IllState = 'IllState';
    /// <summary> ��ҺҺ�������� </summary>
    const TransWeight = 'TransWeight';
    /// <summary> ��ҺҺ��ʣ������ </summary>
    const TransRemain = 'TransRemain';
    /// <summary> ����������Ϣ </summary>
    const VitalSigns = 'VitalSigns';
    /// <summary> ����һ�� </summary>
    const TransDrip = 'TransDrip';
    /// <summary> ��Һ���� </summary>
    const TransDripSpeed = 'TransDripSpeed';
    /// <summary> ��Һ��ʼʱ�� </summary>
    const TransTimeStart = 'TransTimeStart';
    /// <summary> ��Һֹͣ </summary>
    const TransStop = 'TransStop';
    /// <summary> ��ҺԤ�ƶ�ý��� </summary>
    const TransTimeOver = 'TransTimeOver';
    /// <summary> ���ߺ��� </summary>
    const Call = 'Call';
    /// <summary> ���� </summary>
    const Temperature = 'Temperature';
    /// <summary> ���� </summary>
    const Pulse = 'Pulse';
    /// <summary> ���� </summary>
    const Heartrate = 'Heartrate';
    /// <summary> ���� </summary>
    const Breathe = 'Breathe';
    /// <summary> �������һ�θ���ʱ�� </summary>
    const LastDateTime = 'LastDataTime';
    /// <summary> ��Ժ���� </summary>
    const InDate = 'InDate';
    /// <summary> ����ҩ�� </summary>
    const AllergicDrug = 'AllergicDrug';
    /// <summary> �������� </summary>
    const LisCount = 'LisCount';
    /// <summary> ������� </summary>
    const PacsCount = 'PacsCount';
    /// <summary> ժҪ </summary>
    const Summarys = 'Summarys';
    /// <summary> ҽ��ID </summary>
    const OneDrID = 'OneDrID';
    /// <summary> �쳣 </summary>
    const Abnormal = 'Abnormal';
    /// <summary> �쳣ֵ���� </summary>
    const AbnormalType = 'AbnormalType';
    /// <summary> �쳣���� </summary>
    const AbnormalData = 'AbnormalData';
  end;

implementation

end.