unit uNetwork;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  uNeuron;

type
  TLayers = class;


  TNetwork = class
  private
    FActive: Boolean;
    layers: TLayers;
    FRecentAverageError: Double;
    FError: Double;
    class var recentAverageSmoothingFactor: Double;    // Number of training samples to average over
  public
    constructor Create(); overload; virtual;
    procedure CreateNetwork(const topology: TList<Word>);
    destructor Destroy; override;
    procedure FeedForward(const inputVals: TList<Double>);
    procedure BackPropagation(const targetVals: TList<Double>);
    procedure GetResults(var resultVals: TList<Double>);
    function GetRecentAverageError(): Double;
  published
    procedure SaveWeights(const filename: string);
    procedure LoadWeights(const filename: string);
    property Active: Boolean read FActive write FActive;
  end;



  TLayers = class(TList<TLayer>)
  private
    procedure LoadFromStream(stream: TStream);
    procedure SaveToStream(stream: TStream);
  public
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

uses uNeuronNetwork;


function Topology2Text(const topology: TList<Word>): string;
var
  i: LongWord;
begin
  Result:= '';
  for i in topology do begin
    Result:= Result + Format(' %d', [i]);
  end;
  Result:= Trim(Result);
end;


{ TNetwork }
constructor TNetwork.Create();
begin
  FActive:= False;
  FError:= 0.0;
  FRecentAverageError:= 0.0;

  Self.layers:= TLayers.Create;
end;
procedure TNetwork.CreateNetwork(const topology: TList<Word>);
var
  numLayers: Cardinal;
  layerNum: Cardinal;
  numOutputs: Cardinal;
  neuronNum: Cardinal;
begin
  numLayers:= topology.Count;

  for layerNum:= 0 to numLayers - 1 do begin
    layers.Add(TLayer.Create);
    if layerNum = topology.Count - 1 then begin
      numOutputs:= 0;
    end else begin
      numOutputs:= topology[layerNum + 1];
    end;

    for neuronNum:= 0 to topology[layerNum]-1 do
      layers.Last.Add(TNeuron.Create(numOutputs, neuronNum));
    layers.Last.Last.setOutputVal(1.0);
  end;
  Self.FActive:= True;
end;
destructor TNetwork.Destroy;
begin
  Self.layers.Free;
  inherited;
end;
procedure TNetwork.GetResults(var resultVals: TList<Double>);
var
  n: Cardinal;
begin
  if not Self.FActive then Exit;

  resultVals.clear;

  for n:= 0 to layers.Last().Count - 1 do begin     // !!!!
    resultVals.Add(layers.Last().Items[n].getOutputVal());
  end;

end;
procedure TNetwork.LoadWeights(const filename: string);
begin
  Self.layers.LoadFromFile(filename);
end;
procedure TNetwork.SaveWeights(const filename: string);
begin
  Self.layers.SaveToFile(filename);
end;
procedure TNetwork.BackPropagation(const targetVals: TList<Double>);
var
  outputLayer,  hiddenLayer, nextLayer,  alayer, prevLayer: TLayer;
  n, layerNum: Cardinal;
  delta: Double;
begin
  if not Self.FActive then Exit;

  outputLayer:= layers.Last;
  FError:= 0.0;

  for n:= 0 to outputLayer.Count - 1 do begin
    delta:= targetVals[n] - outputLayer[n].getOutputVal();
    FError:= FError + (delta * delta);
  end;
  FError:= FError / (outputLayer.Count{ - 1});
  FError:= sqrt(FError);


  FRecentAverageError:= (FRecentAverageError * recentAverageSmoothingFactor + FError) / (recentAverageSmoothingFactor + 1.0);

  for n:= 0 to outputLayer.Count - 1 do begin
    outputLayer[n].calcOutputGradients(targetVals[n]);
  end;

  for layerNum:= layers.Count - 2 downto 1 do begin
    hiddenLayer:= layers[layerNum];
    nextLayer:= layers[layerNum + 1];

    for n:= 0 to hiddenLayer.Count - 1 do begin
      hiddenLayer[n].calcHiddenGradients(nextLayer);
    end;
  end;

  for layerNum:= layers.Count - 1 downto 1 do begin
    alayer:= layers[layerNum];
    prevLayer:= layers[layerNum - 1];
    for n:= 0 to alayer.Count - 1 do begin
      alayer[n].updateInputWeights(prevLayer);
    end;
  end;
end;
procedure TNetwork.FeedForward(const inputVals: TList<Double>);
var
  i, layerNum, n: Cardinal;
  prevLayer: TLayer;
begin
  prevLayer:= nil;
  if not Self.FActive then Exit;
  if inputVals.Count = layers.Items[0].Count - 1 then Exit;

  for i:= 0 to inputVals.Count - 1 do begin
    layers[0][i].setOutputVal(inputVals.Items[i]);
  end;

  for layerNum:= 1 to layers.Count - 1 do begin
    prevLayer:= layers.Items[layerNum - 1];
    for n:= 0 to layers[layerNum].Count - 1 do begin
      layers[layerNum][n].feedForward(prevLayer);
    end;
  end;
end;
function TNetwork.GetRecentAverageError: Double;
begin
  Result:= FRecentAverageError;
end;



procedure TLayers.LoadFromStream(stream: TStream);
var
  Layer: TLayer;
  neuron: TNeuron;
  reader: TReader;
  myIndex: Cardinal;
  logStr: string;
begin
  Clear;
  logStr:= '';
  reader:= TReader.Create(stream, 1024);
  try
    reader.ReadListBegin;
    while not reader.EndOfList do begin
      reader.Position;
      Layer:= TLayer.Create;
      reader.ReadListBegin;
      logStr:= logStr + #13;
      while not reader.EndOfList do begin
        myIndex:= reader.ReadInteger;
        neuron:= TNeuron.Create(myIndex);
        reader.ReadListBegin;
        logStr:= logStr + #13;
        while not reader.EndOfList do begin
          neuron.outputWeights.Add(Connection.Create);
          neuron.outputWeights.Last.weight:= reader.ReadDouble;
          neuron.outputWeights.Last.deltaWeight:= reader.ReadDouble;
          logStr:= logStr + Format('%.3f ', [neuron.outputWeights.Last.weight]);
        end;
        reader.ReadListEnd;
        Layer.Add(neuron);
      end;
      reader.ReadListEnd;
      Add(Layer);
    end;
    reader.ReadListEnd;
  finally
    reader.Free;
  end;
  logStr:= Trim(logStr);
  log.LogException(Format('Загрузил веса: %s.', [#13+logStr+#13#13]));
end;
procedure TLayers.SaveToStream(stream: TStream);
var
  i: Integer;
  layer: TLayer;
  neuron: TNeuron;
  connect: Connection;
  writer: TWriter;
  logStr: string;
begin
  logStr:= '';
  writer:= TWriter.Create(stream, 4096);
  try
    writer.WriteListBegin;
    for layer in Self do begin
      logStr:= logStr + #13;
      writer.WriteListBegin;
      for neuron in layer do begin
        logStr:= logStr + #13;
        writer.WriteInteger(neuron.myIndex);
        writer.WriteListBegin;
        for connect in neuron.outputWeights do begin

          writer.WriteDouble(connect.weight);
          writer.WriteDouble(connect.deltaWeight);
          logStr:= logStr + Format('%.3f ', [connect.weight]);
        end;
        writer.WriteListEnd;
      end;
      writer.WriteListEnd;
    end;
    writer.WriteListEnd;
  finally
    writer.Free;
  end;
  logStr:= Trim(logStr);
  log.LogException(Format('Сохранил веса: %s.', [#13+logStr+#13#13]));
end;
procedure TLayers.LoadFromFile(const AFileName: string);
var
  stream: TStream;
begin
  stream:= TFileStream.Create(AFileName, fmOpenRead);
  try
    LoadFromStream(stream);
  finally
    stream.Free;
  end;
end;
procedure TLayers.SaveToFile(const AFileName: string);
var
  stream: TStream;
begin
  stream:= TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(stream);
  finally
    stream.Free;
  end;
end;


initialization
  TNetwork.recentAverageSmoothingFactor:= 100;

end.
