{
  **************************************************************************
 *                                                                          *
 *  This file is part of OpenALSoundManager library.                        *
 *                                                                          *
 *  See the file LICENSE included in this distribution,                     *
 *  for details about the copyright.                                        *
 *                                                                          *
 *  This software is distributed in the hope of being useful                *
 *  for learning purposes about OpenGL and Lazarus,                         *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    *
 *                                                                          *
  **************************************************************************

 written by Lulu  2017 - 2018
}


{

-- USAGE --

uses OALSoundManager,
     VelocityCurve;
...
var
 MySound: TOALSound;
...


Loading wav file
   MySound := OALManager.Add( 'Path/MyMusic.wav' );

Audio are automatically deleted from memory when the application is closed.
however, if you need to delete audio at run time, use
   OALManager.Delete( MySound );



-- FILE ERROR --

Loading file error can be retrieved with
   MySound.GetFileError
It return:
    - oal_NOERROR : audio is loaded in memory and ready to play
    - oal_ERR_NOTWAVFILE : bad format, only wav file are played
    - oal_ERR_BADBITPERSAMPLE : audio file have bad bit per sample
                                (only 8 and 16 bits per sample are allowed)



-- COMMON ACTIONS --

   MySound.Play( AFromBegin: boolean );
   MySound.Pause;
   MySound.Stop;



-- VOLUME --

Get/set current volume of the sound
   MySound.Volume.Value // return single type value between 0 and 1000


Slide the volume to new value in specified time, using velocity curve
   MySound.Volume.ChangeTo( ANewValue, ATimeSec: single; AVelocityCurve: word );


-- FADE IN/OUT --

You can also fade in and fade out the sound

Play the sound then increase volume to maximum
Do it in specified time and with specified velocity curve
   MySound.FadeIn( ATimeSec: single; AVelocityCurve: word );



Play the sound then increase volume to specified value
Do it in specified time and with specified velocity curve
   MySound.FadeIn( AVolume, ATimeSec: single; AVelocityCurve: word );



Slide the volume to zero then stop the sound
Do it in specified time and with specified velocity curve
   MySound.FadeOut( ATimeSec: single; AVelocityCurve: word );



-- PITCH --

Like volume, you can set or slide value for pitch between 0.1 and 4.0
Default pitch value is 1.0.

   MySound.Pitch.Value := 0.1;
   MySound.Pitch.ChangeTo( 4.0, 3.0, idcStartSlowEndFast );



-- VELOCITY CURVE --

Volume and Pitch are derived from TBoundedFParam class, so you can
simply change their value throught time like below:
   Volume.ChangeTo( newValue, TimeInSeconds, VelocityCurveID );

To set a value:
   Volume.Value := 1000;

Available velocity curve for volume and pitch are (see VelocityCurve unit)
  idcLinear
  idcStartFastEndSlow
  idcStartSlowEndFast
  idcSinusoid
  idcSinusoid2
  idc5Steps

}
unit OALSoundManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  OpenALWrapper,
  LCLType, LCLIntf,
  VelocityCurve;

const

// Volume range
  oal_VOLUME_MIN =    0;
  oal_VOLUME_MAX =    1;

// Pitch range
  oal_PITCH_MAX     = 4.0;
  oal_PITCH_MIN     = 0.1;
  oal_PITCH_NORMAL  = 1.0;

// Sound state - same value as those in unit openal
   AL_INITIAL   = $1011;
   AL_PLAYING   = $1012;
   AL_PAUSED    = $1013;
   AL_STOPPED   = $1014;

type

// wav file error
TOALError = ( oal_NOERROR, oal_ERR_NOTWAVFILE, oal_ERR_BADBITPERSAMPLE );

{$I oalwavloaderDeclaration.inc }

TOALSound = class;

{ TVolumeParam }

TVolumeParam = class( TBoundedFParam )
private
  FParentOALSound: TOALSound;
protected
  procedure SetValue( AValue: single ); override;
end;

{ TPitchParam }

TPitchParam = class( TBoundedFParam )
private
 FParentOALSound: TOALSound;
protected
 procedure SetValue( AValue: single ); override;
end;


{ TOALSound }

TOALSound = class
protected
  FWavLoader: TWavLoader;
  FSamples : TArrayOfByte;
  FError  : boolean;
  FBuffer : LongWord;
  FSource : LongWord;
  FLoop   : boolean;
  FPaused: boolean;
  FPan: integer;
  FPitch: single;
protected
  FFadeOutEnabled,
  FKillAfterFadeOut,
  FKillAfterPlay,
  FKill: boolean;
private
  FGlobalVolume: single;
  function GetBitsPerSample: byte;
  function GetChannelCount: integer;
  function GetFormat: word;
  function GetFrequency: integer;
  function GetSampleCount: QWord;
  procedure SetGlobalVolume(AValue: single);
  procedure SetLoop(AValue: boolean);
  procedure SetALVolume;
  procedure SetALPitch;
protected
  procedure Update( const aElapsedTime: single );
public
  Constructor Create( const aFilename:string );
  Destructor Destroy; override;

  procedure Play( AFromBegin: boolean=TRUE );
  procedure Stop;
  procedure Pause;

  procedure FadeIn( ATimeSec: single; AVelocityCurve: word=idcLinear );
  procedure FadeIn( AVolume: single; ATimeSec: single; AVelocityCurve: word=idcLinear );
  procedure FadeOut( ATimeSec: single; AVelocityCurve: word=idcLinear );

  // play the sound one time and kill it when it reach the end. Loop need to be set to FALSE
  procedure PlayThenKill( FromBeginning: boolean= TRUE );
  // fadeout the sound and kill it
  procedure FadeOutThenKill( aDuration: single; aCurve: Word=idcLinear );
  // kill the sound (stop it and free ressources for this sound)
  procedure Kill;

  function GetState: integer;
  function GetFileError: TOALError;

  function TotalDuration : single ;
  function GetTimePosition : single ;
  function Byte2Seconds ( aPosition : QWord ) : single ;
  function Seconds2Byte ( aTimePosition : single ) : QWord;

public
  Volume: TVolumeParam;    // [0..oal_VOLUME_MAX]
  Pitch:  TPitchParam;     // pitch is [0.1,4.0] range
  property Frequency: integer read GetFrequency;
  property Loop: boolean read FLoop write SetLoop;
  property ChannelCount : integer read GetChannelCount;
  property Format: word read GetFormat;
  property SampleCount: QWord read GetSampleCount;
  property BitsPerSample: byte read GetBitsPerSample;
  property State: integer read GetState;
  property GlobalVolume: single read FGlobalVolume write SetGlobalVolume;// global volume [0..1] set to 1 by default
end;

type
TDoUpdate=procedure( const aElapsedTime: single ) of object;

{ TTimeableThread }

TTimeableThread= class( TThread )
private
  FPeriodUpdate: integer;
  FDoUpdate: TDoUpdate ;
  procedure SetPeriodUpdate(AValue: integer);
protected
  procedure Execute ; override;
public
 Constructor Create( aCallBackDoUpdate: TDoUpdate; aUpdatePeriod: integer; aStart: boolean );
 property UpdatePeriod: integer read FPeriodUpdate write SetPeriodUpdate; // period is in millisecond
 property DoUpdate: TDoUpdate read FDoUpdate write FDoUpdate;
end;

{ TOALCustomSoundManager }

TOALCustomSoundManager = class
  Constructor Create ;
  Destructor Destroy ; override ;
protected
  FCriticalSection: TCriticalSection;
  FThread: TTimeableThread;
  procedure DoUpdate( const aElapsedTime: single );
private
  FList    : TList;
  FDevice  : PALCdevice;
  FContext : PALCcontext;
  function GetCount: integer;
  function GetSoundCount: integer;
  function GetSoundByIndex(aIndex: integer): TOALSound;
  procedure DoDeleteSound( AIndex: integer );
  function GetOpenALLibraryLoaded: boolean;
public
  function Add( const aFilename: string; aLooped: boolean=FALSE ): TOALSound;
  procedure PlayThenKill( const aFilename: string; aVolume: single );

  procedure Delete( ASound: TOALSound );
  procedure Clear;
  procedure StopAllSound;
  property OpenALLibraryLoaded: boolean read GetOpenALLibraryLoaded;
  property Count: integer read GetCount;
end;

var
  OALManager: TOALCustomSoundManager;

implementation

{$I oalwavloaderImplementation.inc }

{ TTimeableThread }

procedure TTimeableThread.SetPeriodUpdate(AValue: integer);
begin
 if FPeriodUpdate=AValue then Exit;
 FPeriodUpdate:=AValue;
 if FPeriodUpdate<1 then FPeriodUpdate:=1;
end;

procedure TTimeableThread.Execute;
var T1, T2, DeltaT: QWord;
    v: single;
begin
 T1 := GetTickCount64;
 while not Terminated do
  begin
   T2 := GetTickCount64;
   DeltaT := T2-T1;
   if (DeltaT >= FPeriodUpdate) and (FDoUpdate <> NIL)
     then begin
           v := single( DeltaT ) * 0.001;
           if FDoUpdate<>NIL then FDoUpdate( v );
           T1 := T2;
          end;
   if FPeriodUpdate > 1 then sleep( FPeriodUpdate - 1 );
  end;
end;

constructor TTimeableThread.Create(aCallBackDoUpdate: TDoUpdate;
  aUpdatePeriod: integer; aStart: boolean);
begin
 inherited Create(true );
 FPeriodUpdate := aUpdatePeriod;
 FDoUpdate := aCallBackDoUpdate;
 if aStart then Start;
end;

{ TVolumeParam }

procedure TVolumeParam.SetValue(AValue: single);
begin
 inherited SetValue(AValue);
 FParentOALSound.SetALVolume;
end;

{ TPitchParam }

procedure TPitchParam.SetValue(AValue: single);
begin
 inherited SetValue(AValue);
 FParentOALSound.SetALPitch;
end;

{ TOALCustomSoundManager }

constructor TOALCustomSoundManager.Create;
begin
 LoadOpenALLibrary;

 if _OpenALLibraryLoaded then
 begin
   FDevice := alcOpenDevice(NIL);
   if (alGetError() = AL_NO_ERROR) and
      (FDevice<>NIL)
     then FContext := alcCreateContext(FDevice, NIL)
     else FContext := NIL;
   if FContext = NIL then raise exception.create('OpenAL error: no context created...');
   alcMakeContextCurrent( FContext );
   alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);
 end;
 FList := TList.Create;

 InitializeCriticalSection( FCriticalSection );
 FThread:= TTimeableThread.Create(@DoUpdate, 10, TRUE );
end;

destructor TOALCustomSoundManager.Destroy;
begin
 FThread.Terminate;
 FThread.WaitFor;
 FThread.Free;

 Clear;
 FreeAndNil( FList );

 DeleteCriticalSection( FCriticalSection );

 if _OpenALLibraryLoaded then
 begin
   alcMakeContextCurrent(NIL);
   if FContext<>NIL
     then alcDestroyContext(FContext);
   FContext:=NIL;
   alcCloseDevice(FDevice);
 end;

 UnloadOpenALLibrary;
end;

procedure TOALCustomSoundManager.DoUpdate(const aElapsedTime: single);
var i: integer;
    s: TOALSound;
begin
 try
  EnterCriticalSection( FCriticalSection );
  for i:=GetSoundCount-1 downto 0 do begin
    s := GetSoundByIndex(i);
    if s.FKill then DoDeleteSound( FList.IndexOf(s) )
               else s.Update( aElapsedTime );
  end;
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

procedure TOALCustomSoundManager.Clear ;
var i : integer ;
begin
 try
  EnterCriticalSection( FCriticalSection );
  for i:=0 to GetSoundCount-1 do GetSoundByIndex(i).Free ;
  FList.Clear;
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

procedure TOALCustomSoundManager.StopAllSound;
var i:integer ;
begin
 try
  EnterCriticalSection( FCriticalSection );
  for i:=0 to GetSoundCount-1 do
    GetSoundByIndex(i).Stop ;
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

function TOALCustomSoundManager.GetSoundCount: integer;
begin
 try
  EnterCriticalSection( FCriticalSection );
  Result := FList.Count;
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

function TOALCustomSoundManager.GetCount: integer;
begin
  Result:=FList.Count;
end;

function TOALCustomSoundManager.GetSoundByIndex(aIndex: integer): TOALSound;
begin
 try
  EnterCriticalSection( FCriticalSection );
  Result := TOALSound( FList.Items[aIndex] );
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

procedure TOALCustomSoundManager.DoDeleteSound(AIndex: integer);
begin
 if (AIndex < 0) and (AIndex >= GetSoundCount ) then exit;

// try
//  EnterCriticalSection( FCriticalSection );
  TOALSound( FList.Items[AIndex] ).Free;
  FList.Delete( AIndex );
// finally
//  LeaveCriticalSection( FCriticalSection );
// end;
end;

function TOALCustomSoundManager.GetOpenALLibraryLoaded: boolean;
begin
 Result := _OpenALLibraryLoaded;
end;

function TOALCustomSoundManager.Add(const aFilename: string; aLooped: boolean): TOALSound;
begin
 try
  EnterCriticalSection( FCriticalSection );
  Result := TOALSound.Create( aFilename );
  Result.Loop:=aLooped;
  FList.Add( Result );
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

procedure TOALCustomSoundManager.PlayThenKill(const aFilename: string; aVolume: single);
var snd: TOALSound;
begin
 snd := Add(aFilename);
 if snd=NIL then exit;
 snd.Volume.Value:=aVolume;
 snd.PlayThenKill(TRUE);
end;

procedure TOALCustomSoundManager.Delete(ASound: TOALSound);
begin
 try
  EnterCriticalSection( FCriticalSection );
  DoDeleteSound( FList.IndexOf( ASound ));
 finally
  LeaveCriticalSection( FCriticalSection );
 end;
end;

{ TOALSound }
constructor TOALSound.Create(const aFilename: string);
begin
 Volume := TVolumeParam.Create;
 Volume.FParentOALSound := Self;
 Volume.MaxValue := oal_VOLUME_MAX;
 Volume.MinValue := oal_VOLUME_MIN;
 Volume.Value := oal_VOLUME_MAX;

 Pitch := TPitchParam.Create;
 Pitch.FParentOALSound := Self;
 Pitch.MaxValue := oal_PITCH_MAX;
 Pitch.MinValue := oal_PITCH_MIN;
 Pitch.Value := oal_PITCH_NORMAL;

 GlobalVolume:=oal_VOLUME_MAX;

 FPaused:=FALSE;
 FLoop := FALSE ;
 FError := FALSE;

 FWavLoader:= TWavLoader.Create;
 FWavLoader.OpenFile( aFilename );

 FSamples := FWavLoader.GetAllData;
 FWavLoader.CloseFile;

 if _OpenALLibraryLoaded then
 begin
   alGenBuffers(1, @FBuffer);
   alBufferData(FBuffer, GetFormat, @FSamples[0], FWavLoader.GetDataSizeInByte, GetFrequency );

   alGenSources(1, @FSource );
   alSourcei(FSource, AL_BUFFER, FBuffer);
 end;
end;

destructor TOALSound.Destroy;
begin
 if _OpenALLibraryLoaded then
 begin
   alDeleteBuffers(1, @FBuffer);
   alSourcei(FSource, AL_BUFFER, 0);
   alDeleteSources(1, @FSource);
 end;

 SetLength( FSamples, 0 );

 Volume.Free ;
 Pitch.Free;
 FWavLoader.Free;
 inherited Destroy;
end;

function TOALSound.GetBitsPerSample: byte;
begin
 Result := FWavLoader.GetBitsPerSample;
end;

function TOALSound.GetChannelCount: integer;
begin
 Result := FWavLoader.GetChannelCount;
end;

function TOALSound.GetFormat: word;
begin
 Result := FWavLoader.GetFormat;
end;

function TOALSound.GetFrequency: integer;
begin
 Result := FWavLoader.GetFrequency;
end;

function TOALSound.GetSampleCount: QWord;
begin
 Result := FWavLoader.GetSampleCount;
end;

procedure TOALSound.SetGlobalVolume(AValue: single);
begin
  if FGlobalVolume=AValue then Exit;
  FGlobalVolume:=AValue;
  SetALVolume;
end;


procedure TOALSound.SetLoop(AValue: boolean);
var v : integer ;
begin
 if FError then exit;
 if AValue then v := 1
           else v := 0;
 if _OpenALLibraryLoaded then alSourcei( FSource, AL_LOOPING, v );
 FLoop := AValue;
end;

procedure TOALSound.SetALVolume;
begin
 if FError then exit;
 if _OpenALLibraryLoaded then
  alSourcef( FSource, AL_GAIN, Volume.Value / oal_VOLUME_MAX*GlobalVolume );
end;

procedure TOALSound.SetALPitch;
begin
 if FError then exit;
 if _OpenALLibraryLoaded then
  alSourcef( FSource, AL_PITCH, Pitch.Value );
end;

procedure TOALSound.Update(const aElapsedTime: single);
var v,p: single;
begin
 v := Volume.Value;
 Volume.OnElapse( aElapsedTime );

 p := Pitch.Value;
 Pitch.OnElapse( aElapsedTime );

 if FError then exit;

 if v <> Volume.Value then SetALVolume;

 if ( Volume.State = psNO_CHANGE ) and FFadeOutEnabled then begin
   FFadeOutEnabled := FALSE;
   if _OpenALLibraryLoaded then alSourceStop( FSource );
   FKill := FKillAfterFadeOut;
 end;

 if FKillAfterPlay and (GetState=AL_STOPPED) then FKill := TRUE;

 if p <> Pitch.Value then SetALPitch;

end;

function TOALSound.GetTimePosition: single;
begin
 Result := 0;
 if FError
   then Result := 0
   else  if _OpenALLibraryLoaded then alGetSourcef(FSource, AL_SEC_OFFSET, Result);
end;

function TOALSound.Byte2Seconds(aPosition: QWord): single;
begin
 if FError
   then Result := 0
   else Result := aPosition / GetFrequency ;
end;

function TOALSound.Seconds2Byte(aTimePosition: single): QWord;
begin
 if FError
   then Result := 0
   else Result := round( aTimePosition * GetFrequency ) ;
end;


function TOALSound.TotalDuration: single;
begin
 if FError
   then Result := 0
   else Result := GetSampleCount / GetFrequency ;
end;

procedure TOALSound.Play(AFromBegin: boolean);
begin
 if FError then exit;
 if not _OpenALLibraryLoaded then exit;

 case GetState of
  AL_STOPPED, AL_INITIAL: begin
   alSourceRewind( FSource );
   alSourcePlay( FSource );
   SetALVolume;
  end;
  AL_PLAYING: begin
   if AFromBegin then begin
     alSourceRewind( FSource );
     alSourcePlay( FSource );
   end;
  end;
  AL_PAUSED: begin
   alSourcePlay( FSource );
  end;
 end;
 FFadeOutEnabled := FALSE;
end;

procedure TOALSound.Stop;
begin
 if FError then exit;
 if not _OpenALLibraryLoaded then exit;

 alSourceStop(FSource);
 FFadeOutEnabled := FALSE;
end;

procedure TOALSound.Pause;
begin
 if FError then exit;
 if not _OpenALLibraryLoaded then exit;

 case GetState of
  AL_PAUSED: Play( FALSE );
  AL_PLAYING: alSourcePause( FSource );
  AL_STOPPED,AL_INITIAL:;
 end;
 FFadeOutEnabled := FALSE;
end;

procedure TOALSound.FadeIn(ATimeSec: single; AVelocityCurve: word);
begin
 FadeIn( oal_VOLUME_MAX, ATimeSec, AVelocityCurve );
end;

procedure TOALSound.FadeIn(AVolume: single; ATimeSec: single;
  AVelocityCurve: word);
begin
 if FError then exit;
 if not _OpenALLibraryLoaded then exit;

 case GetState of
  AL_STOPPED, AL_INITIAL: begin
    Volume.Value := 0.0;
    Volume.ChangeTo( AVolume, ATimeSec, AVelocityCurve );
    alSourcePlay( FSource );
  end;
  AL_PAUSED: begin
    Volume.Value := 0.0;
    Volume.ChangeTo( AVolume, ATimeSec, AVelocityCurve );
    alSourcePlay( FSource );
  end;
  AL_PLAYING: Volume.ChangeTo(aVolume, ATimeSec, AVelocityCurve );
 end;
 FFadeOutEnabled := FALSE;
end;

procedure TOALSound.FadeOut(ATimeSec: single; AVelocityCurve: word);
begin
 if FError then exit;
 if not _OpenALLibraryLoaded then exit;

 case GetState of
  AL_STOPPED, AL_INITIAL:;
  AL_PLAYING: begin
   Volume.ChangeTo( 0, ATimeSec, AVelocityCurve);
   FFadeOutEnabled := TRUE;
  end;
  AL_PAUSED: begin
   Volume.ChangeTo( 0, ATimeSec, AVelocityCurve);
   FFadeOutEnabled := TRUE;
   alSourcePlay( FSource );
  end;
 end;
end;

procedure TOALSound.PlayThenKill(FromBeginning: boolean);
begin
 Loop:=FALSE;
 FKillAfterPlay := TRUE;
 Play( FromBeginning );
end;

procedure TOALSound.FadeOutThenKill(aDuration: single; aCurve: Word);
begin
 if (GetState=AL_STOPPED)or(GetState=AL_PAUSED)
   then Kill
   else begin
         FKillAfterFadeOut := TRUE;
         FadeOut( aDuration, aCurve );
   end;
end;

procedure TOALSound.Kill;
begin
 FKill := TRUE;
end;

function TOALSound.GetState: integer;
begin
 Result := AL_INITIAL;
 if FError
   then exit
   else if _OpenALLibraryLoaded
          then alGetSourcei( FSource, AL_SOURCE_STATE, Result );
end;

function TOALSound.GetFileError: TOALError;
begin
 Result := FWavLoader.GetError;
end;

Initialization
OALManager := TOALCustomSoundManager.Create ;
Finalization
OALManager.Free;

end.


