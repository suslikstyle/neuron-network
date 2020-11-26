unit uLog;

interface

uses
  Classes {$IFDEF MSWINDOWS} ,
  Windows {$ENDIF},
  SysUtils,
  SyncObjs;

type
  TEncoding = (eUTF8, eANSI);
  TLogType = (LogMain, LogDB, LogVideo, LogWago);

  TLogThread = class(TThread)
  private
    Logs: TStrings;
    FFlilename: string;
    FFileMaxSize: Cardinal;
    FEncoding: TEncoding;
    LogOverRead: TOverlapped;
    procedure setFileMaxSize(const Value: Cardinal);
  protected
    procedure Execute; override;
  public
    constructor Create(FileName: string = 'events.log'; Encoding: TEncoding = eUTF8; MaxSize: Cardinal = 1000000); overload;
    destructor Destroy; override;
    procedure Add(Text: string);
  published
    procedure LogException(Text: string; logType: TLogType = LogMain);
    property MaxFileSize: Cardinal read FFileMaxSize write setFileMaxSize;
  end;


var
  csLog: TCriticalSection;

implementation


constructor TLogThread.Create(FileName: string; Encoding: TEncoding; MaxSize: Cardinal);
begin
  inherited Create(False);
  Priority:= tpLower;
  FreeOnTerminate:= False;
  If Self = nil Then Begin
    SysErrorMessage(GetLastError);
    Exit;
  End;

  if Length(FileName) = 0 then FileName:= 'events.log';
  if MaxSize < 32 then MaxSize:= 32;

  Self.FFlilename:= FileName;
  Self.FFileMaxSize:= MaxSize;
  Self.FEncoding:= Encoding;

  Logs:= TStringList.Create;
  Logs.Add(#13#9#9+'* * *');
  LogOverRead.hEvent:= CreateEvent(nil, True, True, nil);//  Self.Resume;
end;

destructor TLogThread.Destroy;
begin
  Self.Terminate;
  SetEvent(LogOverRead.hEvent);

  inherited;
end;

function ExtractOnlyFileName(const FileName: string): string;
begin
  result:= StringReplace(ExtractFileName(FileName),ExtractFileExt(FileName),'',[]);
end;

function CreateFileLog(filename : String):boolean;
var
  FSLog: TFileStream;
begin
  if not FileExists(ExtractFileDir(ParamStr(0))+'\Logs\' + filename) then begin
    try
      ForceDirectories(ExtractFileDir(ParamStr(0))+'\Logs\');
      FSLog:= TFileStream.Create(ExtractFileDir(ParamStr(0))+'\Logs\' + filename, fmCreate);
      try
      finally
        FSLog.Free;
        Result:= true;
      end;
    except
      Result:= false;
    end;
  end else begin
    Result:= true;
  end;
end;

procedure TLogThread.Execute;
var
  Buffer: PChar;
  FSLog: TFileStream;
  LogSize: int64;
  formattedDateTime : string;
  SRes: UTF8String;
begin
  LogException(Format('Запущен поток логирования. ThreadID: %d', [self.ThreadID]));
  repeat
    if CreateFileLog(FFlilename) then begin
      try
        FSLog:= TFileStream.Create(Format('%sLogs\%s', [ExtractFilePath(ParamStr(0)), FFlilename]), fmOpenWrite or fmShareDenyNone);
        try
          Repeat
            WaitForSingleObject(LogOverRead.hEvent, INFINITE);  // INFINITE
            if (Logs.Count > 0) then begin
              case Self.FEncoding of
                eUTF8: begin
                  SRes:= AnsiToUtf8(Logs[0] + #10);
                  FSLog.Seek(0, soFromEnd);
                  FSLog.Write(Pointer(SRes)^, Length(SRes));
                end;
                eANSI: begin
                  Buffer:= PChar(Logs[0] + #13#10);
                  FSLog.Seek(0, soFromEnd);
                  FSLog.Write(Buffer^, length(Buffer) * 2);
                end;
              end;
              Logs.Delete(0);
            end;

            if (Logs.Count = 0) then begin
              ResetEvent(LogOverRead.hEvent);
            end;
          until (Terminated) or (FSLog.Size > FFileMaxSize);
          LogSize:= FSLog.Size;
        finally
          FSLog.Free;
        end;
        DateTimeToString(formattedDateTime, 'yymmdd.hhnn', Now);
        if LogSize > FFileMaxSize then begin
          RenameFile( Format('%sLogs\%s', [ExtractFilePath(ParamStr(0)), FFlilename]),
                      Format('%sLogs\%s_back_%s.back', [ExtractFilePath(ParamStr(0)), ExtractOnlyFileName(FFlilename), formattedDateTime])
          );
        end;
      except
      end;
    end;
    sleep(50);
  until (Terminated);

  Logs.Free;
end;

procedure TLogThread.Add(Text: string);
var
  fDateTime: string;
begin
  try
    DateTimeToString(fDateTime, '[yyyy.mm.dd hh:nn:ss.zzz]', Now);
    Logs.Add(fDateTime+' : ' + Text);
    SetEvent(LogOverRead.hEvent);
  except
  end;
end;

procedure TLogThread.LogException(Text: string; logType: TLogType);
var
  fDateTime: string;
begin
  csLog.Enter;
  try
    DateTimeToString(fDateTime, 'yyyy.mm.dd hh:nn:ss.zzz', Now);
    if logType = LogMain then begin
      Logs.Add(Format('%s [Main]%s', [fDateTime, #9+'-> ' + text]));
    end else if (logType = LogDB) then begin
      Logs.Add(Format('%s [DB]%s', [fDateTime, #9+'-> ' + text]));
    end else if (logType = LogVideo) then begin
      Logs.Add(Format('%s [VIDEO]%s', [fDateTime, #9+'-> ' + text]));
    end else if (logType = LogWago) then begin
      Logs.Add(Format('%s [VAGO]%s', [fDateTime, #9+'-> ' + text]));
    end;
    SetEvent(LogOverRead.hEvent);
  finally
    csLog.Leave;
  end;
end;

procedure TLogThread.setFileMaxSize(const Value: Cardinal);
begin
  FFileMaxSize:= Value;
end;


initialization
  csLog:= TCriticalSection.Create;

finalization
  csLog.Free;

end.
