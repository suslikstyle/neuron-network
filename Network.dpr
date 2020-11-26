program Network;



uses
  Vcl.Forms,
  Main in 'Main.pas' {fMain},
  uLog in 'uLog.pas',
  uNetwork in 'uNetwork.pas',
  uNeuron in 'uNeuron.pas',
  uNeuronNetwork in 'uNeuronNetwork.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
