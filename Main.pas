unit Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  uNeuronNetwork,
  System.Generics.Collections,
  System.StrUtils,
  Vcl.ExtCtrls;

type
  TfMain = class(TForm)
    btnTrain: TButton;
    lblResult: TLabel;
    edt1: TEdit;
    edt2: TEdit;
    edt3: TEdit;
    edt4: TEdit;
    btnSave: TButton;
    btnLoad: TButton;
    edt5: TEdit;
    chkWeight: TCheckBox;
    chkAddedStat: TCheckBox;
    chkInSensor: TCheckBox;
    chkOutSensor: TCheckBox;
    chkPosEnabled: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CheckChangeHandler(Sender: TObject);
    procedure btnTrainClick(Sender: TObject);
    procedure edtKeyPress(Sender: TObject; var Key: Char);
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
  private
    FNet: TNeuronNetwork;
    procedure learnStatUpd(Sender: TObject; const Epoch: Cardinal; const ErrorValue: Double; const setErrorVal: Double);
    procedure EdtChangeHandler();
  public
    { Public declarations }
  end;


var
  fMain: TfMain;


implementation

{$R *.dfm}

function bool2float(const value: Boolean): Double;
begin
  Result:= 0.0;
  if value then Result:= 1.0;
end;


procedure TfMain.btnTrainClick(Sender: TObject);
begin
//  Self.FNet.Train(0.0002);
  Self.FNet.NetError:= 0.0002;
  Self.FNet.TrainThread;
end;
procedure TfMain.btnLoadClick(Sender: TObject);
begin
  if not FileExists('weights.nww') then begin
    Application.MessageBox('Загрузка отменена. Отсутствует файл весов. Попробуйте обучить сеть заного.',
                          'Ошибка', MB_OK or MB_ICONERROR);
    Exit;
  end;
  try
    Self.FNet.LoadFromFile('weights.nww');
    Application.MessageBox('Загрузка завершена.','Успешно', MB_OK or MB_ICONINFORMATION);
  except
  end;
end;

procedure TfMain.btnSaveClick(Sender: TObject);
const
  WEIGHTS_FILENAME = 'weights.nww';
var
  s: string;
begin
  Self.FNet.SaveToFile(WEIGHTS_FILENAME);
  s:= Format('Сохранил веса в файл: %s.', [WEIGHTS_FILENAME]);
  Application.MessageBox(PChar(s), 'Успешно', MB_OK or MB_ICONINFORMATION);
end;
procedure TfMain.CheckChangeHandler(Sender: TObject);
var
  vals: TList<Double>;
  svetofor_value: Word;
begin
  vals:= TList<Double>.Create;
  svetofor_value:= 0;
  try
    vals.Add( bool2float(chkWeight.Checked) );
    vals.Add( bool2float(chkAddedStat.Checked) );
    vals.Add( bool2float(chkInSensor.Checked) );
    vals.Add( bool2float(chkOutSensor.Checked) );
    vals.Add( bool2float(chkPosEnabled.Checked) );

    edt1.Text:= FormatFloat('0.0', bool2float(chkWeight.Checked));
    edt2.Text:= FormatFloat('0.0', bool2float(chkAddedStat.Checked));
    edt3.Text:= FormatFloat('0.0', bool2float(chkInSensor.Checked));
    edt4.Text:= FormatFloat('0.0', bool2float(chkOutSensor.Checked));
    edt5.Text:= FormatFloat('0.0', bool2float(chkPosEnabled.Checked));
    lblResult.Caption:= Format('Результат: %s.', [FNet.Predict(vals, svetofor_value)]);
  finally
    vals.Free;
  end;

end;
procedure TfMain.EdtChangeHandler;
var
  vals: TList<Double>;
  svetofor_value: Word;
begin
  vals:= TList<Double>.Create;
  svetofor_value:= 0;
  try
    vals.Add( StrToFloat(AnsiReplaceStr( Trim(edt1.Text), '.', ',' )) );
    vals.Add( StrToFloat(AnsiReplaceStr( Trim(edt2.Text), '.', ',' )) );
    vals.Add( StrToFloat(AnsiReplaceStr( Trim(edt3.Text), '.', ',' )) );
    vals.Add( StrToFloat(AnsiReplaceStr( Trim(edt4.Text), '.', ',' )) );
    vals.Add( StrToFloat(AnsiReplaceStr( Trim(edt5.Text), '.', ',' )) );
    lblResult.Caption:= Format('Результат: %s.', [FNet.Predict(vals, svetofor_value)]);
  finally
    vals.Free;
  end;
end;
procedure TfMain.edtKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then EdtChangeHandler();
end;
procedure TfMain.FormCreate(Sender: TObject);
begin
  Self.FNet:= TNeuronNetwork.Create(5, 7, 4);
  Self.FNet.AddHidenLayer(6);
  Self.FNet.CreateNetwork;
  Self.FNet.OnLearningStatusUpdate:= learnStatUpd;


end;
procedure TfMain.FormDestroy(Sender: TObject);
begin
  Self.FNet.Free;
end;

procedure TfMain.learnStatUpd(Sender: TObject; const Epoch: Cardinal;
  const ErrorValue: Double; const setErrorVal: Double);
begin
  lblResult.Caption:= Format('Обучение... [NetError value: %.5f -> %.5f] [epoch: %d].', [ErrorValue, setErrorVal, Epoch]);
end;



end.
