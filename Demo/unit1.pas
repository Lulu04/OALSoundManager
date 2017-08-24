unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Spin, Buttons,
  OALSoundManager,
  VelocityCurve;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    CheckBox1: TCheckBox;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    FSE1: TFloatSpinEdit;
    FSE2: TFloatSpinEdit;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    OD1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    ProgressBar1: TProgressBar;
    Timer1: TTimer;
    TrackBar1: TTrackBar;
    TrackBar2: TTrackBar;
    procedure BitBtn1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
  private
    FSound: TOALSound;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
 if FSound = NIL then exit;
 FSound.Play;
 FSound.Volume.Value := oal_VOLUME_MAX;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
 if not OD1.Execute then exit;

 Label11.Caption := ExtractFileName( OD1.FileName );

 if FSound <> NIL then OALManager.Delete( FSound );

 FSound := OALManager.Add( OD1.FileName );

 if FSound.GetFileError = oal_ERR_NOTWAVFILE
   then showmessage('Only wav files can be played by this library...');

// if ( FSound.BitsPerSample <> 8 ) and ( FSound.BitsPerSample <> 16 )
 if FSound.GetFileError = oal_ERR_BADBITPERSAMPLE
   then Showmessage('Only 8 or 16 bits per samples are supported.'+lineending+
                    Label11.Caption+' is '+inttostr(FSound.BitsPerSample)+
                    ' bits per sample');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 if FSound = NIL then exit;
 if FSound <> nil then FSound.Pause;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 if FSound = NIL then exit;
 if FSound <> nil then FSound.Stop;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
 if FSound = NIL then exit;
 FSound.FadeIn( oal_VOLUME_MAX, FSE1.Value, ComboBox1.ItemIndex );
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
 if FSound = NIL then exit;
 FSound.FadeOut( FSE2.Value, ComboBox2.ItemIndex );
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
 TrackBar2.Position := 100;
end;

procedure TForm1.CheckBox1Change(Sender: TObject);
begin
 if FSound = NIL then exit;
 FSound.Loop := CheckBox1.Checked;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var i: integer;
begin
 i := ComboBox1.ItemIndex;
 if i = -1 then exit;
 VelocityCurveList.GetCurveByIndex( i ).DrawOn( Image1 );
end;

procedure TForm1.ComboBox2Change(Sender: TObject);
var i: integer;
begin
  i := ComboBox2.ItemIndex;
  if i = -1 then exit;
 VelocityCurveList.GetCurveByIndex( i ).DrawOn( Image2 );
end;

procedure TForm1.FormShow(Sender: TObject);
var i: integer;
begin
  if not OALManager.OpenALLibraryLoaded then
    ShowMessage('Can not play sounds, Openal is not installed on your computer' + LINEENDING +
      'You should go on www.openal.org to install it. It''s free !');

  // fill the combo box with available velocity curve list
  ComboBox1.Clear;
  ComboBox2.Clear;
  for i:=0 to VelocityCurveList.Count-1 do
   begin
    ComboBox1.Items.Add( VelocityCurveList.GetCurveByIndex( i ).Name );
    ComboBox2.Items.Add( VelocityCurveList.GetCurveByIndex( i ).Name );
   end;
  ComboBox1.ItemIndex := 0;
  ComboBox2.ItemIndex := 1;
  ComboBox1Change( self );
  ComboBox2Change( self );
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  s: string;
begin
  if FSound = NIL then begin
    Label1.Caption := '';
    Label4.Caption := '';
    exit;
  end;

  if FSound.GetFileError <> oal_NOERROR then exit;

  Label1.Caption := 'channel: ' + IntToStr(FSound.ChannelCount) + '  time: ' +
    formatfloat('0.00', FSound.GetTimePosition) + ' / ' + formatfloat(
    '0.00', FSound.TotalDuration) + '  at ' + IntToStr(FSound.Frequency) + 'Hz';

  ProgressBar1.Max := FSound.Seconds2Byte( FSound.TotalDuration ); // FSound.SampleCount div FSound.ChannelCount;
  ProgressBar1.Position := FSound.Seconds2Byte( FSound.GetTimePosition );

  case FSound.State of
    AL_INITIAL: s := 'INITIAL';
    AL_STOPPED: s := 'STOPPED';
    AL_PLAYING: s := 'PLAYING';
    AL_PAUSED: s := 'PAUSED';
  end;
  Label4.Caption := 'State : ' + s;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
 if FSound = NIL then exit;
 FSound.Volume.Value := TrackBar1.Position;
end;

procedure TForm1.TrackBar2Change(Sender: TObject);
begin
 if FSound = NIL then exit;
 FSound.Pitch.Value := TrackBar2.Position / 100;
 Label3.Caption := 'Pitch : ' + formatfloat('0.00', FSound.Pitch.Value);
end;


end.
