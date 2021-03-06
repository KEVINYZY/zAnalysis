{ ****************************************************************************** }
{ * ZDBLocal , createby qq600585                                               * }
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
unit ZDBLocalManager;

{$INCLUDE zDefine.inc}

interface

uses SysUtils, Variants,
  CoreClasses, ListEngine, UnicodeMixedLib, DataFrameEngine, MemoryStream64, TextDataEngine,
{$IFNDEF FPC}
  JsonDataObjects,
{$ENDIF}
  DoStatusIO, Cadencer, NotifyObjectBase, PascalStrings, CoreCipher, ZDBEngine, ItemStream;

type
  TZDBStoreEngine = class(TDBStoreBase)
  protected
    FName: SystemString;
    FLastModifyTime: TTimeTickValue;
    procedure DoCreateInit; override;
  public
    property Name: SystemString read FName;
  end;

  TZDBLocalManager = class;
  TZDBPipeline     = class;

  TZDBPipelineFilterCall   = procedure(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
  TZDBPipelineFilterMethod = procedure(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean) of object;

  TZDBPipelineDoneCall   = procedure(dPipe: TZDBPipeline);
  TZDBPipelineDoneMethod = procedure(dPipe: TZDBPipeline) of object;

{$IFNDEF FPC}
  TZDBPipelineFilterProc = reference to procedure(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
  TZDBPipelineDoneProc   = reference to procedure(dPipe: TZDBPipeline);
{$ENDIF}

  TZDBStorePosTransform = record
    OriginPos, NewPos: Int64;
  end;

  PZDBStorePosTransform = ^TZDBStorePosTransform;

  TZDBStorePosTransformArray = array of TZDBStorePosTransform;
  PZDBStorePosTransformArray = ^TZDBStorePosTransformArray;

  TZDBStorePosTransformNotify = procedure(const Data: Pointer; const TransformBuff: PZDBStorePosTransformArray) of object;

  TZDBPipeline = class(TCoreClassInterfacedObject)
  private
    FQueryCounter: Int64;
    FCurrentFragmentTime: TTimeTickValue;
    FFragmentBuffer: TMemoryStream64;
    FActivted: Boolean;
    FQueryTask: TQueryTask;
    FPerformaceCounter: nativeInt;
    FLastPerformaceTime: TTimeTickValue;
    FQueryCounterOfPerSec: Double;
    FRealTimePostFragmentData: Boolean;
    FQueryResultCounter: Int64;
    FStorePosTransformList: TCoreClassList;

    procedure Query(var qState: TQueryState);
    procedure QueryDone();

    procedure WriteToOutput(DBEng: TDBStoreBase; StorePos: Int64; ID: Cardinal);
    procedure PostFragmentData(forcePost: Boolean); {$IFDEF INLINE_ASM} inline; {$ENDIF}
  public
    Owner: TZDBLocalManager;
    SourceDB: TZDBStoreEngine;
    OutputDB: TZDBStoreEngine;
    SourceDBName, OutputDBName, PipelineName: SystemString;

    // query options
    WriteResultToOutputDB: Boolean; // result write to output
    AutoDestroyDB: Boolean;         // complete time destroy DB
    FragmentWaitTime: Double;       // fragment time,realtime send to client
    MaxWaitTime: Double;            // max wait complete time,query to abort from out time
    MaxQueryCompare: Int64;         // max query compare
    MaxQueryResult: Int64;          // max query result
    QueryDoneFreeDelayTime: Double; // delay free query pipeline
    WriteFragmentBuffer: Boolean;   // write fragment buffer

    OnDataFilterCall: TZDBPipelineFilterCall;
    OnDataFilterMethod: TZDBPipelineFilterMethod;

    OnDataDoneCall: TZDBPipelineDoneCall;
    OnDataDoneMethod: TZDBPipelineDoneMethod;
{$IFNDEF FPC}
    OnDataFilterProc: TZDBPipelineFilterProc;
    OnDataDoneProc: TZDBPipelineDoneProc;
{$ENDIF}
    OnStorePosTransform: TZDBStorePosTransformNotify;
    //
    //
    values: THashVariantList;
    DataEng: TDataFrameEngine;
    UserPointer: Pointer;
    UserObject: TCoreClassObject;
    UserVariant: Variant;
  public
    procedure InitOptions;

    constructor Create(InMem: Boolean; AOwner: TZDBLocalManager; sourDBName, APipelineN, OutDBName: SystemString); virtual;

    destructor Destroy; override;

    procedure Progress(deltaTime: Double); virtual;

    procedure ClearStorePosTransform;
    procedure AddStorePosTransform(OriginPos, NewPos: Int64);
    function StorePosTransformCount: Integer;
    function GetStorePosTransform(const index: Integer): PZDBStorePosTransform;
    property StorePosTransform[const index: Integer]: PZDBStorePosTransform read GetStorePosTransform;

    procedure stop; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure Pause; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure Play; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function Paused: Boolean; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function QueryConsumTime: Double; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    property Activted: Boolean read FActivted;
    property QueryCounterOfPerSec: Double read FQueryCounterOfPerSec;
    property RealTimePostFragmentData: Boolean read FRealTimePostFragmentData write FRealTimePostFragmentData;
    property QueryCounter: Int64 read FQueryCounter;
    property QueryResultCounter: Int64 read FQueryResultCounter;
  end;

  TZDBPipelineClass = class of TZDBPipeline;

  IZDBLocalManagerNotify = interface
    procedure CreateQuery(pipe: TZDBPipeline);
    procedure QueryFragmentData(pipe: TZDBPipeline; FragmentSource: TMemoryStream64);
    procedure QueryDone(pipe: TZDBPipeline);
    procedure CreateDB(ActiveDB: TZDBStoreEngine);
    procedure CloseDB(ActiveDB: TZDBStoreEngine);
    procedure InsertData(Sender: TZDBStoreEngine; InsertPos: Int64; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64);
    procedure AddData(Sender: TZDBStoreEngine; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64);
    procedure ModifyData(Sender: TZDBStoreEngine; const StorePos: Int64; buff: TCoreClassStream);
    procedure DeleteData(Sender: TZDBStoreEngine; const StorePos: Int64);
  end;

  TCompressDoneNotify = record
    OnStorePosTransform: TZDBStorePosTransformNotify;
    Data: Pointer;
    TransformBuff: TZDBStorePosTransformArray;
  end;

  PCompressDoneNotify = ^TCompressDoneNotify;

  TZDBLocalManager = class(TCoreClassInterfacedObject, IDBStoreBaseNotify, ICadencerProgressInterface)
  protected
    FRootPath: SystemString;
    FDBPool: THashObjectList;
    FQueryPipelinePool: THashObjectList;
    FQueryPipelineList: TCoreClassListForObj;
    FTaskCounter: Cardinal;
    FCadencerEng: TCadencer;
    FProgressPost: TNProgressPost;
    FPipelineClass: TZDBPipelineClass;
    FNotifyIntf: IZDBLocalManagerNotify;
  protected
    // zdbEngine trigger
    procedure DoInsertData(Sender: TDBStoreBase; InsertPos: Int64; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64); virtual;
    procedure DoAddData(Sender: TDBStoreBase; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64); virtual;
    procedure DoModifyData(Sender: TDBStoreBase; const StorePos: Int64; buff: TCoreClassStream); virtual;
    procedure DoDeleteData(Sender: TDBStoreBase; const StorePos: Int64); virtual;
  protected
    // canencer trigger
    procedure ZDBEngProgress(const Name: PSystemString; Obj: TCoreClassObject);
    procedure CadencerProgress(const deltaTime, newTime: Double);
  protected
    procedure DoQueryFragmentData(pipe: TZDBPipeline; FragmentSour: TMemoryStream64); virtual;
    procedure DoQueryDone(pipe: TZDBPipeline); virtual;
    procedure DelayFreePipe(Sender: TNPostExecute); virtual;

    procedure DoQueryCopy(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
    procedure DoCopyDone(dPipe: TZDBPipeline);
    procedure DoCompressDone(dPipe: TZDBPipeline);
    procedure DelayReplaceDB(Sender: TNPostExecute);
  public
    constructor Create;
    destructor Destroy; override;

    property PipelineClass: TZDBPipelineClass read FPipelineClass write FPipelineClass;
    property NotifyIntf: IZDBLocalManagerNotify read FNotifyIntf write FNotifyIntf;

    procedure Clear;
    procedure LoadDB(ReadOnly: Boolean);
    procedure SetRootPath(const Value: SystemString);
    property RootPath: SystemString read FRootPath write SetRootPath;

    procedure Progress; virtual;
    property ProgressPost: TNProgressPost read FProgressPost;

    // local operation
    function InitDB(dbN: SystemString): TZDBStoreEngine; overload;
    function InitDB(dbN: SystemString; ReadOnly: Boolean): TZDBStoreEngine; overload;
    function InitNewDB(dbN: SystemString): TZDBStoreEngine;
    function InitMemoryDB(dbN: SystemString): TZDBStoreEngine;
    procedure CloseDB(dbN: SystemString);
    procedure CloseAndDeleteDB(dbN: SystemString);

    // async operation
    function CopyDB(SourN, DestN: SystemString): TZDBPipeline; overload;
    function CopyDB(SourN, DestN: SystemString; const UserData: Pointer; const OnStorePosTransform: TZDBStorePosTransformNotify): TZDBPipeline; overload;
    function CompressDB(dbN: SystemString): TZDBPipeline; overload;
    function CompressDB(dbN: SystemString; const UserData: Pointer; const OnStorePosTransform: TZDBStorePosTransformNotify): TZDBPipeline; overload;

    procedure ReplaceDB(dbN, replaceN: SystemString);
    procedure ResetData(dbN: SystemString);

    // cleaup all cache
    procedure Recache;

    // container operation
    function GenerateTaskName: SystemString; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function GenerateNewTaskName: SystemString; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function GetPipeline(pipeName: SystemString): TZDBPipeline;
    function GetDB(dn: SystemString): TZDBStoreEngine;
    function GetDBName(dn: SystemString): TZDBStoreEngine;
    property DBName[dn: SystemString]: TZDBStoreEngine read GetDBName; default;
    property PipelineN[pipeName: SystemString]: TZDBPipeline read GetPipeline;
    property QueryPipelineList: TCoreClassListForObj read FQueryPipelineList;
    function ExistsDB(dn: SystemString): Boolean;
    function ExistsPipeline(pipeName: SystemString): Boolean;
    procedure StopPipeline(pipeName: SystemString);
    procedure GetPipeList(OutputList: TCoreClassListForObj);
    procedure GetDBList(OutputList: TCoreClassListForObj);
    function Busy(db: TZDBStoreEngine): Boolean;
    function AllowDestroy(db: TZDBStoreEngine): Boolean;

    // query
    function QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
      AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
      MaxQueryCompare, MaxQueryResult: Int64): TZDBPipeline; overload;

    function QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
      AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
      MaxQueryCompare, MaxQueryResult: Int64;
      OnDataFilterCall: TZDBPipelineFilterCall; OnDataDoneCall: TZDBPipelineDoneCall): TZDBPipeline; overload;

    function QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
      AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
      MaxQueryCompare, MaxQueryResult: Int64;
      OnDataFilterMethod: TZDBPipelineFilterMethod; OnDataDoneMethod: TZDBPipelineDoneMethod): TZDBPipeline; overload;

{$IFNDEF FPC}
    function QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
      AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
      MaxQueryCompare, MaxQueryResult: Int64;
      OnDataFilterProc: TZDBPipelineFilterProc; OnDataDoneProc: TZDBPipelineDoneProc): TZDBPipeline; overload;
    function QueryDB(DataEng: TDataFrameEngine; UserObj: TCoreClassObject;
      WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
      AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
      MaxQueryCompare, MaxQueryResult: Int64;
      OnDataFilterProc: TZDBPipelineFilterProc; OnDataDoneProc: TZDBPipelineDoneProc): TZDBPipeline; overload;
{$ENDIF}
    function QueryDBToMemory(WriteResultToOutputDB, ReverseQuery: Boolean; dbN: SystemString;
      QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
      MaxQueryCompare, MaxQueryResult: Int64): TZDBPipeline; overload;

    function QueryDBToMemory(WriteResultToOutputDB, ReverseQuery: Boolean; dbN: SystemString;
      FragmentWaitTime, MaxWaitTime: Double; MaxQueryResult: Int64): TZDBPipeline; overload;

{$IFNDEF FPC}
    function QueryDBToMemory(WriteResultToOutputDB, ReverseQuery: Boolean; dbN: SystemString;
      QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double; MaxQueryCompare, MaxQueryResult: Int64;
      OnDataFilterProc: TZDBPipelineFilterProc; OnDataDoneProc: TZDBPipelineDoneProc): TZDBPipeline; overload;
{$ENDIF}
    function QueryDBToFile(WriteResultToOutputDB, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
      FragmentWaitTime, MaxWaitTime: Double; MaxQueryCompare, MaxQueryResult: Int64): TZDBPipeline;

    // build single data fragment
    function WriteDBItemToOneFragment(dbN: SystemString; StorePos: Int64; DestStream: TMemoryStream64): Boolean;

    // post operation
    function PostData(dn: SystemString; sourDBEng: TZDBStoreEngine; SourStorePos: Int64): Int64; overload;
    function PostData(dn: SystemString; var qState: TQueryState): Int64; overload;
    function PostData(dn: SystemString; dSour: TCoreClassStream; ID: Cardinal): Int64; overload;
    function PostData(dn: SystemString; dSour: TDataFrameEngine): Int64; overload;
    function PostData(dn: SystemString; dSour: THashVariantList): Int64; overload;
    function PostData(dn: SystemString; dSour: TSectionTextData): Int64; overload;
    function PostData(dn: SystemString; dSour: TPascalString): Int64; overload;
{$IFNDEF FPC}
    function PostData(dn: SystemString; dSour: TJsonObject): Int64; overload;
{$ENDIF}
    //
    // insert operation
    function InsertData(dn: SystemString; InsertPos: Int64; dSour: TCoreClassStream; ID: Cardinal): Int64; overload;
    function InsertData(dn: SystemString; InsertPos: Int64; dSour: TDataFrameEngine): Int64; overload;
    function InsertData(dn: SystemString; InsertPos: Int64; dSour: THashVariantList): Int64; overload;
    function InsertData(dn: SystemString; InsertPos: Int64; dSour: TSectionTextData): Int64; overload;
    function InsertData(dn: SystemString; InsertPos: Int64; dSour: TPascalString): Int64; overload;
{$IFNDEF FPC}
    function InsertData(dn: SystemString; InsertPos: Int64; dSour: TJsonObject): Int64; overload;
{$ENDIF}
    //
    // delete operation
    procedure DeleteData(dn: SystemString; StorePos: Int64); {$IFDEF INLINE_ASM} inline; {$ENDIF}
    //
    // manual getData
    function GetData(dn: SystemString; StorePos: Int64; ID: Cardinal): TMemoryStream64InCache; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    //
    // modify operation
    function SetData(dn: SystemString; StorePos: Int64; dSour: TMemoryStream64): Boolean; {$IFDEF INLINE_ASM} inline; {$ENDIF}
  end;

  TFillQueryDataCall   = procedure(dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64);
  TFillQueryDataMethod = procedure(dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64) of object;
  //
{$IFNDEF FPC}
  TFillQueryDataProc = reference to procedure(dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64);
{$ENDIF}
  TUserFillQueryDataCall = procedure(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
    dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64);
  TUserFillQueryDataMethod = procedure(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
    dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64) of object;
{$IFNDEF FPC}
  TUserFillQueryDataProc = reference to procedure(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
    dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64);
{$ENDIF}

function GeneratePipeName(const sourDBName, taskName: SystemString): SystemString; {$IFDEF INLINE_ASM} inline; {$ENDIF}

// fill and store
procedure FillFragmentToDB(DataSour: TMemoryStream64; db: TDBStoreBase); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure FillFragmentSource(dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TFillQueryDataCall); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure FillFragmentSource(dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TFillQueryDataMethod); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
{$IFNDEF FPC} procedure FillFragmentSource(dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TFillQueryDataProc); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}{$ENDIF}

// fill and trigger
procedure FillFragmentSource(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
  dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TUserFillQueryDataCall); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure FillFragmentSource(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
  dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TUserFillQueryDataMethod); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
{$IFNDEF FPC} procedure FillFragmentSource(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
  dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TUserFillQueryDataProc); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}{$ENDIF}
// one fragment operation
function EncodeOneFragment(db: TDBStoreBase; StorePos: Int64; DestStream: TMemoryStream64): Boolean; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function DecodeOneFragment(DataSour: TMemoryStream64; var dStorePos: Int64; var ID: Cardinal): TMemoryStream64; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function DecodeOneFragment(DataSour: TMemoryStream64): TMemoryStream64; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function DecodeOneNewFragment(DataSour: TMemoryStream64; var dStorePos: Int64; var ID: Cardinal): TMemoryStream64; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function DecodeOneNewFragment(DataSour: TMemoryStream64): TMemoryStream64; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}

// encrypt as completeBuffer
function EncodeOneBuff(const dbN: TPascalString; const ID: Cardinal; const StorePos: Int64;
  buff: Pointer; buffSiz: nativeUInt; var outputSiz: nativeUInt): Pointer; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure DecodeOneBuff(buff: Pointer; buffSiz: nativeUInt;
  var dbN: TPascalString; var ID: Cardinal; var StorePos: Int64; var output: Pointer; var outputSiz: nativeUInt); {$IFDEF INLINE_ASM} inline; {$ENDIF}


implementation

function GeneratePipeName(const sourDBName, taskName: SystemString): SystemString;
begin
  Result := sourDBName + '.QueryPipe.' + taskName;
end;

procedure FillFragmentToDB(DataSour: TMemoryStream64; db: TDBStoreBase);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Cardinal_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Cardinal_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        db.AddData(m64, ID);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;

procedure FillFragmentSource(dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TFillQueryDataCall);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  if not Assigned(OnResult) then
      Exit;
  if DataSour.Size <= 0 then
      Exit;

  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        OnResult(dbN, pipeN, StorePos, ID, m64);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;

procedure FillFragmentSource(dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TFillQueryDataMethod);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  if not Assigned(OnResult) then
      Exit;
  if DataSour.Size <= 0 then
      Exit;

  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        OnResult(dbN, pipeN, StorePos, ID, m64);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;

{$IFNDEF FPC}


procedure FillFragmentSource(dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TFillQueryDataProc);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  if not Assigned(OnResult) then
      Exit;
  if DataSour.Size <= 0 then
      Exit;

  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        OnResult(dbN, pipeN, StorePos, ID, m64);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;
{$ENDIF}


procedure FillFragmentSource(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
  dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TUserFillQueryDataCall);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  if not Assigned(OnResult) then
      Exit;
  if DataSour.Size <= 0 then
      Exit;

  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        OnResult(UserPointer, UserObject, UserVariant, dbN, pipeN, StorePos, ID, m64);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;

procedure FillFragmentSource(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
  dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TUserFillQueryDataMethod);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  if not Assigned(OnResult) then
      Exit;
  if DataSour.Size <= 0 then
      Exit;

  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        OnResult(UserPointer, UserObject, UserVariant, dbN, pipeN, StorePos, ID, m64);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;

{$IFNDEF FPC}


procedure FillFragmentSource(UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant;
  dbN, pipeN: SystemString; DataSour: TMemoryStream64; OnResult: TUserFillQueryDataProc);
var
  StorePos, siz: Int64;
  ID: Cardinal;
  m64: TMemoryStream64;
begin
  if not Assigned(OnResult) then
      Exit;
  if DataSour.Size <= 0 then
      Exit;

  DataSour.Position := 0;

  m64 := TMemoryStream64.Create;
  while DataSour.Position < DataSour.Size do
    begin
      if DataSour.ReadPtr(@StorePos, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
          Break;
      if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
          Break;

      if DataSour.Position + siz > DataSour.Size then
          Break;

      try
        m64.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
        OnResult(UserPointer, UserObject, UserVariant, dbN, pipeN, StorePos, ID, m64);
      except
      end;

      DataSour.Position := DataSour.Position + siz;
    end;
  DisposeObject(m64);
end;
{$ENDIF}


function EncodeOneFragment(db: TDBStoreBase; StorePos: Int64; DestStream: TMemoryStream64): Boolean;
var
  itmStream: TMemoryStream64InCache;
  siz: Int64;
  ID: Cardinal;
begin
  Result := False;
  itmStream := db.GetCacheStream(StorePos);
  if itmStream <> nil then
    begin
      siz := itmStream.Size;
      ID := itmStream.CacheID;
      DestStream.Position := DestStream.Size;
      DestStream.WritePtr(@StorePos, C_Int64_Size);
      DestStream.WritePtr(@siz, C_Int64_Size);
      DestStream.WritePtr(@ID, C_Cardinal_Size);
      DestStream.CopyFrom(itmStream, siz);

      DisposeObject(itmStream);
      Result := True;
    end;
end;

function DecodeOneFragment(DataSour: TMemoryStream64; var dStorePos: Int64; var ID: Cardinal): TMemoryStream64;
var
  siz: Int64;
begin
  Result := nil;
  if DataSour.ReadPtr(@dStorePos, C_Int64_Size) <> C_Int64_Size then
      Exit;
  if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
      Exit;
  if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
      Exit;

  if DataSour.Position + siz > DataSour.Size then
      Exit;

  Result := TMemoryStream64.Create;
  Result.SetPointerWithProtectedMode(DataSour.PositionAsPtr(DataSour.Position), siz);
end;

function DecodeOneFragment(DataSour: TMemoryStream64): TMemoryStream64;
var
  dStorePos: Int64;
  ID: Cardinal;
begin
  Result := DecodeOneFragment(DataSour, dStorePos, ID);
end;

function DecodeOneNewFragment(DataSour: TMemoryStream64; var dStorePos: Int64; var ID: Cardinal): TMemoryStream64;
var
  siz: Int64;
begin
  Result := nil;
  if DataSour.ReadPtr(@dStorePos, C_Int64_Size) <> C_Int64_Size then
      Exit;
  if DataSour.ReadPtr(@siz, C_Int64_Size) <> C_Int64_Size then
      Exit;
  if DataSour.ReadPtr(@ID, C_Cardinal_Size) <> C_Cardinal_Size then
      Exit;

  if DataSour.Position + siz > DataSour.Size then
      Exit;

  Result := TMemoryStream64.Create;
  Result.CopyFrom(DataSour, siz);
  Result.Position := 0;
end;

function DecodeOneNewFragment(DataSour: TMemoryStream64): TMemoryStream64;
var
  dStorePos: Int64;
  ID: Cardinal;
begin
  Result := DecodeOneNewFragment(DataSour, dStorePos, ID);
end;

function EncodeOneBuff(const dbN: TPascalString; const ID: Cardinal; const StorePos: Int64;
  buff: Pointer; buffSiz: nativeUInt; var outputSiz: nativeUInt): Pointer;
var
  nb: TBytes;
  L: Word;
  p: PByteArray;
begin
  dbN.FastGetBytes(nb);
  L := length(nb);
  outputSiz := 2 + L + 4 + 8 + buffSiz;
  p := GetMemory(outputSiz);
  Result := p;
  PWORD(@p^[0])^ := L;
  CopyPtr(@nb[0], @p^[2], L);
  PCardinal(@(p^[2 + L]))^ := ID;
  PInt64(@(p^[2 + L + 4]))^ := StorePos;
  CopyPtr(buff, @p^[2 + L + 4 + 8], buffSiz);
end;

procedure DecodeOneBuff(buff: Pointer; buffSiz: nativeUInt;
  var dbN: TPascalString; var ID: Cardinal; var StorePos: Int64; var output: Pointer; var outputSiz: nativeUInt);
var
  nb: TBytes;
  p: PByteArray;
begin
  p := buff;
  SetLength(nb, PWORD(@p^[0])^);
  CopyPtr(@p^[2], @nb[0], PWORD(@p^[0])^);
  dbN.Bytes := nb;
  ID := PCardinal(@(p^[2 + PWORD(@p^[0])^]))^;
  StorePos := PInt64(@(p^[2 + PWORD(@p^[0])^ + 4]))^;
  outputSiz := buffSiz - (2 + PWORD(@p^[0])^ + 4 + 8);
  output := @p^[2 + PWORD(@p^[0])^ + 4 + 8];
end;

procedure TZDBStoreEngine.DoCreateInit;
begin
  inherited DoCreateInit;
  FName := '';
  FLastModifyTime := GetTimeTick;
end;

procedure TZDBPipeline.Query(var qState: TQueryState);
var
  lastTime: TTimeTickValue;
  AlreadWrite: Boolean;
  Allowed: Boolean;

  procedure DoWrite;
  begin
    if AlreadWrite then
        Exit;

    WriteToOutput(qState.DBEng, qState.StorePos, qState.ID);
    AlreadWrite := True;
    Inc(FQueryResultCounter);
  end;

begin
  lastTime := GetTimeTick;
  Inc(FPerformaceCounter);

  FActivted := True;

  AlreadWrite := False;

  Allowed := False;

  if OutputDB = nil then
      Exit;
  if SourceDB = nil then
      Exit;

  try
    if Assigned(OnDataFilterCall) then
        OnDataFilterCall(Self, qState, Allowed);

    if Allowed then
        DoWrite;
  except
  end;

  Allowed := False;
  try
    if Assigned(OnDataFilterMethod) then
        OnDataFilterMethod(Self, qState, Allowed);

    if Allowed then
        DoWrite;
  except
  end;

{$IFNDEF FPC}
  Allowed := False;
  try
    if Assigned(OnDataFilterProc) then
        OnDataFilterProc(Self, qState, Allowed);

    if Allowed then
        DoWrite;
  except
  end;
{$ENDIF}
  Inc(FQueryCounter);

  FCurrentFragmentTime := FCurrentFragmentTime + qState.deltaTime;
  if (AlreadWrite) and (FCurrentFragmentTime >= Trunc(FragmentWaitTime * 1000)) then
    begin
      PostFragmentData(False);
      FCurrentFragmentTime := 0;
    end;

  if (MaxQueryResult > 0) and (FQueryResultCounter >= MaxQueryResult) then
    begin
      qState.Aborted := True;
      Exit;
    end;
  if (MaxQueryCompare > 0) and (FQueryCounter >= MaxQueryCompare) then
    begin
      qState.Aborted := True;
      Exit;
    end;
  if (MaxWaitTime > 0) and (qState.newTime >= Trunc(MaxWaitTime * 1000)) then
    begin
      qState.Aborted := True;
      Exit;
    end;

  if lastTime - FLastPerformaceTime > 1000 then
    begin
      try
        if FPerformaceCounter > 0 then
            FQueryCounterOfPerSec := FPerformaceCounter / ((lastTime - FLastPerformaceTime) * 0.001)
        else
            FQueryCounterOfPerSec := 0;
      except
          FQueryCounterOfPerSec := 0;
      end;
      FLastPerformaceTime := lastTime;
      FPerformaceCounter := 0;
    end;
end;

procedure TZDBPipeline.QueryDone();
begin
  PostFragmentData(True);

  try
    if Assigned(OnDataDoneCall) then
        OnDataDoneCall(Self);
  except
  end;

  try
    if Assigned(OnDataDoneMethod) then
        OnDataDoneMethod(Self);
  except
  end;

{$IFNDEF FPC}
  try
    if Assigned(OnDataDoneProc) then
        OnDataDoneProc(Self);
  except
  end;
{$ENDIF}
  //
  try
      Owner.DoQueryDone(Self);
  except
  end;

  FActivted := False;
  FQueryTask := nil;

  FPerformaceCounter := 0;
  FLastPerformaceTime := GetTimeTick;
end;

procedure TZDBPipeline.WriteToOutput(DBEng: TDBStoreBase; StorePos: Int64; ID: Cardinal);
var
  itmStream: TMemoryStream64;
  siz: Int64;
begin
  if (not WriteResultToOutputDB) and (not WriteFragmentBuffer) then
      Exit;

  itmStream := DBEng.GetCacheStream(StorePos, ID);

  if WriteResultToOutputDB then
    begin
      OutputDB.AddData(itmStream, ID);
    end;

  if WriteFragmentBuffer then
    begin
      itmStream.Position := 0;
      siz := itmStream.Size;
      FFragmentBuffer.Position := FFragmentBuffer.Size;
      FFragmentBuffer.WritePtr(@StorePos, C_Int64_Size);
      FFragmentBuffer.WritePtr(@siz, C_Int64_Size);
      FFragmentBuffer.WritePtr(@ID, C_Cardinal_Size);
      FFragmentBuffer.CopyFrom(itmStream, siz);
    end;
end;

procedure TZDBPipeline.PostFragmentData(forcePost: Boolean);
begin
  if (not forcePost) and (not FRealTimePostFragmentData) then
      Exit;
  if FFragmentBuffer.Size <= 0 then
      Exit;

  FFragmentBuffer.Position := 0;
  Owner.DoQueryFragmentData(Self, FFragmentBuffer);
  FFragmentBuffer.Clear;
end;

procedure TZDBPipeline.InitOptions;
begin
  FQueryCounter := 0;
  FCurrentFragmentTime := 0;
  FFragmentBuffer := TMemoryStream64.Create;

  FActivted := True;
  FQueryTask := nil;
  FPerformaceCounter := 0;
  FLastPerformaceTime := GetTimeTick;
  FQueryCounterOfPerSec := 0;
  FRealTimePostFragmentData := True;
  FQueryResultCounter := 0;
  FStorePosTransformList := TCoreClassList.Create;

  // data query options
  WriteResultToOutputDB := True; // query result write to output
  AutoDestroyDB := True;         // complete time destroy DB
  FragmentWaitTime := 0.5;       // fragment time,realtime send to client
  MaxWaitTime := 0;              // max wait complete time,query to abort from out time
  MaxQueryCompare := 0;          // max query compare
  MaxQueryResult := 0;           // max query result
  QueryDoneFreeDelayTime := 60;  // query done free delay time
  WriteFragmentBuffer := True;   // write fragment

  OnDataFilterCall := nil;
  OnDataFilterMethod := nil;
{$IFNDEF FPC}
  OnDataFilterProc := nil;
{$ENDIF}
  OnDataDoneCall := nil;
  OnDataDoneMethod := nil;
{$IFNDEF FPC}
  OnDataDoneProc := nil;
{$ENDIF}
  OnStorePosTransform := nil;

  values := THashVariantList.Create;
  DataEng := TDataFrameEngine.Create;
  UserPointer := nil;
  UserObject := nil;
  UserVariant := Null;

  Owner.FQueryPipelinePool[PipelineName] := Self;
  Owner.FQueryPipelineList.Add(Self);
end;

constructor TZDBPipeline.Create(InMem: Boolean; AOwner: TZDBLocalManager; sourDBName, APipelineN, OutDBName: SystemString);
begin
  inherited Create;
  Owner := AOwner;

  SourceDB := Owner.FDBPool[sourDBName] as TZDBStoreEngine;

  PipelineName := APipelineN;
  SourceDBName := sourDBName;
  OutputDBName := OutDBName;

  if InMem then
      OutputDB := Owner.InitMemoryDB(OutDBName)
  else
      OutputDB := Owner.InitDB(OutDBName, False);

  InitOptions;
end;

destructor TZDBPipeline.Destroy;
var
  fn: SystemString;
  i: Integer;
  pl: TZDBPipeline;
begin
  i := 0;
  while i < Owner.FQueryPipelineList.Count do
    begin
      if Owner.FQueryPipelineList[i] = Self then
          Owner.FQueryPipelineList.Delete(i)
      else
          Inc(i);
    end;

  Owner.FQueryPipelinePool.Delete(PipelineName);

  try
    if (OutputDB <> nil) and (AutoDestroyDB) then
      begin
        for i := 0 to Owner.FQueryPipelineList.Count - 1 do
          begin
            pl := TZDBPipeline(Owner.FQueryPipelineList[i]);
            if pl.OutputDB = OutputDB then
                pl.OutputDB := nil;
            if pl.SourceDB = OutputDB then
                pl.SourceDB := nil;
          end;

        if OutputDB.IsMemoryMode then
          begin
            Owner.CloseDB(OutputDB.Name);
          end
        else
          begin
            Owner.CloseAndDeleteDB(OutputDB.Name);
          end;
      end;
  except
  end;

  DisposeObject([FFragmentBuffer, values, DataEng]);

  for i := 0 to FStorePosTransformList.Count - 1 do
      Dispose(PZDBStorePosTransform(FStorePosTransformList[i]));
  DisposeObject(FStorePosTransformList);

  inherited Destroy;
end;

procedure TZDBPipeline.Progress(deltaTime: Double);
begin
end;

procedure TZDBPipeline.ClearStorePosTransform;
var
  i: Integer;
begin
  for i := 0 to FStorePosTransformList.Count - 1 do
      Dispose(PZDBStorePosTransform(FStorePosTransformList[i]));
  FStorePosTransformList.Clear;
end;

procedure TZDBPipeline.AddStorePosTransform(OriginPos, NewPos: Int64);
var
  p: PZDBStorePosTransform;
begin
  new(p);
  p^.OriginPos := OriginPos;
  p^.NewPos := NewPos;
  FStorePosTransformList.Add(p);
end;

function TZDBPipeline.StorePosTransformCount: Integer;
begin
  Result := FStorePosTransformList.Count;
end;

function TZDBPipeline.GetStorePosTransform(const index: Integer): PZDBStorePosTransform;
begin
  Result := PZDBStorePosTransform(FStorePosTransformList[index]);
end;

procedure TZDBPipeline.stop;
begin
  if FQueryTask <> nil then
      FQueryTask.stop;
end;

procedure TZDBPipeline.Pause;
begin
  if (FragmentWaitTime > 0) then
      PostFragmentData(True);
  if FQueryTask <> nil then
      FQueryTask.Pause;
end;

procedure TZDBPipeline.Play;
begin
  if FQueryTask <> nil then
      FQueryTask.Play;
end;

function TZDBPipeline.Paused: Boolean;
begin
  if FQueryTask <> nil then
      Result := FQueryTask.Paused
  else
      Result := False;
end;

function TZDBPipeline.QueryConsumTime: Double;
begin
  if FQueryTask <> nil then
      Result := FQueryTask.ConsumTime
  else
      Result := 0;
end;

procedure TZDBLocalManager.DoInsertData(Sender: TDBStoreBase; InsertPos: Int64; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64);
begin
  TZDBStoreEngine(Sender).FLastModifyTime := GetTimeTick;
  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.InsertData(TZDBStoreEngine(Sender), InsertPos, buff, ID, CompletePos);
  except
  end;
end;

procedure TZDBLocalManager.DoAddData(Sender: TDBStoreBase; buff: TCoreClassStream; ID: Cardinal; CompletePos: Int64);
begin
  TZDBStoreEngine(Sender).FLastModifyTime := GetTimeTick;
  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.AddData(TZDBStoreEngine(Sender), buff, ID, CompletePos);
  except
  end;
end;

procedure TZDBLocalManager.DoModifyData(Sender: TDBStoreBase; const StorePos: Int64; buff: TCoreClassStream);
begin
  TZDBStoreEngine(Sender).FLastModifyTime := GetTimeTick;
  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.ModifyData(TZDBStoreEngine(Sender), StorePos, buff);
  except
  end;
end;

procedure TZDBLocalManager.DoDeleteData(Sender: TDBStoreBase; const StorePos: Int64);
begin
  TZDBStoreEngine(Sender).FLastModifyTime := GetTimeTick;
  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.DeleteData(TZDBStoreEngine(Sender), StorePos);
  except
  end;
end;

procedure TZDBLocalManager.DoQueryFragmentData(pipe: TZDBPipeline; FragmentSour: TMemoryStream64);
begin
  if not Assigned(FNotifyIntf) then
      Exit;

  FragmentSour.Position := 0;

  try
      FNotifyIntf.QueryFragmentData(pipe, FragmentSour);
  except
  end;
end;

procedure TZDBLocalManager.DoQueryDone(pipe: TZDBPipeline);
begin
  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.QueryDone(pipe);
  except
  end;

  with ProgressPost.PostExecute(pipe.QueryDoneFreeDelayTime, {$IFDEF FPC}@{$ENDIF FPC}DelayFreePipe) do
      Data1 := pipe;
end;

procedure TZDBLocalManager.DelayFreePipe(Sender: TNPostExecute);
var
  i: Integer;
  sour, pl: TZDBPipeline;
begin
  sour := TZDBPipeline(Sender.Data1);

  if sour.AutoDestroyDB then
    for i := 0 to FQueryPipelineList.Count - 1 do
      begin
        pl := TZDBPipeline(FQueryPipelineList[i]);
        if (pl.SourceDB = sour.OutputDB) and (pl.Activted) then
          begin
            with ProgressPost.PostExecute(1.0, {$IFDEF FPC}@{$ENDIF FPC}DelayFreePipe) do
                Data1 := sour;
            Exit;
          end;
      end;

  DisposeObject(sour);
end;

procedure TZDBLocalManager.DoQueryCopy(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
var
  n: Int64;
begin
  n := PostData(dPipe.UserVariant, qState);
  dPipe.AddStorePosTransform(qState.StorePos, n);
  Allowed := False;
end;

procedure TZDBLocalManager.DoCopyDone(dPipe: TZDBPipeline);
var
  i: Integer;
  TransformBuff: TZDBStorePosTransformArray;
begin
  if Assigned(dPipe.OnStorePosTransform) then
    begin
      SetLength(TransformBuff, dPipe.FStorePosTransformList.Count);
      for i := 0 to dPipe.StorePosTransformCount - 1 do
          TransformBuff[i] := dPipe.StorePosTransform[i]^;

      dPipe.OnStorePosTransform(dPipe.UserPointer, @TransformBuff);
      SetLength(TransformBuff, 0);
    end;
end;

procedure TZDBLocalManager.DoCompressDone(dPipe: TZDBPipeline);
var
  SourN: SystemString;
  replaceN: SystemString;
  i: Integer;
  Done_Ptr: PCompressDoneNotify;
begin
  Done_Ptr := nil;
  if Assigned(dPipe.OnStorePosTransform) then
    begin
      new(Done_Ptr);
      Done_Ptr^.OnStorePosTransform := dPipe.OnStorePosTransform;
      Done_Ptr^.Data := dPipe.UserPointer;
      SetLength(Done_Ptr^.TransformBuff, dPipe.FStorePosTransformList.Count);
      for i := 0 to dPipe.StorePosTransformCount - 1 do
          Done_Ptr^.TransformBuff[i] := dPipe.StorePosTransform[i]^;
    end;

  SourN := dPipe.SourceDB.Name;
  replaceN := dPipe.UserVariant;
  with ProgressPost.PostExecute(2.0, {$IFDEF FPC}@{$ENDIF FPC}DelayReplaceDB) do
    begin
      Data3 := SourN;
      Data4 := replaceN;
      Data5 := Done_Ptr;
    end;
end;

procedure TZDBLocalManager.DelayReplaceDB(Sender: TNPostExecute);
var
  SourN: SystemString;
  replaceN: SystemString;
  Done_Ptr: PCompressDoneNotify;
  sourDB: TZDBStoreEngine;
  pl: TZDBPipeline;
  i: Integer;
  dbBusy: Boolean;
begin
  SourN := Sender.Data3;
  replaceN := Sender.Data4;
  Done_Ptr := Sender.Data5;

  if not ExistsDB(SourN) then
      Exit;
  if not ExistsDB(replaceN) then
      Exit;

  sourDB := DBName[SourN];

  dbBusy := sourDB.QueryProcessing;

  if not dbBusy then
    for i := 0 to FQueryPipelineList.Count - 1 do
      if TZDBPipeline(FQueryPipelineList[i]).SourceDB = sourDB then
        begin
          dbBusy := True;
          Break;
        end;

  if dbBusy then
    begin
      with ProgressPost.PostExecute(1.0, {$IFDEF FPC}@{$ENDIF FPC}DelayReplaceDB) do
        begin
          Data3 := SourN;
          Data4 := replaceN;
          Data5 := Done_Ptr;
        end;
      Exit;
    end;

  CloseAndDeleteDB(SourN);

  if DBName[replaceN].RenameDB(SourN + '.OX') then
    begin
      CloseDB(replaceN);
      InitDB(SourN, False);
    end;
  if Done_Ptr <> nil then
    begin
      if Assigned(Done_Ptr^.OnStorePosTransform) then
          Done_Ptr^.OnStorePosTransform(Done_Ptr^.Data, @Done_Ptr^.TransformBuff);
      SetLength(Done_Ptr^.TransformBuff, 0);
      Dispose(Done_Ptr);
    end;
end;

constructor TZDBLocalManager.Create;
begin
  inherited Create;
  FRootPath := umlCurrentPath;
  FDBPool := THashObjectList.Create(True, 1024);
  FDBPool.AccessOptimization := False;

  FQueryPipelinePool := THashObjectList.Create(False, 1024);
  FQueryPipelinePool.AccessOptimization := False;

  FQueryPipelineList := TCoreClassListForObj.Create;

  FTaskCounter := 1;
  FCadencerEng := TCadencer.Create;
  FCadencerEng.ProgressIntf := Self;
  FProgressPost := TNProgressPost.Create;
  FPipelineClass := TZDBPipeline;
  FNotifyIntf := nil;
end;

destructor TZDBLocalManager.Destroy;
var
  lst: TCoreClassListForObj;
  i: Integer;
begin
  FProgressPost.ResetPost;

  lst := TCoreClassListForObj.Create;
  FDBPool.GetAsList(lst);
  for i := 0 to lst.Count - 1 do
      TZDBStoreEngine(lst[i]).StopAllQuery;
  DisposeObject(lst);

  lst := TCoreClassListForObj.Create;
  FQueryPipelinePool.GetAsList(lst);
  for i := 0 to lst.Count - 1 do
      DisposeObject(lst[i]);
  DisposeObject(lst);

  DisposeObject([FDBPool, FQueryPipelinePool, FQueryPipelineList, FCadencerEng, FProgressPost]);
  inherited Destroy;
end;

function TZDBLocalManager.InitDB(dbN: SystemString): TZDBStoreEngine;
begin
  Result := InitDB(dbN, False);
end;

function TZDBLocalManager.InitDB(dbN: SystemString; ReadOnly: Boolean): TZDBStoreEngine;
var
  fn: U_String;
  isNewDB: Boolean;
begin
  Result := GetDB(dbN);
  if Result <> nil then
      Exit;

  if not U_String(dbN).Exists(['/', '\']) then
      fn := umlCombineFileName(FRootPath, dbN + '.OX')
  else
    begin
      fn.Text := dbN;
      dbN := umlChangeFileExt(umlGetFileName(dbN), '');
    end;

  isNewDB := not umlFileExists(fn);

  if isNewDB then
      Result := TZDBStoreEngine.CreateNew(fn)
  else
      Result := TZDBStoreEngine.Create(fn, ReadOnly);

  Result.NotifyIntf := Self;
  Result.FName := dbN;

  FDBPool[dbN] := Result;

  try
    if (isNewDB) and (Assigned(FNotifyIntf)) then
        FNotifyIntf.CreateDB(Result);
  except
  end;
end;

function TZDBLocalManager.InitNewDB(dbN: SystemString): TZDBStoreEngine;
var
  fn: U_String;
begin
  if not U_String(dbN).Exists(['/', '\']) then
      fn := umlCombineFileName(FRootPath, dbN + '.OX')
  else
    begin
      fn := dbN;
      dbN := umlChangeFileExt(umlGetFileName(dbN), '');
    end;

  FDBPool.Delete(dbN);

  Result := TZDBStoreEngine.CreateNew(fn);

  Result.NotifyIntf := Self;
  Result.FName := dbN;

  FDBPool[dbN] := Result;

  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.CreateDB(Result);
  except
  end;
end;

function TZDBLocalManager.InitMemoryDB(dbN: SystemString): TZDBStoreEngine;
begin
  Result := GetDB(dbN);
  if Result <> nil then
      Exit;
  Result := TZDBStoreEngine.CreateNewMemory;

  Result.NotifyIntf := Self;
  Result.FName := dbN;

  FDBPool[dbN] := Result;

  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.CreateDB(Result);
  except
  end;
end;

procedure TZDBLocalManager.ZDBEngProgress(const Name: PSystemString; Obj: TCoreClassObject);
var
  db: TZDBStoreEngine;
begin
  if Obj = nil then
      Exit;

  db := TZDBStoreEngine(Obj);
  if (db.DBEngine.Modify) and (GetTimeTick - db.FLastModifyTime > 1000) then
    begin
      db.DBEngine.Update;
      db.FLastModifyTime := GetTimeTick;
    end;
end;

procedure TZDBLocalManager.CadencerProgress(const deltaTime, newTime: Double);
var
  i: Integer;
begin
  FProgressPost.Progress(deltaTime);

  for i := 0 to FQueryPipelineList.Count - 1 do
    begin
      try
          TZDBPipeline(FQueryPipelineList[i]).Progress(deltaTime);
      except
      end;
    end;

  FDBPool.Progress({$IFDEF FPC}@{$ENDIF FPC}ZDBEngProgress);
end;

procedure TZDBLocalManager.CloseDB(dbN: SystemString);
var
  db: TZDBStoreEngine;
  i: Integer;
  pl: TZDBPipeline;
begin
  db := GetDB(dbN);
  if db = nil then
      Exit;

  for i := 0 to FQueryPipelineList.Count - 1 do
    begin
      pl := TZDBPipeline(FQueryPipelineList[i]);
      if pl.OutputDB = db then
          pl.OutputDB := nil;
      if pl.SourceDB = db then
          pl.SourceDB := nil;
    end;

  try
    if Assigned(FNotifyIntf) then
        FNotifyIntf.CloseDB(db);
  except
  end;

  FDBPool.Delete(dbN);
end;

procedure TZDBLocalManager.CloseAndDeleteDB(dbN: SystemString);
var
  db: TZDBStoreEngine;
  fn: SystemString;
begin
  db := GetDB(dbN);
  if db = nil then
      Exit;

  if db.DBEngine.StreamEngine is TMemoryStream64 then
    begin
      CloseDB(db.Name);
    end
  else
    begin
      fn := db.DBEngine.ObjectName;
      CloseDB(db.Name);
      if umlFileExists(fn) then
          umlDeleteFile(fn);
    end;
end;

function TZDBLocalManager.CopyDB(SourN, DestN: SystemString): TZDBPipeline;
var
  n: SystemString;
  pl: TZDBPipeline;
  db: TZDBStoreEngine;
  nd: TZDBStoreEngine;
begin
  Result := nil;
  db := GetDB(SourN);
  if db = nil then
      Exit;

  if db.IsReadOnly then
      Exit;

  n := DestN;

  if db.IsMemoryMode then
      nd := InitMemoryDB(n)
  else
      nd := InitDB(n, False);

  pl := QueryDB(False, True, False, db.Name, 'Copying', True, 0.0, 0, 0, 0, 0);
  pl.OnDataFilterMethod := {$IFDEF FPC}@{$ENDIF FPC}DoQueryCopy;
  pl.OnDataDoneMethod := {$IFDEF FPC}@{$ENDIF FPC}DoCopyDone;
  pl.UserVariant := nd.Name;
  pl.ClearStorePosTransform;
  Result := pl;
end;

function TZDBLocalManager.CopyDB(SourN, DestN: SystemString; const UserData: Pointer; const OnStorePosTransform: TZDBStorePosTransformNotify): TZDBPipeline;
begin
  Result := CopyDB(SourN, DestN);
  Result.OnStorePosTransform := OnStorePosTransform;
  Result.UserPointer := UserData;
end;

function TZDBLocalManager.CompressDB(dbN: SystemString): TZDBPipeline;
var
  n: SystemString;
  pl: TZDBPipeline;
  db: TZDBStoreEngine;
  nd: TZDBStoreEngine;
begin
  Result := nil;
  db := GetDB(dbN);
  if db = nil then
      Exit;

  if db.IsReadOnly then
      Exit;

  if ExistsPipeline(db.Name + '.*.Compressing') then
      Exit;

  n := db.Name + '.CompressSwap';

  if ExistsDB(n) then
      Exit;

  if db.IsMemoryMode then
      nd := InitMemoryDB(n)
  else
      nd := InitNewDB(n);

  pl := QueryDB(False, True, False, db.Name, n, False, 0.0, 0, 0, 0, 0);
  pl.OnDataFilterMethod := {$IFDEF FPC}@{$ENDIF FPC}DoQueryCopy;
  pl.OnDataDoneMethod := {$IFDEF FPC}@{$ENDIF FPC}DoCompressDone;
  pl.UserVariant := nd.Name;
  pl.ClearStorePosTransform;
  Result := pl;
end;

function TZDBLocalManager.CompressDB(dbN: SystemString; const UserData: Pointer; const OnStorePosTransform: TZDBStorePosTransformNotify): TZDBPipeline;
begin
  Result := CompressDB(dbN);
  Result.OnStorePosTransform := OnStorePosTransform;
  Result.UserPointer := UserData;
end;

procedure TZDBLocalManager.ReplaceDB(dbN, replaceN: SystemString);
begin
  with ProgressPost.PostExecute(0, {$IFDEF FPC}@{$ENDIF FPC}DelayReplaceDB) do
    begin
      Data3 := dbN;
      Data4 := replaceN;
    end;
end;

procedure TZDBLocalManager.ResetData(dbN: SystemString);
var
  db: TZDBStoreEngine;
begin
  db := GetDB(dbN);
  if db = nil then
      Exit;

  if db.IsReadOnly then
      Exit;

  db.ResetDB;
end;

procedure TZDBLocalManager.Recache;
var
  lst: TCoreClassListForObj;
  i: Integer;
  db: TZDBStoreEngine;
begin
  lst := TCoreClassListForObj.Create;
  FDBPool.GetAsList(lst);
  for i := 0 to lst.Count - 1 do
    begin
      db := TZDBStoreEngine(lst[i]);
      db.Recache;
    end;
  DisposeObject(lst);
end;

function TZDBLocalManager.GenerateTaskName: SystemString;
begin
  Result := 'Task' + umlIntToStr(FTaskCounter);
end;

function TZDBLocalManager.GenerateNewTaskName: SystemString;
begin
  Result := GenerateTaskName;
  Inc(FTaskCounter);
end;

function TZDBLocalManager.GetPipeline(pipeName: SystemString): TZDBPipeline;
begin
  Result := TZDBPipeline(FQueryPipelinePool[pipeName]);
end;

function TZDBLocalManager.GetDB(dn: SystemString): TZDBStoreEngine;
begin
  Result := TZDBStoreEngine(FDBPool[dn]);
end;

function TZDBLocalManager.GetDBName(dn: SystemString): TZDBStoreEngine;
begin
  Result := InitMemoryDB(dn);
end;

function TZDBLocalManager.ExistsDB(dn: SystemString): Boolean;
begin
  Result := FDBPool.Exists(dn);
end;

function TZDBLocalManager.ExistsPipeline(pipeName: SystemString): Boolean;
var
  i: Integer;
begin
  Result := FQueryPipelinePool.Exists(pipeName);
  if Result then
      Exit;
  for i := 0 to FQueryPipelineList.Count - 1 do
    if umlMultipleMatch(True, pipeName, TZDBPipeline(FQueryPipelineList[i]).PipelineName) then
      begin
        Result := True;
        Exit;
      end;
end;

procedure TZDBLocalManager.StopPipeline(pipeName: SystemString);
var
  pl: TZDBPipeline;
begin
  pl := GetPipeline(pipeName);
  if pl <> nil then
      pl.stop;
end;

procedure TZDBLocalManager.GetPipeList(OutputList: TCoreClassListForObj);
begin
  FQueryPipelinePool.GetAsList(OutputList);
end;

procedure TZDBLocalManager.GetDBList(OutputList: TCoreClassListForObj);
begin
  FDBPool.GetAsList(OutputList);
end;

function TZDBLocalManager.Busy(db: TZDBStoreEngine): Boolean;
var
  i: Integer;
  pl: TZDBPipeline;
begin
  Result := False;
  for i := 0 to FQueryPipelineList.Count - 1 do
    begin
      pl := TZDBPipeline(FQueryPipelineList[i]);
      if (pl.Activted) and ((pl.SourceDB = db) or (pl.OutputDB = db)) then
        begin
          Result := True;
          Exit;
        end;
    end;
end;

function TZDBLocalManager.AllowDestroy(db: TZDBStoreEngine): Boolean;
var
  i: Integer;
  pl: TZDBPipeline;
begin
  Result := False;
  if db = nil then
      Exit;

  for i := 0 to FQueryPipelineList.Count - 1 do
    begin
      pl := TZDBPipeline(FQueryPipelineList[i]);
      if (pl.Activted) and (pl.AutoDestroyDB) and ((pl.SourceDB = db) or (pl.OutputDB = db)) then
          Exit;
    end;

  Result := True;
end;

function TZDBLocalManager.QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
  AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
  MaxQueryCompare, MaxQueryResult: Int64): TZDBPipeline;
var
  tN: SystemString;
  plN: SystemString;
begin
  Result := nil;

  if not ExistsDB(dbN) then
      Exit;

  tN := GenerateNewTaskName;
  plN := GeneratePipeName(dbN, tN);
  if OutputDB = '' then
      OutputDB := plN;
  Result := FPipelineClass.Create(InMemory, Self, dbN, plN, OutputDB);

  Result.WriteResultToOutputDB := WriteResultToOutputDB;
  Result.AutoDestroyDB := AutoDestroyDB;
  Result.FragmentWaitTime := FragmentWaitTime;
  Result.MaxWaitTime := MaxWaitTime;
  Result.MaxQueryCompare := MaxQueryCompare;
  Result.MaxQueryResult := MaxQueryResult;
  Result.QueryDoneFreeDelayTime := QueryDoneFreeDelayTime;
  Result.WriteFragmentBuffer := True;

  Result.FQueryTask := Result.SourceDB.Query(Result.PipelineName, ReverseQuery, {$IFDEF FPC}@{$ENDIF FPC}Result.Query, {$IFDEF FPC}@{$ENDIF FPC}Result.QueryDone);
  try
    if Assigned(NotifyIntf) then
        NotifyIntf.CreateQuery(Result);
  except
  end;
end;

function TZDBLocalManager.QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
  AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
  MaxQueryCompare, MaxQueryResult: Int64;
  OnDataFilterCall: TZDBPipelineFilterCall; OnDataDoneCall: TZDBPipelineDoneCall): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery, dbN, OutputDB, AutoDestroyDB, QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
  Result.OnDataFilterCall := OnDataFilterCall;
  Result.OnDataDoneCall := OnDataDoneCall;
end;

function TZDBLocalManager.QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
  AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
  MaxQueryCompare, MaxQueryResult: Int64;
  OnDataFilterMethod: TZDBPipelineFilterMethod; OnDataDoneMethod: TZDBPipelineDoneMethod): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery, dbN, OutputDB, AutoDestroyDB, QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
  Result.OnDataFilterMethod := OnDataFilterMethod;
  Result.OnDataDoneMethod := OnDataDoneMethod;
end;

{$IFNDEF FPC}


function TZDBLocalManager.QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
  AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
  MaxQueryCompare, MaxQueryResult: Int64;
  OnDataFilterProc: TZDBPipelineFilterProc; OnDataDoneProc: TZDBPipelineDoneProc): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery, dbN, OutputDB, AutoDestroyDB, QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
  Result.OnDataFilterProc := OnDataFilterProc;
  Result.OnDataDoneProc := OnDataDoneProc;
end;

function TZDBLocalManager.QueryDB(DataEng: TDataFrameEngine; UserObj: TCoreClassObject;
  WriteResultToOutputDB, InMemory, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
  AutoDestroyDB: Boolean; QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
  MaxQueryCompare, MaxQueryResult: Int64;
  OnDataFilterProc: TZDBPipelineFilterProc; OnDataDoneProc: TZDBPipelineDoneProc): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, InMemory, ReverseQuery, dbN, OutputDB, AutoDestroyDB, QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
  Result.OnDataFilterProc := OnDataFilterProc;
  Result.OnDataDoneProc := OnDataDoneProc;
  if DataEng <> nil then
      Result.DataEng.Assign(DataEng);
  Result.UserObject := UserObj;
end;

{$ENDIF}


function TZDBLocalManager.QueryDBToMemory(WriteResultToOutputDB, ReverseQuery: Boolean; dbN: SystemString;
  QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double;
  MaxQueryCompare, MaxQueryResult: Int64): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, True, ReverseQuery, dbN, 'Temp', True, QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
end;

function TZDBLocalManager.QueryDBToMemory(WriteResultToOutputDB, ReverseQuery: Boolean; dbN: SystemString;
  FragmentWaitTime, MaxWaitTime: Double; MaxQueryResult: Int64): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, True, ReverseQuery, dbN, 'Temp', True, 60 * 5, FragmentWaitTime, MaxWaitTime, 0, MaxQueryResult);
end;

{$IFNDEF FPC}


function TZDBLocalManager.QueryDBToMemory(WriteResultToOutputDB, ReverseQuery: Boolean; dbN: SystemString;
  QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime: Double; MaxQueryCompare, MaxQueryResult: Int64;
  OnDataFilterProc: TZDBPipelineFilterProc; OnDataDoneProc: TZDBPipelineDoneProc): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, True, ReverseQuery, dbN, 'Temp', True, QueryDoneFreeDelayTime, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
  Result.OnDataFilterProc := OnDataFilterProc;
  Result.OnDataDoneProc := OnDataDoneProc;
end;
{$ENDIF}


function TZDBLocalManager.QueryDBToFile(WriteResultToOutputDB, ReverseQuery: Boolean; dbN, OutputDB: SystemString;
  FragmentWaitTime, MaxWaitTime: Double; MaxQueryCompare, MaxQueryResult: Int64): TZDBPipeline;
begin
  Result := QueryDB(WriteResultToOutputDB, False, ReverseQuery, dbN, OutputDB, False, 0, FragmentWaitTime, MaxWaitTime, MaxQueryCompare, MaxQueryResult);
end;

function TZDBLocalManager.WriteDBItemToOneFragment(dbN: SystemString; StorePos: Int64; DestStream: TMemoryStream64): Boolean;
begin
  Result := False;
  if not ExistsDB(dbN) then
      Exit;

  Result := EncodeOneFragment(DBName[dbN], StorePos, DestStream);
end;

function TZDBLocalManager.PostData(dn: SystemString; sourDBEng: TZDBStoreEngine; SourStorePos: Int64): Int64;
var
  d: TZDBStoreEngine;
  M: TMemoryStream64InCache;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  M := sourDBEng.GetCacheStream(SourStorePos);
  if M <> nil then
    begin
      Result := d.AddData(M, M.CacheID);
      DisposeObject(M);
    end;
end;

function TZDBLocalManager.PostData(dn: SystemString; var qState: TQueryState): Int64;
var
  d: TZDBStoreEngine;
  M: TMemoryStream64InCache;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  M := qState.DBEng.GetCacheStream(qState.StorePos, qState.ID);
  if M <> nil then
    begin
      Result := d.AddData(M, M.CacheID);
      DisposeObject(M);
    end;
end;

function TZDBLocalManager.PostData(dn: SystemString; dSour: TCoreClassStream; ID: Cardinal): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  Result := d.AddData(dSour, ID);
end;

function TZDBLocalManager.PostData(dn: SystemString; dSour: TDataFrameEngine): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  Result := d.AddData(dSour);
end;

function TZDBLocalManager.PostData(dn: SystemString; dSour: THashVariantList): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  Result := d.AddData(dSour);
end;

function TZDBLocalManager.PostData(dn: SystemString; dSour: TSectionTextData): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  Result := d.AddData(dSour);
end;

function TZDBLocalManager.PostData(dn: SystemString; dSour: TPascalString): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  Result := d.AddData(dSour);
end;

{$IFNDEF FPC}


function TZDBLocalManager.PostData(dn: SystemString; dSour: TJsonObject): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
      d := InitMemoryDB(dn);
  Result := d.AddData(dSour);
end;
{$ENDIF}


procedure TZDBLocalManager.Clear;
var
  lst: TCoreClassListForObj;
  i: Integer;
begin
  FProgressPost.ResetPost;

  lst := TCoreClassListForObj.Create;
  FDBPool.GetAsList(lst);
  for i := 0 to lst.Count - 1 do
      TZDBStoreEngine(lst[i]).StopAllQuery;
  DisposeObject(lst);

  lst := TCoreClassListForObj.Create;
  FQueryPipelinePool.GetAsList(lst);
  for i := 0 to lst.Count - 1 do
      DisposeObject(lst[i]);
  DisposeObject(lst);

  FDBPool.Clear;
end;

procedure TZDBLocalManager.LoadDB(ReadOnly: Boolean);
var
  Arr: U_StringArray;
  fn, n: SystemString;

begin
  Clear;

  Arr := umlGetFileListWithFullPath(RootPath);

  for fn in Arr do
    begin
      n := umlGetFileName(fn);
      if not umlMultipleMatch(True, '*.CompressSwap.*', n) then
        if umlMultipleMatch(True, '*.OX', n) then
            InitDB(umlChangeFileExt(n, '').Text, ReadOnly);
    end;
  SetLength(Arr, 0);
end;

procedure TZDBLocalManager.SetRootPath(const Value: SystemString);
begin
  FRootPath := Value;
  LoadDB(False);
end;

procedure TZDBLocalManager.Progress;
begin
  FCadencerEng.Progress;
end;

function TZDBLocalManager.InsertData(dn: SystemString; InsertPos: Int64; dSour: TCoreClassStream; ID: Cardinal): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
    begin
      d := InitMemoryDB(dn);
      Result := d.AddData(dSour, ID);
    end
  else
      Result := d.InsertData(InsertPos, dSour, ID);
end;

function TZDBLocalManager.InsertData(dn: SystemString; InsertPos: Int64; dSour: TDataFrameEngine): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
    begin
      d := InitMemoryDB(dn);
      Result := d.AddData(dSour);
    end
  else
      Result := d.InsertData(InsertPos, dSour);
end;

function TZDBLocalManager.InsertData(dn: SystemString; InsertPos: Int64; dSour: THashVariantList): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
    begin
      d := InitMemoryDB(dn);
      Result := d.AddData(dSour);
    end
  else
      Result := d.InsertData(InsertPos, dSour);
end;

function TZDBLocalManager.InsertData(dn: SystemString; InsertPos: Int64; dSour: TSectionTextData): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
    begin
      d := InitMemoryDB(dn);
      Result := d.AddData(dSour);
    end
  else
      Result := d.InsertData(InsertPos, dSour);
end;

function TZDBLocalManager.InsertData(dn: SystemString; InsertPos: Int64; dSour: TPascalString): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
    begin
      d := InitMemoryDB(dn);
      Result := d.AddData(dSour);
    end
  else
      Result := d.InsertData(InsertPos, dSour);
end;

{$IFNDEF FPC}


function TZDBLocalManager.InsertData(dn: SystemString; InsertPos: Int64; dSour: TJsonObject): Int64;
var
  d: TZDBStoreEngine;
begin
  Result := -1;
  d := GetDB(dn);
  if d = nil then
    begin
      d := InitMemoryDB(dn);
      Result := d.AddData(dSour);
    end
  else
      Result := d.InsertData(InsertPos, dSour);
end;
{$ENDIF}


procedure TZDBLocalManager.DeleteData(dn: SystemString; StorePos: Int64);
var
  d: TZDBStoreEngine;
begin
  d := GetDB(dn);
  if d = nil then
      Exit;
  d.PostDeleteData(StorePos);
end;

function TZDBLocalManager.GetData(dn: SystemString; StorePos: Int64; ID: Cardinal): TMemoryStream64InCache;
var
  d: TZDBStoreEngine;
begin
  Result := nil;
  d := GetDB(dn);
  if d = nil then
      Exit;
  Result := d.GetCacheStream(StorePos, ID);
end;

function TZDBLocalManager.SetData(dn: SystemString; StorePos: Int64; dSour: TMemoryStream64): Boolean;
var
  d: TZDBStoreEngine;
begin
  Result := False;
  d := GetDB(dn);
  if d = nil then
      Exit;
  Result := d.SetData(StorePos, dSour);
end;

initialization

end. 
 
