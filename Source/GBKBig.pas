{ ****************************************************************************** }
{ * GBK with Big text data support,  written by QQ 600585@qq.com               * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }
unit GBKBig;

interface

{$INCLUDE zDefine.inc}


uses DoStatusIO, CoreClasses, PascalStrings, MemoryStream64, ListEngine, UnicodeMixedLib,
  UPascalStrings;

procedure BigKeyAnalysis(const Analysis: THashVariantList);
function BigKey(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer;
function BigKeyValue(const s: TUPascalString; const MatchSingleWord: Boolean; const Analysis: THashVariantList): Integer;
function BigKeyWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString;

function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer; overload;
function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString; overload;

implementation

uses GBKMediaCenter, GBK, GBKVec;

type
  TBigKeyAnalysis = class
    output: THashVariantList;
    procedure doProgress(Sender: THashStringList; Name: PSystemString; const v: SystemString);
  end;

procedure TBigKeyAnalysis.doProgress(Sender: THashStringList; Name: PSystemString; const v: SystemString);
begin
  umlSeparatorText(v, output, ',;'#9);
end;

procedure BigKeyAnalysis(const Analysis: THashVariantList);
var
  tmp: TBigKeyAnalysis;
begin
  tmp := TBigKeyAnalysis.Create;
  tmp.output := Analysis;
  {$IFDEF FPC}
  bigKeyDict.Progress(@tmp.doProgress);
  {$ELSE FPC}
  bigKeyDict.Progress(tmp.doProgress);
  {$ENDIF FPC}
  DisposeObject(tmp);
end;

function BigKey(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer;
var
  ns, N2   : TUPascalString;
  i, J     : Integer;
  Successed: Boolean;
begin
  ns := GBKString(s);
  Result := 0;

  i := 1;
  while i <= ns.Len do
    begin
      Successed := False;
      J := umlMin(bigKeyDict.HashList.MaxNameLen, ns.Len - i);
      while J > 1 do
        begin
          N2 := ns.Copy(i, J);
          Successed := bigKeyDict.Exists(N2);
          if Successed then
            begin
              Completed.Add(N2.Text);
              Inc(Result);
              Inc(i, J);
              Break;
            end;
          Dec(J);
        end;

      if not Successed then
        begin
          Successed := MatchSingleWord and bigKeyDict.Exists(ns[i]);
          if Successed then
            begin
              Completed.Add(ns[i]);
              Inc(Result);
            end
          else
            begin
              Unidentified.Add(ns[i]);
            end;
          Inc(i);
        end;
    end;
end;

function BigKeyValue(const s: TUPascalString; const MatchSingleWord: Boolean; const Analysis: THashVariantList): Integer;
var
  Unidentified: TListPascalString;
  Completed   : TListPascalString;
  i           : Integer;
begin
  Analysis.Clear;
  Unidentified := TListPascalString.Create;
  Completed := TListPascalString.Create;
  Result := BigKey(s, MatchSingleWord, Unidentified, Completed);
  if Result > 0 then
    for i := 0 to Completed.Count - 1 do
        umlSeparatorText(bigKeyDict.GetDefaultValue(Completed[i], ''), Analysis, ',;'#9);
  DisposeObject([Unidentified, Completed]);
end;

function BigKeyWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString;
var
  Unidentified: TListPascalString;
  Completed   : TListPascalString;
  i           : Integer;
begin
  Result := '';
  Unidentified := TListPascalString.Create;
  Completed := TListPascalString.Create;
  if BigKey(s, MatchSingleWord, Unidentified, Completed) > 0 then
    begin
      for i := 0 to Completed.Count - 1 do
        begin
          if Result.Len > 0 then
              Result.Append(',');
          Result.Append(Completed[i]);
        end;
    end;
  DisposeObject([Unidentified, Completed]);
end;

function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer;
var
  ns, N2   : TUPascalString;
  i, J     : Integer;
  Successed: Boolean;
begin
  ns := GBKString(s);
  Result := 0;

  i := 1;
  while i <= ns.Len do
    begin
      Successed := False;
      J := umlMin(bigWordDict.MaxNameLen, ns.Len - i);
      while J > 1 do
        begin
          N2 := ns.Copy(i, J);
          Successed := bigWordDict.Exists(N2);
          if Successed then
            begin
              Completed.Add(N2.Text);
              Inc(Result);
              Inc(i, J);
              Break;
            end;
          Dec(J);
        end;

      if not Successed then
        begin
          Successed := MatchSingleWord and bigWordDict.Exists(ns[i]);
          if Successed then
            begin
              Completed.Add(ns[i]);
              Inc(Result);
            end
          else
            begin
              Unidentified.Add(ns[i]);
            end;
          Inc(i);
        end;
    end;
end;

function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString;
var
  Unidentified: TListPascalString;
  Completed   : TListPascalString;
  i           : Integer;
begin
  Result := '';
  Unidentified := TListPascalString.Create;
  Completed := TListPascalString.Create;
  if BigWord(s, MatchSingleWord, Unidentified, Completed) > 0 then
    begin
      for i := 0 to Completed.Count - 1 do
        begin
          if Result.Len > 0 then
              Result.Append(',');
          Result.Append(Completed[i]);
        end;
    end;
  DisposeObject([Unidentified, Completed]);
end;

initialization

end. 
