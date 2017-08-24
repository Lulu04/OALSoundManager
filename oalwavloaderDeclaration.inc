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

type


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
  FWavHeaderInitialized: boolean;
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


