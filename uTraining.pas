unit uTraining;

interface
uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.StrUtils,
  System.Types;


type
  TTrainingSet = class
  private
    FInputCount: Cardinal;
    FOutputCount: Cardinal;
    procedure LineHandler( line: string );
  public
    constructor Create(const inputLayer: Cardinal; const outputLayer: Cardinal);
    destructor Destroy; override;
  published
    procedure LoadFile(fileName: string);
  end;


implementation

uses uNeuronNetwork;


{ TTrainingSet }

procedure LogVector(const alabel: string; const vector: TList<Double>);
var
  logStr: string;
  item: Double;
begin
  logStr:= alabel + ' ';
  for item in vector do begin
    logStr:= logStr + Format('%.2f ', [item]);
  end;
  logStr:= Trim(logStr);
end;


constructor TTrainingSet.Create(const inputLayer: Cardinal; const outputLayer: Cardinal);
begin
  FInputCount:= inputLayer;
  FOutputCount:= outputLayer;
  LoadFile('1.txt');
end;

destructor TTrainingSet.Destroy;
begin

  inherited;
end;

procedure TTrainingSet.LineHandler(line: string);
var
  all, aIn, aOut: TStringDynArray;
  item: string;
  in_val, out_val: TList<Double>;

  e: Cardinal;
begin
  line:= Trim(line);
  if (Length(line) = 0) or (line[1] = '#') or (Pos('|', line) < 0) then Exit;
  line:= StringReplace(line, ';', ';', [rfReplaceAll]);
  line:= StringReplace(line, ',', ';', [rfReplaceAll]);
  line:= StringReplace(line, #9, ';', [rfReplaceAll]);
  line:= StringReplace(line, ' ', ';', [rfReplaceAll]);
  line:= StringReplace(line, ';;', ';', [rfReplaceAll]);
  all:= System.StrUtils.SplitString(line, '|');
  if Length(all) <> 2 then Exit;
  aIn:= System.StrUtils.SplitString(all[0], ';');
  aOut:= System.StrUtils.SplitString(all[1], ';');

  in_val:= TList<Double>.Create;
  out_val:= TList<Double>.Create;

  for item in aIn do
    in_val.Add(item.ToDouble);
  for item in aOut do
    out_val.Add(item.ToDouble);

  for e:= 0 to 100 do begin
    if in_val.Count <> Self.FInputCount then break;

  end;


  in_val.Free;
  out_val.Free;
//  log.LogException(line);
end;

procedure TTrainingSet.LoadFile(fileName: string);
var
  f: TextFile;
  buf: string;
begin
  AssignFile(f, fileName);
	{$i-}
  try
		Reset(f);
    while not EOF(f) do begin
      readln(f, buf);
      LineHandler(buf);
    end;
  finally
    CloseFile(f) ;
  end;
end;

end.
