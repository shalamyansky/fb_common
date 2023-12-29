(*
    Unit       : fbudr
    Date       : 2023-01-05
    Compiler   : Delphi XE3, Delphi 12
    ©Copyright : Shalamyansky Mikhail Arkadievich
    Contents   : Firebird UDR most common routines
    Project    : https://github.com/shalamyansky/fb_common
    Company    : BWR
*)
unit fbutils;

interface

uses
    SysUtils
;

function MAKEINT64( lo, hi : LONGWORD ):INT64;
function IfString( Condition:BOOLEAN; TrueValue:UnicodeString; FalseValue:UnicodeString = '' ):UnicodeString;
function FileToBytes( Handle:THandle; out Content:TBytes ):BOOLEAN; overload;
function FileToBytes( FilePath:UnicodeString; out Content:TBytes ):BOOLEAN; overload;
function ReadFile( Path:UnicodeString; out Content:TBytes ):BOOLEAN;
function ReadZipEntry( ZipPath:UnicodeString; Entry:UnicodeString; out Content:TBytes ):BOOLEAN;


implementation

uses
    System.Zip
;

function MAKEINT64( lo, hi : LONGWORD ):INT64;
begin
    Result := INT64( lo ) or ( INT64( hi ) shl 32 );
end;{ MAKEINT64 }

function IfString( Condition:BOOLEAN; TrueValue:UnicodeString; FalseValue:UnicodeString = '' ):UnicodeString;
begin
    if Condition then begin
        Result := TrueValue;
    end else begin
        Result := FalseValue;
    end;
end;{ IfString }

function FileToBytes( Handle:THandle; out Content:TBytes ):BOOLEAN; overload;
var
    Size : LONGINT;
begin
    Result := FALSE;
    System.Finalize( Content );
    if( Handle >= 0 )then begin
        Result := TRUE;
        Size   := SysUtils.FileSeek( Handle, 0, 2 );
        if( Size > 0 )then begin
          SysUtils.FileSeek( Handle, 0, 0 ); //return to the beginning of the file
            SetLength( Content, Size );
            Result := ( Size = SysUtils.FileRead( Handle, POINTER( Content )^, Size ) );
            if( not Result )then begin
                System.Finalize( Content );
            end;
        end;
    end;
end;{ FileToBytes }

function FileToBytes( FilePath:UnicodeString; out Content:TBytes ):BOOLEAN; overload;
var
    Handle : THandle;
begin
    Result := FALSE;
    System.Finalize( Content );
    Handle := INVALID_HANDLE_VALUE;
    try
        Handle := SysUtils.FileOpen( FilePath, fmOpenRead or fmShareDenyWrite );
        if( Handle <> INVALID_HANDLE_VALUE )then begin
            Result := FileToBytes( Handle, Content );
        end;
    finally
        if( Handle <> INVALID_HANDLE_VALUE )then begin
            FileClose( Handle );
        end;
    end;
end;{ FileToBytes }

function ReadZipEntry( ZipPath:UnicodeString; Entry:UnicodeString; out Content:TBytes ):BOOLEAN;
var
    Zipper : TZipFile;
begin
    Result := FALSE;
    System.Finalize( Content );
    try
        try
            Zipper := nil;
            Zipper := TZipFile.Create;
            Zipper.Open( ZipPath, zmRead );
            Zipper.Read( Entry, Content );
            Result := TRUE;
        finally
            Zipper.Free;
            Zipper := nil;
        end;
    except
        Result := FALSE;
        System.Finalize( Content );
    end;
end;{ ReadZipEntry }

function ReadFile( Path:UnicodeString; out Content:TBytes ):BOOLEAN;
const
  {$IFDEF MSWINDOWS}
    trueSlash = '\';
    wrngSlash = '/';
  {$ELSE}
    trueSlash = '/';
    wrngSlash = '\';
  {$ENDIF}
var
    FileName, Tail : UnicodeString;
begin
    Result := FALSE;
    System.Finalize( Content );
    Tail := '';
    Path := StringReplace( Path, wrngSlash, trueSlash, [ rfReplaceAll ] );
    while( TRUE )do begin
        if( ( Path = '' ) or DirectoryExists( Path ) )then begin  //Path is directory - nothing to do
            break;
        end else if( FileExists( Path ) )then begin               //Path is file - read it
            if( Tail = '' )then begin
                Result := FileToBytes( Path, Content );
            end else begin
                Result := ReadZipEntry( Path, Tail, Content );
            end;
            break;
        end else begin                                            //Path does not exist - maybe it is archive inside?
            FileName := SysUtils.ExtractFileName( Path );
            if( FileName = '' )then begin
                break;
            end;
            Tail := FileName + IfString( Tail <> '', '/', '' ) + Tail;
            Path := SysUtils.ExtractFileDir( Path );
        end;
    end;
end;{ ReadFile }


end.
