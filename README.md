# OALSoundManager

DEPRECATED: please consider to use the new ALSound repository.

Easy library for FreePascal - Lazarus to play sound throught OpenAL. If OpenAL is not installed, application will run anyway but without sound.
Tested and work on Windows, Linux and Mac.

Limitations:
  - Play only WAV file with 8 or 16 bits per sample, mono or stereo.
  - Load the whole wav data in memory, no streaming process

written by Lulu - 2017

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
Volume range is [0..1000]

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
   MySound.Volume.ChangeTo( newValue, TimeInSeconds, VelocityCurveID );

To set a value:
   MySound.Volume.Value := 1000;

Available velocity curve for volume and pitch are (see VelocityCurve unit)
  idcLinear
  idcStartFastEndSlow
  idcStartSlowEndFast
  idcSinusoid
  idcSinusoid2
idc5Steps
