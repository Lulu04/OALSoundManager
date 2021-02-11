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
unit OpenALSoundWavFileLoader;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils,
 OpenALWrapper;


type

TOALError = ( oal_NOERROR, oal_ERR_NOTWAVFILE, oal_ERR_BADBITPERSAMPLE );

TArrayOfByte = array of byte;

{ TOALSoundLoader Abstract class }

TOALSoundLoader = class
protected
  FStream: TFileStream;
  FError: TOALError;
public
  procedure OpenFile( const AFilename: string ); virtual;
  procedure CloseFile; virtual;
  function GetError: TOALError;
  function GetAllData: TArrayOfByte; virtual; abstract;
  function GetChannelCount: integer; virtual; abstract;
  function GetFormat: word; virtual; abstract;
  function GetFrequency: integer; virtual; abstract;
  function GetSampleCount: QWord; virtual; abstract;
  function GetBytePerSample: integer; virtual; abstract;
  function GetBitsPerSample: word; virtual; abstract;
  function GetDataSizeInByte: QWord; virtual; abstract;
end;


TWavHeader = packed record
    RIFFHeader       : array[0..3] of char;
    FileSize         : integer;
    WAVEHeader       : array[0..3] of char;

    FormatHeader     : array[0..3] of char;
    FormatHeaderSize : integer;
    FormatCode       : word;
    ChannelNumber    : word;
    SampleRate       : longword;
    BytesPerSecond   : longword;
    BytesPerSample   : word;
    BitsPerSample    : word;
 end;

TWavChunk = packed record
    ChunkName        : array[0..3] of char;
    ChunkSize        : integer;
end;


{ TWavLoader }

TWavLoader = class( TOALSoundLoader )
private
  FWavHeader: TWavHeader;
  FWavDataStreamPos : int64;
  FWavDataByteLength : integer;
  procedure InitFromHeader;
public
  constructor Create;
  destructor Destroy; override;
  procedure OpenFile( const AFilename: string ); override;
  function GetAllData: TArrayOfByte; override;
  function GetChannelCount: integer; override;
  function GetFormat: word; override;
  function GetFrequency: integer; override;
  function GetSampleCount: QWord; override;
  function GetBytePerSample: integer; override;
  function GetBitsPerSample: word; override;
  function GetDataSizeInByte: QWord; override;
end;

implementation

{ TOALSoundLoader }

procedure TOALSoundLoader.OpenFile(const AFilename: string);
begin
 if FStream <> NIL then FStream.Free;

 FStream := TFileStream.Create( AFilename, fmOpenRead );
end;

procedure TOALSoundLoader.CloseFile;
begin
 if FStream <> NIL then FreeAndNil( FStream );
end;

function TOALSoundLoader.GetError: TOALError;
begin
 Result := FError;
end;

{ TWavLoader }

procedure TWavLoader.InitFromHeader;
var wc: TWavChunk;
begin
 if FStream = NIL then exit;

 FStream.Position := 0;
 FStream.ReadBuffer( FWavHeader, sizeof ( TWavHeader ));

 with FWavHeader do
 begin

 if ( RIFFHeader[0]<>'R' ) or ( RIFFHeader[1]<>'I' ) or
    ( RIFFHeader[2]<>'F' ) or ( RIFFHeader[3]<>'F' )
    then begin
      FError := oal_ERR_NOTWAVFILE;
      CloseFile;
      exit;
    end;

   FormatHeaderSize := LEtoN( FWavHeader.FormatHeaderSize );
   FormatCode := LEtoN( FWavHeader.FormatCode );
   ChannelNumber := LEtoN( FWavHeader.ChannelNumber );
   SampleRate := LEtoN( FWavHeader.SampleRate );
   BytesPerSecond := LEtoN( FWavHeader.BytesPerSecond );
   BytesPerSample := LEtoN( FWavHeader.BytesPerSample );

   BitsPerSample := LEtoN( FWavHeader.BitsPerSample );
   if ( BitsPerSample <> 8 ) and ( BitsPerSample <> 16 )then begin
     FError := oal_ERR_BADBITPERSAMPLE;
     CloseFile;
     exit;
   end;

 end;

 // read data in memory
 repeat
  FStream.ReadBuffer( wc{%H-}, sizeof ( wc ));  // read chunk header
  wc.ChunkSize := LEtoN( wc.ChunkSize );
  if wc.ChunkName = 'data' then begin
    FWavDataByteLength := wc.ChunkSize;
    FWavDataStreamPos := FStream.Position;
    exit;
  end else FStream.Seek( wc.ChunkSize, soCurrent );
 until FStream.Position >= FStream.Size;

 FError := oal_NOERROR;
end;

constructor TWavLoader.Create;
begin
 FStream := NIL;
end;

destructor TWavLoader.Destroy;
begin
 if FStream <> NIL then FStream.Free;
 inherited Destroy;
end;

procedure TWavLoader.OpenFile(const AFilename: string);
begin
 inherited OpenFile( AFilename );
 InitFromHeader;
end;

function TWavLoader.GetAllData: TArrayOfByte;
begin
 if FStream = NIL
   then SetLength( Result, 0 )
   else begin
     SetLength( Result, FWavDataByteLength );
     FStream.Position := FWavDataStreamPos;
     FWavDataByteLength := FStream.Read( Result[0], FWavDataByteLength );
   end;
end;

function TWavLoader.GetChannelCount: integer;
begin
 if FStream = NIL
   then Result := 0
   else Result := FWavHeader.ChannelNumber;
end;

function TWavLoader.GetFormat: word;
begin
 Result := $0000;
 if FStream = NIL then exit;
 case FWavHeader.ChannelNumber of
         1: case FWavHeader.BitsPerSample of
                8: Result := AL_FORMAT_MONO8;
               16: Result := AL_FORMAT_MONO16;
         end;
         2: case FWavHeader.BitsPerSample of
                8: Result := AL_FORMAT_STEREO8;
               16: Result := AL_FORMAT_STEREO16;
         end;
   end;
end;

function TWavLoader.GetFrequency: integer;
begin
 if FStream = NIL
   then Result := 0
   else Result := FWavHeader.SampleRate;
end;

function TWavLoader.GetSampleCount: QWord;
begin
 if FStream = NIL
   then Result := 0
   else Result := QWord( FWavDataByteLength div GetBytePerSample );
end;

function TWavLoader.GetBytePerSample: integer;
begin
 if FStream = NIL
   then Result := 0
   else Result := FWavHeader.BytesPerSample;
end;

function TWavLoader.GetBitsPerSample: word;
begin
 if FStream = NIL
   then Result := 0
   else Result := FWavHeader.BitsPerSample;
end;

function TWavLoader.GetDataSizeInByte: QWord;
begin
 Result := FWavDataByteLength;
end;

end.

