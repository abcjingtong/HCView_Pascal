unit UPCommon;

interface

uses
  System.Classes, System.SysUtils;

const
  { ��Ϣָ���� }
  MSG_CMD = 'm.cmd';  // ָ������
  CMD_KEEPALIVE = 1;  // ������
  CMD_CHECKVERSION = 2;  // ���汾
  CMD_UPDATEFIELS = 3;  // Ҫ�������ļ�
  CMD_DOWNLOADFILE = 4;  // ����Ҫ�������ļ�

  /// <summary> ������� </summary>
  HCUP_VERNO = 'u.no';
  HCUP_FILE = 'u.f';
  HCUP_UPDATEFILES = 'u.fs';
  HCUP_FILEPATH = 'u.ph';
  HCUP_FILEPOS = 'u.ps';
  HCUP_FILESIZE = 'u.sz';

  function BytesToStr(const Bytes: Extended): string;

implementation

const
  KB = Int64(1024);
  MB = KB * 1024;
  GB = MB * 1024;
  TB = GB * 1024;
  PB = TB * 1024;

function BytesToStr(const Bytes: Extended): string;
begin
  if (Bytes = 0) then
    Result := ''
  else
  if (Bytes < KB) then
    Result := FormatFloat('0.##B', Bytes)
  else
  if (Bytes < MB) then
    Result := FormatFloat('0.##KB', Bytes / KB)
  else
  if (Bytes < GB) then
    Result := FormatFloat('0.##MB', Bytes / MB)
  else
  if (Bytes < TB) then
    Result := FormatFloat('0.##GB', Bytes / GB)
  else
  if (Bytes < PB) then
    Result := FormatFloat('0.##TB', Bytes / TB)
  else
    Result := FormatFloat('0.##PB', Bytes / PB)
end;

end.
