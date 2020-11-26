unit uNeuron;

interface
uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Math;

type
  Connection = class(TObject)
  public
    weight: double;
    deltaWeight: double;
  end;
  TWeights = TObjectList<Connection>;

  TNeuron = class;
  TLayer = TObjectList<TNeuron>;

  TNeuron = class
  private
    outputVal: Double;
    FOutPutsCount: Cardinal;
    m_myIndex: Cardinal;
    gradient:Double;

    class var eta: Double;
    class var alpha: Double;
    class function randomWeight: Double;
    class function activationFunction(x: Double): Double;
    class function activationFunctionDerivative(x: Double): Double;
    function sumDOW( const nextLayer: TLayer ): Double;
  public
    outputWeights: TWeights;
    constructor Create(const numOutputs: Cardinal; const myIndex: Cardinal); overload;
    constructor Create(const myIndex: Cardinal); overload;
    destructor Destroy; override;
    procedure SetOutputVal(const value: Double);
    function GetOutputVal(): Double;
    procedure feedForward(const prevLayer: TLayer);
    procedure calcOutputGradients(targetVals: Double);
    procedure calcHiddenGradients( const nextLayer: TLayer );
    procedure updateInputWeights( const prevLayer: TLayer );
  published
    property myIndex: Cardinal read m_myIndex;
  end;


implementation

{ TNeuron }
constructor TNeuron.Create(const numOutputs: Cardinal; const myIndex: Cardinal);
var
  c: Cardinal;
begin
  Self.outputWeights:= TWeights.Create;

  for c:= 0 to numOutputs do begin
    Self.outputWeights.Add(Connection.Create);
    Self.outputWeights.Last.weight:= randomWeight;
  end;
  Self.m_myIndex:= myIndex;
end;

constructor TNeuron.Create(const myIndex: Cardinal);
begin
  Self.outputWeights:= TWeights.Create;
  Self.m_myIndex:= myIndex;
end;

destructor TNeuron.Destroy;
begin
  Self.outputWeights.Free;
  inherited;
end;

procedure TNeuron.updateInputWeights( const prevLayer: TLayer );
var
  n: Cardinal;
  nr: TNeuron;
  oldDeltaWeight, newDeltaWeight: Double;
begin
  for n:= 0 to prevLayer.Count - 1 do begin
    nr:= prevLayer[n];
    oldDeltaWeight:= nr.outputWeights[m_myIndex].deltaWeight;
    newDeltaWeight:= eta * nr.getOutputVal() * gradient + alpha * oldDeltaWeight;
    nr.outputWeights[m_myIndex].deltaWeight:= newDeltaWeight;
		nr.outputWeights[m_myIndex].weight:= nr.outputWeights[m_myIndex].weight + newDeltaWeight;
  end;
end;

function TNeuron.sumDOW(const nextLayer: TLayer): Double;     // !!!!
var
  n: Cardinal;
begin
  Result:= 0.0;
  for n:= 0 to nextLayer.Count - 1 do begin         // !!!!
    Result:= Result + outputWeights[n].weight * nextLayer[n].gradient;
  end;
end;

procedure TNeuron.calcHiddenGradients( const nextLayer: TLayer );
var
  dow: Double;
begin
  dow:= sumDOW(nextLayer);
  gradient:= dow * activationFunctionDerivative(outputVal);
end;

procedure TNeuron.calcOutputGradients(targetVals: Double);
var
  delta: Double;
begin
  delta:= targetVals - outputVal;
  gradient:= delta * activationFunctionDerivative(outputVal);
end;

class function TNeuron.activationFunction(x: Double): Double;
begin
  Result:= Math.Tanh(x);
end;

class function TNeuron.activationFunctionDerivative(x: Double): Double;
begin
  Result:= 1.0 - x * x;
end;

procedure TNeuron.feedForward(const prevLayer: TLayer);
var
  sum: Double;
  n: Cardinal;
begin
  sum:= 0;
  for n:= 0 to prevLayer.Count - 1 do begin
    sum:= sum + prevLayer[n].getOutputVal() *	prevLayer[n].outputWeights[m_myIndex].weight;
  end;
  outputVal:= activationFunction(sum);
end;

function TNeuron.GetOutputVal: Double;
begin
  Result:= outputVal;
end;

class function TNeuron.randomWeight: Double;
begin
  Result:= Random(1000)/1000;
end;

procedure TNeuron.SetOutputVal(const value: Double);
begin
  outputVal:= value;
end;








initialization
  TNeuron.eta:= 0.15;         // net learning rate
  TNeuron.alpha:= 0.5;        // momentum

end.
