{
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

unit OpenALWrapper;

{$mode objfpc}{$H+}

interface

uses

  DynLibs, ctypes;

{
 we don't use fpc 'openal.pas' (in fpc OpenAL package) to load dynamically
 the library because if binary files (openal32.dll for windows, or
 libopenal.so for linux) are not present, application exit with error message and
 not run.
 Here, if OpenAL is not installed, application will run anyway, but without sound.
 It seems that Mac have openal installed natively.
}

const
{$IFDEF LINUX}
  openallib = 'libopenal.so';
{$ENDIF}
{$IFDEF WINDOWS}
  openallib = 'openal32.dll';
{$ENDIF}
{$IFDEF DARWIN}
  openallib = '/System/Library/Frameworks/OpenAL.framework/OpenAL';
{$ENDIF}

// redefine constant from file openal.pas ( fpc package )
const
  AL_LOOPING = $1007;
  AL_INVERSE_DISTANCE_CLAMPED = $D002;
  AL_BUFFER = $1009;
  AL_GAIN = $100A;
  AL_PITCH = $1003;
  AL_SEC_OFFSET = $1024;
  AL_SOURCE_STATE = $1010;
  AL_FORMAT_MONO8 = $1100;
  AL_FORMAT_MONO16 = $1101;
  AL_FORMAT_STEREO8 = $1102;
  AL_FORMAT_STEREO16 = $1103;

type
  PALCdevice = ^ALCdevice;
  ALCdevice = record
  end;

  PALCcontext = ^ALCcontext;
  ALCcontext = record
  end;

var

  alGenBuffers: procedure(n: cint32; buffers: pcuint32); cdecl;
  alBufferData: procedure(bid: cuint32; format: cint32; Data: pointer; size: cint32; freq: cint32); cdecl;
  alGenSources: procedure(n: cint32; sources: pcuint32); cdecl;
  alSourcei: procedure(sid: cuint32; param: cint32; Value: cint32); cdecl;
  alDeleteBuffers: procedure(n: cint32; const buffers: pcuint32); cdecl;
  alDeleteSources: procedure(n: cint32; const sources: pcuint32); cdecl;
  alSourcef: procedure(sid: cuint32; param: cint32; Value: cfloat); cdecl;
  alGetSourcef: procedure(sid: cuint32; param: cint32; var Value: cfloat); cdecl;
  alGetSourcei: procedure(sid: cuint32; param: cint32; var Value: cint32); cdecl;
  alSourcePlay: procedure(sid: cuint32); cdecl;
  alSourcePause: procedure(sid: cuint32); cdecl;
  alSourceStop: procedure(sid: cuint32); cdecl;
  alSourceRewind: procedure(sid: cuint32); cdecl;
  alcOpenDevice: function(const devicename: pcchar): PALCdevice; cdecl;
  alcCloseDevice: function(device: PALCdevice): cbool; cdecl;
  alcCreateContext: function(device: PALCdevice; const attrlist: pcint32): PALCcontext; cdecl;
  alcDestroyContext: procedure(context: PALCcontext); cdecl;
  alcMakeContextCurrent: function(context: PALCcontext): cbool; cdecl;
  alDistanceModel: procedure(distanceModel: cint32); cdecl;

  _OpenALLibraryLoaded: boolean = False;
  _OpenALLib_ReferenceCounter: cardinal = 0;
  _OpenALLib_Handle: TLibHandle = dynlibs.NilHandle;


procedure LoadOpenALLibrary;
procedure UnloadOpenALLibrary;


implementation


procedure LoadOpenALLibrary;
begin
  if _OpenALLib_Handle <> 0 then
  begin
    Inc(_OpenALLib_ReferenceCounter);
  end
  else
  begin
    _OpenALLib_Handle := DynLibs.LoadLibrary( openallib );
    if _OpenALLib_Handle <> DynLibs.NilHandle then
    begin
      Pointer(alGenBuffers) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alGenBuffers'));
      Pointer(alBufferData) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alBufferData'));
      Pointer(alGenSources) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alGenSources'));
      Pointer(alSourcei) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alSourcei'));
      Pointer(alDeleteBuffers) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alDeleteBuffers'));
      Pointer(alDeleteSources) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alDeleteSources'));
      Pointer(alSourcef) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alSourcef'));
      Pointer(alGetSourcef) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alGetSourcef'));
      Pointer(alGetSourcei) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alGetSourcei'));
      Pointer(alSourcePlay) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alSourcePlay'));
      Pointer(alSourcePause) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alSourcePause'));
      Pointer(alSourceStop) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alSourceStop'));
      Pointer(alSourceRewind) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alSourceRewind'));
      Pointer(alcOpenDevice) := DynLibs.GetProcedureAddress(
        _OpenALLib_Handle, PChar('alcOpenDevice'));
      Pointer(alcCloseDevice) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alcCloseDevice'));
      Pointer(alcCreateContext) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alcCreateContext'));
      Pointer(alcDestroyContext) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alcDestroyContext'));
      Pointer(alcMakeContextCurrent) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alcMakeContextCurrent'));
      Pointer(alDistanceModel) :=
        DynLibs.GetProcedureAddress(_OpenALLib_Handle, PChar('alDistanceModel'));
      _OpenALLib_ReferenceCounter := 1;
      _OpenALLibraryLoaded := True;
    end;
  end;
end;

procedure UnloadOpenALLibrary;
begin
  // Reference counting
  if _OpenALLib_ReferenceCounter > 0 then
    Dec(_OpenALLib_ReferenceCounter);
  if _OpenALLib_ReferenceCounter > 0 then
    exit;

  if _OpenALLib_Handle <> dynlibs.NilHandle then
  begin
    DynLibs.UnloadLibrary(_OpenALLib_Handle);
    _OpenALLib_Handle := DynLibs.NilHandle;
  end;
end;

end.
