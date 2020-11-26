unit uNeuronNetwork;

interface
uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Types,
  System.StrUtils,
  uNetwork,
  uNeuron,
  uLog,
  uTraining,
  RegularExpressions;

type
  TLearningStatusEvent = procedure(Sender: TObject; const Epoch: Cardinal; const ErrorValue: Double; const setErrorVal: Double) of object;


  TTrainItem = TPair<TList<Double>, TList<Double>>;

  TNeuronNetwork = class(TThread)
  private
    FTopology: TList<Word>;
    FNetwork: TNetwork;
    trainingPass: Cardinal;
    resultVals: TList<Double>;
    FOverRead: TOverlapped;
    FError: Double;
    FEpochs: Cardinal;
    FTrainData: TList<TTrainItem>;               // ������ TTrainData ����� � ���������� � �������
    FLearnStatUpd: TLearningStatusEvent;
    procedure LoadTrainFile(fileName: string);
    procedure LineHandler(line: string);
    procedure UpdateStatus;
  protected
    procedure Execute; override;
  public
    constructor Create(const inputLayers: Cardinal; const hiddenLayers: Cardinal; const outputLayers: Cardinal); overload;
    destructor Destroy; override;
    procedure LoadFromFile(fileName: string);
    procedure SaveToFile(fileName: string);
  published
    procedure CreateNetwork;
    procedure AddHidenLayer(NeuronCount: Word);
    procedure Train(Error: Double);
    procedure TrainThread();
    function Predict(const input: TList<Double>; var svetoforValue: Word): string;
    property NetError: Double read FError write FError;     // ������ ��� �� ��������� �������� ����������� ����
    property OnLearningStatusUpdate: TLearningStatusEvent read FLearnStatUpd write FLearnStatUpd;
  end;

var
  log: TLogThread;

implementation


function FormatLine(line: string): string;
const
  clearSpace = '[ \t]+';
  elemSeparator = '\b[ ;:\-*#@!&,]+';    // ����� ��� ������ �� ';'
  groupSeparator = '[\\|\/\- ]+';        // ����� ��� ������ �� '|'
var
  RegEx: TRegEx;
  Options: TRegExOptions;
  lineIn, lineout: string;
begin
  Result:= '';
  Include(Options, roIgnoreCase);
  Include(Options, roMultiLine);

  RegEx:= TRegEx.Create(clearSpace, Options);
  line:= RegEx.Replace(line, '');

  RegEx:= TRegEx.Create(elemSeparator, Options);
  line:= RegEx.Replace(line, ';');

  RegEx:= TRegEx.Create(groupSeparator, Options);
  Result:= RegEx.Replace(line, '|');
end;
function Vector2Text(const vector: TList<Double>): string;
var
  item: Double;
begin
  result:= '';
  for item in vector do begin
    result:= result + Format('%.2f ', [item]);
  end;
  result:= Trim(result);
end;
function GetBit(const from, b: integer): boolean; inline;
begin
  result:= (from and (1 shl b))=(1 shl b);
end;
function SetBitTrue(const from, b: integer): integer; inline;
begin
  result:= from or (1 shl b);
end;
function SetBitFalse(const from, b: integer): integer; inline;
begin
  result:= from and (not (1 shl b));
end;


{ TNeuronNetwork }

constructor TNeuronNetwork.Create(const inputLayers: Cardinal; const hiddenLayers: Cardinal; const outputLayers: Cardinal); // �� ������� 3 ����: �������, ������� � ��������
begin
  inherited Create(True);
  Priority:= tpNormal;
  FreeOnTerminate:= False;
  FOverRead.hEvent:= CreateEvent(nil, True, False, nil);

  log.LogException(Format('����������� ����. ������� �����:%d, ������� �����:%d, �������� �����:%d.', [inputLayers, hiddenLayers, outputLayers]));
  FTopology:= TList<Word>.Create;
  FTopology.AddRange([inputLayers, hiddenLayers, outputLayers]);
  resultVals:= TList<Double>.Create;
  FNetwork:= TNetwork.Create();
  FTrainData:= TList<TTrainItem>.Create();

  trainingPass:= 0;
  FError:= 0.05;

  LoadTrainFile('TrainData.txt');
  Resume;
end;
procedure TNeuronNetwork.CreateNetwork;
begin
  FNetwork.CreateNetwork(Self.FTopology);
end;
destructor TNeuronNetwork.Destroy;
begin
  Terminate;
  SetEvent(FOverRead.hEvent);

  FNetwork.Free;
  FTrainData.Free;
  resultVals.Free;
  FTopology.Free;
  log.LogException('��������� ���� ����������.');
  inherited;
end;
procedure TNeuronNetwork.Execute;
begin
  log.LogException(Format('������ ������ ����. ID%d', [self.ThreadID]));
  while True do begin
    WaitForSingleObject(FOverRead.hEvent, INFINITE);     // ����������� ��������
    if Terminated then Break;

    Train(FError);
  end;
  log.LogException('����� �� ������ ����.');
end;
procedure TNeuronNetwork.LoadTrainFile(fileName: string);
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
procedure TNeuronNetwork.LoadFromFile(fileName: string);
begin
  Self.FNetwork.LoadWeights('weights.nww');
  log.LogException('���� ��������� �� �����.');
end;
procedure TNeuronNetwork.SaveToFile(fileName: string);
begin
  Self.FNetwork.SaveWeights('weights.nww');
  log.LogException('���� ��������� � ����.');
end;
function TNeuronNetwork.Predict(const input: TList<Double>; var svetoforValue: Word): string;

  function trimVal(const value: Double): Double;
  begin
    Result:= 0.0;
    if value > 0 then Result:= value;
  end;

var
  results: TList<Double>;
  item: Double;
begin
  Result:= '';
  results:= TList<Double>.Create;
  FNetwork.FeedForward(input);
  FNetwork.GetResults(results);

  for item in results do begin
    Result:= Result + Format('%.1f | ', [item]);
    svetoforValue:= svetoforValue shl 1;
    svetoforValue:= svetoforValue or (Round(trimVal(item)) and $01);
  end;
  Result:= Trim(Result);
  results.Free;
end;
procedure TNeuronNetwork.Train(Error: Double);
var
  dataItem: Cardinal;
begin
  if FTrainData.Count < 1 then begin
    log.LogException('��� ������ ��� ��������.');
    Exit;
  end;

  FError:= Error;
  FEpochs:= 1;

  log.LogException(Format('������ �������� ���� �� ����������� %.5f', [Error]));
  repeat
    for dataItem:= 0 to FTrainData.Count - 1 do begin
      Self.FNetwork.FeedForward(FTrainData[dataItem].Key);
      Self.FNetwork.GetResults(resultVals);
      Self.FNetwork.BackPropagation(FTrainData[dataItem].Value);
    end;
    if (FEpochs mod 50000) = 0 then
      log.LogException(Format('�����: %d. ������ ����: %.5f.', [FEpochs, Self.FNetwork.GetRecentAverageError]));
    if (FEpochs mod 500) = 0 then
      Synchronize(UpdateStatus);

    Inc(FEpochs);
  until Self.FNetwork.GetRecentAverageError < Error;
  ResetEvent(FOverRead.hEvent);
  log.LogException(Format('��������� �������� ����. ����������� %.5f', [Self.FNetwork.GetRecentAverageError]));

end;
procedure TNeuronNetwork.TrainThread;
begin
  if FTrainData.Count > 0 then
    SetEvent(FOverRead.hEvent);
end;
procedure TNeuronNetwork.UpdateStatus;
begin
  try
    if Assigned(FLearnStatUpd) then FLearnStatUpd(Self, FEpochs, Self.FNetwork.GetRecentAverageError, FError);
  except
  end;
end;
procedure TNeuronNetwork.LineHandler(line: string);
var
  all: TStringDynArray;
  item: string;
  e: Cardinal;
begin
  line:= Trim(line);
  if (Length(line) = 0) or (line[1] = '#') or (Pos('|', line) < 0) then Exit;
  line:= FormatLine(line);
  all:= System.StrUtils.SplitString(line, '|');
  if Length(all) <> 2 then Exit;

  FTrainData.add( TPair<TList<Double>, TList<Double>>.Create(TList<Double>.Create, TList<Double>.Create) );

  for item in System.StrUtils.SplitString(all[0], ';') do
    FTrainData.Last.Key.Add( StrToFloat(StringReplace(item,'.',',',[rfReplaceAll])) );
  for item in System.StrUtils.SplitString(all[1], ';') do
    FTrainData.Last.Value.Add(StrToFloat(StringReplace(item,'.',',',[rfReplaceAll])));

  if (FTrainData.Last.Key.Count <> FTopology.First) then
    raise Exception.Create( Format('������������� ��������� ����. ���������� ��������� � ������������ ������� �������� [%d] �� ����� ���������� ������� �������� � ������������� ����� [%d]',[FTopology.First, FTrainData.Last.Key.Count]) );
  if (FTrainData.Last.Value.Count <> FTopology.Last) then
    raise Exception.Create( Format('������������� ��������� ����. ���������� ��������� � ������������ �������� �������� [%d] �� ����� ���������� �������� �������� � ������������� ����� [%d]',[FTopology.Last, FTrainData.Last.Value.Count]) );

  log.LogException(Format('��������� �������: %s � �������� %s ������. ���������� ������: %d' , [Vector2Text(FTrainData.Last.Key), Vector2Text(FTrainData.Last.Value), FTrainData.Count]));
end;
procedure TNeuronNetwork.AddHidenLayer(NeuronCount: Word);
begin
  FTopology.Insert(FTopology.Count - 2, NeuronCount);
end;



initialization
  log:= TLogThread.Create();

finalization
  log.Free;

end.
