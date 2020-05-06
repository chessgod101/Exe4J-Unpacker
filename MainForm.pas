unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI;

type
  Texe4jupFrmMain = class(TForm)
    UnpackBtn: TButton;
    FilePathEdit: TEdit;
    ChooseBtn: TButton;
    OpenDialog1: TOpenDialog;
    Label1: TLabel;
    WebsiteButton: TButton;
    OWCheckBox: TCheckBox;
    procedure UnpackBtnClick(Sender: TObject);
    procedure ChooseBtnClick(Sender: TObject);
    procedure WebsiteButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  protected
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
  end;

type sHeader=packed record
sType:Cardinal;
sLength:Cardinal;
end;
Type psHeader=^sHeader;

var
  exe4jupFrmMain: Texe4jupFrmMain;
MainClass,FileNames:ansiString;

FileNamesA:array of ansiString;
implementation

Function GetOffsetOfAppendedData(fH:THandle;Var offset:Cardinal):Boolean;
var
dh:tImageDosHeader;
pe:timageFileHeader;
secH:TImageSectionHeader;
tmp:Cardinal;
Begin
result:=false;
offset:=0;
SetFilePointer(fH,0,nil,FILE_BEGIN);
if ReadFile(fH,dh,sizeof(TImageDosHeader),tmp,nil)=true then begin
if dh.e_magic=23117 then begin
SetFilePointer(fH,dh._lfanew+4,nil,FILE_BEGIN);
if ReadFile(fH,pe,sizeof(TImageFileHeader),tmp,nil)=true then begin
SetFilePointer(fH,pe.SizeOfOptionalHeader+(sizeof(TImageSectionHeader)*(pe.NumberOfSections-1)),nil,FILE_CURRENT);
if ReadFile(fH,secH,sizeof(TImageSectionHeader),tmp,nil)=true then begin
offset:=secH.SizeOfRawData+secH.PointerToRawData;
result:=true;
end;
end;
end;
end;
End;

{$R *.dfm}
Function SaveFile(FileName:wideString;data:Pbyte;size:Cardinal;overwrite:Boolean):Boolean;
var
fh:THandle;
tmp:cardinal;
Begin
result:=false;
 if overwrite=true then
 tmp:=CREATE_ALWAYS
 else
 tmp:=CREATE_NEW;
fh:=CreateFileW(@FileName[1],GENERIC_WRITE,0,NIL,tmp,FILE_ATTRIBUTE_NORMAL,0);
if fh<>INVALID_HANDLE_VALUE then begin
if WriteFile(fh,data[0],size,tmp,nil)=true then
result:=true;
CloseHandle(fh);
end;
End;

Function ParseFileNames():cardinal;
var
I,len,nstr,count:cardinal;
Begin
result:=0;
len:=length(FileNames);
if len=0 then exit;
nstr:=1;
count:=0;
for I := 1 to len do begin
if FileNames[I]=ansiChar(';') then begin
 inc(count);
setlength(FileNamesA,count);
setLength(FileNamesA[count-1],I-nstr);
CopyMemory(@FileNamesA[count-1][1],@FileNames[nstr],I-nstr);
nstr:=I+1;
end;
end;
result:=count;
end;


procedure DecryptSection(buffer:PByte;len:Cardinal);
var
I:Cardinal;
Begin
dec(len);
for I := 0 to len do
buffer[I]:=buffer[I] xor $88;
End;



Function TraceStrings(buffer:PByte;strCount:cardinal):PByte;
var
pshdr:psHeader;
I:Cardinal;
Begin
for I := 1 to strcount do begin
pshdr:=psHeader(@buffer[0]);
buffer:=@buffer[8];
case pshdr.sType of
$7A:
Begin
 setlength(mainClass,pshdr.sLength);
 CopyMemory(@mainClass[1],buffer,pshdr.sLength);
End;
$07d3:
Begin
 setlength(FileNames,pshdr.sLength);
 CopyMemory(@FileNames[1],buffer,pshdr.sLength);
End;
end;
buffer:=@buffer[pshdr.sLength];
end;
result:=buffer;
End;

Procedure UnpackExe4J(fName:WideString;Overwrite:Boolean);
var
tmp,aOffset,fLength,sLength,fcount,I:Cardinal;
unpDir:WideString;
fH:THandle;
buffer:Array of byte;
fByte:PByte;
begin
MainClass:='';
Setlength(FileNamesA,0);
FileNames:='';
if FileExists(fName)=false then Begin
MessageBox(Application.Handle,PChar('File not found!'),PChar('exe4j Unpacker'),MB_OK) ;
End;

unpDir:=ExtractFilePath(fName)+'unpacked_files\';

if forceDirectories(unpDir)=false then begin
MessageBox(Application.Handle,PChar('Failed to Force Directories!'),PChar('exe4j Unpacker'),MB_OK) ;
exit;
End;

fH:=CreateFile(@fName[1],GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
if fH=INVALID_HANDLE_VALUE then Begin
MessageBox(Application.Handle,PChar('Failed to Open File!'),PChar('exe4j Unpacker'),MB_OK) ;
exit;
End;


if GetOffsetOfAppendedData(fH,aoffset)=false then begin
MessageBox(Application.Handle,PChar('Failed to retrieve offset of appended data.'),PChar('exe4j Unpacker'),MB_OK) ;
CloseHandle(fH);
exit;
end;

fLength:=GetFileSize(fH,nil);

if fLength<=aOffset then begin
MessageBox(Application.Handle,PChar('No Appended Data. Not an exe4j File.'),PChar('exe4j Unpacker'),MB_OK) ;
CloseHandle(fH);
exit;
End;

SetFilePointer(fH,aOffset,nil,FILE_BEGIN);
sLength:=fLength-aOffset;
setLength(buffer,sLength);

if ReadFile(fH,buffer[0],sLength,tmp,nil)=false then begin
MessageBox(Application.Handle,PChar('No Appended Data. Not an exe4j File.'),PChar('exe4j Unpacker'),MB_OK) ;
CloseHandle(fH);
exit;
End;

CloseHandle(fH);
if Cardinal(pCardinal(@buffer[0])^)<>$E8E413D5 then begin
MessageBox(Application.Handle,PChar('Identifier Value Mismatch. Not an exe4j File.'),PChar('exe4j Unpacker'),MB_OK) ;
exit;
End;

tmp:=Cardinal(pCardinal(@buffer[$14])^);//getStrCount
fByte:=TraceStrings(@buffer[$18],tmp);
if Cardinal(pCardinal(@fByte[0])^)<>0 then begin
tmp:=Cardinal(pCardinal(@fbyte[$0])^);//getStrCount
fByte:=TraceStrings(@fbyte[4],tmp);
end
else fByte:=@fByte[4];

if Cardinal(pCardinal(@fByte[0])^)<>0 then begin
MessageBox(Application.Handle,PChar('Extra Header Found. Please email the file to chessgod101<@>gmail.com so I can add support for it.'),PChar('exe4j Unpacker'),MB_OK) ;
exit;
end;
fCount:=ParseFileNames-1;

fByte:=@fByte[4];
for I := 0 to fcount do begin
tmp:=Cardinal(pCardinal(@fByte[0])^);
DecryptSection(@fByte[8],tmp);
SaveFile(unpDir+WideString(FileNamesA[I]),@fByte[8],tmp,overwrite);
fByte:=@fByte[8+tmp];
end;

if length(MainClass)>0 then
SaveFile(unpDir+'mainclass.txt',@MainClass[1],length(MainClass),overwrite);

MessageBeep(MB_ICONINFORMATION);
MessageBox(Application.Handle,PChar('Done! Check upacked_files folder in app directory.'),PChar('exe4j Unpacker'), MB_OK);
end;

procedure Texe4jupFrmMain.UnpackBtnClick(Sender: TObject);
Begin
UnpackExe4J(FilePathEdit.Text,OWCheckBox.Checked);

end;

procedure Texe4jupFrmMain.ChooseBtnClick(Sender: TObject);
begin
if OpenDialog1.Execute=true then
FilePathEdit.Text:=OpenDialog1.FileName;
end;

procedure Texe4jupFrmMain.WebsiteButtonClick(Sender: TObject);
begin
ShellExecute(0, NIL, PWideChar('http://www.reverseengineeringtips.blogspot.com/'),NIL,NIL, 0);
end;

procedure Texe4jupFrmMain.FormCreate(Sender: TObject);
begin
DragAcceptFiles(Handle,true);
end;

procedure Texe4jupFrmMain.FormDestroy(Sender: TObject);
begin
DragAcceptFiles(Handle,false);
end;

procedure Texe4jupFrmMain.WMDropFiles(var Msg: TMessage);
var
l:cardinal;
s,ext:string;
Begin
l:=DragQueryFile(Msg.WParam,0,nil,0)+1;
SetLength(s,l);
DragQueryFile(Msg.WParam,0,Pointer(s),l);
ext:= lowercase(TrimRight(ExtractFileExt(s)));
if ext='.exe' then
FilePathEdit.Text:=s;
End;

end.
