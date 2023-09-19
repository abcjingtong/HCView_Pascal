unit UPMsgCoder;

interface

uses
  System.Classes, diocp_coder_baseObject, utils_buffer;

type
  TUPMsgDecoder = class(TIOCPDecoder)
  public
    /// <summary> �����յ������� </summary>
    function Decode(const AInBuffer: TBufferLink; AContext: TObject): TObject; override;
  end;

  TUPMsgEncoder = class(TIOCPEncoder)
  public
    /// <summary> ����Ҫ���͵����� </summary>
    procedure Encode(ADataObject: TObject; const AOutBuffer: TBufferLink); override;
    procedure EncodeToStream(const AInStream: TMemoryStream; const AOutStream: TMemoryStream);
  end;

implementation

uses
  System.SysUtils, UPMsgPack;

{ TUPMsgDecoder }

function TUPMsgDecoder.Decode(const AInBuffer: TBufferLink;
  AContext: TObject): TObject;
var
  vDataLen: Integer;
  vPackFlag: Word;
  vVerifyValue, vActVerifyValue: Cardinal;
begin
  Result := nil;

  //��������е����ݳ��Ȳ�����ͷ���ȣ�
  vDataLen := AInBuffer.validCount;   //pack_flag + head_len + buf_len
  if (vDataLen < SizeOf(Word) + SizeOf(Integer) + SizeOf(Integer)) then Exit;

  //��¼��ȡλ��
  AInBuffer.MarkReaderIndex;
  AInBuffer.ReadBuffer(@vPackFlag, 2);

  if vPackFlag <> PACK_FLAG then
  begin
    //����İ�����
    Result := TObject(-1);
    Exit;
  end;

  AInBuffer.ReadBuffer(@vDataLen, SizeOf(vDataLen));  // ���ݳ���
  AInBuffer.ReadBuffer(@vVerifyValue, SizeOf(vVerifyValue));  // У��ֵ

  if vDataLen > 0 then
  begin
    if vDataLen > MAX_OBJECT_SIZE then  //�ļ�ͷ���ܹ���
    begin
      Result := TObject(-1);
      Exit;
    end;

    if AInBuffer.ValidCount < vDataLen then  // ����buf�Ķ�ȡλ��
    begin
      AInBuffer.restoreReaderIndex;
      Exit;
    end;

    Result := TMemoryStream.Create;
    TMemoryStream(Result).SetSize(vDataLen);
    AInBuffer.ReadBuffer(TMemoryStream(Result).Memory, vDataLen);
    TMemoryStream(Result).Position := 0;

    // У��
    vActVerifyValue := VerifyData(TMemoryStream(Result).Memory^, vDataLen);
    if vVerifyValue <> vActVerifyValue then
      raise Exception.Create(strRecvException_VerifyErr);
  end
  else
    Result := nil;
end;

{ TUPMsgEncoder }

procedure TUPMsgEncoder.Encode(ADataObject: TObject; const AOutBuffer: TBufferLink);
var
  vPackFlag: Word;
  vDataLen: Integer;
  vBuffer: TBytes;
  vVerifyValue: Cardinal;
begin
  vPackFlag := PACK_FLAG;

  TStream(ADataObject).Position := 0;

  if TStream(ADataObject).Size > MAX_OBJECT_SIZE then
    raise Exception.CreateFmt(strSendException_TooBig, [MAX_OBJECT_SIZE]);

  AOutBuffer.AddBuffer(@vPackFlag, 2);  // ��ͷ

  vDataLen := TStream(ADataObject).Size;  // ���ݴ�С
  //vDataLenSw := TByteTools.swap32(vDataLen);
  AOutBuffer.AddBuffer(@vDataLen, SizeOf(vDataLen));  // ���ݳ���

  // stream data
  SetLength(vBuffer, vDataLen);
  TStream(ADataObject).Read(vBuffer[0], vDataLen);

  // У��ֵ
  vVerifyValue := VerifyData(vBuffer[0], vDataLen);
  AOutBuffer.AddBuffer(@vVerifyValue, SizeOf(vVerifyValue));  // д��У��ֵ

  AOutBuffer.AddBuffer(@vBuffer[0], vDataLen);  // ����
end;

procedure TUPMsgEncoder.EncodeToStream(const AInStream: TMemoryStream;
  const AOutStream: TMemoryStream);
var
  vPackFlag: Word;
  vDataLen: Integer;
  vVerifyValue: Cardinal;
begin
  if AInStream.Size > MAX_OBJECT_SIZE then  // �����������
    raise Exception.CreateFmt(strSendException_TooBig, [MAX_OBJECT_SIZE]);

  vPackFlag := PACK_FLAG;
  AOutStream.Write(vPackFlag, SizeOf(vPackFlag));  // д��ͷ

  vDataLen := AInStream.Size;  // ���ݴ�С
  AOutStream.Write(vDataLen, SizeOf(vDataLen));  // д�����ݴ�С��ֵ

  // У��ֵ
  vVerifyValue := VerifyData(AInStream.Memory^, vDataLen);
  AOutStream.Write(vVerifyValue, SizeOf(vVerifyValue));  // д��У��ֵ

  AInStream.Position := 0;
  AOutStream.Write(AInStream.Memory^, AInStream.Size);  // д��ʵ������
end;

end.
