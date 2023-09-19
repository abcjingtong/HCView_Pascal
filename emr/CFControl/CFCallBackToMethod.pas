unit CFCallBackToMethod;

{*******************************************
 * brief: �ص�����ת���󷽷���ʵ��
 * autor: linzhenqun
 * date:  2006-12-18
 * email: linzhengqun@163.com
********************************************}
{
˵��������Ԫ��ʵ�ַ�����һ�ֱȽϰ�ȫ�ķ�ʽ�����в��ƻ��κμĴ�����ֵ������
      ָ��Ĵ�Сֻ��16�ֽڡ�
ʹ�ã��������Ƽ���ʹ�÷���
      1. �����б���һ��ָ���Ա P: Pointer
      2. ����Ĺ��캯���д���ָ��飺
         var
           M: TMethod;
         begin
           M.Code := @MyMethod;
           M.Data := Self;
           P := MakeInstruction(M);
         end;
      3. ������Ҫ�ص�������APIʱ��ֱ�Ӵ���P���ɣ��磺
         HHK := SetWindowsHookEx(WH_KEYBOARD, P, HInstance, 0);
      4. ����������������ͷ�ָ���
         FreeInstruction(P);
ע�⣺��Ϊ�ص������Ķ��󷽷�������StdCall���ù���
}

interface

(* �����ص�����ת���󷽷���ָ��� *)
function MakeInstruction(Method: TMethod): Pointer;
(* ����ָ��� *)
procedure FreeInstruction(P: Pointer);

implementation

uses SysUtils;

type
  {
    ָ����е������൱������Ļ����룺
    ----------------------------------
    push  [ESP]
    mov   [ESP+4], ObjectAddr
    jmp   MethodAddr
    ----------------------------------
  }
  PInstruction = ^TInstruction;
  TInstruction = packed record
    Code1: array [0..6] of byte;
    Self: Pointer;
    Code2: byte;
    Method: Pointer;
  end;

function MakeInstruction(Method: TMethod): Pointer;
const
  Code: array[0..15] of byte =
   ($FF,$34,$24,$C7,$44,$24,$04,$00,$00,$00,$00,$E9,$00,$00,$00,$00);
var
  P: PInstruction;
begin
  New(P);
  Move(Code, P^, SizeOf(Code));
  P^.Self := Method.Data;
  P^.Method := Pointer(Longint(Method.Code)-(Longint(P)+SizeOf(Code)));
  Result := P;
end;

procedure FreeInstruction(P: Pointer);
begin
  Dispose(P);
end;

end.
