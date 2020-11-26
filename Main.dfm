object fMain: TfMain
  Left = 0
  Top = 0
  Caption = 'fMain'
  ClientHeight = 167
  ClientWidth = 193
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblResult: TLabel
    Left = 8
    Top = 140
    Width = 68
    Height = 13
    Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090': #'
  end
  object btnTrain: TButton
    Left = 8
    Top = 8
    Width = 49
    Height = 25
    Caption = 'Train'
    TabOrder = 0
    OnClick = btnTrainClick
  end
  object edt1: TEdit
    Left = 139
    Top = 37
    Width = 33
    Height = 17
    TabOrder = 1
    Text = '0'
    OnKeyPress = edtKeyPress
  end
  object edt2: TEdit
    Left = 139
    Top = 54
    Width = 33
    Height = 17
    TabOrder = 2
    Text = '0'
    OnKeyPress = edtKeyPress
  end
  object edt3: TEdit
    Left = 139
    Top = 71
    Width = 33
    Height = 17
    TabOrder = 3
    Text = '0'
    OnKeyPress = edtKeyPress
  end
  object edt4: TEdit
    Left = 139
    Top = 88
    Width = 33
    Height = 18
    TabOrder = 4
    Text = '0'
    OnKeyPress = edtKeyPress
  end
  object btnSave: TButton
    Left = 95
    Top = 8
    Width = 38
    Height = 25
    Caption = 'Save'
    TabOrder = 5
    OnClick = btnSaveClick
  end
  object btnLoad: TButton
    Left = 139
    Top = 8
    Width = 48
    Height = 25
    Caption = 'Load'
    TabOrder = 6
    OnClick = btnLoadClick
  end
  object edt5: TEdit
    Left = 139
    Top = 105
    Width = 33
    Height = 17
    TabOrder = 7
    Text = '0'
    OnKeyPress = edtKeyPress
  end
  object chkWeight: TCheckBox
    Left = 8
    Top = 39
    Width = 121
    Height = 17
    Caption = 'inputValue1'
    TabOrder = 8
    OnClick = CheckChangeHandler
  end
  object chkAddedStat: TCheckBox
    Left = 8
    Top = 54
    Width = 121
    Height = 21
    Caption = 'inputValue2'
    TabOrder = 9
    OnClick = CheckChangeHandler
  end
  object chkInSensor: TCheckBox
    Left = 8
    Top = 71
    Width = 121
    Height = 21
    Caption = 'inputValue3'
    TabOrder = 10
    OnClick = CheckChangeHandler
  end
  object chkOutSensor: TCheckBox
    Left = 8
    Top = 88
    Width = 125
    Height = 21
    Caption = 'inputValue4'
    TabOrder = 11
    OnClick = CheckChangeHandler
  end
  object chkPosEnabled: TCheckBox
    Left = 8
    Top = 105
    Width = 125
    Height = 21
    Caption = 'inputValue5'
    TabOrder = 12
    OnClick = CheckChangeHandler
  end
end
