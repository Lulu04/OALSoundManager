{
   Velocity Curve - written by lulu - 2017

  ****************************************************************************
  *                                                                          *
  *  This file is part of OpenALSoundManager library which is distributed    *
  *  under the modified LGPL.                                                *
  *                                                                          *
  *  See the file COPYING.modifiedLGPL.txt, included in this distribution,   *
  *  for details about the copyright.                                        *
  *                                                                          *
  *  This program is distributed in the hope that it will be useful,         *
  *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
  *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    *
  *                                                                          *
  ****************************************************************************

  written by Lulu - 2017

}
unit VelocityCurve;

{$mode objfpc}{$H+}


interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Types;

const
  // available predefined curves IDentificator
  idcLinear = 0;
  idcStartFastEndSlow = 1;
  idcStartSlowEndFast = 2;
  idcSinusoid = 3;
  idcSinusoid2 = 4;
  idc5Steps = 5;

function CurveIDToString(ACurveID: word): string;
function StringToCurveID(ACurveName: string): word;

type

  TCustomParam = class;

  PPointF = ^TPointF;
 {$if FPC_FULLVERSION>=030001}
  TPointF = Types.TPointF;
 {$else}
  TPointF = packed record
    x, y: single;
  end;
 {$endif}

  { TDataCurve }

  TDataCurve = class
  protected
    FID: word;
    FName: string;
    function GetPointCount: integer;
    procedure CreateExtremities;
  public
    Points: array of TPointF;
    constructor Create;
    destructor Destroy; override;
    // tools for curve construct
    procedure Clear(aCreateExtremities: boolean = True);

    procedure DeletePoint(aIndex: integer);
    procedure CopyPointsFrom(const aSource: array of TPointf);
    function ValidIndex(aIndex: integer): boolean;
    // Render curve on given TImage. You have to free it yourself
    procedure DrawOn(aImage: TImage);
    property Name: string read FName write FName;
    property ID: word read FID;
    property PointCount: integer read GetPointCount;
  end;

  { TVelocityCurve }
  TVelocityCurve = class
  private
    FDataCurveToUse: TDataCurve;
    FFinished, FInvert: boolean;
    FX, FDuration, FYOrigin, FYTarget, FDeltaY: single;
    FCurrentIndexPoint1: integer;
    a, x1, y1, x2, y2: single;
    procedure GetSegmentCoor;
  public
    constructor Create;
    // initiate calculation
    procedure InitParameters(aCurrentValue, aTargetValue, aSeconds: single;
      aCurveID: word = idcLinear);
    // Computes and return the new value according to elapsed time
    function Compute(const AElapsedSec: single): single;
    property Finished: boolean read FFinished write FFinished;
  end;



  { TDataCurveList }
  TDataCurveList = class
  private
    FList: TList;
    FNumID: integer;
    function GetDataCurveCount: integer;
    function NextID: integer;
  protected
    procedure Clear;
    procedure DeleteByIndex(aIndex: integer);
    procedure DeleteByID(aIDCurve: word);
    procedure DeleteByName(ACurveName: string);
  public
    constructor Create;
    destructor Destroy; override;
    // Add new curve to the list. Return the ID of the created curve
    function AddCurve(const aName: string; const Pts: array of TPointF): word;
    function GetCurveByID(aID: word): TDataCurve;
    function GetCurveByIndex(aIndex: integer): TDataCurve;
    function CurveNameAlreadyExist(const aCurveName: string): boolean;
    property Count: integer read GetDataCurveCount;
  end;


type

  TParamState = (psNO_CHANGE, psADD_CONSTANT, psUSE_CURVE);

  TCustomParam = class
    procedure OnElapse(const AElapsedSec: single); virtual; abstract;
  end;


  TFParam = class(TCustomParam)
  private
    FValue, FConstPerSecond: single;
    FState: TParamState;
    FCurve: TVelocityCurve;
  protected
    function GetValue: single; virtual;
    procedure SetValue(AValue: single); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure OnElapse(const AElapsedSec: single); override;

    // use velocity curve
    procedure ChangeTo(aNewValue, aSecond: single; aCurveID: word = idcLinear); virtual;
    // add a constant per second
    procedure AddConstant(aConstPerSecond: single);
    // Current value of the parameter. Setting a value, stop an "ChangeTo" or "AddConstant" action.
    property Value: single read GetValue write SetValue;
    property State: TParamState read FState;
  end;

type
  { TBoundedFParam }
  // parameter with boundary

  TBoundedFParam = class(TFParam)
  private
    function GetpcValue: single;
    procedure SetpcValue(AValue: single);
    procedure ClampPercent( var AValue: single );
  protected
    function GetValue: single; override;
    procedure SetValue(AValue: single); override;
    procedure ApplyBounds(var AValue: single);
  public
    MinValue, MaxValue: single;
    Loop: boolean;
    // if Loop is set to TRUE, value can loop between bounds (usefull for i.e. [0..360] angle)
    // if it's set to FALSE, value is clamped to MinValue and MaxValue.
    procedure SetBoundary(aMin, aMax: single; aLoop: boolean = False);
    procedure OnElapse(const AElapsedSec: single); override;
    // percentage range is [0..1], 0 is MinValue and 1 is MaxValue (see SetBoundary)
    function PercentToValue(aPercentage: single): single;
    function ValueToPercent(aValue: single): single;
    function pcRandomValueBetween(PercentageMin, PercentageMax: single): single;
    procedure pcChangeTo(aNewPercentValue, aSecond: single; aCurveID: word = idcLinear);
    property pcValue: single read GetpcValue write SetpcValue;
  end;

function CreateBoundedFParam(Min, Max: single; Loop: boolean = False): TBoundedFParam;


type
  { TPointFParam }

  TPointFParam = class(TCustomParam)
  private

    function GetPointF: TPointF;
    function GetState: TParamState;
    procedure SetPointF(AValue: TPointF);
  public
    x, y: TFParam;
    constructor Create;
    destructor Destroy; override;
    procedure OnElapse(const AElapsedSec: single); override;
    procedure ChangeTo(aNewValue: TPointF; aSeconds: single; aCurveID: word = idcLinear);
    property Value: TPointF read GetPointF write SetPointF;
    property State: TParamState read GetState;
  end;


var
  VelocityCurveList: TDataCurveList;

implementation

function PointF(x, y: single): TPointF;
begin
  Result.x := x;
  Result.y := y;
end;

function CurveIDToString(ACurveID: word): string;
begin
  case ACurveID of
    idcStartFastEndSlow: Result := 'StartFastEndSlow';
    idcStartSlowEndFast: Result := 'StartSlowEndFast';
    idcSinusoid: Result := 'Sinusoid';
    idcSinusoid2: Result := 'Sinusoid2';
    idc5steps: Result := '5Steps'
    else
      Result := 'Linear';
  end;
end;

function StringToCurveID(ACurveName: string): word;
begin
  case LowerCase(ACurveName) of
    'startfastendslow': Result := idcStartFastEndSlow;
    'startslowendfast': Result := idcStartSlowEndFast;
    'sinusoid': Result := idcSinusoid;
    'sinusoid2': Result := idcSinusoid2;
    '5steps': Result := idc5steps
    else
      Result := idcLinear;
  end;
end;

function CreateBoundedFParam(Min, Max: single; Loop: boolean): TBoundedFParam;
begin
  Result := TBoundedFParam.Create;
  Result.SetBoundary(Min, Max);
  Result.Loop := Loop;
end;


{ TPointFParam }

function TPointFParam.GetPointF: TPointF;
begin
  Result.x := x.Value;
  Result.y := y.Value;
end;

function TPointFParam.GetState: TParamState;
begin
  if (x.State = psNO_CHANGE) and (y.State = psNO_CHANGE) then
    Result := psNO_CHANGE
  else if (x.State = psADD_CONSTANT) and (y.State = psADD_CONSTANT) then
    Result := psADD_CONSTANT
  else
    Result := psUSE_CURVE;
end;

procedure TPointFParam.SetPointF(AValue: TPointF);
begin
  x.Value := AValue.x;
  y.Value := AValue.y;
end;

constructor TPointFParam.Create;
begin
  x := TFParam.Create;
  y := TFParam.Create;
end;

destructor TPointFParam.Destroy;
begin
  FreeAndNil(x);
  FreeAndNil(y);
  inherited Destroy;
end;

procedure TPointFParam.OnElapse(const AElapsedSec: single);
begin
  x.OnElapse(AElapsedSec);
  y.OnElapse(AElapsedSec);
end;

procedure TPointFParam.ChangeTo(aNewValue: TPointF; aSeconds: single; aCurveID: word);
begin
  x.ChangeTo(aNewValue.x, aSeconds, aCurveID);
  y.ChangeTo(aNewValue.y, aSeconds, aCurveID);
end;

{ TDataCurve }

function TDataCurve.GetPointCount: integer;
begin
  Result := Length(Points);
end;

procedure TDataCurve.CreateExtremities;
begin
  SetLength(Points, 2);
  Points[0] := PointF(0, 1);
  Points[1] := PointF(1, 0);
end;

constructor TDataCurve.Create;
begin
  inherited Create;
  CreateExtremities;
end;

destructor TDataCurve.Destroy;
begin
  Clear(False);
  inherited Destroy;
end;

procedure TDataCurve.Clear(aCreateExtremities: boolean);
begin
  SetLength(Points, 0);
  if aCreateExtremities then
    CreateExtremities;
end;

procedure TDataCurve.DeletePoint(aIndex: integer);
var
  i: integer;
begin
  if (aIndex < 1) or (aIndex > Length(Points) - 2) then
    exit;
  for i := GetPointCount - 1 downto aIndex do
    Points[i - 1] := Points[i];
  SetLength(Points, Length(Points) - 1);
end;

procedure TDataCurve.CopyPointsFrom(const aSource: array of TPointf);
var
  i: integer;
begin
  Clear(False);
  SetLength(Points, Length(aSource));
  for i := 0 to Length(aSource) - 1 do
    Points[i] := aSource[i];
end;

function TDataCurve.ValidIndex(aIndex: integer): boolean;
begin
  Result := (aIndex >= 0) and (aIndex < GetPointCount);
end;

procedure TDataCurve.DrawOn(aImage: TImage);
var
  x1, y1, x2, y2, i: integer;
  cline, clineinvert: TColor;
begin
  with aImage.Canvas do
  begin
    // background
    Brush.Color := rgbToColor(50, 20, 20);
    FillRect(0, 0, Width, Height);
    cline := rgbToColor(255, 140, 0);
    clineinvert := rgbToColor(20, 80, 100);
    // inverted curve
    Pen.Color := clineinvert;
    for i := 1 to GetPointCount - 1 do
    begin
      with Points[i - 1] do
      begin
        x1 := System.round(x * Width);
        y1 := System.round(Height - y * Height);
      end;
      with Points[i] do
      begin
        x2 := System.round(x * Width);
        y2 := System.round(Height - y * Height);
      end;
      Line(x1, y1, x2, y2);
    end;
    // axis
    Pen.Color := rgbToColor(150, 100, 100);
    Line(0, Height - 1, Width, Height - 1);
    Line(0, Height - 2, Width, Height - 2);
    Line(0, 0, 0, Height);
    Line(1, 0, 1, Height);
    // normal curve
    Pen.Color := cline;
    for i := 1 to GetPointCount - 1 do
    begin
      with Points[i - 1] do
      begin
        x1 := System.round(x * Width);
        y1 := System.round(y * Height);
      end;
      with Points[i] do
      begin
        x2 := System.round(x * Width);
        y2 := System.round(y * Height);
      end;
      Line(x1, y1, x2, y2);
    end;
  end;
end;

{ TBoundedFParam }

function TBoundedFParam.GetpcValue: single;
begin
  Result := ValueToPercent(FValue);
end;

procedure TBoundedFParam.SetpcValue(AValue: single);
var
  v: single;
begin
  v := PercentToValue(AValue);
  SetValue(v);
end;

procedure TBoundedFParam.ClampPercent(var AValue: single);
begin
 if AValue < 0.0
   then AValue := 0.0
   else if AValue > 1.0
          then Avalue := 1.0;
end;

function TBoundedFParam.GetValue: single;
begin
 Result := FValue;
 ApplyBounds( Result );
end;

procedure TBoundedFParam.SetValue(AValue: single);
begin
  ApplyBounds(AValue);
  inherited SetValue(AValue);
end;

procedure TBoundedFParam.ApplyBounds(var AValue: single);
var
  delta: single;
begin
  if Loop then
  begin  // loop mode
    delta := MaxValue - MinValue;
    while AValue < MinValue do AValue += delta;
    while AValue > MaxValue do AValue -= delta;
  end
  else
  begin  // clamp mode
    if AValue < MinValue then
      AValue := MinValue
    else if AValue > MaxValue then
      AValue := MaxValue;
  end;
end;

procedure TBoundedFParam.SetBoundary(aMin, aMax: single; aLoop: boolean);
begin
  if aMin > aMax then
  begin
    MinValue := aMax;
    MaxValue := aMin;
  end
  else
  begin
    MinValue := aMin;
    MaxValue := aMax;
  end;

  Loop := aLoop;
end;

function TBoundedFParam.PercentToValue(aPercentage: single): single;
begin
  ClampPercent( aPercentage );
  Result := ( MaxValue - MinValue ) * aPercentage + MinValue;
end;

function TBoundedFParam.ValueToPercent(aValue: single): single;
begin
  Result := (aValue - MinValue) / (MaxValue - MinValue);
end;

function TBoundedFParam.pcRandomValueBetween(PercentageMin, PercentageMax:
  single): single;
var
  p: single;
begin
  ClampPercent( PercentageMin );
  ClampPercent( PercentageMax );

  if PercentageMin > PercentageMax then
  begin
    p := PercentageMax;
    PercentageMax := PercentageMin;
    PercentageMin := p;
  end;

  p := random(round((PercentageMax - PercentageMin) * 1000000.0)) *
    0.0000001 + PercentageMin;
  Result := PercentToValue(p);
end;

procedure TBoundedFParam.pcChangeTo(aNewPercentValue, aSecond: single; aCurveID: word);
var
  v: single;
begin
  ClampPercent( aNewPercentValue );
  v := PercentToValue(aNewPercentValue);
  ChangeTo(v, aSecond, aCurveID);
end;

procedure TBoundedFParam.OnElapse(const AElapsedSec: single);
begin
  case FState of
    psADD_CONSTANT:
    begin
      FValue += FConstPerSecond * AElapsedSec;
      if not Loop then
      begin
        if FValue <= MinValue then
        begin
          FValue := MinValue;
          FState := psNO_CHANGE;
        end
        else if FValue >= MaxValue then
        begin
          FValue := MaxValue;
          FState := psNO_CHANGE;
        end;
      end;
    end;

    psUSE_CURVE:
    begin
      FValue := FCurve.Compute(AElapsedSec);
      if FCurve.Finished then
        FState := psNO_CHANGE;
    end;
  end;
end;


{ TFParam }


function TFParam.GetValue: single;
begin
  Result := FValue;
end;

procedure TFParam.SetValue(AValue: single);
begin
  FValue := AValue;
  FState := psNO_CHANGE;
end;

constructor TFParam.Create;
begin
  FState := psNO_CHANGE;
  FValue := 0.0;
  FConstPerSecond := 0.0;
  FCurve := TVelocityCurve.Create;
end;

destructor TFParam.Destroy;
begin
  FreeAndNil(FCurve);
  inherited Destroy;
end;

procedure TFParam.ChangeTo(aNewValue, aSecond: single; aCurveID: word);
begin
  if aSecond <= 0 then
  begin
    SetValue(aNewValue);
    exit;
  end;

  if aNewValue <> FValue then
  begin
    FState := psUSE_CURVE;
    FCurve.InitParameters(FValue, aNewValue, aSecond, aCurveID);
  end
  else
    FState := psNO_CHANGE;
end;

procedure TFParam.AddConstant(aConstPerSecond: single);
begin
  if aConstPerSecond <> 0 then
  begin
    FState := psADD_CONSTANT;
    FConstPerSecond := aConstPerSecond;
  end
  else
    FState := psNO_CHANGE;
end;

procedure TFParam.OnElapse(const AElapsedSec: single);
begin
  case FState of
    psADD_CONSTANT: FValue += FConstPerSecond * AElapsedSec;
    psUSE_CURVE:
    begin
      FValue := FCurve.Compute(AElapsedSec);
      if FCurve.FFinished then
        FState := psNO_CHANGE;
    end;
  end;
end;

{ TVelocityCurve }

constructor TVelocityCurve.Create;
begin
  inherited Create;
  FFinished := True;
  FInvert := False;
end;

procedure TVelocityCurve.GetSegmentCoor;
var
  fp, fp1: TPointF;
begin
  fp := FDataCurveToUse.Points[FCurrentIndexPoint1];
  fp1 := FDataCurveToUse.Points[FCurrentIndexPoint1 + 1];
  x1 := fp.x;
  x2 := fp1.x;

  if FInvert then
  begin
    y1 := fp.y;
    y2 := fp1.y;
  end
  else
  begin
    y1 := 1 - fp.y;
    y2 := 1 - fp1.y;
  end;

  a := (y2 - y1) / (x2 - x1);
end;

procedure TVelocityCurve.InitParameters(aCurrentValue, aTargetValue, aSeconds: single;
  aCurveID: word);
begin
  FX := 0;
  FYOrigin := aCurrentValue;
  FYTarget := aTargetValue;

  FInvert := aCurrentValue > aTargetValue;

  FDeltaY := FYTarget - FYOrigin;
  FDuration := aSeconds;
  FFinished := aSeconds = 0.0;
  FCurrentIndexPoint1 := 0;

  FDataCurveToUse := VelocityCurveList.GetCurveByID(aCurveID);
  if FDataCurveToUse = nil then
    raise Exception.Create('Velocities curves error ! no curve available for ID=' +
      IntToStr(aCurveID) + ')');

  GetSegmentCoor;
end;

function TVelocityCurve.Compute(const AElapsedSec: single): single;
var
  xcurve, ycurve: single;
begin
  FX += AElapsedSec;
  if (FX >= FDuration) or (FDuration <= 0) then
    FFinished := True;
  if FFinished then
  begin
    Result := FYTarget;
    exit;
  end
  else
  begin
    xcurve := FX / FDuration;
    while xcurve > x2 do
    begin
      Inc(FCurrentIndexPoint1);
      GetSegmentCoor;
    end;

    ycurve := a * (xcurve - x1) + y1;
    if FInvert then
      ycurve := 1 - ycurve;

    Result := FYOrigin + ycurve * FDeltaY;
  end;
end;




//------------------------------------------------------------------------------------

//                            TDataCurveList




{ TDataCurveList }

constructor TDataCurveList.Create;
begin
  inherited Create;
  FList := TList.Create;
  FNumID := -1;
end;

destructor TDataCurveList.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TDataCurveList.Clear;
var
  i: integer;
begin
  for i := 0 to FList.Count - 1 do
    TDataCurve(FList.Items[i]).Free;
  FList.Clear;
  FNumID := -1;
end;

function TDataCurveList.GetDataCurveCount: integer;
begin
  Result := FList.Count;
end;

function TDataCurveList.NextID: integer;
begin
  Inc(FNumID);
  Result := FNumID;
end;


function TDataCurveList.AddCurve(const aName: string; const Pts: array of TPointF): word;
var
  o: TDataCurve;
begin
  o := TDataCurve.Create;
  o.Name := aName;
  o.FID := NextID;
  o.CopyPointsFrom(Pts);
  FList.Add(o);
  Result := o.ID;
end;

procedure TDataCurveList.DeleteByIndex(aIndex: integer);
begin
  if (aIndex < 0) or (aIndex >= FList.Count) then
    exit;
  TDataCurve(FList.Items[aIndex]).Free;
  FList.Delete(aIndex);
end;

procedure TDataCurveList.DeleteByID(aIDCurve: word);
var
  i: integer;
begin
  for i := 0 to FList.Count - 1 do
    if GetCurveByIndex(i).ID = aIDCurve then
    begin
      DeleteByIndex(i);
      exit;
    end;
end;

procedure TDataCurveList.DeleteByName(ACurveName: string);
var
  i: integer;
begin
  for i := 0 to FList.Count - 1 do
    if GetCurveByIndex(i).Name = ACurveName then
    begin
      DeleteByIndex(i);
      exit;
    end;
end;

function TDataCurveList.GetCurveByID(aID: word): TDataCurve;
var
  i: integer;
  dc: TDataCurve;
begin
  Result := GetCurveByIndex(0); // Linear curve by default
  for i := 0 to FList.Count - 1 do
  begin
    dc := GetCurveByIndex(i);
    if dc.ID = aID then
    begin
      Result := dc;
      exit;
    end;
  end;
end;

function TDataCurveList.GetCurveByIndex(aIndex: integer): TDataCurve;
begin
  if (aIndex < 0) or (aIndex >= FList.Count) then
    Result := TDataCurve(FList.Items[0])  // Linear curve by default
  else
    Result := TDataCurve(FList.Items[aIndex]);
end;

function TDataCurveList.CurveNameAlreadyExist(const aCurveName: string): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to FList.Count - 1 do
    if GetCurveByIndex(i).FName = aCurveName then
    begin
      Result := True;
      exit;
    end;
end;


initialization

  VelocityCurveList := TDataCurveList.Create;

  VelocityCurveList.AddCurve('Linear', [PointF(0, 1), PointF(1, 0)]);

  VelocityCurveList.AddCurve('StartFastEndSlow', [PointF(0, 1),
    PointF(0.020024182, 0.93652451), PointF(0.040863961, 0.875130057),
    PointF(0.062519327, 0.81581676), PointF(0.084990293, 0.758584738),
    PointF(0.108276844, 0.70343399), PointF(0.132378981, 0.65036422),
    PointF(0.157296717, 0.599375546), PointF(
    0.183030054, 0.550468266), PointF(0.209578991, 0.503642082),
    PointF(0.236943483, 0.458896935),
    PointF(0.265123576, 0.416233003), PointF(
    0.294119269, 0.375650346), PointF(0.323930591, 0.337148845),
    PointF(0.354557455, 0.300728381),
    PointF(0.385999888, 0.266389161), PointF(
    0.418257982, 0.234131128), PointF(0.451331586, 0.20395425),
    PointF(0.48522082, 0.175858527),
    PointF(0.519925535, 0.149843991), PointF(0.555446029, 0.12591061),
    PointF(0.591781974, 0.10405837), PointF(0.628933609, 0.084287308),
    PointF(0.666900694, 0.066597417), PointF(
    0.705683529, 0.050988663), PointF(0.745281875, 0.037461091),
    PointF(0.785695732, 0.026014673),
    PointF(0.826925337, 0.016649416), PointF(
    0.868970394, 0.009365318), PointF(0.911831021, 0.004162385),
    PointF(0.955507398, 0.001040612), PointF(1, 0)]);

  VelocityCurveList.AddCurve('StartSlowEndFast', [PointF(0, 1),
    PointF(0.051241662, 0.998875022), PointF(
    0.101217754, 0.995674491), PointF(0.149928272, 0.990398407),
    PointF(0.197373211, 0.98304683),
    PointF(0.24355258, 0.973619819), PointF(0.288466364, 0.962117136),
    PointF(0.332114607, 0.948538899), PointF(0.374497294, 0.93288511),
    PointF(0.415614307, 0.915156007), PointF(
    0.455465853, 0.895351171), PointF(0.494051784, 0.873470724),
    PointF(0.53137207, 0.849514902),
    PointF(0.56742692, 0.823483407), PointF(0.602216125, 0.79537642),
    PointF(0.635739744, 0.76519376), PointF(0.667997777, 0.732935786),
    PointF(0.698990226, 0.698602259), PointF(0.728717089, 0.66219312),
    PointF(0.757178485, 0.623708546), PointF(0.784374237, 0.58314836),
    PointF(0.810304403, 0.540512621), PointF(
    0.834969103, 0.495801389), PointF(0.85836798, 0.449014604),
    PointF(0.880501449, 0.400152236),
    PointF(0.901369393, 0.349214405), PointF(0.920971751, 0.29620102),
    PointF(0.939308524, 0.241112053), PointF(
    0.956379592, 0.183947578), PointF(0.972185254, 0.124707572),
    PointF(0.98672545, 0.063392036), PointF(1, 0)]);

  VelocityCurveList.AddCurve('Sinusoid', [PointF(0, 1),
    PointF(0.024732787, 0.998385906), PointF(
    0.049185738, 0.993821561), PointF(0.073372178, 0.986447573),
    PointF(0.097305417, 0.976404548),
    PointF(0.1209988, 0.963833213), PointF(0.14446567, 0.948873878),
    PointF(0.167719305, 0.931667387), PointF(
    0.190773025, 0.912354112), PointF(0.213640243, 0.891074657),
    PointF(0.23633422, 0.867969751),
    PointF(0.258868277, 0.843180001), PointF(
    0.281255752, 0.816845596), PointF(0.303509951, 0.789107561),
    PointF(0.325644255, 0.760106564),
    PointF(0.347671956, 0.729982734), PointF(
    0.369606346, 0.698877037), PointF(0.391460717, 0.666929662),
    PointF(0.413248628, 0.634281814),
    PointF(0.434983134, 0.601073563), PointF(
    0.456677645, 0.567445576), PointF(0.478345513, 0.53353852),
    PointF(0.500000119, 0.499493062),
    PointF(0.521654665, 0.465449661), PointF(
    0.543322504, 0.431548983), PointF(0.565017045, 0.397931635),
    PointF(0.586751521, 0.364737958),
    PointF(0.608539283, 0.332108915), PointF(
    0.630393684, 0.300184816), PointF(0.652328074, 0.269106299),
    PointF(0.674355745, 0.23901397),
    PointF(0.69648999, 0.210048467), PointF(0.718744099, 0.182350308),
    PointF(0.741131604, 0.15606007), PointF(0.763665676, 0.131318435),
    PointF(0.786359549, 0.108265862), PointF(
    0.809226751, 0.087043017), PointF(0.832280397, 0.067790486),
    PointF(0.855533957, 0.050648808),
    PointF(0.879000902, 0.035758596), PointF(
    0.902694285, 0.023260433), PointF(0.926627457, 0.013294909),
    PointF(0.95081389, 0.006002605),
    PointF(0.975266695, 0.001524106), PointF(1, 0)]);

  VelocityCurveList.AddCurve('Sinusoid2', [PointF(0, 1),
    PointF(0.036280163, 0.997963548), PointF(0.070699692, 0.992895722),
    PointF(0.103349388, 0.984944582), PointF(0.134319976, 0.974257946),
    PointF(0.16370222, 0.960983336), PointF(0.191586897, 0.945268929),
    PointF(0.218064785, 0.927262723), PointF(0.243226603, 0.907112002),
    PointF(0.267163068, 0.884965181), PointF(0.289965093, 0.86097008),
    PointF(0.311723292, 0.835274339), PointF(0.332528561, 0.808026016),
    PointF(0.35247153, 0.779372931), PointF(0.371643096, 0.749462903),
    PointF(0.390133888, 0.718443811), PointF(0.408034772, 0.686463714),
    PointF(0.425436437, 0.653670132), PointF(0.442429692, 0.620211244),
    PointF(0.459105253, 0.586234868), PointF(0.47555393, 0.551888585),
    PointF(0.491866469, 0.517320752), PointF(0.50813359, 0.48267895),
    PointF(0.52444613, 0.448111027), PointF(0.540894747, 0.413764864),
    PointF(0.557570398, 0.379788399), PointF(0.574563563, 0.34632957),
    PointF(0.591965258, 0.313536048), PointF(0.609866142, 0.281555861),
    PointF(0.628356934, 0.250536829), PointF(0.647528529, 0.220626801),
    PointF(0.667471528, 0.191973701), PointF(0.688276827, 0.164725393),
    PointF(0.710035086, 0.139029726), PointF(0.732836962, 0.115034543),
    PointF(0.756773591, 0.092887774), PointF(0.781935513, 0.072737254),
    PointF(0.808413386, 0.054730862), PointF(0.836297989, 0.03901647),
    PointF(0.865680397, 0.025741952), PointF(0.89665091, 0.015055172),
    PointF(0.929300606, 0.007104006), PointF(0.963720202, 0.002036323),
    PointF(1, 0)]);


  VelocityCurveList.AddCurve('5Steps', [PointF(0, 1),
    PointF(0.00476256, 0.998198748), PointF(0.01001783, 0.997401655),
    PointF(0.016586913, 0.996307433), PointF(0.02446977, 0.993674755),
    PointF(0.03366648, 0.988263667), PointF(0.044176985, 0.978832901),
    PointF(0.056086004, 0.963840008), PointF(0.069737703, 0.941852033),
    PointF(0.084797069, 0.915453315), PointF(0.100826055, 0.88770926),
    PointF(0.1173869, 0.861685932), PointF(0.134041592, 0.840448678),
    PointF(0.14986001, 0.827404022), PointF(0.165319234, 0.822299838),
    PointF(0.180999905, 0.821759641), PointF(0.196729809, 0.822855532),
    PointF(0.212336704, 0.822659731), PointF(0.227648303, 0.8182441),
    PointF(0.242492482, 0.806681752), PointF(0.25666675, 0.785713494),
    PointF(0.270275384, 0.757253945), PointF(0.283605009, 0.724631786),
    PointF(0.296942919, 0.691177368), PointF(0.310576051, 0.660220385),
    PointF(0.324791402, 0.635090232), PointF(0.339277983, 0.619380832),
    PointF(0.353822023, 0.612306178), PointF(0.368825495, 0.610563397),
    PointF(0.384196669, 0.611486435), PointF(0.399843752, 0.612409592),
    PointF(0.415674627, 0.610666871), PointF(0.431597352, 0.603591919),
    PointF(0.447597653, 0.588620067), PointF(0.463997573, 0.565705121),
    PointF(0.480650008, 0.537434995), PointF(0.49732542, 0.506522119),
    PointF(0.513794065, 0.475678205), PointF(0.529826105, 0.447614998),
    PointF(0.545191526, 0.425044417), PointF(0.559649169, 0.410597384),
    PointF(0.573107302, 0.404411435), PointF(0.585852742, 0.403787076),
    PointF(0.598207474, 0.40587458), PointF(0.610493481, 0.407824278),
    PointF(0.623032153, 0.406786263), PointF(0.636145294, 0.399910569),
    PointF(0.650130808, 0.384445608), PointF(0.664943099, 0.360299051),
    PointF(0.680306613, 0.330269039), PointF(0.695945978, 0.297297269),
    PointF(0.711585343, 0.264325589), PointF(0.726948977, 0.234295577),
    PointF(0.74176085, 0.210148841), PointF(0.755756915, 0.194641665),
    PointF(0.768937349, 0.187498108), PointF(0.781566083, 0.186100006),
    PointF(0.793918848, 0.187781528), PointF(0.806271791, 0.189876765),
    PointF(0.818900585, 0.189719737), PointF(0.832080722, 0.184644371),
    PointF(0.846693695, 0.171546355), PointF(0.863076866, 0.150098905),
    PointF(0.880165517, 0.123468272), PointF(0.897327781, 0.094524868),
    PointF(0.91393286, 0.066139199), PointF(0.929347813, 0.041181549),
    PointF(0.942942917, 0.022522518), PointF(0.954777062, 0.010850859),
    PointF(0.965332329, 0.004099932), PointF(0.974607587, 0.001006695),
    PointF(0.982603788, 0.000308192), PointF(0.989320636, 0.000741532),
    PointF(0.99475807, 0.001043589), PointF(1, 0)]);

finalization
  FreeAndNil(VelocityCurveList);
end.

