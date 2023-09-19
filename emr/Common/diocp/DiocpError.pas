unit DiocpError;

interface

const
  WSABASEERR              = 10000;

{ Windows Sockets definitions of regular Microsoft C error constants }

  {$EXTERNALSYM WSAEINTR}
  WSAEINTR                = (WSABASEERR+4);   // ���������жϡ��ô���������ڶ�WSACancelBlockingCall�ĵ��ã������һ�ε��ñ�ǿ���жϡ�
  {$EXTERNALSYM WSAEBADF}
  WSAEBADF                = (WSABASEERR+9);   // �ļ�������󡣸ô�������ṩ���ļ������Ч��
  {$EXTERNALSYM WSAEACCES}
  WSAEACCES               = (WSABASEERR+13);  // Ȩ�ޱ��ܡ����Զ��׽��ֽ��в�����������ֹ������ͼ��sendto��WSASendTo��ʹ��һ���㲥��ַ��������δ��setsockopt��SO_BROADCAST������ѡ�����ù㲥Ȩ�ޣ��������������
  {$EXTERNALSYM WSAEFAULT}
  WSAEFAULT               = (WSABASEERR+14);  // ��ַ��Ч������Winsock������ָ���ַ��Ч����ָ���Ļ�����̫С��Ҳ������������
  {$EXTERNALSYM WSAEINVAL}
  WSAEINVAL               = (WSABASEERR+22);  // ������Ч��ָ����һ����Ч���������磬����ΪWSAIoctl����ָ����һ����Ч���ƴ��룬����������������⣬��Ҳ���ܱ����׽��ֵ�ǰ��״̬�д�������һ��Ŀǰû�м������׽����ϵ���accept��WSAAccept��
  {$EXTERNALSYM WSAEMFILE}
  WSAEMFILE               = (WSABASEERR+24);  // ���ļ����ࡣ��ʾ�򿪵��׽���̫���ˡ�ͨ����Microsoft�ṩ��ֻ�ܵ�ϵͳ�ڿ�����Դ���������ơ�

{ Windows Sockets definitions of regular Berkeley error constants }

  {$EXTERNALSYM WSAEWOULDBLOCK}
  WSAEWOULDBLOCK          = (WSABASEERR+35);  // �׽��ֱ��Ϊδ�ֿ飬���������ֿ�
  {$EXTERNALSYM WSAEINPROGRESS}
  WSAEINPROGRESS          = (WSABASEERR+36);  // ��Դ��ʱ�����á��Է������׽�����˵��������������������ִ�еĻ���ͨ���᷵��������󡣱���˵����һ������ͣ�׽����ϵ���conn ect���ͻ᷵�����������Ϊ��������������ִ�С�
  {$EXTERNALSYM WSAEALREADY}
  WSAEALREADY             = (WSABASEERR+37);  // ��������ɡ�һ����˵���ڷ������׽����ϳ����Ѵ��ڽ����еĲ���ʱ�������������󡣱��磬��һ���Ѵ������ӽ��̵ķ������׽����ϣ���һ�ε���connect��WSAConnect�����⣬�����ṩ�ߴ���ִ�лص�����
  {$EXTERNALSYM WSAENOTSOCK}
  WSAENOTSOCK             = (WSABASEERR+38);  // ��Ч�׽����ϵ��׽��ֲ������κ�һ����SOCKET�������������Winsock�������᷵����������������ṩ���׽��־����Ч��
  {$EXTERNALSYM WSAEDESTADDRREQ}
  WSAEDESTADDRREQ         = (WSABASEERR+39);  // ��ҪĿ���ַ������������û���ṩ�����ַ���ȷ�˵�������ڵ���sendtoʱ����Ŀ���ַ��ΪINADDR_ANY�������ַ������᷵���������
  {$EXTERNALSYM WSAEMSGSIZE}
  WSAEMSGSIZE             = (WSABASEERR+40);  // ��Ϣ�������������ĺ���ܶࡣ�����һ�����ݱ��׽����Ϸ���һ����Ϣ��������Ϣ���ڲ�����������̫��Ļ����ͻ������������ٱ��磬�������籾������ƣ�ʹһ����Ϣ������Ҳ�������������������յ����ݱ�֮�󣬻�����̫С�����ܽ�����Ϣʱ��Ҳ������������
  {$EXTERNALSYM WSAEPROTOTYPE}
  WSAEPROTOTYPE           = (WSABASEERR+41);  // �׽���Э������������socket��WSASocket ������ָ����Э�鲻֧��ָ�����׽������͡����磬Ҫ����SOCK_STREAM���͵�һ��IP�׽��֣�ͬʱָ��Э��ΪIPPROTO_UDP�������������Ĵ���
  {$EXTERNALSYM WSAENOPROTOOPT}
  WSAENOPROTOOPT          = (WSABASEERR+42);  // Э��ѡ����󡣱�����getsockopt��setsockopt �����У�ָ�����׽���ѡ��򼶱�����δ��֧�ֻ�����Ч��
  {$EXTERNALSYM WSAEPROTONOSUPPORT}
  WSAEPROTONOSUPPORT      = (WSABASEERR+43);  // ��֧�ֵ�Э�顣ϵͳ��û�а�װ�����Э���û����Ӧ��ʵʩ���������磬���ϵͳ��û�а�װTCP/IP�������Ž���TCP��UDP�׽���ʱ���ͻ�����������
  {$EXTERNALSYM WSAESOCKTNOSUPPORT}
  WSAESOCKTNOSUPPORT      = (WSABASEERR+44);  // ��֧�ֵ��׽������͡���ָ���ĵ�ַ������˵��û����Ӧ�ľ����׽�������֧�֡����磬����һ����֧��ԭʼ�׽��ֵ�Э��������һ��SOCK_RAW�׽�������ʱ���ͻ�����������
  {$EXTERNALSYM WSAEOPNOTSUPP}
  WSAEOPNOTSUPP           = (WSABASEERR+45);  // ��֧�ֵĲ������������ָ���Ķ�����ͼ��ȡ�Ĳ���δ��֧�֡�ͨ�������������һ����֧�ֵ���Winsock�������׽����ϵ�����Winsockʱ���ͻ�����������
  {$EXTERNALSYM WSAEPFNOSUPPORT}
  WSAEPFNOSUPPORT         = (WSABASEERR+46);  // ��֧�ֵ�Э����塣�����Э����岻���ڣ���ϵͳ����δ��װ����������£�����������WSAEAFNOSUPPORT���������ߵȼۣ������߳��ֵø�ΪƵ����
  {$EXTERNALSYM WSAEAFNOSUPPORT}
  WSAEAFNOSUPPORT         = (WSABASEERR+47);  // ��ַ���岻֧������Ĳ��������׽������Ͳ�֧�ֵĲ�����˵��������ִ����ʱ���ͻ����������󡣱��磬������ΪSOCK_STREAM��һ���׽����ϵ���sendto��WSASendTo����ʱ���ͻ��������������⣬�ڵ���socket��WSASocket������ʱ����ͬʱ������һ����Ч�ĵ�ַ���塢�׽������ͼ�Э����ϣ�Ҳ������������
  {$EXTERNALSYM WSAEADDRINUSE}
  WSAEADDRINUSE           = (WSABASEERR+48);  // ��ַ����ʹ�á���������£�ÿ���׽���ֻ����ʹ��һ���׽��ֵ�ַ�������һ���bind��connect��WSAConnect�����������йء�����setsockopt�����������׽���ѡ��SO_REUSEA D D R ���������׽��ַ���ͬһ������I P ��ַ���˿ں�
  {$EXTERNALSYM WSAEADDRNOTAVAIL}
  WSAEADDRNOTAVAIL        = (WSABASEERR+49);  // ���ܷ�������ĵ�ַ��API������ָ���ĵ�ַ���Ǹ�������˵��Чʱ���ͻ���������Ĵ������磬����bind������ָ��һ��IP��ַ����ȴû�ж�Ӧ�ı���IP�ӿڣ������������Ĵ������⣬ͨ��connect��WSAConnect��sendto��WSASendTo��WSAJoinLeaf���ĸ�����Ϊ׼�����ӵ�Զ�̼����ָ���˿�0ʱ��Ҳ����������Ĵ���
  {$EXTERNALSYM WSAENETDOWN}
  WSAENETDOWN             = (WSABASEERR+50);  // ����Ͽ�����ͼ��ȡһ�����ʱ��ȴ�������������жϡ�����������������ջ�Ĵ�������ӿڵĹ��ϣ����߱��������������ɵġ�
  {$EXTERNALSYM WSAENETUNREACH}
  WSAENETUNREACH          = (WSABASEERR+51);  // ���粻�ɵִ��ͼ��ȡһ�����ʱ��ȴ����Ŀ�����粻�ɵִ���ɷ��ʣ�������ζ�ű���������֪����εִ�һ��Զ������������֮��Ŀǰû����֪��·�ɿɵִ��Ǹ�Ŀ��������
  {$EXTERNALSYM WSAENETRESET}
  WSAENETRESET            = (WSABASEERR+52);  // ��������ʱ�Ͽ������ӡ����ڡ����ֻ��������⵽һ����������������ӵ��жϡ�����һ���Ѿ���Ч������֮�ϣ�ͨ��setsockopt��������SO_KEEPALIVEѡ�Ҳ����������Ĵ���
  {$EXTERNALSYM WSAECONNABORTED}
  WSAECONNABORTED         = (WSABASEERR+53);  // ����������ȡ������������������һ���Ѿ����������ӱ�ȡ������������£�����ζ������������Э���ʱ�������ȡ���ġ�
  {$EXTERNALSYM WSAECONNRESET}
  WSAECONNRESET           = (WSABASEERR+54);  // ���ӱ��Է����衣һ���Ѿ����������ӱ�Զ������ǿ�йرա���Զ�������ϵĽ����쳣��ֹ���У������ڴ��ͻ��Ӳ�����ϣ�����������׽���ִ����һ��ǿ�йرգ������������Ĵ������ǿ�йرյ����������SO_LINGER�׽���ѡ���setsockopt������һ���׽���
  {$EXTERNALSYM WSAENOBUFS}
  WSAENOBUFS              = (WSABASEERR+55);  // û�л������ռ䡣����ϵͳȱ���㹻�Ļ������ռ䣬����Ĳ�������ִ�С�
  {$EXTERNALSYM WSAEISCONN}
  WSAEISCONN              = (WSABASEERR+56);  // �׽����Ѿ����ӡ�������һ���ѽ������ӵ��׽����ϣ���ͼ�ٽ���һ�����ӡ�Ҫע����ǣ����ݱ����������׽��־��п��ܳ��������Ĵ���ʹ�����ݱ��׽���ʱ������������ͨ��connect��WSAConnect���ã�Ϊ���ݱ�ͨ�Ź�����һ���˵�ĵ�ַ����ô�Ժ���ͼ�ٴε���sendto��WSASendTo�������������Ĵ���
  {$EXTERNALSYM WSAENOTCONN}
  WSAENOTCONN             = (WSABASEERR+57);  // �׽�����δ���ӡ�����һ����δ�������ӵġ��������ӡ��׽����Ϸ��������շ����󣬱����������Ĵ���
  {$EXTERNALSYM WSAESHUTDOWN}
  WSAESHUTDOWN            = (WSABASEERR+58);  // �׽��ֹرպ��ܷ��͡�������ͨ����shutdown��һ�ε��ã����ֹر����׽��֣�����������������ݵ��շ�������Ҫע����ǣ����ִ���ֻ�����Ѿ��رյ��Ǹ��������������ϲŻᷢ�����ٸ�������˵��������ݷ��ͺ�������shutdown����ô�Ժ��κ����ݷ��͵��ö�����������Ĵ���
  {$EXTERNALSYM WSAETOOMANYREFS}
  WSAETOOMANYREFS         = (WSABASEERR+59);
  {$EXTERNALSYM WSAETIMEDOUT}
  WSAETIMEDOUT            = (WSABASEERR+60);  // ���ӳ�ʱ����������һ���������󣬵������涨��ʱ�䣬Զ�̼������δ������ȷ����Ӧ�������û���κ���Ӧ������ᷢ�������Ĵ���Ҫ���յ������Ĵ���ͨ����Ҫ�����׽��������ú�SO_SNDTIMEO��SO_RCVTIMEOѡ�Ȼ�����connect��WSAConnect������
  {$EXTERNALSYM WSAECONNREFUSED}
  WSAECONNREFUSED         = (WSABASEERR+61);  // ���ӱ��ܡ����ڱ�Ŀ������ܾ��������޷���������ͨ����������Զ�̻����ϣ�û���κ�Ӧ�ó�������Ǹ���ַ֮�ϣ�Ϊ�����ṩ����
  {$EXTERNALSYM WSAELOOP}
  WSAELOOP                = (WSABASEERR+62);
  {$EXTERNALSYM WSAENAMETOOLONG}
  WSAENAMETOOLONG         = (WSABASEERR+63);
  {$EXTERNALSYM WSAEHOSTDOWN}
  WSAEHOSTDOWN            = (WSABASEERR+64); // �����رա��������ָ������Ŀ�������رգ���ɲ���ʧ�ܡ�Ȼ����Ӧ�ó����ʱ���п����յ�����һ��WSAETIMEDOUT�����ӳ�ʱ��������Ϊ�Է��ػ������ͨ��������ͼ����һ�����ӵ�ʱ�����ġ�
  {$EXTERNALSYM WSAEHOSTUNREACH}
  WSAEHOSTUNREACH         = (WSABASEERR+65); // û�е�������·�ɡ�Ӧ�ó�����ͼ����һ�����ɵִ���������ô���������WSAENETUNREACH��
  {$EXTERNALSYM WSAENOTEMPTY}
  WSAENOTEMPTY            = (WSABASEERR+66);
  {$EXTERNALSYM WSAEPROCLIM}
  WSAEPROCLIM             = (WSABASEERR+67);
  {$EXTERNALSYM WSAEUSERS}
  WSAEUSERS               = (WSABASEERR+68);
  {$EXTERNALSYM WSAEDQUOT}
  WSAEDQUOT               = (WSABASEERR+69);
  {$EXTERNALSYM WSAESTALE}
  WSAESTALE               = (WSABASEERR+70);
  {$EXTERNALSYM WSAEREMOTE}
  WSAEREMOTE              = (WSABASEERR+71);

  {$EXTERNALSYM WSAEDISCON}
  WSAEDISCON              = (WSABASEERR+101);

{ Extended Windows Sockets error constant definitions }

  {$EXTERNALSYM WSASYSNOTREADY}
  WSASYSNOTREADY          = (WSABASEERR+91);  // ������ϵͳ�����á�����WSAStartupʱ�����ṩ�߲������������������ṩ����Ļ���ϵͳ�����ã�����᷵�����ִ���
  {$EXTERNALSYM WSAVERNOTSUPPORTED}
  WSAVERNOTSUPPORTED      = (WSABASEERR+92);  // Winsock.dll�汾���󡣱�����֧�������Winsock�ṩ�߰汾��
  {$EXTERNALSYM WSANOTINITIALISED}
  WSANOTINITIALISED       = (WSABASEERR+93);  // Winsock��δ��ʼ������δ�ɹ���ɶ�WSAStartup��һ�ε��á�

{ Error return codes from gethostbyname() and gethostbyaddr()
  (when using the resolver). Note that these errors are
  retrieved via WSAGetLastError() and must therefore follow
  the rules for avoiding clashes with error numbers from
  specific implementations or language run-time systems.
  For this reason the codes are based at WSABASEERR+1001.
  Note also that [WSA]NO_ADDRESS is defined only for
  compatibility purposes. }

{ Authoritative Answer: Host not found }

  {$EXTERNALSYM WSAHOST_NOT_FOUND}
  WSAHOST_NOT_FOUND       = (WSABASEERR+1001);  // �Ҳ�������
  {$EXTERNALSYM HOST_NOT_FOUND}
  HOST_NOT_FOUND          = WSAHOST_NOT_FOUND;

{ Non-Authoritative: Host not found, or SERVERFAIL }

  {$EXTERNALSYM WSATRY_AGAIN}
  WSATRY_AGAIN            = (WSABASEERR+1002);  // �Ҳ�����������������Ʒ������м����������� IP ��ַʧ��
  {$EXTERNALSYM TRY_AGAIN}
  TRY_AGAIN               = WSATRY_AGAIN;

{ Non recoverable errors, FORMERR, REFUSED, NOTIMP }

  {$EXTERNALSYM WSANO_RECOVERY}
  WSANO_RECOVERY          = (WSABASEERR+1003);
  {$EXTERNALSYM NO_RECOVERY}
  NO_RECOVERY             = WSANO_RECOVERY;

{ Valid name, no data record of requested type }

  {$EXTERNALSYM WSANO_DATA}
  WSANO_DATA              = (WSABASEERR+1004);  // ������Ч��û����������͵����ݼ�¼�����Ʒ������� hosts �ļ���ʶ���������������� services �ļ���δָ��������
  {$EXTERNALSYM NO_DATA}
  NO_DATA                 = WSANO_DATA;

{ no address, look for MX record }

  {$EXTERNALSYM WSANO_ADDRESS}
  WSANO_ADDRESS           = WSANO_DATA;
  {$EXTERNALSYM NO_ADDRESS}
  NO_ADDRESS              = WSANO_ADDRESS;

{ Windows Sockets errors redefined as regular Berkeley error constants.
  These are commented out in Windows NT to avoid conflicts with errno.h.
  Use the WSA constants instead. }

  {$EXTERNALSYM EWOULDBLOCK}
  EWOULDBLOCK        =  WSAEWOULDBLOCK;
  {$EXTERNALSYM EINPROGRESS}
  EINPROGRESS        =  WSAEINPROGRESS;
  {$EXTERNALSYM EALREADY}
  EALREADY           =  WSAEALREADY;
  {$EXTERNALSYM ENOTSOCK}
  ENOTSOCK           =  WSAENOTSOCK;
  {$EXTERNALSYM EDESTADDRREQ}
  EDESTADDRREQ       =  WSAEDESTADDRREQ;
  {$EXTERNALSYM EMSGSIZE}
  EMSGSIZE           =  WSAEMSGSIZE;
  {$EXTERNALSYM EPROTOTYPE}
  EPROTOTYPE         =  WSAEPROTOTYPE;
  {$EXTERNALSYM ENOPROTOOPT}
  ENOPROTOOPT        =  WSAENOPROTOOPT;
  {$EXTERNALSYM EPROTONOSUPPORT}
  EPROTONOSUPPORT    =  WSAEPROTONOSUPPORT;
  {$EXTERNALSYM ESOCKTNOSUPPORT}
  ESOCKTNOSUPPORT    =  WSAESOCKTNOSUPPORT;
  {$EXTERNALSYM EOPNOTSUPP}
  EOPNOTSUPP         =  WSAEOPNOTSUPP;
  {$EXTERNALSYM EPFNOSUPPORT}
  EPFNOSUPPORT       =  WSAEPFNOSUPPORT;
  {$EXTERNALSYM EAFNOSUPPORT}
  EAFNOSUPPORT       =  WSAEAFNOSUPPORT;
  {$EXTERNALSYM EADDRINUSE}
  EADDRINUSE         =  WSAEADDRINUSE;
  {$EXTERNALSYM EADDRNOTAVAIL}
  EADDRNOTAVAIL      =  WSAEADDRNOTAVAIL;
  {$EXTERNALSYM ENETDOWN}
  ENETDOWN           =  WSAENETDOWN;
  {$EXTERNALSYM ENETUNREACH}
  ENETUNREACH        =  WSAENETUNREACH;
  {$EXTERNALSYM ENETRESET}
  ENETRESET          =  WSAENETRESET;
  {$EXTERNALSYM ECONNABORTED}
  ECONNABORTED       =  WSAECONNABORTED;
  {$EXTERNALSYM ECONNRESET}
  ECONNRESET         =  WSAECONNRESET;
  {$EXTERNALSYM ENOBUFS}
  ENOBUFS            =  WSAENOBUFS;
  {$EXTERNALSYM EISCONN}
  EISCONN            =  WSAEISCONN;
  {$EXTERNALSYM ENOTCONN}
  ENOTCONN           =  WSAENOTCONN;
  {$EXTERNALSYM ESHUTDOWN}
  ESHUTDOWN          =  WSAESHUTDOWN;
  {$EXTERNALSYM ETOOMANYREFS}
  ETOOMANYREFS       =  WSAETOOMANYREFS;
  {$EXTERNALSYM ETIMEDOUT}
  ETIMEDOUT          =  WSAETIMEDOUT;
  {$EXTERNALSYM ECONNREFUSED}
  ECONNREFUSED       =  WSAECONNREFUSED;
  {$EXTERNALSYM ELOOP}
  ELOOP              =  WSAELOOP;
  {$EXTERNALSYM ENAMETOOLONG}
  ENAMETOOLONG       =  WSAENAMETOOLONG;
  {$EXTERNALSYM EHOSTDOWN}
  EHOSTDOWN          =  WSAEHOSTDOWN;
  {$EXTERNALSYM EHOSTUNREACH}
  EHOSTUNREACH       =  WSAEHOSTUNREACH;
  {$EXTERNALSYM ENOTEMPTY}
  ENOTEMPTY          =  WSAENOTEMPTY;
  {$EXTERNALSYM EPROCLIM}
  EPROCLIM           =  WSAEPROCLIM;
  {$EXTERNALSYM EUSERS}
  EUSERS             =  WSAEUSERS;
  {$EXTERNALSYM EDQUOT}
  EDQUOT             =  WSAEDQUOT;
  {$EXTERNALSYM ESTALE}
  ESTALE             =  WSAESTALE;
  {$EXTERNALSYM EREMOTE}
  EREMOTE            =  WSAEREMOTE;

  function GetDiocpErrorMessage(const AErrCode: Integer): string;

implementation

function GetDiocpErrorMessage(const AErrCode: Integer): string;
begin
  case AErrCode of
    WSAETIMEDOUT: Result := '�����û����Ӧ�����ӳ�ʱ��';
    WSAECONNREFUSED: Result := '�޷����ӵ�����ˣ��������粢�����������ӣ�';
    WSAECONNRESET: Result := '����˹رգ�ͨѶ�жϣ�';
  else
    Result := 'HC Socketδ֪����';
  end;
end;

end.
