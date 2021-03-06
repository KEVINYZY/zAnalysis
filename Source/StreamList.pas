{ ****************************************************************************** }
{ * fast StreamQuery,writen by QQ 600585@qq.com                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }
(*
  update history
*)

unit StreamList;

{$INCLUDE zDefine.inc}

interface

uses SysUtils, ObjectDataManager, ItemStream, CoreClasses, PascalStrings, ListEngine;

type
  THashStreamList = class;

  THashStreamListData = packed record
    qHash: THash;
    LowerCaseName, OriginName: SystemString;
    stream: TItemStream;
    ItemHnd: TItemHandle;
    CallCount: Integer;
    ForceFreeCustomObject: Boolean;
    CustomObject: TCoreClassObject;
    ID: Integer;
    Owner: THashStreamList;
  end;

  PHashStreamListData = ^THashStreamListData;

  THashStreamList = class(TCoreClassObject)
  protected
    FCounter    : Boolean;
    FCount      : Integer;
    FName       : SystemString;
    FDescription: SystemString;
    FDBEngine   : TObjectDataManager;
    FFieldPos   : Int64;
    FAryList    : packed array of TCoreClassList;
    FData       : Pointer;

    function GetListTable(hash: THash; AutoCreate: Boolean): TCoreClassList;
    procedure RefreshDBLst(aDBEngine: TObjectDataManager; var aFieldPos: Int64);
  public
    constructor Create(aDBEngine: TObjectDataManager; aFieldPos: Int64);
    destructor Destroy; override;
    procedure Clear;
    procedure Refresh;
    procedure GetOriginNameListFromFilter(aFilter: SystemString; OutputList: TCoreClassStrings);
    procedure GetListFromFilter(aFilter: SystemString; OutputList: TCoreClassList);
    procedure GetOriginNameList(OutputList: TCoreClassStrings); overload;
    procedure GetOriginNameList(OutputList: TListString); overload;
    procedure GetList(OutputList: TCoreClassList);
    function Find(AName: SystemString): PHashStreamListData;
    function Exists(AName: SystemString): Boolean;

    procedure SetHashBlockCount(cnt: Integer);

    function GetItem(AName: SystemString): PHashStreamListData;
    property Names[AName: SystemString]: PHashStreamListData read GetItem; default;

    property DBEngine: TObjectDataManager read FDBEngine;
    property FieldPos: Int64 read FFieldPos;
    property Name: SystemString read FName write FName;
    property Description: SystemString read FDescription write FDescription;
    property Counter: Boolean read FCounter write FCounter;
    property Count: Integer read FCount;
    property Data: Pointer read FData write FData;
  end;

implementation

uses UnicodeMixedLib;

constructor THashStreamList.Create(aDBEngine: TObjectDataManager; aFieldPos: Int64);
begin
  inherited Create;
  FCounter := True;
  FCount := 0;
  FData := nil;
  SetLength(FAryList, 0);
  SetHashBlockCount(100);
  RefreshDBLst(aDBEngine, aFieldPos);
end;

destructor THashStreamList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure THashStreamList.Clear;
var
  i            : Integer;
  Rep_Int_Index: Integer;
begin
  FCount := 0;
  if length(FAryList) = 0 then
      Exit;

  for i := low(FAryList) to high(FAryList) do
    begin
      if FAryList[i] <> nil then
        begin
          with FAryList[i] do
            begin
              if Count > 0 then
                begin
                  for Rep_Int_Index := 0 to Count - 1 do
                    begin
                      with PHashStreamListData(Items[Rep_Int_Index])^ do
                        begin
                          if stream <> nil then
                            begin
                              DisposeObject(stream);
                              if (ForceFreeCustomObject) and (CustomObject <> nil) then
                                begin
                                  try
                                    DisposeObject(CustomObject);
                                    CustomObject := nil;
                                  except
                                  end;
                                end;
                            end;
                        end;
                      try
                          Dispose(PHashStreamListData(Items[Rep_Int_Index]));
                      except
                      end;
                    end;
                end;
            end;

          DisposeObject(FAryList[i]);
          FAryList[i] := nil;
        end;
    end;
end;

function THashStreamList.GetListTable(hash: THash; AutoCreate: Boolean): TCoreClassList;
var
  idx: Integer;
begin
  idx := hash mod length(FAryList);

  if (AutoCreate) and (FAryList[idx] = nil) then
      FAryList[idx] := TCoreClassList.Create;
  Result := FAryList[idx];
end;

procedure THashStreamList.RefreshDBLst(aDBEngine: TObjectDataManager; var aFieldPos: Int64);
var
  ItemSearchHnd: TItemSearch;
  ICnt         : Integer;

  procedure AddLstItem(_ItemPos: Int64);
  var
    newhash: THash;
    p      : PHashStreamListData;
    idxLst : TCoreClassList;
    lName  : SystemString;
    ItemHnd: TItemHandle;
  begin
    if FDBEngine.ItemFastOpen(_ItemPos, ItemHnd) then
      if umlGetLength(ItemHnd.Name) > 0 then
        begin
          lName := ItemHnd.Name.LowerText;
          newhash := MakeHash(lName);
          idxLst := GetListTable(newhash, True);
          new(p);
          p^.qHash := newhash;
          p^.LowerCaseName := lName;
          p^.OriginName := ItemHnd.Name;
          p^.stream := nil;
          p^.ItemHnd := ItemHnd;
          p^.CallCount := 0;
          p^.ForceFreeCustomObject := False;
          p^.CustomObject := nil;
          p^.ID := ICnt;
          p^.Owner := Self;
          idxLst.Add(p);
          Inc(ICnt);
        end;
  end;

begin
  FDBEngine := aDBEngine;
  FFieldPos := aFieldPos;
  FCount := 0;
  ICnt := 0;
  if FDBEngine.ItemFastFindFirst(FFieldPos, '*', ItemSearchHnd) then
    begin
      repeat
        Inc(FCount);
        AddLstItem(ItemSearchHnd.HeaderPOS);
      until not FDBEngine.ItemFastFindNext(ItemSearchHnd);
    end;
end;

procedure THashStreamList.Refresh;
begin
  Clear;
  RefreshDBLst(FDBEngine, FFieldPos);
end;

procedure THashStreamList.GetOriginNameListFromFilter(aFilter: SystemString; OutputList: TCoreClassStrings);
var
  i: Integer;
  L: TCoreClassList;
  p: PHashStreamListData;
begin
  L := TCoreClassList.Create;
  GetList(L);

  OutputList.Clear;
  if L.Count > 0 then
    for i := 0 to L.Count - 1 do
      begin
        p := PHashStreamListData(L[i]);
        if umlMultipleMatch(aFilter, p^.OriginName) then
            OutputList.Add(p^.OriginName);
      end;

  DisposeObject(L);
end;

procedure THashStreamList.GetListFromFilter(aFilter: SystemString; OutputList: TCoreClassList);
var
  i: Integer;
  L: TCoreClassList;
  p: PHashStreamListData;
begin
  L := TCoreClassList.Create;
  GetList(L);

  OutputList.Clear;
  if L.Count > 0 then
    for i := 0 to L.Count - 1 do
      begin
        p := PHashStreamListData(L[i]);
        if umlMultipleMatch(aFilter, p^.OriginName) then
            OutputList.Add(p);
      end;

  DisposeObject(L);
end;

procedure THashStreamList.GetOriginNameList(OutputList: TCoreClassStrings);
var
  i: Integer;
  L: TCoreClassList;
begin
  L := TCoreClassList.Create;
  GetList(L);

  OutputList.Clear;
  if L.Count > 0 then
    for i := 0 to L.Count - 1 do
        OutputList.Add(PHashStreamListData(L[i])^.OriginName);

  DisposeObject(L);
end;

procedure THashStreamList.GetOriginNameList(OutputList: TListString);
var
  i: Integer;
  L: TCoreClassList;
begin
  L := TCoreClassList.Create;
  GetList(L);

  OutputList.Clear;
  if L.Count > 0 then
    for i := 0 to L.Count - 1 do
        OutputList.Add(PHashStreamListData(L[i])^.OriginName);

  DisposeObject(L);
end;

procedure THashStreamList.GetList(OutputList: TCoreClassList);
  function ListSortCompare(Item1, Item2: Pointer): Integer;
    function aCompareValue(const A, b: Int64): Integer; inline;
    begin
      if A = b then
          Result := 0
      else if A < b then
          Result := -1
      else
          Result := 1;
    end;

  begin
    Result := aCompareValue(PHashStreamListData(Item1)^.ID, PHashStreamListData(Item2)^.ID);
  end;

  procedure QuickSortList(var SortList: TCoreClassPointerList; L, R: Integer);
  var
    i, J: Integer;
    p, T: Pointer;
  begin
    repeat
      i := L;
      J := R;
      p := SortList[(L + R) shr 1];
      repeat
        while ListSortCompare(SortList[i], p) < 0 do
            Inc(i);
        while ListSortCompare(SortList[J], p) > 0 do
            Dec(J);
        if i <= J then
          begin
            if i <> J then
              begin
                T := SortList[i];
                SortList[i] := SortList[J];
                SortList[J] := T;
              end;
            Inc(i);
            Dec(J);
          end;
      until i > J;
      if L < J then
          QuickSortList(SortList, L, J);
      L := i;
    until i >= R;
  end;

var
  i            : Integer;
  Rep_Int_Index: Integer;
begin
  OutputList.Clear;

  if Count > 0 then
    begin
      OutputList.Capacity := Count;

      for i := low(FAryList) to high(FAryList) do
        begin
          if FAryList[i] <> nil then
            begin
              with FAryList[i] do
                if Count > 0 then
                  begin
                    for Rep_Int_Index := 0 to Count - 1 do
                      with PHashStreamListData(Items[Rep_Int_Index])^ do
                        begin
                          if stream = nil then
                              stream := TItemStream.Create(FDBEngine, ItemHnd)
                          else
                              stream.SeekStart;
                          if FCounter then
                              Inc(CallCount);
                          OutputList.Add(Items[Rep_Int_Index]);
                        end;
                  end;
            end;
        end;

      if OutputList.Count > 1 then
          QuickSortList(OutputList.ListData^, 0, OutputList.Count - 1);
    end;
end;

function THashStreamList.Find(AName: SystemString): PHashStreamListData;
var
  i            : Integer;
  Rep_Int_Index: Integer;
begin
  Result := nil;
  for i := low(FAryList) to high(FAryList) do
    begin
      if FAryList[i] <> nil then
        begin
          with FAryList[i] do
            if Count > 0 then
              begin
                for Rep_Int_Index := 0 to Count - 1 do
                  begin
                    if umlMultipleMatch(True, AName, PHashStreamListData(Items[Rep_Int_Index])^.OriginName) then
                      begin
                        Result := Items[Rep_Int_Index];
                        if Result^.stream = nil then
                            Result^.stream := TItemStream.Create(FDBEngine, Result^.ItemHnd)
                        else
                            Result^.stream.SeekStart;
                        if FCounter then
                            Inc(Result^.CallCount);
                        Exit;
                      end;
                  end;
              end;
        end;
    end;
end;

function THashStreamList.Exists(AName: SystemString): Boolean;
var
  newhash: THash;
  i      : Integer;
  idxLst : TCoreClassList;
  lName  : SystemString;
begin
  Result := False;
  if umlGetLength(AName) > 0 then
    begin
      lName := LowerCase(AName);
      newhash := MakeHash(lName);
      idxLst := GetListTable(newhash, False);
      if idxLst <> nil then
        if idxLst.Count > 0 then
          for i := 0 to idxLst.Count - 1 do
            if (newhash = PHashStreamListData(idxLst[i])^.qHash) and (PHashStreamListData(idxLst[i])^.LowerCaseName = lName) then
                Exit(True);
    end;
end;

procedure THashStreamList.SetHashBlockCount(cnt: Integer);
var
  i: Integer;
begin
  Clear;
  SetLength(FAryList, cnt);
  for i := low(FAryList) to high(FAryList) do
      FAryList[i] := nil;
end;

function THashStreamList.GetItem(AName: SystemString): PHashStreamListData;
var
  newhash: THash;
  i      : Integer;
  idxLst : TCoreClassList;
  lName  : SystemString;
begin
  Result := nil;
  if umlGetLength(AName) > 0 then
    begin
      lName := LowerCase(AName);
      newhash := MakeHash(lName);
      idxLst := GetListTable(newhash, False);
      if idxLst <> nil then
        if idxLst.Count > 0 then
          for i := 0 to idxLst.Count - 1 do
            begin
              if (newhash = PHashStreamListData(idxLst[i])^.qHash) and (PHashStreamListData(idxLst[i])^.LowerCaseName = lName) then
                begin
                  Result := idxLst[i];
                  if Result^.stream = nil then
                      Result^.stream := TItemStream.Create(FDBEngine, Result^.ItemHnd)
                  else
                      Result^.stream.SeekStart;
                  if FCounter then
                      Inc(Result^.CallCount);
                  Exit;
                end;
            end;
    end;
end;

end. 
