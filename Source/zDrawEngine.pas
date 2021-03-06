{ ****************************************************************************** }
{ * zDrawEngine                                                                 * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }
unit zDrawEngine;

{$INCLUDE zDefine.inc}

interface


uses Variants, Types, CoreClasses, Geometry2DUnit, Geometry3DUnit, UnicodeMixedLib,
  ListEngine, MemoryRaster, PascalStrings, DataFrameEngine, MemoryStream64;

type
  TDrawEngine        = class;
  TDrawEngine_Raster = class;

  TDEColor = TVec4;
  PDEColor = ^TDEColor;

  TDEVec = TVec2;
  PDEVec = ^TDEVec;

  TDERect  = TRectV2;
  PDERect  = ^TRectV2;
  TDEFloat = TGeoFloat;

  TDETexture = class(TSequenceMemoryRaster)
  protected
    IsStaticShadow: Boolean;
    FStaticShadow: TDETexture;
    function GetStaticShadow: TDETexture; virtual;
  public
    Name: SystemString;
    constructor Create; override;
    destructor Destroy; override;

    procedure ReleaseFMXResource; virtual;
    procedure FastUpdateTexture; virtual;

    property StaticShadow: TDETexture read GetStaticShadow;
  end;

  TDETextureClass = class of TDETexture;

  TDE4V = packed record
  public
    Left, Top, Right, Bottom: TDEFloat;
    angle: TDEFloat;

    function IsZero: Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function width: TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function height: TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function MakeRectV2: TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function MakeRectf: TRectf; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function BoundRect: TDERect; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function Centroid: TDEVec; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function Add(v: TDEVec): TDE4V; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function Add(X, Y: TDEFloat): TDE4V; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function Scale(F: TDEFloat): TDE4V; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetDistance(dest: TDE4V): TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetAngleDistance(dest: TDE4V): TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function MovementToLerp(dest: TDE4V; mLerp, rLerp: Double): TDE4V; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function MovementToDistance(dest: TDE4V; mSpeed, rSpeed: TDEFloat): TDE4V; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function MovementToDistanceCompleteTime(dest: TDE4V; mSpeed, rSpeed: TDEFloat): Double; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function Fit(dest: TDE4V): TDE4V; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function Fit(dest: TDERect): TDE4V; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function Init(R: TDERect; Ang: TDEFloat): TDE4V; overload; static; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function Init(R: TRectf; Ang: TDEFloat): TDE4V; overload; static; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function Init(R: TRect; Ang: TDEFloat): TDE4V; overload; static; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function Init(CenPos: TDEVec; AWidth, AHeight, Ang: TDEFloat): TDE4V; overload; static; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function Init(AWidth, AHeight, Ang: TDEFloat): TDE4V; overload; static; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function Init: TDE4V; overload; static; {$IFDEF INLINE_ASM}inline; {$ENDIF}
  end;

  IDrawEngineInterface = interface
    procedure SetSize(R: TDERect);
    procedure SetLineWidth(w: TDEFloat);
    procedure DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor);
    procedure DrawRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor);
    procedure FillRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor);
    procedure DrawEllipse(R: TDERect; COLOR: TDEColor);
    procedure FillEllipse(R: TDERect; COLOR: TDEColor);
    procedure DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat);
    procedure DrawTexture(T: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat);
    procedure Flush;
    procedure ResetState;
    procedure BeginDraw;
    procedure EndDraw;
    function CurrentScreenSize: TDEVec;
    function GetTextSize(Text: SystemString; Size: TDEFloat): TDEVec;
    function ReadyOK: Boolean;
    function EngineIntfObject: TCoreClassObject;
  end;

  TDrawCommandParam_1Float = packed record
    F: TDEFloat;
  end;

  PDrawCommandParam_1Float = ^TDrawCommandParam_1Float;

  TDrawCommandParam_1Rect = packed record
    R: TDERect;
  end;

  PDrawCommandParam_1Rect = ^TDrawCommandParam_1Rect;

  TDrawCommandParam_PT_Color = packed record
    pt1, pt2: TDEVec;
    COLOR: TDEColor;
  end;

  PDrawCommandParam_PT_Color = ^TDrawCommandParam_PT_Color;

  TDrawCommandParam_Rect_Color = packed record
    R: TDERect;
    angle: TDEFloat;
    COLOR: TDEColor;
  end;

  PDrawCommandParam_Rect_Color = ^TDrawCommandParam_Rect_Color;

  TDrawCommandParam_Textout = packed record
    Text: SystemString;
    Size: TDEFloat;
    R: TDERect;
    COLOR: TDEColor;
    center: Boolean;
    RotateVec: TDEVec;
    angle: TDEFloat;
    bak_r: TDERect;
    bak_color: TDEColor;
  end;

  PDrawCommandParam_Textout = ^TDrawCommandParam_Textout;

  TDrawCommandParam_Texture = packed record
    T: TCoreClassObject;
    sour, dest: TDE4V;
    alpha: TDEFloat;
    bak_t: TCoreClassObject;
    bak_dest: TDE4V;
    bak_alpha: TDEFloat;
  end;

  PDrawCommandParam_Texture = ^TDrawCommandParam_Texture;

  TUserCustomDrawProc = procedure(Sender: TDrawEngine; const UserData: Pointer; const UserObject: TCoreClassObject) of object;

  TDrawCommandParam_UserCustom = packed record
    UserProc: TUserCustomDrawProc;
    UserData: Pointer;
    UserObject: TCoreClassObject;
  end;

  PDrawCommandParam_UserCustom = ^TDrawCommandParam_UserCustom;

  TDrawCommandType = (dctSetSize, dctSetLineWidth,
    dctLine, dctDrawRect, dctFillRect, dctDrawEllipse, dctFillEllipse,
    dctDrawText, dctDrawTexture, dctUserCustom, dctFlush);

  TDrawExecute = class;

  TDrawCommand = packed record
    T: TDrawCommandType;
    Data: Pointer;
    procedure DoFreeData; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure Execute(OwnerDrawExecute: TDrawExecute; IDraw: IDrawEngineInterface); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure copyto(var Dst: TDrawCommand); {$IFDEF INLINE_ASM}inline; {$ENDIF}
  end;

  PDrawCommand = ^TDrawCommand;

  TTextureOutputState = packed record
    Source: TCoreClassObject;
    SourceRect: TDE4V;
    DestScreen: TDE4V;
    alpha: TDEFloat;
    index: Integer;
  end;

  PTextureOutputState = ^TTextureOutputState;

  TTextureOutputStateBuffer = packed array of TTextureOutputState;

  TDrawQueue = class(TCoreClassPersistent)
  protected
    FOwner: TDrawEngine;
    FCommandList: TCoreClassList;

    FStartDrawShadowIndex: Integer;
    FShadowVec: TDEVec;
    FShadowAlpha: TDEFloat;
  public
    constructor Create(AOwner: TDrawEngine);
    destructor Destroy; override;

    procedure Assign(Source: TDrawQueue); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    // queue manager
    procedure Clear(ForceFree: Boolean); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    // post command
    procedure SetSize(R: TDERect); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure SetLineWidth(w: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawEllipse(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillEllipse(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTexture(T: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawUserCustom(const UserProc: TUserCustomDrawProc; const UserData: Pointer; const UserObject: TCoreClassObject); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure Flush; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure BeginCaptureShadow(const OffsetVec: TDEVec; const alpha: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure EndCaptureShadow; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure BuildTextureOutputState(var buff: TTextureOutputStateBuffer); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    property Owner: TDrawEngine read FOwner;
  end;

  TDrawExecute = class(TCoreClassPersistent)
  protected
    FOwner: TDrawEngine;
    FCommandList: TCoreClassList;
  private
    FSourQueue: TDrawQueue;
    procedure Sync_PickQueue;
  public
    constructor Create(AOwner: TDrawEngine);
    destructor Destroy; override;

    procedure Clear;

    procedure PickQueue(Queue: TDrawQueue); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure PickQueue(Thread: TCoreClassThread; Queue: TDrawQueue); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure Execute(IDraw: IDrawEngineInterface); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    property Owner: TDrawEngine read FOwner;
  end;

  TPolyDrawOption = packed record
    LineColor: TDEColor;
    PointColor: TDEColor;
    LineWidth: TDEFloat;
    PointScreenRadius: TDEFloat;
  end;

  PPolyDrawOption = ^TPolyDrawOption;

  IDrawEngineResourceInterface = interface
    function GetTextureFromFile(F: SystemString): TDETexture;
  end;

  TDrawEngineViewOption  = (devpFPS, devpFrameEndge, devpTextBox, devpTextureState);
  TDrawEngineViewOptions = set of TDrawEngineViewOption;

  TDrawEngine_UIBase = class;

  TDrawEngine_UIClick = procedure(Sender: TDrawEngine_UIBase) of object;

  TDrawEngine_UIBase = class(TCoreClassPersistent)
  private
  public
    DataObject: TCoreClassObject;
    DataPointer: Pointer;
    DataVariant: Variant;
    Owner: TDrawEngine;
    OnClick: TDrawEngine_UIClick;
    Visibled: Boolean;

    constructor Create(AOwner: TDrawEngine);
    destructor Destroy; override;

    function TapDown(X, Y: TDEFloat): Boolean; virtual;
    function TapMove(X, Y: TDEFloat): Boolean; virtual;
    function TapUp(X, Y: TDEFloat): Boolean; virtual;

    procedure DoClick; virtual;

    procedure DoDraw; virtual;
  end;

  TDrawEngine_UIClass = class of TDrawEngine_UIBase;

  TDrawEngine_RectButton = class(TDrawEngine_UIBase)
  private
    Downed: Boolean;
    DownPT, MovePT, UpPT: TDEVec;
  public
    Button: TDERect;
    Text: SystemString;
    TextSize: Integer;

    constructor Create(AOwner: TDrawEngine);
    destructor Destroy; override;

    function TapDown(X, Y: TDEFloat): Boolean; override;
    function TapMove(X, Y: TDEFloat): Boolean; override;
    function TapUp(X, Y: TDEFloat): Boolean; override;

    procedure DoDraw; override;
  end;

  TScrollTextSource = class(TCoreClassPersistent)
  public
    LifeTime: Double;
    textRectSize: TDEVec;
    TextSize: Integer;
    TextColor: TDEColor;
    Text: SystemString;
    Tag: TCoreClassObject;
  end;

  TEffect = class;

  TSequenceAnimationPlayMode = (sapmLoop, sapmPlayOne);

  TSequenceAnimationBase = class(TCoreClassPersistent)
  protected
    Effect: TEffect;
    Owner: TDrawEngine;
    procedure Progress(deltaTime: Double); {$IFDEF INLINE_ASM}inline; {$ENDIF}
  public
    Source: TCoreClassObject;
    width: Integer;
    height: Integer;
    Total: Integer;
    Column: Integer;
    CompleteTime: Double;
    PlayMode: TSequenceAnimationPlayMode;
    OverAnimationSmoothTime: Double;
    flag: Variant;

    CurrentTime: Double;
    LastUsed: Boolean;

    constructor Create(AOwner: TDrawEngine); virtual;
    destructor Destroy; override;

    function SequenceAnimationPlaying: Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetOverAnimationSmoothAlpha(alpha: TDEFloat): TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function IsOver: Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SequenceIndex: Integer; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SequenceFrameRect: TDE4V; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure LoadFromStream(stream: TCoreClassStream);
    procedure SaveToStream(stream: TCoreClassStream);
  end;

  TParticleData = packed record
    Source: TSequenceAnimationBase;
    Position: TDEVec;
    radius: TDEFloat;
    angle: TDEFloat;
    alpha: TDEFloat;
    Acceleration: TDEFloat;
    CurrentTime: Double;
  end;

  PParticleData = ^TParticleData;

  TParticles = class(TCoreClassPersistent)
  protected
    Effect: TEffect;
    Owner: TDrawEngine;
    ParticleBuff: TCoreClassList;
    PrepareParticleCount: Double;
    NoEnabledAutoFree: Boolean;
    LastDrawPosition: TDEVec;

    procedure Progress(deltaTime: Double); {$IFDEF INLINE_ASM}inline; {$ENDIF}
  public
    SequenceTexture: TCoreClassObject;
    SequenceTextureCompleteTime: Double;
    MaxParticle: Integer;
    ParticleSize: TDEFloat;
    MinAlpha: TDEFloat;
    MaxAlpha: TDEFloat;
    GenerateRange: TDERect;
    Dispersion: TDEVec;
    DispersionAcceleration: TDEFloat;
    RotationOfSecond: TDEFloat;
    GenSpeedOfPerSecond: Integer;
    LifeTime: Double;
    Enabled: Boolean;
    Visible: Boolean;

    constructor Create(AOwner: TDrawEngine); virtual;
    destructor Destroy; override;

    function VisibledParticle: Integer; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FinishAndDelayFree; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure LoadFromStream(stream: TCoreClassStream);
    procedure SaveToStream(stream: TCoreClassStream);
  end;

  TTParticleClass = class of TParticles;

  TEffectMode = (emSequenceAnimation, emParticle, emNo);

  TEffect = class(TCoreClassPersistent)
  public
    Owner: TDrawEngine;
    Mode: TEffectMode;
    Particle: TParticles;
    SequenceAnimation: TSequenceAnimationBase;
    SequenceAnimation_Width: TDEFloat;
    SequenceAnimation_Height: TDEFloat;
    SequenceAnimation_Angle: TDEFloat;
    SequenceAnimation_Alpha: TDEFloat;

    constructor Create(AOwner: TDrawEngine); virtual;
    destructor Destroy; override;

    procedure Reset;

    procedure LoadFromStream(stream: TCoreClassStream);
    procedure SaveToStream(stream: TCoreClassStream);

    procedure Draw(pos: TDEVec); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawInScene(pos: TDEVec); {$IFDEF INLINE_ASM}inline; {$ENDIF}
  end;

  TGetTexture = procedure(TextureOfName: SystemString; var Texture: TDETexture);

  TDrawEngine = class(TCoreClassPersistent)
  protected
    FRasterInterface: TDrawEngine_Raster;
    FDrawInterface: IDrawEngineInterface;
    FDrawCommand: TDrawQueue;
    FDrawExecute: TDrawExecute;
    FScale: TDEFloat;
    FOffset: TDEVec;
    FResourceIntf: IDrawEngineResourceInterface;
    FCommandCounter: Integer;
    FPerformaceCounter: Cardinal;
    FLastPerformaceTime: TTimeTickValue;
    FFrameCounterOfPerSec: Double;
    FCommandCounterOfPerSec: Double;
    FWidth, FHeight: TDEFloat;
    FLastDeltaTime, FLastNewTime: Double;
    FViewOptions: TDrawEngineViewOptions;
    FLastDrawInfo: SystemString;
    FTextSizeCache: THashList;
    FScrollTextList: TCoreClassListForObj;
    FDownPT, FMovePT, FUpPT: TDEVec;
    FLastAcceptDownUI: TDrawEngine_UIBase;
    FUIList: TCoreClassListForObj;
    FSequenceAnimationBuffer: TCoreClassListForObj;
    FParticleBuffer: TCoreClassListForObj;
    FLastDynamicSeqenceFlag: Cardinal;
    FFPSFontColor: TDEColor;
    FScreenFrameColor: TDEColor;
    FTextureLibrary: THashObjectList;
    FOnGetTexture: TGetTexture;
    FDefaultTexture: TDETexture;

    // user
    FUserData: Pointer;
    FUserValue: Variant;
    FUserVariants: THashVariantList;
    FUserObjects: THashObjectList;
    FUserAutoFreeObjects: THashObjectList;

    FTextureOutputStateBox: TDERect;

    procedure DoFlush; virtual;

    function DoTapDown(X, Y: TDEFloat): Boolean; virtual;
    function DoTapMove(X, Y: TDEFloat): Boolean; virtual;
    function DoTapUp(X, Y: TDEFloat): Boolean; virtual;

    procedure TextSizeCacheDoDataFree(p: Pointer);

    function GetUserVariants: THashVariantList;
    function GetUserObjects: THashObjectList;
    function GetUserAutoFreeObjects: THashObjectList;
  public
    constructor Create(ADrawInterface: IDrawEngineInterface); overload; virtual;
    constructor Create; overload;
    destructor Destroy; override;

    property ResourceIntf: IDrawEngineResourceInterface read FResourceIntf write FResourceIntf;
    property ViewOptions: TDrawEngineViewOptions read FViewOptions write FViewOptions;
    property DrawOptions: TDrawEngineViewOptions read FViewOptions write FViewOptions;

    property LastDrawInfo: SystemString read FLastDrawInfo;

    function SceneToScreen(pt: TDEVec): TDEVec; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SceneToScreen(X, Y: TDEFloat): TDEVec; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SceneToScreen(R: TDE4V): TDE4V; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SceneToScreen(R: TDERect): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ScreenToScene(pt: TDEVec): TDEVec; overload;
    function ScreenToScene(X, Y: TDEFloat): TDEVec; overload;
    function ScreenToScene(R: TDERect): TDERect; overload;
    function ScreenToScene(R: TDE4V): TDE4V; overload;

    function SceneToScreenDistance(ScenePt1, ScenePt2: TDEVec): TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ScreenToSceneDistance(ScreenPt1, ScreenPt2: TDEVec): TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ScreenCenterOfWorld: TDEVec; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SceneRectFromScreen: TDERect; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ScreenRect: TDERect; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    property FrameCounterOfPerSec: Double read FFrameCounterOfPerSec;
    property CommandCounterOfPerSec: Double read FCommandCounterOfPerSec;

    function TapDown(X, Y: TDEFloat): Boolean;
    function TapMove(X, Y: TDEFloat): Boolean;
    function TapUp(X, Y: TDEFloat): Boolean;

    property Scale: TDEFloat read FScale write FScale;
    property Offset: TDEVec read FOffset write FOffset;

    property width: TDEFloat read FWidth;
    property height: TDEFloat read FHeight;

    function SceneWidth: TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SceneHeight: TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    property LastDeltaTime: Double read FLastDeltaTime;
    property LastNewTime: Double read FLastNewTime write FLastNewTime;

    function ReadyOK: Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetTextSize(Text: SystemString; Size: TDEFloat): TDEVec; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure SetSize; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure SetSize(w, h: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure SetSizeAndOffset(R: TDERect); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure ClearScrollText; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure PostScrollText(LifeTime: Double; Text: SystemString; Size: Integer; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure PostScrollText(Tag: TCoreClassObject; LifeTime: Double; Text: SystemString; Size: Integer; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetLastPostScrollText: SystemString; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure ClearUI; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure AllUINoVisibled; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure SetDrawBound(R: TDERect); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure SetDrawBound(R: TRectf); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure BeginCaptureShadow(const OffsetVec: TDEVec; const alpha: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure EndCaptureShadow; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function CaptureShadow: Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function LastCaptureShadowOffsetVec: TDEVec; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function LastCaptureShadowAlpha: TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { custom draw }
    procedure DrawUserCustom(const UserProc: TUserCustomDrawProc; const UserData: Pointer; const UserObject: TCoreClassObject); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw vec2List + Poly }
    procedure DrawPLInScene(pl: TVec2List; ClosedLine: Boolean; opt: TPolyDrawOption); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawPolyInScene(Poly: TPoly; ClosedLine: Boolean; opt: TPolyDrawOption); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawPolyExpandInScene(Poly: TPoly; ExpandDistance: TDEFloat; ClosedLine: Boolean; opt: TPolyDrawOption); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw line }
    procedure DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawLineInScene(pt1, pt2: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw DE4V rect }
    procedure DrawDE4V(d: TDE4V; COLOR: TDEColor; LineWidth: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawDE4VInScene(d: TDE4V; COLOR: TDEColor; LineWidth: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw point }
    procedure DrawPoint(pt: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawPointInScene(pt: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw box }
    procedure DrawBox(R: TDERect; angle: TGeoFloat; COLOR: TDEColor; LineWidth: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawBoxInScene(R: TDERect; angle: TGeoFloat; COLOR: TDEColor; LineWidth: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawBox(R: TDERect; COLOR: TDEColor; LineWidth: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawBoxInScene(R: TDERect; COLOR: TDEColor; LineWidth: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { fill box }
    procedure FillBox(R: TDERect; angle: TGeoFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillBoxInScene(R: TDERect; angle: TGeoFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillBox(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillBoxInScene(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw ellipse }
    procedure DrawEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawEllipse(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawEllipseInScene(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawEllipseInScene(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { fill ellipse }
    procedure FillEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillEllipse(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillEllipseInScene(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FillEllipseInScene(R: TDERect; COLOR: TDEColor); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw text }
    procedure DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawText(Text: SystemString; Size: TDEFloat; COLOR: TDEColor; ScreenPt: TDEVec); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextInScene(Text: SystemString; Size: TDEFloat; COLOR: TDEColor; ScenePos: TDEVec); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextInScene(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw texture }
    procedure DrawTexture(T: TCoreClassObject; sour, DestScreen: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTexture(T: TCoreClassObject; sour: TDERect; DestScreen: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTexture(T: TCoreClassObject; sour, DestScreen: TDERect; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTexture(T: TCoreClassObject; sour: TDERect; destScreenPt: TDEVec; angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTexture(T: TCoreClassObject; sour, DestScreen: TDERect; angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawTexture(indentEndge: Boolean; T: TCoreClassObject; sour, DestScreen: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { fit draw texture }
    procedure FitDrawTexture(T: TCoreClassObject; sour, destScene: TDERect; angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawTexture(T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawTexture(indentEndge: Boolean; T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { draw texture in scene }
    procedure DrawTextureInScene(T: TCoreClassObject; sour, destScene: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextureInScene(T: TCoreClassObject; sour: TDERect; destScene: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextureInScene(T: TCoreClassObject; destScene: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextureInScene(T: TCoreClassObject; sour: TDERect; destScenePt: TDEVec; angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawTextureInScene(T: TCoreClassObject; destScenePt: TDEVec; AWidth, AHeight, angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawTextureInScene(indentEndge: Boolean; T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { fit draw texture in scene }
    procedure FitDrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; angle, alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawTextureInScene(indentEndge: Boolean; T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { sequence animation }
    function CreateSequenceAnimation(stream: TCoreClassStream): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetOrCreateSequenceAnimation(flag: Variant; T: TCoreClassObject): TSequenceAnimationBase; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SequenceAnimationPlaying(flag: Variant; T: TCoreClassObject): Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function SequenceAnimationIsOver(flag: Variant; T: TCoreClassObject): Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ExistsSequenceAnimation(SA: TSequenceAnimationBase): Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetNewSequenceFlag: Variant; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ManualDrawSequenceTexture(flag: Variant; T: TCoreClassObject; TextureWidth, TextureHeight, Total, Column: Integer; CompleteTime: Double; Looped: Boolean;
      DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; virtual;
    function DrawSequenceTexture(flag: Variant; T: TCoreClassObject; TextureWidth, TextureHeight, Total, Column: Integer; CompleteTime: Double; Looped: Boolean;
      DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDERect; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawSequenceTexture(indentEndge: Boolean; flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawSequenceTexture(SA: TSequenceAnimationBase; DestScreen: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTextureInScene(flag: Variant; T: TCoreClassObject; TextureWidth, TextureHeight, Total, Column: Integer; CompleteTime: Double; Looped: Boolean;
      destScene: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDERect; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function DrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; destScene: TDE4V; alpha: TDEFloat): TSequenceAnimationBase; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function FitDrawSequenceTextureInScene(indentEndge: Boolean; flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDERect; alpha: TDEFloat): TDERect; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawSequenceTextureInScene(SA: TSequenceAnimationBase; destScene: TDE4V; alpha: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { particles }
    function CreateParticles: TParticles; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function CreateParticles(stream: TCoreClassStream): TParticles; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DeleteParticles(p: TParticles); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure FreeAndDeleteParticles(p: TParticles); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure ClearParticles; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ExistsParticles(p: TParticles): Boolean; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function TotalParticleData: Integer; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function ParticleCount: Integer; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetParticles(const index: Integer): TParticles; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    property Particles[const index: Integer]: TParticles read GetParticles;
    procedure DrawParticle(Particle: TParticles; DestScreen: TDEVec); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure DrawParticleInScene(Particle: TParticles; destScene: TDEVec); {$IFDEF INLINE_ASM}inline; {$ENDIF}
    { texture IO }
    function GetTexture(TextureName: SystemString): TDETexture; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetTextureName(T: TCoreClassObject): SystemString; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    class function NewTexture: TDETexture;

    { flush }
    procedure PrepareTextureOutputState; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure PrepareFlush; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure ClearFlush; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure Flush; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure Flush(Prepare: Boolean); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    procedure CopyFlushTo(Dst: TDrawExecute);

    { cadencer progress }
    procedure Progress(deltaTime: Double); virtual;

    { build-in rasterization }
    property Rasterization: TDrawEngine_Raster read FRasterInterface;
    { draw interface }
    property DrawInterface: IDrawEngineInterface read FDrawInterface write FDrawInterface;
    { prepare container }
    property DrawCommand: TDrawQueue read FDrawCommand;
    { implementation container }
    property DrawExecute: TDrawExecute read FDrawExecute;

    { misc }
    property FPSFontColor: TDEColor read FFPSFontColor write FFPSFontColor;
    property ScreenFrameColor: TDEColor read FScreenFrameColor write FScreenFrameColor;

    { texture }
    property TextureLibrary: THashObjectList read FTextureLibrary;
    property OnGetTexture: TGetTexture read FOnGetTexture write FOnGetTexture;
    property DefaultTexture: TDETexture read FDefaultTexture;
    property TextureOutputStateBox: TDERect read FTextureOutputStateBox write FTextureOutputStateBox;

    { user variant }
    property UserVariants: THashVariantList read GetUserVariants;
    property UserObjects: THashObjectList read GetUserObjects;
    property UserAutoFreeObjects: THashObjectList read GetUserAutoFreeObjects;
    property UserData: Pointer read FUserData write FUserData;
    property UserValue: Variant read FUserValue write FUserValue;
  end;

  PDrawEnginePoolData = ^TDrawEnginePoolData;

  TDrawEnginePoolData = packed record
    DrawEng: TDrawEngine;
    workObj: TCoreClassObject;
    LastActivted: Cardinal;
  end;

  TDrawEngineClass = class of TDrawEngine;

  TDrawEnginePool = class(TCoreClassPersistent)
  protected
    FDefaultDrawEngineClass: TDrawEngineClass;
    FDrawEngineList: TCoreClassList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure ClearActivtedTimeOut(tickLen: Cardinal);

    procedure Progress(deltaTime: Double);

    property DefaultDrawEngineClass: TDrawEngineClass read FDefaultDrawEngineClass write FDefaultDrawEngineClass;

    function GetEng(const workObj: TCoreClassObject; const ADrawInterface: IDrawEngineInterface): TDrawEngine; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
    function GetEng(const workObj: TCoreClassObject): TDrawEngine; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
  end;

  TDrawEngine_Raster = class(TCoreClassInterfacedObject, IDrawEngineInterface)
  private
    FDebug: Boolean;
    FMemory: TDETexture;
    FEngine: TDrawEngine;
    function DEColor2RasterColor(const COLOR: TDEColor): TRasterColor; overload;
    function DEColor2RasterColor(const COLOR: TDEColor; const alpha: Byte): TRasterColor; overload;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure SetSize(R: TDERect); virtual;
    procedure SetLineWidth(w: TDEFloat); virtual;
    procedure DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor); virtual;
    procedure DrawRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor); virtual;
    procedure FillRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor); virtual;
    procedure DrawEllipse(R: TDERect; COLOR: TDEColor); virtual;
    procedure FillEllipse(R: TDERect; COLOR: TDEColor); virtual;
    procedure DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat); virtual;
    procedure DrawTexture(T: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat); virtual;
    procedure Flush; virtual;
    procedure ResetState; virtual;
    procedure BeginDraw; virtual;
    procedure EndDraw; virtual;
    function CurrentScreenSize: TDEVec; virtual;
    function GetTextSize(Text: SystemString; Size: TDEFloat): TDEVec; virtual;
    function ReadyOK: Boolean; virtual;
    function EngineIntfObject: TCoreClassObject; virtual;
  public
    function Engine: TDrawEngine;
    property Memory: TDETexture read FMemory;
    property Debug: Boolean read FDebug write FDebug;
  end;

const
  NULLVec: TDEVec = (0, 0);

function DrawPool(workObj: TCoreClassObject; ADrawInterface: IDrawEngineInterface): TDrawEngine; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DrawPool(workObj: TCoreClassObject): TDrawEngine; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}

function DEVec(X, Y: TDEFloat): TDEVec; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DEVec(pt: TPointf): TDEVec; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DEColor(const R, g, b, A: TDEFloat): TDEColor; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DEColor(const C: TDEColor; const alpha: TDEFloat): TDEColor; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DEColor2RasterColor(const C: TDEColor): TRasterColor; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DEAlpha(C: TDEColor): TDEFloat; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DERect(const X, Y, radius: TDEFloat): TRectV2; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DERect(const x1, y1, x2, y2: TDEFloat): TRectV2; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DERect(const p1, p2: T2DPoint): TRectV2; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DERect(const X, Y: TDEFloat; const p2: T2DPoint): TRectV2; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DERect(const Rect: TRect): TRectV2; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
function DERect(const Rect: TRectf): TRectV2; overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}

function Interval2Delta(interval: Integer): Double; {$IFDEF INLINE_ASM}inline; {$ENDIF}

procedure FitScale(const sour, dest: TDERect; var outOffset: TDEVec; var outScale: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
procedure FitScale(const sour: TDERect; const DestWidth, DestHeight: TDEFloat; var outOffset: TDEVec; var outScale: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
procedure FitScale(const sour: TRectf; const DestWidth, DestHeight: TDEFloat; var outOffset: TDEVec; var outScale: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
procedure FitScale(const sour, dest: TRectf; var outOffset: TDEVec; var outScale: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}
procedure FitScale(const sourWidth, sourHeight, DestWidth, DestHeight: TDEFloat; var outOffset: TDEVec; var outScale: TDEFloat); overload; {$IFDEF INLINE_ASM}inline; {$ENDIF}


var
  DefaultTextureClass: TDETextureClass = TDETexture;
  EnginePool: TDrawEnginePool          = nil;

implementation

uses Math;

function DrawPool(workObj: TCoreClassObject; ADrawInterface: IDrawEngineInterface): TDrawEngine;
begin
  Result := EnginePool.GetEng(workObj, ADrawInterface);
end;

function DrawPool(workObj: TCoreClassObject): TDrawEngine;
begin
  Result := EnginePool.GetEng(workObj);
end;

function DEVec(X, Y: TDEFloat): TDEVec;
begin
  Result[0] := X;
  Result[1] := Y;
end;

function DEVec(pt: TPointf): TDEVec;
begin
  Result[0] := pt.X;
  Result[1] := pt.Y;
end;

function DEColor(const R, g, b, A: TDEFloat): TDEColor;
begin
  Result[0] := R;
  Result[1] := g;
  Result[2] := b;
  Result[3] := A;
end;

function DEColor(const C: TDEColor; const alpha: TDEFloat): TDEColor;
begin
  Result := C;
  Result[3] := alpha;
end;

function DEColor2RasterColor(const C: TDEColor): TRasterColor;
begin
  Result := RasterColorF(C[0], C[1], C[2], C[3]);
end;

function DEAlpha(C: TDEColor): TDEFloat;
begin
  Result := C[3];
end;

function DERect(const X, Y, radius: TDEFloat): TRectV2;
begin
  Result[0][0] := X - radius;
  Result[0][1] := Y - radius;
  Result[1][0] := X + radius;
  Result[1][1] := Y + radius;
end;

function DERect(const x1, y1, x2, y2: TDEFloat): TRectV2;
begin
  Result[0][0] := x1;
  Result[0][1] := y1;
  Result[1][0] := x2;
  Result[1][1] := y2;
end;

function DERect(const p1, p2: T2DPoint): TRectV2;
begin
  Result[0] := p1;
  Result[1] := p2;
end;

function DERect(const X, Y: TDEFloat; const p2: T2DPoint): TRectV2;
begin
  Result[0] := DEVec(X, Y);
  Result[1] := p2;
end;

function DERect(const Rect: TRect): TRectV2;
begin
  Result[0][0] := Rect.Left;
  Result[0][1] := Rect.Top;
  Result[1][0] := Rect.Right;
  Result[1][1] := Rect.Bottom;
end;

function DERect(const Rect: TRectf): TRectV2;
begin
  Result[0][0] := Rect.Left;
  Result[0][1] := Rect.Top;
  Result[1][0] := Rect.Right;
  Result[1][1] := Rect.Bottom;
end;

function Interval2Delta(interval: Integer): Double;
begin
  Result := 1.0 / (1000.0 / interval);
end;

procedure FitScale(const sour, dest: TDERect; var outOffset: TDEVec; var outScale: TDEFloat);
var
  R: TDERect;
begin
  // compute scale
  R := RectFit(sour, dest);
  outScale := RectWidth(R) / RectWidth(sour);
  outOffset := R[0];
end;

procedure FitScale(const sour: TDERect; const DestWidth, DestHeight: TDEFloat; var outOffset: TDEVec; var outScale: TDEFloat);
begin
  FitScale(sour, DERect(0, 0, DestWidth, DestHeight), outOffset, outScale);
end;

procedure FitScale(const sour: TRectf; const DestWidth, DestHeight: TDEFloat; var outOffset: TDEVec; var outScale: TDEFloat);
begin
  FitScale(DERect(sour), DERect(0, 0, DestWidth, DestHeight), outOffset, outScale);
end;

procedure FitScale(const sour, dest: TRectf; var outOffset: TDEVec; var outScale: TDEFloat);
begin
  FitScale(DERect(sour), DERect(dest), outOffset, outScale);
end;

procedure FitScale(const sourWidth, sourHeight, DestWidth, DestHeight: TDEFloat; var outOffset: TDEVec; var outScale: TDEFloat);
begin
  FitScale(DERect(0, 0, sourWidth, sourHeight), DERect(0, 0, DestWidth, DestHeight), outOffset, outScale);
end;

function TDETexture.GetStaticShadow: TDETexture;
var
  i: Integer;
  p1, p2: PRasterColorEntry;
begin
  if FStaticShadow = nil then
    begin
      if not IsStaticShadow then
        begin
          FStaticShadow := DefaultTextureClass.Create;
          FStaticShadow.IsStaticShadow := True;
          FStaticShadow.SetSize(width, height);
          for i := (width * height) - 1 downto 0 do
            begin
              p1 := @Bits^[i];
              p2 := @FStaticShadow.Bits^[i];
              p2^.RGBA := RasterColor(0, 0, 0, p1^.A);
            end;
        end
      else
          Result := Self;
    end;
  Result := FStaticShadow;
end;

constructor TDETexture.Create;
begin
  inherited Create;
  FStaticShadow := nil;
  IsStaticShadow := False;
end;

destructor TDETexture.Destroy;
begin
  if FStaticShadow <> nil then
      DisposeObject(FStaticShadow);
  inherited Destroy;
end;

procedure TDETexture.ReleaseFMXResource;
begin
end;

procedure TDETexture.FastUpdateTexture;
begin
end;

function TDE4V.IsZero: Boolean;
begin
  Result :=
    Geometry2DUnit.IsZero(Left) and
    Geometry2DUnit.IsZero(Top) and
    Geometry2DUnit.IsZero(Right) and
    Geometry2DUnit.IsZero(Bottom);
end;

function TDE4V.width: TDEFloat;
begin
  if Right > Left then
      Result := Right - Left
  else
      Result := Left - Right;
end;

function TDE4V.height: TDEFloat;
begin
  if Bottom > Top then
      Result := Bottom - Top
  else
      Result := Top - Bottom;
end;

function TDE4V.MakeRectV2: TDERect;
begin
  Result := DERect(Left, Top, Right, Bottom);
end;

function TDE4V.MakeRectf: TRectf;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Right;
  Result.Bottom := Bottom;
end;

function TDE4V.BoundRect: TDERect;
begin
  Result := Geometry2DUnit.TV2Rect4.Init(MakeRectV2, angle).BoundRect;
end;

function TDE4V.Centroid: TDEVec;
begin
  Result := Geometry2DUnit.TV2Rect4.Init(MakeRectV2, angle).Centroid;
end;

function TDE4V.Add(v: TDEVec): TDE4V;
var
  R: TRectV2;
begin
  R := MakeRectV2;
  R[0] := Vec2Add(R[0], v);
  R[1] := Vec2Add(R[1], v);
  Result := Init(R, angle);
end;

function TDE4V.Add(X, Y: TDEFloat): TDE4V;
var
  R: TRectV2;
begin
  R := MakeRectV2;
  R[0] := Vec2Add(R[0], X, Y);
  R[1] := Vec2Add(R[1], X, Y);
  Result := Init(R, angle);
end;

function TDE4V.Scale(F: TDEFloat): TDE4V;
begin
  Result.Left := Left * F;
  Result.Top := Top * F;
  Result.Right := Right * F;
  Result.Bottom := Bottom * F;
  Result.angle := angle;
end;

function TDE4V.GetDistance(dest: TDE4V): TDEFloat;
begin
  Result := Geometry3DUnit.Distance(MakeRectV2, dest.MakeRectV2);
end;

function TDE4V.GetAngleDistance(dest: TDE4V): TDEFloat;
begin
  Result := Geometry3DUnit.AngleDistance(angle, dest.angle);
end;

function TDE4V.MovementToLerp(dest: TDE4V; mLerp, rLerp: Double): TDE4V;
var
  R: TDERect;
begin
  Result.angle := MovementLerp(angle, dest.angle, rLerp);

  R := MovementLerp(MakeRectV2, dest.MakeRectV2, mLerp);
  Result.Left := R[0][0];
  Result.Top := R[0][1];
  Result.Right := R[1][0];
  Result.Bottom := R[1][1];
end;

function TDE4V.MovementToDistance(dest: TDE4V; mSpeed, rSpeed: TDEFloat): TDE4V;
var
  R: TDERect;
begin
  Result.angle := SmoothAngle(angle, dest.angle, rSpeed);

  R := MovementDistance(MakeRectV2, dest.MakeRectV2, mSpeed);
  Result.Left := R[0][0];
  Result.Top := R[0][1];
  Result.Right := R[1][0];
  Result.Bottom := R[1][1];
end;

function TDE4V.MovementToDistanceCompleteTime(dest: TDE4V; mSpeed, rSpeed: TDEFloat): Double;
var
  d1, d2: Double;
begin
  d1 := Geometry3DUnit.AngleRollDistanceDeltaTime(angle, dest.angle, rSpeed);
  d2 := Geometry3DUnit.MovementDistanceDeltaTime(MakeRectV2, dest.MakeRectV2, mSpeed);
  if d1 > d2 then
      Result := d1
  else
      Result := d2;
end;

function TDE4V.Fit(dest: TDE4V): TDE4V;
var
  R: TDERect;
begin
  R := RectFit(dest.MakeRectV2, MakeRectV2);
  Result.angle := angle;
  Result.Left := R[0][0];
  Result.Top := R[0][1];
  Result.Right := R[1][0];
  Result.Bottom := R[1][1];
end;

function TDE4V.Fit(dest: TDERect): TDE4V;
var
  R: TDERect;
begin
  R := RectFit(dest, MakeRectV2);
  Result.angle := angle;
  Result.Left := R[0][0];
  Result.Top := R[0][1];
  Result.Right := R[1][0];
  Result.Bottom := R[1][1];
end;

class function TDE4V.Init(R: TDERect; Ang: TDEFloat): TDE4V;
begin
  with Result do
    begin
      Left := R[0][0];
      Top := R[0][1];
      Right := R[1][0];
      Bottom := R[1][1];
      angle := Ang;
    end;
end;

class function TDE4V.Init(R: TRectf; Ang: TDEFloat): TDE4V;
begin
  Result := Init(DERect(R), Ang);
end;

class function TDE4V.Init(R: TRect; Ang: TDEFloat): TDE4V;
begin
  Result := Init(DERect(R), Ang);
end;

class function TDE4V.Init(CenPos: TDEVec; AWidth, AHeight, Ang: TDEFloat): TDE4V;
var
  R: TDERect;
begin
  R[0][0] := CenPos[0] - AWidth * 0.5;
  R[0][1] := CenPos[1] - AHeight * 0.5;
  R[1][0] := CenPos[0] + AWidth * 0.5;
  R[1][1] := CenPos[1] + AHeight * 0.5;
  Result := Init(R, Ang);
end;

class function TDE4V.Init(AWidth, AHeight, Ang: TDEFloat): TDE4V;
begin
  Result := Init(DERect(0, 0, AWidth, AHeight), Ang);
end;

class function TDE4V.Init: TDE4V;
begin
  Result := Init(ZeroRect, 0);
end;

procedure TDrawCommand.DoFreeData;
begin
  case T of
    dctSetLineWidth: Dispose(PDrawCommandParam_1Float(Data));
    dctLine: Dispose(PDrawCommandParam_PT_Color(Data));
    dctSetSize: Dispose(PDrawCommandParam_1Rect(Data));
    dctDrawRect, dctFillRect, dctDrawEllipse, dctFillEllipse: Dispose(PDrawCommandParam_Rect_Color(Data));
    dctDrawText: Dispose(PDrawCommandParam_Textout(Data));
    dctDrawTexture: Dispose(PDrawCommandParam_Texture(Data));
    dctUserCustom: Dispose(PDrawCommandParam_UserCustom(Data));
  end;
end;

procedure TDrawCommand.Execute(OwnerDrawExecute: TDrawExecute; IDraw: IDrawEngineInterface);
begin
  case T of
    dctSetSize: with PDrawCommandParam_1Rect(Data)^ do
          IDraw.SetSize(R);
    dctSetLineWidth: with PDrawCommandParam_1Float(Data)^ do
          IDraw.SetLineWidth(F);
    dctLine: with PDrawCommandParam_PT_Color(Data)^ do
          IDraw.DrawLine(pt1, pt2, COLOR);
    dctDrawRect: with PDrawCommandParam_Rect_Color(Data)^ do
          IDraw.DrawRect(R, angle, COLOR);
    dctFillRect: with PDrawCommandParam_Rect_Color(Data)^ do
          IDraw.FillRect(R, angle, COLOR);
    dctDrawEllipse: with PDrawCommandParam_Rect_Color(Data)^ do
          IDraw.DrawEllipse(R, COLOR);
    dctFillEllipse: with PDrawCommandParam_Rect_Color(Data)^ do
          IDraw.FillEllipse(R, COLOR);
    dctDrawText: with PDrawCommandParam_Textout(Data)^ do
          IDraw.DrawText(Text, Size, R, COLOR, center, RotateVec, angle);
    dctDrawTexture: with PDrawCommandParam_Texture(Data)^ do
          IDraw.DrawTexture(T, sour, dest, alpha);
    dctUserCustom: with PDrawCommandParam_UserCustom(Data)^ do
          UserProc(OwnerDrawExecute.FOwner, UserData, UserObject);
    dctFlush: IDraw.Flush;
  end;
end;

procedure TDrawCommand.copyto(var Dst: TDrawCommand);
begin
  Dst.T := T;
  Dst.Data := nil;
  case T of
    dctSetSize:
      begin
        new(PDrawCommandParam_1Rect(Dst.Data));
        PDrawCommandParam_1Rect(Dst.Data)^ := PDrawCommandParam_1Rect(Data)^;
      end;
    dctSetLineWidth:
      begin
        new(PDrawCommandParam_1Float(Dst.Data));
        PDrawCommandParam_1Float(Dst.Data)^ := PDrawCommandParam_1Float(Data)^;
      end;
    dctLine:
      begin
        new(PDrawCommandParam_PT_Color(Dst.Data));
        PDrawCommandParam_PT_Color(Dst.Data)^ := PDrawCommandParam_PT_Color(Data)^;
      end;
    dctDrawRect:
      begin
        new(PDrawCommandParam_Rect_Color(Dst.Data));
        PDrawCommandParam_Rect_Color(Dst.Data)^ := PDrawCommandParam_Rect_Color(Data)^;
      end;
    dctFillRect:
      begin
        new(PDrawCommandParam_Rect_Color(Dst.Data));
        PDrawCommandParam_Rect_Color(Dst.Data)^ := PDrawCommandParam_Rect_Color(Data)^;
      end;
    dctDrawEllipse:
      begin
        new(PDrawCommandParam_Rect_Color(Dst.Data));
        PDrawCommandParam_Rect_Color(Dst.Data)^ := PDrawCommandParam_Rect_Color(Data)^;
      end;
    dctFillEllipse:
      begin
        new(PDrawCommandParam_Rect_Color(Dst.Data));
        PDrawCommandParam_Rect_Color(Dst.Data)^ := PDrawCommandParam_Rect_Color(Data)^;
      end;
    dctDrawText:
      begin
        new(PDrawCommandParam_Textout(Dst.Data));
        PDrawCommandParam_Textout(Dst.Data)^ := PDrawCommandParam_Textout(Data)^;
      end;
    dctDrawTexture:
      begin
        new(PDrawCommandParam_Texture(Dst.Data));
        PDrawCommandParam_Texture(Dst.Data)^ := PDrawCommandParam_Texture(Data)^;
      end;
    dctUserCustom:
      begin
        new(PDrawCommandParam_UserCustom(Dst.Data));
        PDrawCommandParam_UserCustom(Dst.Data)^ := PDrawCommandParam_UserCustom(Data)^;
      end;
  end;
end;

constructor TDrawQueue.Create(AOwner: TDrawEngine);
begin
  inherited Create;
  FOwner := AOwner;
  FCommandList := TCoreClassList.Create;
  FStartDrawShadowIndex := -1;
  FShadowVec := NULLVec;
  FShadowAlpha := 0.5;
end;

destructor TDrawQueue.Destroy;
begin
  Clear(True);
  DisposeObject(FCommandList);
  inherited Destroy;
end;

procedure TDrawQueue.Assign(Source: TDrawQueue);
var
  i: Integer;
  p: PDrawCommand;
begin
  LockObject(FCommandList);
  LockObject(Source.FCommandList);
  for i := 0 to Source.FCommandList.Count - 1 do
    begin
      new(p);
      PDrawCommand(Source.FCommandList[i])^.copyto(p^);
      FCommandList.Add(p);
    end;
  UnLockObject(FCommandList);
  UnLockObject(Source.FCommandList);
end;

procedure TDrawQueue.Clear(ForceFree: Boolean);
var
  i: Integer;
  p: PDrawCommand;
begin
  for i := 0 to FCommandList.Count - 1 do
    begin
      p := FCommandList[i];
      if ForceFree then
          p^.DoFreeData;
      Dispose(p);
    end;
  FCommandList.Clear;
end;

procedure TDrawQueue.SetSize(R: TDERect);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_1Rect;
begin
  new(p);
  new(Data);

  Data^.R := R;

  p^.T := dctSetSize;
  p^.Data := Data;

  LockObject(FCommandList);
  FCommandList.Add(p);
  UnLockObject(FCommandList);
end;

procedure TDrawQueue.SetLineWidth(w: TDEFloat);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_1Float;
begin
  new(p);
  new(Data);

  Data^.F := w;

  p^.T := dctSetLineWidth;
  p^.Data := Data;

  LockObject(FCommandList);
  FCommandList.Add(p);
  UnLockObject(FCommandList);
end;

procedure TDrawQueue.DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_PT_Color;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      new(p);
      new(Data);

      Data^.pt1 := pt1;
      Data^.pt2 := pt2;
      Data^.COLOR := COLOR;

      p^.T := dctLine;
      p^.Data := Data;

      LockObject(FCommandList);
      FCommandList.Add(p);
      UnLockObject(FCommandList);
    end;
end;

procedure TDrawQueue.DrawRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_Rect_Color;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      new(p);
      new(Data);

      Data^.R := R;
      Data^.angle := angle;
      Data^.COLOR := COLOR;

      p^.T := dctDrawRect;
      p^.Data := Data;

      LockObject(FCommandList);
      FCommandList.Add(p);
      UnLockObject(FCommandList);
    end;
end;

procedure TDrawQueue.FillRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_Rect_Color;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      new(p);
      new(Data);

      Data^.R := R;
      Data^.angle := angle;
      Data^.COLOR := COLOR;

      p^.T := dctFillRect;
      p^.Data := Data;

      LockObject(FCommandList);
      FCommandList.Add(p);
      UnLockObject(FCommandList);
    end;
end;

procedure TDrawQueue.DrawEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor);
var
  R: TDERect;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      R[0][0] := pt[0] - radius;
      R[0][1] := pt[1] - radius;
      R[1][0] := pt[0] + radius;
      R[1][1] := pt[1] + radius;
      DrawEllipse(R, COLOR);
    end;
end;

procedure TDrawQueue.DrawEllipse(R: TDERect; COLOR: TDEColor);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_Rect_Color;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      new(p);
      new(Data);

      Data^.R := R;
      Data^.COLOR := COLOR;

      p^.T := dctDrawEllipse;
      p^.Data := Data;

      LockObject(FCommandList);
      FCommandList.Add(p);
      UnLockObject(FCommandList);
    end;
end;

procedure TDrawQueue.FillEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor);
var
  R: TDERect;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      R[0][0] := pt[0] - radius;
      R[0][1] := pt[1] - radius;
      R[1][0] := pt[0] + radius;
      R[1][1] := pt[1] + radius;
      FillEllipse(R, COLOR);
    end;
end;

procedure TDrawQueue.FillEllipse(R: TDERect; COLOR: TDEColor);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_Rect_Color;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      new(p);
      new(Data);

      Data^.R := R;
      Data^.COLOR := COLOR;

      p^.T := dctFillEllipse;
      p^.Data := Data;

      LockObject(FCommandList);
      FCommandList.Add(p);
      UnLockObject(FCommandList);
    end;
end;

procedure TDrawQueue.DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat);
var
  PrepareDraw: Boolean;
  p: PDrawCommand;
  Data: PDrawCommandParam_Textout;
begin
  if DEAlpha(COLOR) > 0 then
    begin
      PrepareDraw := False;
      PrepareDraw := PrepareDraw or RectWithinRect(R, Owner.ScreenRect);
      PrepareDraw := PrepareDraw or RectWithinRect(Owner.ScreenRect, R);
      PrepareDraw := PrepareDraw or RectToRectIntersect(Owner.ScreenRect, R);
      PrepareDraw := PrepareDraw or RectToRectIntersect(R, Owner.ScreenRect);
      if PrepareDraw then
        begin
          new(p);
          new(Data);

          Data^.Text := Text;
          Data^.Size := Size;
          Data^.R := R;
          Data^.COLOR := COLOR;
          Data^.center := center;
          Data^.RotateVec := RotateVec;
          Data^.angle := angle;

          Data^.bak_r := Data^.R;
          Data^.bak_color := Data^.COLOR;

          p^.T := dctDrawText;
          p^.Data := Data;

          if (FStartDrawShadowIndex >= 0) then
            begin
              Data^.R := Geometry2DUnit.RectOffset(Data^.R, FShadowVec);
              Data^.COLOR := DEColor(0, 0, 0, Data^.COLOR[3] * FShadowAlpha);
            end;

          LockObject(FCommandList);
          FCommandList.Add(p);
          UnLockObject(FCommandList);
        end;
    end;
end;

procedure TDrawQueue.DrawTexture(T: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat);
var
  PrepareDraw: Boolean;
  p: PDrawCommand;
  Data: PDrawCommandParam_Texture;
  R: TDERect;
begin
  if alpha > 0 then
    begin
      R := dest.BoundRect;
      PrepareDraw := False;
      PrepareDraw := PrepareDraw or RectWithinRect(R, Owner.ScreenRect);
      PrepareDraw := PrepareDraw or RectWithinRect(Owner.ScreenRect, R);
      PrepareDraw := PrepareDraw or RectToRectIntersect(Owner.ScreenRect, R);
      PrepareDraw := PrepareDraw or RectToRectIntersect(R, Owner.ScreenRect);
      if PrepareDraw then
        begin
          new(p);
          new(Data);

          Data^.T := T;
          Data^.sour := sour;
          Data^.dest := dest;
          Data^.alpha := alpha;

          Data^.bak_t := T;
          Data^.bak_dest := dest;
          Data^.bak_alpha := alpha;

          p^.T := dctDrawTexture;
          p^.Data := Data;

          if (FStartDrawShadowIndex >= 0) and (Data^.T is TDETexture) and (not TDETexture(Data^.T).IsStaticShadow) then
            begin
              Data^.T := TDETexture(Data^.T).GetStaticShadow;
              Data^.dest := Data^.dest.Add(FShadowVec);
              Data^.alpha := Data^.alpha * FShadowAlpha;
            end;

          LockObject(FCommandList);
          FCommandList.Add(p);
          UnLockObject(FCommandList);
        end;
    end;
end;

procedure TDrawQueue.DrawUserCustom(const UserProc: TUserCustomDrawProc; const UserData: Pointer; const UserObject: TCoreClassObject);
var
  p: PDrawCommand;
  Data: PDrawCommandParam_UserCustom;
begin
  new(p);
  new(Data);

  Data^.UserProc := UserProc;
  Data^.UserData := UserData;
  Data^.UserObject := UserObject;

  p^.T := dctUserCustom;
  p^.Data := Data;

  LockObject(FCommandList);
  FCommandList.Add(p);
  UnLockObject(FCommandList);
end;

procedure TDrawQueue.Flush;
var
  p: PDrawCommand;
begin
  new(p);

  p^.T := dctFlush;
  p^.Data := nil;

  LockObject(FCommandList);
  FCommandList.Add(p);
  UnLockObject(FCommandList);
end;

procedure TDrawQueue.BeginCaptureShadow(const OffsetVec: TDEVec; const alpha: TDEFloat);
begin
  EndCaptureShadow;
  FStartDrawShadowIndex := FCommandList.Count;
  FShadowVec := OffsetVec;
  FShadowAlpha := alpha;
end;

procedure TDrawQueue.EndCaptureShadow;
var
  i, b: Integer;
  lst: TCoreClassList;

  p: PDrawCommand;
  pTextureData: PDrawCommandParam_Texture;
  pTextData: PDrawCommandParam_Textout;
begin
  if FStartDrawShadowIndex >= 0 then
    begin
      i := FStartDrawShadowIndex;
      b := FStartDrawShadowIndex;
      FStartDrawShadowIndex := -1;

      lst := TCoreClassList.Create;

      while i < FCommandList.Count do
        begin
          p := PDrawCommand(FCommandList[i]);
          if (p^.T = dctDrawTexture) and (PDrawCommandParam_Texture(p^.Data)^.T is TDETexture) and
            (TDETexture(PDrawCommandParam_Texture(p^.Data)^.T).IsStaticShadow) then
            begin
              new(pTextureData);
              pTextureData^ := PDrawCommandParam_Texture(p^.Data)^;
              pTextureData^.T := pTextureData^.bak_t;
              pTextureData^.dest := pTextureData^.bak_dest;
              pTextureData^.alpha := pTextureData^.bak_alpha;

              new(p);
              p^.T := dctDrawTexture;
              p^.Data := pTextureData;
              lst.Add(p);
              Inc(i);
            end
          else if (p^.T = dctDrawText) then
            begin
              new(pTextData);
              pTextData^ := PDrawCommandParam_Textout(p^.Data)^;
              pTextData^.R := pTextData^.bak_r;
              pTextData^.COLOR := pTextData^.bak_color;

              new(p);
              p^.T := dctDrawText;
              p^.Data := pTextData;
              lst.Add(p);
              Inc(i);
            end
          else
            begin
              lst.Add(p);
              FCommandList.Delete(i);
            end;
        end;

      LockObject(FCommandList);
      for i := 0 to lst.Count - 1 do
          FCommandList.Add(lst[i]);
      UnLockObject(FCommandList);

      DisposeObject(lst);
    end;
end;

procedure TDrawQueue.BuildTextureOutputState(var buff: TTextureOutputStateBuffer);
var
  i, J: Integer;
  p: PDrawCommand;
  ptex: PDrawCommandParam_Texture;
begin
  try
    J := 0;

    for i := 0 to FCommandList.Count - 1 do
      if PDrawCommand(FCommandList[i])^.T = dctDrawTexture then
          Inc(J);

    SetLength(buff, J);

    J := 0;
    for i := 0 to FCommandList.Count - 1 do
      begin
        p := PDrawCommand(FCommandList[i]);
        if p^.T = dctDrawTexture then
          begin
            ptex := PDrawCommandParam_Texture(p^.Data);
            buff[J].Source := ptex^.T;
            buff[J].SourceRect := ptex^.sour;
            buff[J].DestScreen := ptex^.dest;
            buff[J].alpha := ptex^.alpha;
            buff[J].index := i;

            Inc(J);
          end;
      end;
  except
  end;
end;

constructor TDrawExecute.Create(AOwner: TDrawEngine);
begin
  inherited Create;
  FOwner := AOwner;
  FCommandList := TCoreClassList.Create;
  FSourQueue := nil;
end;

destructor TDrawExecute.Destroy;
begin
  Clear;

  DisposeObject(FCommandList);
  inherited Destroy;
end;

procedure TDrawExecute.Clear;
var
  i: Integer;
  p: PDrawCommand;
begin
  for i := 0 to FCommandList.Count - 1 do
    begin
      p := FCommandList[i];
      p^.DoFreeData;
      Dispose(p);
    end;
  FCommandList.Clear;
end;

procedure TDrawExecute.PickQueue(Queue: TDrawQueue);
var
  i: Integer;
begin
  LockObject(Queue.FCommandList);
  for i := 0 to Queue.FCommandList.Count - 1 do
      FCommandList.Add(Queue.FCommandList[i]);
  Queue.FCommandList.Clear;
  UnLockObject(Queue.FCommandList);
end;

procedure TDrawExecute.PickQueue(Thread: TCoreClassThread; Queue: TDrawQueue);
begin
  FSourQueue := Queue;
  Thread.Synchronize(Thread, {$IFDEF FPC}@{$ENDIF FPC}Sync_PickQueue);
  FSourQueue := nil;
end;

procedure TDrawExecute.Sync_PickQueue;
begin
  PickQueue(FSourQueue);
end;

procedure TDrawExecute.Execute(IDraw: IDrawEngineInterface);
var
  i: Integer;
  p: PDrawCommand;
begin
  IDraw.ResetState;
  IDraw.BeginDraw;
  try
    for i := 0 to FCommandList.Count - 1 do
        PDrawCommand(FCommandList[i])^.Execute(Self, IDraw);
  except
  end;
  IDraw.Flush;
  IDraw.EndDraw;

  for i := 0 to FCommandList.Count - 1 do
    begin
      p := FCommandList[i];
      p^.DoFreeData;
      Dispose(p);
    end;
  FCommandList.Clear;
end;

constructor TDrawEngine_UIBase.Create(AOwner: TDrawEngine);
begin
  inherited Create;
  DataObject := nil;
  DataPointer := nil;
  DataVariant := Null;
  Owner := AOwner;
  OnClick := nil;
  Visibled := True;

  Owner.FUIList.Add(Self);
end;

destructor TDrawEngine_UIBase.Destroy;
var
  i: Integer;
begin
  i := 0;
  while Owner.FUIList.Count > i do
    begin
      if Owner.FUIList[i] = Self then
          Owner.FUIList.Delete(i)
      else
          Inc(i);
    end;

  inherited Destroy;
end;

function TDrawEngine_UIBase.TapDown(X, Y: TDEFloat): Boolean;
begin
  Result := False;
end;

function TDrawEngine_UIBase.TapMove(X, Y: TDEFloat): Boolean;
begin
  Result := False;
end;

function TDrawEngine_UIBase.TapUp(X, Y: TDEFloat): Boolean;
begin
  Result := False;
end;

procedure TDrawEngine_UIBase.DoClick;
begin
  if Assigned(OnClick) then
      OnClick(Self);
end;

procedure TDrawEngine_UIBase.DoDraw;
begin
end;

constructor TDrawEngine_RectButton.Create(AOwner: TDrawEngine);
begin
  inherited Create(AOwner);
  Downed := False;
  DownPT := NULLPoint;
  MovePT := NULLPoint;
  UpPT := NULLPoint;
  Button := NULLRect;
  TextSize := 9;
end;

destructor TDrawEngine_RectButton.Destroy;
begin
  inherited Destroy;
end;

function TDrawEngine_RectButton.TapDown(X, Y: TDEFloat): Boolean;
begin
  if PointInRect(DEVec(X, Y), Button) then
    begin
      Downed := True;
      DownPT := DEVec(X, Y);
      MovePT := DownPT;
      UpPT := DownPT;
      Result := True;
    end
  else
    begin
      Result := inherited TapDown(X, Y);
      Downed := False;
      DownPT := NULLPoint;
      MovePT := NULLPoint;
      UpPT := NULLPoint;
    end;
end;

function TDrawEngine_RectButton.TapMove(X, Y: TDEFloat): Boolean;
begin
  if Downed then
    begin
      MovePT := DEVec(X, Y);
      UpPT := MovePT;
      Result := True;
    end
  else
    begin
      Result := inherited TapMove(X, Y);
    end;
end;

function TDrawEngine_RectButton.TapUp(X, Y: TDEFloat): Boolean;
begin
  if Downed then
    begin
      UpPT := DEVec(X, Y);
      DoClick;
      Downed := False;
      Result := True;
    end
  else
    begin
      Result := inherited TapUp(X, Y);
    end;
end;

procedure TDrawEngine_RectButton.DoDraw;
var
  R: TDERect;
  C: TDEColor;
begin
  inherited DoDraw;
  if Downed then
    begin
      R := Button;
      R[0] := Vec2Add(R[0], PointMake(2, 2));
      R[1] := Vec2Add(R[1], PointMake(2, 2));
    end
  else
      R := Button;

  Owner.FDrawCommand.SetLineWidth(1);
  C := DEColor(0, 0, 0, 0.0);
  Owner.FDrawCommand.FillRect(R, 0, C);
  C := DEColor(1, 1, 1, 1);
  Owner.FDrawCommand.DrawRect(R, 0, C);
  Owner.FDrawCommand.DrawText(Text, TextSize, R, C, True, DEVec(0.5, 0.5), 0);
end;

procedure TSequenceAnimationBase.Progress(deltaTime: Double);
begin
  CurrentTime := CurrentTime + deltaTime;

  if PlayMode = sapmLoop then
    begin
      while (CurrentTime > CompleteTime) do
          CurrentTime := CurrentTime - CompleteTime;
    end;
end;

constructor TSequenceAnimationBase.Create(AOwner: TDrawEngine);
begin
  inherited Create;
  Effect := nil;
  Owner := AOwner;
  Source := nil;
  width := 0;
  height := 0;
  Total := 0;
  Column := 0;
  CompleteTime := 0;
  PlayMode := sapmPlayOne;
  OverAnimationSmoothTime := 0.5;
  flag := Null;
  CurrentTime := 0;
  LastUsed := False;
end;

destructor TSequenceAnimationBase.Destroy;
begin
  if Effect <> nil then
      Effect.SequenceAnimation := nil;
  inherited Destroy;
end;

function TSequenceAnimationBase.SequenceAnimationPlaying: Boolean;
begin
  Result := CurrentTime <= CompleteTime;
end;

function TSequenceAnimationBase.GetOverAnimationSmoothAlpha(alpha: TDEFloat): TDEFloat;
var
  v: TDEFloat;
begin
  if SequenceAnimationPlaying then
      Result := alpha
  else
    begin
      v := CurrentTime - CompleteTime;
      if (v > OverAnimationSmoothTime) then
          Result := 0.0
      else if v > 0 then
        begin
          Result := alpha - (1.0 / (OverAnimationSmoothTime / v));
          if Result < 0 then
              Result := 0.0;
        end
      else
          Result := alpha;
    end;
end;

function TSequenceAnimationBase.IsOver: Boolean;
begin
  Result := (not SequenceAnimationPlaying) and (CurrentTime > CompleteTime + OverAnimationSmoothTime);
end;

function TSequenceAnimationBase.SequenceIndex: Integer;
begin
  if CurrentTime <= CompleteTime then
      Result := Round((CurrentTime / CompleteTime) * (Total - 1))
  else
      Result := Total - 1;
end;

function TSequenceAnimationBase.SequenceFrameRect: TDE4V;
var
  idx: Integer;
  rowIdx, colIdx: Integer;
  Row: Integer;
  AWidth, AHeight: Integer;
begin
  if Total <= 1 then
      Exit(TDE4V.Init(width, height, 0));

  if Column > Total then
      Column := Total;

  idx := SequenceIndex;
  colIdx := idx mod Column;
  rowIdx := idx div Column;
  Row := Total div Column;
  if Total mod Column > 0 then
      Inc(Row);

  AWidth := width div Column;
  AHeight := height div Row;

  Result := TDE4V.Init(Rect(colIdx * AWidth, rowIdx * AHeight, colIdx * AWidth + AWidth, rowIdx * AHeight + AHeight), 0);
end;

procedure TSequenceAnimationBase.LoadFromStream(stream: TCoreClassStream);
var
  df: TDataFrameEngine;
begin
  df := TDataFrameEngine.Create;
  df.LoadFromStream(stream);

  Source := Owner.GetTexture(df.Reader.ReadString);
  width := df.Reader.ReadInteger;
  height := df.Reader.ReadInteger;
  Total := df.Reader.ReadInteger;
  Column := df.Reader.ReadInteger;
  CompleteTime := df.Reader.ReadDouble;
  PlayMode := TSequenceAnimationPlayMode(df.Reader.ReadInteger);

  flag := Owner.GetNewSequenceFlag;

  CurrentTime := 0;
  LastUsed := True;

  DisposeObject(df);
end;

procedure TSequenceAnimationBase.SaveToStream(stream: TCoreClassStream);
var
  df: TDataFrameEngine;
begin
  df := TDataFrameEngine.Create;

  df.WriteString(Owner.GetTextureName(Source));
  df.WriteInteger(width);
  df.WriteInteger(height);
  df.WriteInteger(Total);
  df.WriteInteger(Column);
  df.WriteDouble(CompleteTime);
  df.WriteInteger(Integer(PlayMode));

  df.SaveToStream(stream);
  DisposeObject(df);
end;

procedure TParticles.Progress(deltaTime: Double);
var
  p: PParticleData;
  i: Integer;
  k: TDEFloat;
begin
  // gen particle
  if Enabled then
    begin
      PrepareParticleCount := PrepareParticleCount + (deltaTime * GenSpeedOfPerSecond);
      while PrepareParticleCount >= 1 do
        begin
          PrepareParticleCount := PrepareParticleCount - 1;

          new(p);
          p^.Source := Owner.GetOrCreateSequenceAnimation(Owner.GetNewSequenceFlag, SequenceTexture);
          p^.Source.CompleteTime := umlRandomRangeF(SequenceTextureCompleteTime * 0.9, SequenceTextureCompleteTime * 1.1);
          p^.Source.PlayMode := TSequenceAnimationPlayMode.sapmLoop;
          p^.Source.LastUsed := True;

          p^.Position := DEVec(
            umlRandomRangeF(GenerateRange[0][0], GenerateRange[1][0]) + LastDrawPosition[0],
            umlRandomRangeF(GenerateRange[0][1], GenerateRange[1][1]) + LastDrawPosition[1]);

          p^.radius := ParticleSize * umlRandomRangeF(0.4, 0.6);
          p^.angle := 0;
          p^.alpha := MaxAlpha;
          p^.CurrentTime := 0;
          p^.Acceleration := 0;

          ParticleBuff.Add(p);
        end;
    end;

  while ParticleBuff.Count > MaxParticle do
    begin
      p := ParticleBuff[ParticleBuff.Count - 1];
      Dispose(p);
      ParticleBuff.Delete(ParticleBuff.Count - 1);
    end;

  // particle life
  i := 0;
  while i < ParticleBuff.Count do
    begin
      p := ParticleBuff[i];
      p^.CurrentTime := p^.CurrentTime + deltaTime;
      if p^.CurrentTime > LifeTime then
        begin
          Dispose(p);
          ParticleBuff.Delete(i);
        end
      else
        begin
          p^.Acceleration := p^.Acceleration + DispersionAcceleration * deltaTime;
          k := PointDistance(ZeroPoint, Dispersion);
          p^.Position := MovementDistance(p^.Position, Vec2Add(p^.Position, Dispersion), (k + k * p^.Acceleration) * deltaTime);
          p^.alpha := Clamp(MaxAlpha - (p^.CurrentTime / LifeTime) * MaxAlpha, MinAlpha, 1.0);
          p^.angle := p^.angle + deltaTime * RotationOfSecond;
          Inc(i);
        end;
    end;
end;

constructor TParticles.Create(AOwner: TDrawEngine);
begin
  inherited Create;
  Effect := nil;
  Owner := AOwner;
  ParticleBuff := TCoreClassList.Create;
  PrepareParticleCount := 0;
  NoEnabledAutoFree := False;
  LastDrawPosition := ZeroPoint;

  // temp define
  SequenceTexture := Owner.DefaultTexture;

  SequenceTextureCompleteTime := 1.0;
  MinAlpha := 0.0;
  MaxAlpha := 1.0;
  MaxParticle := 100;
  ParticleSize := 10;
  GenerateRange := DERect(0, 0, 0, 0);
  Dispersion := DEVec(0, 0);
  DispersionAcceleration := 0;
  RotationOfSecond := 0;
  GenSpeedOfPerSecond := 50;
  LifeTime := 2.0;
  Enabled := True;
  Visible := True;
end;

destructor TParticles.Destroy;
var
  i: Integer;
begin
  if Effect <> nil then
      Effect.Particle := nil;
  if Owner <> nil then
      Owner.DeleteParticles(Self);

  for i := 0 to ParticleBuff.Count - 1 do
      Dispose(PParticleData(ParticleBuff[i]));
  DisposeObject(ParticleBuff);

  inherited Destroy;
end;

function TParticles.VisibledParticle: Integer;
begin
  Result := ParticleBuff.Count;
end;

procedure TParticles.FinishAndDelayFree;
begin
  NoEnabledAutoFree := True;
  Enabled := False;
end;

procedure TParticles.LoadFromStream(stream: TCoreClassStream);
var
  df: TDataFrameEngine;
begin
  df := TDataFrameEngine.Create;
  df.LoadFromStream(stream);

  SequenceTexture := Owner.GetTexture(df.Reader.ReadString);
  SequenceTextureCompleteTime := df.Reader.ReadDouble;
  MaxParticle := df.Reader.ReadInteger;
  ParticleSize := df.Reader.ReadSingle;
  MinAlpha := df.Reader.ReadSingle;
  MaxAlpha := df.Reader.ReadSingle;
  with df.Reader.ReadArraySingle do
      GenerateRange := DERect(buffer[0], buffer[1], buffer[2], buffer[3]);
  with df.Reader.ReadArraySingle do
      Dispersion := DEVec(buffer[0], buffer[1]);
  DispersionAcceleration := df.Reader.ReadSingle;
  RotationOfSecond := df.Reader.ReadSingle;
  GenSpeedOfPerSecond := df.Reader.ReadInteger;
  LifeTime := df.Reader.ReadDouble;
  Enabled := df.Reader.ReadBool;
  Visible := df.Reader.ReadBool;

  DisposeObject(df);
end;

procedure TParticles.SaveToStream(stream: TCoreClassStream);
var
  df: TDataFrameEngine;
begin
  df := TDataFrameEngine.Create;

  df.WriteString(Owner.GetTextureName(SequenceTexture));
  df.WriteDouble(SequenceTextureCompleteTime);
  df.WriteInteger(MaxParticle);
  df.WriteSingle(ParticleSize);
  df.WriteSingle(MinAlpha);
  df.WriteSingle(MaxAlpha);
  with df.WriteArraySingle do
    begin
      Add(GenerateRange[0][0]);
      Add(GenerateRange[0][1]);
      Add(GenerateRange[1][0]);
      Add(GenerateRange[1][1]);
    end;
  with df.WriteArraySingle do
    begin
      Add(Dispersion[0]);
      Add(Dispersion[0]);
    end;
  df.WriteSingle(DispersionAcceleration);
  df.WriteSingle(RotationOfSecond);
  df.WriteInteger(GenSpeedOfPerSecond);
  df.WriteDouble(LifeTime);
  df.WriteBool(Enabled);
  df.WriteBool(Visible);

  df.SaveToStream(stream);
  DisposeObject(df);
end;

constructor TEffect.Create(AOwner: TDrawEngine);
begin
  inherited Create;
  Owner := AOwner;
  Mode := emNo;
  Particle := nil;
  SequenceAnimation := nil;
  SequenceAnimation_Width := 0;
  SequenceAnimation_Height := 0;
  SequenceAnimation_Angle := 0;
  SequenceAnimation_Alpha := 1.0;
end;

destructor TEffect.Destroy;
begin
  Reset;
  inherited;
end;

procedure TEffect.Reset;
begin
  if Particle <> nil then
      DisposeObject(Particle);
  if SequenceAnimation <> nil then
      DisposeObject(SequenceAnimation);
end;

procedure TEffect.LoadFromStream(stream: TCoreClassStream);
var
  df: TDataFrameEngine;
  ms: TMemoryStream64;
begin
  Reset;
  df := TDataFrameEngine.Create;
  df.LoadFromStream(stream);

  Mode := TEffectMode(df.Reader.ReadInteger);
  ms := TMemoryStream64.Create;
  df.Reader.ReadStream(ms);
  ms.Position := 0;
  case Mode of
    emSequenceAnimation:
      begin
        SequenceAnimation := Owner.CreateSequenceAnimation(ms);
        SequenceAnimation.Effect := Self;
        SequenceAnimation_Width := df.Reader.ReadSingle;
        SequenceAnimation_Height := df.Reader.ReadSingle;
        SequenceAnimation_Angle := df.Reader.ReadSingle;
        SequenceAnimation_Alpha := df.Reader.ReadSingle;
      end;
    emParticle:
      begin
        Particle := Owner.CreateParticles;
        Particle.LoadFromStream(ms);
        Particle.Effect := Self;
        SequenceAnimation_Width := 0;
        SequenceAnimation_Height := 0;
        SequenceAnimation_Angle := 0;
        SequenceAnimation_Alpha := 1.0;
      end;
  end;
  DisposeObject(ms);

  DisposeObject(df);
end;

procedure TEffect.SaveToStream(stream: TCoreClassStream);
var
  df: TDataFrameEngine;
  ms: TMemoryStream64;
begin
  Reset;
  df := TDataFrameEngine.Create;

  df.WriteInteger(Integer(Mode));
  ms := TMemoryStream64.Create;
  case Mode of
    emSequenceAnimation:
      begin
        SequenceAnimation.SaveToStream(ms);
        df.WriteStream(ms);
        df.WriteSingle(SequenceAnimation_Width);
        df.WriteSingle(SequenceAnimation_Height);
        df.WriteSingle(SequenceAnimation_Angle);
        df.WriteSingle(SequenceAnimation_Alpha);
      end;
    emParticle:
      begin
        Particle.SaveToStream(ms);
        df.WriteStream(ms);
      end;
  end;
  DisposeObject(ms);

  df.SaveToStream(stream);

  DisposeObject(df);
end;

procedure TEffect.Draw(pos: TDEVec);
begin
  case Mode of
    emSequenceAnimation:
      begin
        if SequenceAnimation = nil then
            Exit;
        Owner.DrawSequenceTexture(SequenceAnimation,
          TDE4V.Init(MakeRectV2(
          pos[0] - SequenceAnimation_Width * 0.5, pos[1] - SequenceAnimation_Height * 0.5,
          pos[0] + SequenceAnimation_Width * 0.5, pos[1] + SequenceAnimation_Height * 0.5), SequenceAnimation_Angle), SequenceAnimation_Alpha);
      end;
    emParticle:
      begin
        if Particle = nil then
            Exit;
        Owner.DrawParticle(Particle, pos);
      end;
  end;
end;

procedure TEffect.DrawInScene(pos: TDEVec);
begin
  case Mode of
    emSequenceAnimation:
      begin
        if SequenceAnimation = nil then
            Exit;
        Owner.DrawSequenceTextureInScene(SequenceAnimation,
          TDE4V.Init(MakeRectV2(
          pos[0] - SequenceAnimation_Width * 0.5, pos[1] - SequenceAnimation_Height * 0.5,
          pos[0] + SequenceAnimation_Width * 0.5, pos[1] + SequenceAnimation_Height * 0.5), SequenceAnimation_Angle), SequenceAnimation_Alpha);
      end;
    emParticle:
      begin
        if Particle = nil then
            Exit;
        Owner.DrawParticleInScene(Particle, pos);
      end;
  end;
end;

procedure TDrawEngine.DoFlush;
begin
end;

function TDrawEngine.DoTapDown(X, Y: TDEFloat): Boolean;
begin
  Result := False;
end;

function TDrawEngine.DoTapMove(X, Y: TDEFloat): Boolean;
begin
  Result := False;
end;

function TDrawEngine.DoTapUp(X, Y: TDEFloat): Boolean;
begin
  Result := False;
end;

procedure TDrawEngine.TextSizeCacheDoDataFree(p: Pointer);
begin
  Dispose(PDEVec(p));
end;

function TDrawEngine.GetUserVariants: THashVariantList;
begin
  if FUserVariants = nil then
      FUserVariants := THashVariantList.Create;

  Result := FUserVariants;
end;

function TDrawEngine.GetUserObjects: THashObjectList;
begin
  if FUserObjects = nil then
      FUserObjects := THashObjectList.Create(False);

  Result := FUserObjects;
end;

function TDrawEngine.GetUserAutoFreeObjects: THashObjectList;
begin
  if FUserAutoFreeObjects = nil then
      FUserAutoFreeObjects := THashObjectList.Create(True);

  Result := FUserAutoFreeObjects;
end;

constructor TDrawEngine.Create(ADrawInterface: IDrawEngineInterface);
begin
  inherited Create;

  if ADrawInterface = nil then
    begin
      FRasterInterface := TDrawEngine_Raster.Create;
      FDrawInterface := FRasterInterface;
    end
  else
    begin
      FRasterInterface := nil;
      FDrawInterface := ADrawInterface;
    end;

  FDrawCommand := TDrawQueue.Create(Self);
  FDrawExecute := TDrawExecute.Create(Self);

  FScale := 1.0;
  FOffset := PointMake(0, 0);

  FResourceIntf := nil;
  FCommandCounter := 0;
  FPerformaceCounter := 0;
  FLastPerformaceTime := GetTimeTick;
  FFrameCounterOfPerSec := 0;
  FCommandCounterOfPerSec := 0;
  FWidth := 0;
  FHeight := 0;
  FLastDeltaTime := 0;
  FLastNewTime := 0;
  FViewOptions := [devpFPS, devpFrameEndge];
  FLastDrawInfo := '';

  FTextSizeCache := THashList.Create;
  FTextSizeCache.SetHashBlockCount(1024);
  FTextSizeCache.AutoFreeData := True;
  FTextSizeCache.OnFreePtr := {$IFDEF FPC}@{$ENDIF FPC}TextSizeCacheDoDataFree;
  FScrollTextList := TCoreClassListForObj.Create;

  FDownPT := NULLPoint;
  FMovePT := NULLPoint;
  FUpPT := NULLPoint;
  FLastAcceptDownUI := nil;
  FUIList := TCoreClassListForObj.Create;

  FSequenceAnimationBuffer := TCoreClassListForObj.Create;
  FParticleBuffer := TCoreClassListForObj.Create;
  FLastDynamicSeqenceFlag := 0;

  FFPSFontColor := DEColor(1, 1, 1, 1);
  FScreenFrameColor := DEColor(0.5, 0.2, 0.2, 0.5);

  FTextureLibrary := THashObjectList.Create(True);
  FOnGetTexture := nil;

  FDefaultTexture := DefaultTextureClass.Create;
  FDefaultTexture.SetSize(2, 2, RasterColorF(0, 0, 0, 1));

  FTextureOutputStateBox := DERect(0, 0, 100, 100);

  FUserData := nil;
  FUserValue := Null;
  FUserVariants := nil;
  FUserObjects := nil;
  FUserAutoFreeObjects := nil;
end;

constructor TDrawEngine.Create;
begin
  Create(nil);
end;

destructor TDrawEngine.Destroy;
var
  i: Integer;
begin
  ClearScrollText;
  ClearUI;

  DisposeObject(FDrawCommand);
  DisposeObject(FDrawExecute);
  DisposeObject(FScrollTextList);
  DisposeObject(FUIList);
  DisposeObject(FTextSizeCache);

  for i := 0 to FSequenceAnimationBuffer.Count - 1 do
      DisposeObject(FSequenceAnimationBuffer[i]);
  DisposeObject(FSequenceAnimationBuffer);

  ClearParticles;
  DisposeObject(FParticleBuffer);
  DisposeObject(FTextureLibrary);
  DisposeObject(FDefaultTexture);

  FDrawInterface := nil;

  if FRasterInterface <> nil then
      DisposeObject(FRasterInterface);

  if FUserVariants <> nil then
      DisposeObject(FUserVariants);
  if FUserObjects <> nil then
      DisposeObject(FUserObjects);
  if FUserAutoFreeObjects <> nil then
      DisposeObject(FUserAutoFreeObjects);
  inherited Destroy;
end;

function TDrawEngine.SceneToScreen(pt: TDEVec): TDEVec;
begin
  Result[0] := (pt[0] * FScale) + FOffset[0];
  Result[1] := (pt[1] * FScale) + FOffset[1];
end;

function TDrawEngine.SceneToScreen(X, Y: TDEFloat): TDEVec;
begin
  Result := SceneToScreen(PointMake(X, Y));
end;

function TDrawEngine.SceneToScreen(R: TDE4V): TDE4V;
begin
  Result := TDE4V.Init(SceneToScreen(R.MakeRectV2), R.angle);
end;

function TDrawEngine.SceneToScreen(R: TDERect): TDERect;
begin
  Result[0] := SceneToScreen(R[0]);
  Result[1] := SceneToScreen(R[1]);
end;

function TDrawEngine.ScreenToScene(pt: TDEVec): TDEVec;
begin
  Result[0] := (pt[0] - FOffset[0]) / FScale;
  Result[1] := (pt[1] - FOffset[1]) / FScale;
end;

function TDrawEngine.ScreenToScene(X, Y: TDEFloat): TDEVec;
begin
  Result := ScreenToScene(PointMake(X, Y));
end;

function TDrawEngine.ScreenToScene(R: TDERect): TDERect;
begin
  Result[0] := ScreenToScene(R[0]);
  Result[1] := ScreenToScene(R[1]);
end;

function TDrawEngine.ScreenToScene(R: TDE4V): TDE4V;
begin
  Result := TDE4V.Init(ScreenToScene(R.MakeRectV2), R.angle);
end;

function TDrawEngine.SceneToScreenDistance(ScenePt1, ScenePt2: TDEVec): TDEFloat;
begin
  Result := PointDistance(SceneToScreen(ScenePt1), SceneToScreen(ScenePt2));
end;

function TDrawEngine.ScreenToSceneDistance(ScreenPt1, ScreenPt2: TDEVec): TDEFloat;
begin
  Result := PointDistance(ScreenToScene(ScreenPt1), ScreenToScene(ScreenPt2));
end;

function TDrawEngine.ScreenCenterOfWorld: TDEVec;
begin
  Result := ScreenToScene(PointMake(width * 0.5, height * 0.5));
end;

function TDrawEngine.SceneRectFromScreen: TDERect;
begin
  Result[0] := ScreenToScene(0, 0);
  Result[1] := ScreenToScene(width, height);
end;

function TDrawEngine.ScreenRect: TDERect;
begin
  Result[0] := NULLPoint;
  Result[1][0] := width;
  Result[1][1] := height;
end;

function TDrawEngine.TapDown(X, Y: TDEFloat): Boolean;
var
  i: Integer;
  ui: TDrawEngine_UIBase;
begin
  FDownPT := PointMake(X, Y);
  FMovePT := FDownPT;
  FUpPT := FMovePT;
  FLastAcceptDownUI := nil;

  i := 0;
  while i < FUIList.Count do
    begin
      ui := FUIList[i] as TDrawEngine_UIBase;
      if (ui.Visibled) and (ui.TapDown(X, Y)) then
        begin
          FLastAcceptDownUI := ui;
          Result := True;
          Exit;
        end;
      Inc(i);
    end;
  Result := DoTapDown(X, Y);
end;

function TDrawEngine.TapMove(X, Y: TDEFloat): Boolean;
var
  i: Integer;
  ui: TDrawEngine_UIBase;
begin
  FMovePT := PointMake(X, Y);
  FUpPT := FMovePT;
  if FLastAcceptDownUI <> nil then
    begin
      Result := FLastAcceptDownUI.TapMove(X, Y);
    end
  else
    begin
      i := 0;
      while i < FUIList.Count do
        begin
          ui := FUIList[i] as TDrawEngine_UIBase;
          if (ui.Visibled) and (ui.TapMove(X, Y)) then
            begin
              Result := True;
              Exit;
            end;
          Inc(i);
        end;
      Result := DoTapMove(X, Y);
    end;
end;

function TDrawEngine.TapUp(X, Y: TDEFloat): Boolean;
var
  i: Integer;
  ui: TDrawEngine_UIBase;
begin
  FUpPT := PointMake(X, Y);
  if FLastAcceptDownUI <> nil then
    begin
      Result := FLastAcceptDownUI.TapUp(X, Y);
    end
  else
    begin
      i := 0;
      while i < FUIList.Count do
        begin
          ui := FUIList[i] as TDrawEngine_UIBase;
          if (ui.Visibled) and (ui.TapUp(X, Y)) then
            begin
              Result := True;
              Exit;
            end;
          Inc(i);
        end;
      Result := DoTapUp(X, Y);
    end;
end;

function TDrawEngine.SceneWidth: TDEFloat;
begin
  Result := width * Scale;
end;

function TDrawEngine.SceneHeight: TDEFloat;
begin
  Result := height * Scale;
end;

function TDrawEngine.ReadyOK: Boolean;
begin
  Result := (FDrawInterface <> nil) and (FDrawInterface.ReadyOK);
end;

function TDrawEngine.GetTextSize(Text: SystemString; Size: TDEFloat): TDEVec;
var
  p: PDEVec;
  n: SystemString;
begin
  if (FDrawInterface <> nil) and (Text <> '') and (FDrawInterface.ReadyOK) then
    begin
      n := umlFloatToStr(Size).Text + '_' + Text;
      p := FTextSizeCache[n];
      if p = nil then
        begin
          new(p);
          LockObject(FDrawExecute);
          try
              p^ := FDrawInterface.GetTextSize(Text, Size);
          finally
              UnLockObject(FDrawExecute);
          end;
          FTextSizeCache.Add(n, p, False);
        end;
      Result := p^;
    end
  else
      Result := NULLPoint;
end;

procedure TDrawEngine.SetSize;
var
  v: TDEVec;
begin
  if ReadyOK then
    begin
      v := FDrawInterface.CurrentScreenSize;
      SetSize(v[0], v[1]);
    end;
end;

procedure TDrawEngine.SetSize(w, h: TDEFloat);
begin
  FWidth := w;
  FHeight := h;
end;

procedure TDrawEngine.SetSizeAndOffset(R: TDERect);
begin
  FWidth := RectWidth(R);
  FHeight := RectHeight(R);
  FOffset := R[0];
end;

procedure TDrawEngine.ClearScrollText;
var
  i: Integer;
begin
  for i := 0 to FScrollTextList.Count - 1 do
      DisposeObject(FScrollTextList[i]);

  FScrollTextList.Clear;
end;

procedure TDrawEngine.PostScrollText(LifeTime: Double; Text: SystemString; Size: Integer; COLOR: TDEColor);
var
  sour: TScrollTextSource;
begin
  if not ReadyOK then
      Exit;

  sour := TScrollTextSource.Create;
  sour.LifeTime := LifeTime;
  sour.textRectSize := GetTextSize(Text, Size);
  sour.TextSize := Size;
  sour.TextColor := COLOR;
  sour.Text := Text;
  sour.Tag := nil;
  FScrollTextList.Add(sour);
end;

procedure TDrawEngine.PostScrollText(Tag: TCoreClassObject; LifeTime: Double; Text: SystemString; Size: Integer; COLOR: TDEColor);
var
  i: Integer;
  sour: TScrollTextSource;
begin
  if not ReadyOK then
      Exit;

  sour := nil;
  for i := 0 to FScrollTextList.Count - 1 do
    begin
      if TScrollTextSource(FScrollTextList[i]).Tag = Tag then
        begin
          sour := TScrollTextSource(FScrollTextList[i]);
          Break;
        end;
    end;
  if sour = nil then
    begin
      sour := TScrollTextSource.Create;
      FScrollTextList.Add(sour);
    end;

  sour.LifeTime := LifeTime;
  sour.textRectSize := GetTextSize(Text, Size);
  sour.TextSize := Size;
  sour.TextColor := COLOR;
  sour.Text := Text;
  sour.Tag := Tag;
end;

function TDrawEngine.GetLastPostScrollText: SystemString;
begin
  Result := '';
  if FScrollTextList.Count > 0 then
      Result := TScrollTextSource(FScrollTextList[FScrollTextList.Count - 1]).Text;
end;

procedure TDrawEngine.ClearUI;
begin
  while FUIList.Count > 0 do
      DisposeObject(FUIList[0]);

  FLastAcceptDownUI := nil;
end;

procedure TDrawEngine.AllUINoVisibled;
var
  i: Integer;
  ui: TDrawEngine_UIBase;
begin
  i := 0;
  while i < FUIList.Count do
    begin
      ui := FUIList[i] as TDrawEngine_UIBase;
      ui.Visibled := False;
      Inc(i);
    end;
end;

procedure TDrawEngine.SetDrawBound(R: TDERect);
begin
  FWidth := RectWidth(R);
  FHeight := RectHeight(R);
  FDrawCommand.SetSize(R);
end;

procedure TDrawEngine.SetDrawBound(R: TRectf);
begin
  SetDrawBound(DERect(R));
end;

procedure TDrawEngine.BeginCaptureShadow(const OffsetVec: TDEVec; const alpha: TDEFloat);
begin
  FDrawCommand.BeginCaptureShadow(OffsetVec, alpha);
end;

procedure TDrawEngine.EndCaptureShadow;
begin
  FDrawCommand.EndCaptureShadow;
end;

function TDrawEngine.CaptureShadow: Boolean;
begin
  Result := FDrawCommand.FStartDrawShadowIndex >= 0;
end;

function TDrawEngine.LastCaptureShadowOffsetVec: TDEVec;
begin
  Result := FDrawCommand.FShadowVec;
end;

function TDrawEngine.LastCaptureShadowAlpha: TDEFloat;
begin
  Result := FDrawCommand.FShadowAlpha;
end;

procedure TDrawEngine.DrawUserCustom(const UserProc: TUserCustomDrawProc; const UserData: Pointer; const UserObject: TCoreClassObject);
begin
  if Assigned(UserProc) then
      FDrawCommand.DrawUserCustom(UserProc, UserData, UserObject);
end;

procedure TDrawEngine.DrawPLInScene(pl: TVec2List; ClosedLine: Boolean; opt: TPolyDrawOption);
var
  i: Integer;
  t1, t2: TDEVec;
  R: TDERect;
begin
  FDrawCommand.SetLineWidth(opt.LineWidth);
  for i := 0 to pl.Count - 1 do
    begin
      t1 := SceneToScreen(pl[i]^);
      R[0][0] := t1[0] - opt.PointScreenRadius;
      R[0][1] := t1[1] - opt.PointScreenRadius;
      R[1][0] := t1[0] + opt.PointScreenRadius;
      R[1][1] := t1[1] + opt.PointScreenRadius;
      FDrawCommand.DrawEllipse(R, opt.PointColor);
    end;

  for i := 1 to pl.Count - 1 do
    begin
      t1 := SceneToScreen(pl[i - 1]^);
      t2 := SceneToScreen(pl[i]^);
      FDrawCommand.DrawLine(t1, t2, opt.LineColor);
    end;
  if (ClosedLine) and (pl.Count > 1) then
    begin
      t1 := SceneToScreen(pl.First^);
      t2 := SceneToScreen(pl.Last^);
      FDrawCommand.DrawLine(t1, t2, opt.LineColor);
    end;
end;

procedure TDrawEngine.DrawPolyInScene(Poly: TPoly; ClosedLine: Boolean; opt: TPolyDrawOption);
var
  i: Integer;
  t1, t2: TDEVec;
  R: TDERect;
begin
  if Poly.Count < 3 then
      Exit;
  FDrawCommand.SetLineWidth(opt.LineWidth);
  for i := 0 to Poly.Count - 1 do
    begin
      t1 := SceneToScreen(Poly.Points[i]);
      R[0][0] := t1[0] - opt.PointScreenRadius;
      R[0][1] := t1[1] - opt.PointScreenRadius;
      R[1][0] := t1[0] + opt.PointScreenRadius;
      R[1][1] := t1[1] + opt.PointScreenRadius;
      FDrawCommand.DrawEllipse(R, opt.PointColor);
    end;

  t1 := SceneToScreen(Poly.Position);
  R[0][0] := t1[0] - opt.PointScreenRadius;
  R[0][1] := t1[1] - opt.PointScreenRadius;
  R[1][0] := t1[0] + opt.PointScreenRadius;
  R[1][1] := t1[1] + opt.PointScreenRadius;
  FDrawCommand.DrawEllipse(R, opt.PointColor);

  for i := 1 to Poly.Count - 1 do
    begin
      t1 := SceneToScreen(Poly.Points[i - 1]);
      t2 := SceneToScreen(Poly.Points[i]);
      FDrawCommand.DrawLine(t1, t2, opt.LineColor);
    end;
  if (ClosedLine) and (Poly.Count > 1) then
    begin
      t1 := SceneToScreen(Poly.Points[0]);
      t2 := SceneToScreen(Poly.Points[Poly.Count - 1]);
      FDrawCommand.DrawLine(t1, t2, opt.LineColor);
    end;
end;

procedure TDrawEngine.DrawPolyExpandInScene(Poly: TPoly; ExpandDistance: TDEFloat; ClosedLine: Boolean; opt: TPolyDrawOption);
var
  i: Integer;
  t1, t2: TDEVec;
  R: TDERect;
begin
  if Poly.Count < 3 then
      Exit;

  FDrawCommand.SetLineWidth(opt.LineWidth);
  for i := 0 to Poly.Count - 1 do
    begin
      t1 := SceneToScreen(Poly.Expands[i, ExpandDistance]);
      R[0][0] := t1[0] - opt.PointScreenRadius;
      R[0][1] := t1[1] - opt.PointScreenRadius;
      R[1][0] := t1[0] + opt.PointScreenRadius;
      R[1][1] := t1[1] + opt.PointScreenRadius;
      FDrawCommand.DrawEllipse(R, opt.PointColor);
    end;

  for i := 1 to Poly.Count - 1 do
    begin
      t1 := SceneToScreen(Poly.Expands[i - 1, ExpandDistance]);
      t2 := SceneToScreen(Poly.Expands[i, ExpandDistance]);
      FDrawCommand.DrawLine(t1, t2, opt.LineColor);
    end;
  if (ClosedLine) and (Poly.Count > 1) then
    begin
      t1 := SceneToScreen(Poly.Expands[0, ExpandDistance]);
      t2 := SceneToScreen(Poly.Expands[Poly.Count - 1, ExpandDistance]);
      FDrawCommand.DrawLine(t1, t2, opt.LineColor);
    end;
end;

procedure TDrawEngine.DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  FDrawCommand.SetLineWidth(LineWidth);
  FDrawCommand.DrawLine(pt1, pt2, COLOR);
end;

procedure TDrawEngine.DrawLineInScene(pt1, pt2: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  DrawLine(SceneToScreen(pt1), SceneToScreen(pt2), COLOR, LineWidth);
end;

procedure TDrawEngine.DrawDE4V(d: TDE4V; COLOR: TDEColor; LineWidth: TDEFloat);
var
  pr: TV2Rect4;
begin
  pr := TV2Rect4.Init(d.MakeRectV2, d.angle);
  DrawLine(pr.LeftTop, pr.RightTop, COLOR, LineWidth);
  DrawLine(pr.RightTop, pr.RightBottom, COLOR, LineWidth);
  DrawLine(pr.RightBottom, pr.LeftBottom, COLOR, LineWidth);
  DrawLine(pr.LeftBottom, pr.LeftTop, COLOR, LineWidth);
end;

procedure TDrawEngine.DrawDE4VInScene(d: TDE4V; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  DrawDE4V(SceneToScreen(d), COLOR, LineWidth);
end;

procedure TDrawEngine.DrawPoint(pt: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat);
var
  pt1, pt2: TDEVec;
begin
  FDrawCommand.SetLineWidth(LineWidth);

  pt1[0] := 2;
  pt1[1] := pt[1];
  pt2[0] := width - 2;
  pt2[1] := pt[1];
  FDrawCommand.DrawLine(pt1, pt2, COLOR);

  pt1[0] := pt[0];
  pt1[1] := 2;
  pt2[0] := pt[0];
  pt2[1] := height - 2;
  FDrawCommand.DrawLine(pt1, pt2, COLOR);
end;

procedure TDrawEngine.DrawPointInScene(pt: TDEVec; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  DrawPoint(SceneToScreen(pt), COLOR, LineWidth);
end;

procedure TDrawEngine.DrawBox(R: TDERect; angle: TGeoFloat; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  FDrawCommand.SetLineWidth(LineWidth);
  FDrawCommand.DrawRect(R, angle, COLOR);
end;

procedure TDrawEngine.DrawBoxInScene(R: TDERect; angle: TGeoFloat; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  DrawBox(SceneToScreen(R), angle, COLOR, LineWidth * Scale);
end;

procedure TDrawEngine.DrawBox(R: TDERect; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  DrawBox(R, 0, COLOR, LineWidth * Scale);
end;

procedure TDrawEngine.DrawBoxInScene(R: TDERect; COLOR: TDEColor; LineWidth: TDEFloat);
begin
  DrawBox(SceneToScreen(R), COLOR, LineWidth * Scale);
end;

procedure TDrawEngine.FillBox(R: TDERect; angle: TGeoFloat; COLOR: TDEColor);
begin
  FDrawCommand.FillRect(R, angle, COLOR);
end;

procedure TDrawEngine.FillBoxInScene(R: TDERect; angle: TGeoFloat; COLOR: TDEColor);
begin
  FillBox(SceneToScreen(R), angle, COLOR);
end;

procedure TDrawEngine.FillBox(R: TDERect; COLOR: TDEColor);
begin
  FillBox(R, 0, COLOR);
end;

procedure TDrawEngine.FillBoxInScene(R: TDERect; COLOR: TDEColor);
begin
  FillBox(SceneToScreen(R), COLOR);
end;

procedure TDrawEngine.DrawEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor);
begin
  FDrawCommand.DrawEllipse(pt, radius, COLOR);
end;

procedure TDrawEngine.DrawEllipse(R: TDERect; COLOR: TDEColor);
begin
  FDrawCommand.DrawEllipse(R, COLOR);
end;

procedure TDrawEngine.DrawEllipseInScene(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor);
begin
  DrawEllipse(SceneToScreen(pt), radius * FScale, COLOR);
end;

procedure TDrawEngine.DrawEllipseInScene(R: TDERect; COLOR: TDEColor);
begin
  DrawEllipse(SceneToScreen(R), COLOR);
end;

procedure TDrawEngine.FillEllipse(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor);
begin
  FDrawCommand.FillEllipse(pt, radius, COLOR);
end;

procedure TDrawEngine.FillEllipse(R: TDERect; COLOR: TDEColor);
begin
  FDrawCommand.FillEllipse(R, COLOR);
end;

procedure TDrawEngine.FillEllipseInScene(pt: TDEVec; radius: TDEFloat; COLOR: TDEColor);
begin
  FillEllipse(SceneToScreen(pt), radius * FScale, COLOR);
end;

procedure TDrawEngine.FillEllipseInScene(R: TDERect; COLOR: TDEColor);
begin
  FillEllipse(SceneToScreen(R), COLOR);
end;

procedure TDrawEngine.DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat);
begin
  FDrawCommand.DrawText(Text, Size, R, COLOR, center, RotateVec, angle);
end;

procedure TDrawEngine.DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean);
var
  siz: TDEVec;
  box: TDERect;
begin
  DrawText(Text, Size, R, COLOR, center, DEVec(0.5, 0.5), 0);

  if devpTextBox in FViewOptions then
    begin
      siz := GetTextSize(Text, Size);
      if center then
        begin
          box[0][0] := (RectWidth(R) - siz[0]) * 0.5;
          box[0][1] := (RectHeight(R) - siz[1]) * 0.5;
          box[0] := Vec2Add(box[0], R[0]);
          box[1] := Vec2Add(box[0], siz);
          DrawBox(box, COLOR, 1);
        end
      else
        begin
          box[0][0] := 0;
          box[0][1] := (RectHeight(R) - siz[1]) * 0.5;
          box[0] := Vec2Add(box[0], R[0]);
          box[1] := Vec2Add(box[0], siz);
          DrawBox(box, COLOR, 1);
        end;
    end;
end;

procedure TDrawEngine.DrawText(Text: SystemString; Size: TDEFloat; COLOR: TDEColor; ScreenPt: TDEVec);
var
  siz: TDEVec;
  R: TDERect;
begin
  siz := GetTextSize(Text, Size);
  R[0] := ScreenPt;
  R[1] := Vec2Add(ScreenPt, siz);
  DrawText(Text, Size, R, COLOR, False);
end;

procedure TDrawEngine.DrawTextInScene(Text: SystemString; Size: TDEFloat; COLOR: TDEColor; ScenePos: TDEVec);
begin
  DrawText(Text, Size * Scale, COLOR, SceneToScreen(ScenePos));
end;

procedure TDrawEngine.DrawTextInScene(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean);
begin
  DrawText(Text, Size * Scale, SceneToScreen(R), COLOR, center);
end;

procedure TDrawEngine.DrawTexture(T: TCoreClassObject; sour, DestScreen: TDE4V; alpha: TDEFloat);
begin
  FDrawCommand.DrawTexture(T, sour, DestScreen, alpha);
end;

procedure TDrawEngine.DrawTexture(T: TCoreClassObject; sour: TDERect; DestScreen: TDE4V; alpha: TDEFloat);
begin
  DrawTexture(T, TDE4V.Init(sour, 0), DestScreen, alpha);
end;

procedure TDrawEngine.DrawTexture(T: TCoreClassObject; sour, DestScreen: TDERect; alpha: TDEFloat);
begin
  DrawTexture(T, TDE4V.Init(sour, 0), TDE4V.Init(DestScreen, 0), alpha);
end;

procedure TDrawEngine.DrawTexture(T: TCoreClassObject; sour: TDERect; destScreenPt: TDEVec; angle, alpha: TDEFloat);
var
  w, h: TDEFloat;
begin
  w := sour[1][0] - sour[0][0];
  h := sour[1][1] - sour[0][1];
  DrawTexture(T, TDE4V.Init(sour, 0), TDE4V.Init(destScreenPt, w, h, angle), alpha);
end;

procedure TDrawEngine.DrawTexture(T: TCoreClassObject; sour, DestScreen: TDERect; angle, alpha: TDEFloat);
begin
  DrawTexture(T, TDE4V.Init(sour, 0), TDE4V.Init(DestScreen, angle), alpha);
end;

function TDrawEngine.DrawTexture(indentEndge: Boolean; T: TCoreClassObject; sour, DestScreen: TDERect; alpha: TDEFloat): TDERect;
begin
  if indentEndge then
      Result := RectEndge(DestScreen, Vec2Mul(RectSize(DestScreen), -0.05))
  else
      Result := DestScreen;

  DrawTexture(T, sour, Result, alpha);
end;

procedure TDrawEngine.FitDrawTexture(T: TCoreClassObject; sour, destScene: TDERect; angle, alpha: TDEFloat);
begin
  DrawTexture(T, sour, RectFit(sour, destScene), angle, alpha);
end;

function TDrawEngine.FitDrawTexture(T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect;
begin
  Result := RectFit(sour, destScene);
  DrawTexture(T, sour, Result, alpha);
end;

function TDrawEngine.FitDrawTexture(indentEndge: Boolean; T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect;
begin
  if indentEndge then
      Result := RectEndge(destScene, Vec2Mul(RectSize(destScene), -0.05))
  else
      Result := destScene;

  FitDrawTexture(T, sour, Result, alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; sour, destScene: TDE4V; alpha: TDEFloat);
begin
  DrawTexture(T, sour, SceneToScreen(destScene), alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; sour: TDERect; destScene: TDE4V; alpha: TDEFloat);
begin
  DrawTextureInScene(T, TDE4V.Init(sour, 0), destScene, alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; destScene: TDE4V; alpha: TDEFloat);
begin
  DrawTextureInScene(T, TDE4V.Init, destScene, alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat);
begin
  DrawTextureInScene(T, TDE4V.Init(sour, 0), TDE4V.Init(destScene, 0), alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; sour: TDERect; destScenePt: TDEVec; angle, alpha: TDEFloat);
var
  w, h: TDEFloat;
begin
  w := sour[1][0] - sour[0][0];
  h := sour[1][1] - sour[0][1];
  DrawTextureInScene(T, TDE4V.Init(sour, 0), TDE4V.Init(destScenePt, w, h, angle), alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; angle, alpha: TDEFloat);
begin
  DrawTextureInScene(T, TDE4V.Init(sour, 0), TDE4V.Init(destScene, angle), alpha);
end;

procedure TDrawEngine.DrawTextureInScene(T: TCoreClassObject; destScenePt: TDEVec; AWidth, AHeight, angle, alpha: TDEFloat);
begin
  DrawTextureInScene(T, TDE4V.Init, TDE4V.Init(destScenePt, AWidth, AHeight, angle), alpha);
end;

function TDrawEngine.DrawTextureInScene(indentEndge: Boolean; T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect;
begin
  if indentEndge then
      Result := RectEndge(destScene, Vec2Mul(RectSize(destScene), -0.05))
  else
      Result := destScene;

  DrawTextureInScene(T, sour, Result, alpha);
end;

procedure TDrawEngine.FitDrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; angle, alpha: TDEFloat);
begin
  DrawTextureInScene(T, sour, RectFit(sour, destScene), angle, alpha);
end;

function TDrawEngine.FitDrawTextureInScene(T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect;
begin
  Result := RectFit(sour, destScene);
  DrawTextureInScene(T, sour, Result, alpha);
end;

function TDrawEngine.FitDrawTextureInScene(indentEndge: Boolean; T: TCoreClassObject; sour, destScene: TDERect; alpha: TDEFloat): TDERect;
begin
  if indentEndge then
      Result := RectEndge(destScene, Vec2Mul(RectSize(destScene), -0.05))
  else
      Result := destScene;

  Result := FitDrawTextureInScene(T, sour, Result, alpha);
end;

function TDrawEngine.CreateSequenceAnimation(stream: TCoreClassStream): TSequenceAnimationBase;
begin
  Result := TSequenceAnimationBase.Create(Self);
  Result.LoadFromStream(stream);
  FSequenceAnimationBuffer.Add(Result);
end;

function TDrawEngine.GetOrCreateSequenceAnimation(flag: Variant; T: TCoreClassObject): TSequenceAnimationBase;
var
  i: Integer;
begin
  for i := 0 to FSequenceAnimationBuffer.Count - 1 do
    begin
      Result := FSequenceAnimationBuffer[i] as TSequenceAnimationBase;
      try
        if (Result.Source = T) and (VarType(Result.flag) = VarType(flag)) and (umlSameVarValue(Result.flag, flag)) then
            Exit;
      except
      end;
    end;

  Result := TSequenceAnimationBase.Create(Self);
  Result.Source := T;
  Result.flag := flag;

  if T is TSequenceMemoryRaster then
    begin
      Result.width := TSequenceMemoryRaster(T).width;
      Result.height := TSequenceMemoryRaster(T).height;
      Result.Total := TSequenceMemoryRaster(T).Total;
      Result.Column := TSequenceMemoryRaster(T).Column;
    end;
  Result.CompleteTime := 1.0;
  Result.PlayMode := TSequenceAnimationPlayMode.sapmPlayOne;

  Result.LastUsed := True;
  FSequenceAnimationBuffer.Add(Result);
end;

function TDrawEngine.SequenceAnimationPlaying(flag: Variant; T: TCoreClassObject): Boolean;
var
  i: Integer;
  SA: TSequenceAnimationBase;
begin
  Result := False;
  SA := nil;
  for i := 0 to FSequenceAnimationBuffer.Count - 1 do
    begin
      SA := FSequenceAnimationBuffer[i] as TSequenceAnimationBase;
      if (SA.Source = T) and (VarType(SA.flag) = VarType(flag)) and (umlSameVarValue(SA.flag, flag)) then
          Break;
    end;
  if SA = nil then
      Exit;
  Result := SA.SequenceAnimationPlaying;
end;

function TDrawEngine.SequenceAnimationIsOver(flag: Variant; T: TCoreClassObject): Boolean;
var
  i: Integer;
  SA: TSequenceAnimationBase;
begin
  Result := True;
  SA := nil;
  for i := 0 to FSequenceAnimationBuffer.Count - 1 do
    begin
      SA := FSequenceAnimationBuffer[i] as TSequenceAnimationBase;
      if (SA.Source = T) and (VarType(SA.flag) = VarType(flag)) and (umlSameVarValue(SA.flag, flag)) then
          Break;
    end;
  if SA = nil then
      Exit;
  Result := SA.IsOver;
end;

function TDrawEngine.ExistsSequenceAnimation(SA: TSequenceAnimationBase): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FSequenceAnimationBuffer.Count - 1 do
    if FSequenceAnimationBuffer[i] = SA then
        Exit(True);
end;

function TDrawEngine.GetNewSequenceFlag: Variant;
begin
  Result := FLastDynamicSeqenceFlag;
  FLastDynamicSeqenceFlag := FLastDynamicSeqenceFlag + 1;
end;

function TDrawEngine.ManualDrawSequenceTexture(flag: Variant; T: TCoreClassObject; TextureWidth, TextureHeight, Total, Column: Integer; CompleteTime: Double; Looped: Boolean;
  DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
var
  SA: TSequenceAnimationBase;
begin
  Result := nil;
  if Total = 0 then
      Exit;
  if Column = 0 then
      Exit;

  SA := GetOrCreateSequenceAnimation(flag, T);
  SA.width := TextureWidth;
  SA.height := TextureHeight;
  SA.Total := Total;
  SA.Column := Column;
  SA.CompleteTime := CompleteTime;
  if Looped then
      SA.PlayMode := TSequenceAnimationPlayMode.sapmLoop
  else
      SA.PlayMode := TSequenceAnimationPlayMode.sapmPlayOne;

  SA.LastUsed := True;
  DrawTexture(SA.Source, SA.SequenceFrameRect, DestScreen, SA.GetOverAnimationSmoothAlpha(alpha));
  Result := SA;
end;

function TDrawEngine.DrawSequenceTexture(flag: Variant; T: TCoreClassObject; TextureWidth, TextureHeight, Total, Column: Integer; CompleteTime: Double; Looped: Boolean;
  DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := ManualDrawSequenceTexture(flag, T, TextureWidth, TextureHeight, Total, Column, CompleteTime, Looped, DestScreen, alpha);
end;

function TDrawEngine.DrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTexture(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, DestScreen, alpha);
end;

function TDrawEngine.DrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDERect; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTexture(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, TDE4V.Init(DestScreen, 0), alpha);
end;

function TDrawEngine.DrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; DestScreen: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTexture(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, False, DestScreen, alpha);
end;

function TDrawEngine.FitDrawSequenceTexture(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDERect; alpha: TDEFloat): TDERect;
begin
  Result := RectFit(T.FrameRect2D, DestScreen);
  DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, TDE4V.Init(Result, 0), alpha);
end;

function TDrawEngine.FitDrawSequenceTexture(indentEndge: Boolean; flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; DestScreen: TDERect; alpha: TDEFloat): TDERect;
var
  d: TDERect;
begin
  if indentEndge then
      d := RectEndge(DestScreen, Vec2Mul(RectSize(DestScreen), -0.05))
  else
      d := DestScreen;

  Result := RectFit(T.FrameRect2D, d);
  DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, TDE4V.Init(Result, 0), alpha);
end;

procedure TDrawEngine.DrawSequenceTexture(SA: TSequenceAnimationBase; DestScreen: TDE4V; alpha: TDEFloat);
begin
  SA.LastUsed := True;
  DrawTexture(SA.Source, SA.SequenceFrameRect, DestScreen, SA.GetOverAnimationSmoothAlpha(alpha));
end;

function TDrawEngine.DrawSequenceTextureInScene(flag: Variant; T: TCoreClassObject; TextureWidth, TextureHeight, Total, Column: Integer; CompleteTime: Double; Looped: Boolean;
  destScene: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTexture(flag, T, TextureWidth, TextureHeight, Total, Column, CompleteTime, Looped, SceneToScreen(destScene), alpha);
end;

function TDrawEngine.DrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, destScene, alpha);
end;

function TDrawEngine.DrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDERect; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, TDE4V.Init(destScene, 0), alpha);
end;

function TDrawEngine.DrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; destScene: TDE4V; alpha: TDEFloat): TSequenceAnimationBase;
begin
  Result := DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, False, destScene, alpha);
end;

function TDrawEngine.FitDrawSequenceTextureInScene(flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDERect; alpha: TDEFloat): TDERect;
begin
  Result := RectFit(T.FrameRect2D, destScene);
  DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, TDE4V.Init(Result, 0), alpha);
end;

function TDrawEngine.FitDrawSequenceTextureInScene(indentEndge: Boolean; flag: Variant; T: TDETexture; CompleteTime: Double; Looped: Boolean; destScene: TDERect; alpha: TDEFloat): TDERect;
var
  d: TDERect;
begin
  if indentEndge then
      d := RectEndge(destScene, Vec2Mul(RectSize(destScene), -0.05))
  else
      d := destScene;

  Result := RectFit(T.FrameRect2D, d);
  DrawSequenceTextureInScene(flag, T, T.width, T.height, T.Total, T.Column, CompleteTime, Looped, TDE4V.Init(Result, 0), alpha);
end;

procedure TDrawEngine.DrawSequenceTextureInScene(SA: TSequenceAnimationBase; destScene: TDE4V; alpha: TDEFloat);
begin
  DrawSequenceTexture(SA, SceneToScreen(destScene), alpha);
end;

function TDrawEngine.CreateParticles: TParticles;
begin
  Result := TParticles.Create(Self);
  FParticleBuffer.Add(Result);
end;

function TDrawEngine.CreateParticles(stream: TCoreClassStream): TParticles;
begin
  Result := TParticles.Create(Self);
  Result.LoadFromStream(stream);
  FParticleBuffer.Add(Result);
end;

procedure TDrawEngine.DeleteParticles(p: TParticles);
var
  i: Integer;
begin
  i := 0;
  while i < FParticleBuffer.Count do
    if FParticleBuffer[i] = p then
        FParticleBuffer.Delete(i)
    else
        Inc(i);
end;

procedure TDrawEngine.FreeAndDeleteParticles(p: TParticles);
var
  i: Integer;
begin
  i := 0;
  while i < FParticleBuffer.Count do
    if FParticleBuffer[i] = p then
        FParticleBuffer.Delete(i)
    else
        Inc(i);
  p.Owner := nil;
  DisposeObject(p);
end;

procedure TDrawEngine.ClearParticles;
var
  i: Integer;
begin
  for i := 0 to FParticleBuffer.Count - 1 do
    begin
      TParticles(FParticleBuffer[i]).Owner := nil;
      DisposeObject(FParticleBuffer[i]);
    end;
  FParticleBuffer.Clear;
end;

function TDrawEngine.ExistsParticles(p: TParticles): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FParticleBuffer.Count - 1 do
    if FParticleBuffer[i] = p then
        Exit(True);
end;

function TDrawEngine.TotalParticleData: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FParticleBuffer.Count - 1 do
      Result := Result + TParticles(FParticleBuffer[i]).ParticleBuff.Count;
end;

function TDrawEngine.ParticleCount: Integer;
begin
  Result := FParticleBuffer.Count;
end;

function TDrawEngine.GetParticles(const index: Integer): TParticles;
begin
  Result := FParticleBuffer[index] as TParticles;
end;

procedure TDrawEngine.DrawParticle(Particle: TParticles; DestScreen: TDEVec);
var
  i: Integer;
  p: PParticleData;
begin
  if (Particle.Owner <> Self) then
    begin
      if Particle.Owner <> nil then
          Particle.Owner.DeleteParticles(Particle);
      DeleteParticles(Particle);
      FParticleBuffer.Add(Particle);
    end;

  Particle.Owner := Self;
  Particle.LastDrawPosition := DestScreen;

  if Particle.Visible then
    begin
      try
        for i := 0 to Particle.ParticleBuff.Count - 1 do
          begin
            p := Particle.ParticleBuff[i];
            DrawSequenceTexture(p^.Source, TDE4V.Init(p^.Position, p^.radius * 2, p^.radius * 2, p^.angle), p^.alpha);
          end;
      except
      end;
    end;
end;

procedure TDrawEngine.DrawParticleInScene(Particle: TParticles; destScene: TDEVec);
begin
  DrawParticle(Particle, SceneToScreen(destScene));
end;

function TDrawEngine.GetTexture(TextureName: SystemString): TDETexture;
begin
  Result := FTextureLibrary[TextureName] as TDETexture;
  if Result = nil then
    begin
      if Assigned(FOnGetTexture) then
          FOnGetTexture(TextureName, Result);
      if Result <> nil then
        begin
          Result.Name := TextureName;
          FTextureLibrary.Add(TextureName, Result);
        end;
    end;
  if Result = nil then
      PostScrollText(10, 'no exists Texture ' + TextureName, 12, DEColor(1, 0.5, 0.5, 1));
end;

function TDrawEngine.GetTextureName(T: TCoreClassObject): SystemString;
begin
  if T is TDETexture then
      Result := TDETexture(T).Name
  else
      Result := FTextureLibrary.GetObjAsName(T);
end;

class function TDrawEngine.NewTexture: TDETexture;
begin
  Result := DefaultTextureClass.Create;
end;

procedure TDrawEngine.PrepareTextureOutputState;
var
  bakScale: TDEFloat;
  bakOffset: TDEVec;
  R: TDERect;

  rl: TRectPacking;
  tsBuff: TTextureOutputStateBuffer;
  i: Integer;
  ptex: PTextureOutputState;
  pr: PRectPackData;
begin
  bakScale := Scale;
  bakOffset := Offset;
  try
    rl := TRectPacking.Create;
    FDrawCommand.BuildTextureOutputState(tsBuff);
    for i := 0 to length(tsBuff) - 1 do
      begin
        ptex := @(tsBuff[i]);
        if not rl.Data2Exists(ptex^.Source) then
          begin
            if ptex^.Source is TMemoryRaster then
                rl.Add(ptex, ptex^.Source, TMemoryRaster(ptex^.Source).BoundsRectV2)
            else
                rl.Add(ptex, ptex^.Source, ptex^.SourceRect.MakeRectV2);
          end;
      end;
    rl.Build(1024 * 1024, 1024 * 1024);

    R := RectFit(DERect(0, 0, rl.MaxWidth + 4, rl.MaxHeight + 4), FTextureOutputStateBox);
    Scale := RectWidth(R) / rl.MaxWidth;
    Offset := R[0];

    FillBox(FTextureOutputStateBox, DEColor(0, 0, 0, 0.95));

    for i := 0 to rl.Count - 1 do
      begin
        pr := rl[i];
        ptex := pr^.Data1;
        DrawTextureInScene(ptex^.Source, ptex^.SourceRect, TDE4V.Init(pr^.Rect, 0), 0.5);
      end;
    DrawText('Texture:' + umlIntToStr(rl.Count).Text + ' Area:' + umlIntToStr(Round(rl.MaxWidth)).Text + ' x ' + umlIntToStr(Round(rl.MaxHeight)).Text,
      10, DEColor(1, 1, 1, 1), R[0]);
    DisposeObject(rl);
  except
  end;
  Scale := bakScale;
  Offset := bakOffset;
end;

procedure TDrawEngine.PrepareFlush;
var
  lastTime: Integer;
  i: Integer;
  pt: TDEVec;
  R: TDERect;
  st: TScrollTextSource;
  ui: TDrawEngine_UIBase;
  SA: TSequenceAnimationBase;
begin
  lastTime := GetTimeTick;
  Inc(FPerformaceCounter);

  FDrawCommand.SetSize(ScreenRect);

  DoFlush;

  pt := PointMake(width - 5, height - 5);
  i := FScrollTextList.Count - 1;
  while i >= 0 do
    begin
      st := FScrollTextList[i] as TScrollTextSource;
      if st.LifeTime > 0 then
        begin
          R[0] := Vec2Sub(pt, st.textRectSize);
          R[1] := Vec2Add(R[0], st.textRectSize);
          pt[1] := pt[1] - st.textRectSize[1];
          DrawText(st.Text, st.TextSize, R, st.TextColor, False);
        end;
      Dec(i);
    end;

  i := 0;
  while i < FUIList.Count do
    begin
      ui := FUIList[i] as TDrawEngine_UIBase;
      if ui.Visibled then
          ui.DoDraw;
      Inc(i);
    end;

  if devpFrameEndge in FViewOptions then
    begin
      FDrawCommand.SetLineWidth(1);
      FDrawCommand.DrawRect(MakeRect(1, 1, width - 1, height - 1), 0, FScreenFrameColor);
    end;

  FLastDrawInfo := 'fps: ' + umlSizeToStr(Round(FrameCounterOfPerSec)).Text + ' cps: ' + umlSizeToStr(Round(CommandCounterOfPerSec)).Text +
    '  resolution: ' + umlIntToStr(Round(width)).Text + ' x ' + umlIntToStr(Round(height)).Text;

  if devpFPS in FViewOptions then
      DrawText(FLastDrawInfo, 12, FFPSFontColor, PointMake(5, 5));

  if lastTime - FLastPerformaceTime > 1000 then
    begin
      FFrameCounterOfPerSec := FPerformaceCounter / ((lastTime - FLastPerformaceTime) / 1000);
      FCommandCounterOfPerSec := FCommandCounter / ((lastTime - FLastPerformaceTime) / 1000);
      FLastPerformaceTime := lastTime;
      FPerformaceCounter := 0;
      FCommandCounter := 0;
    end;

  i := 0;
  while i < FSequenceAnimationBuffer.Count do
    begin
      SA := FSequenceAnimationBuffer[i] as TSequenceAnimationBase;
      if not SA.LastUsed then
        begin
          DisposeObject(SA);
          FSequenceAnimationBuffer.Delete(i);
        end
      else
          Inc(i);
    end;

  if devpTextureState in FViewOptions then
      PrepareTextureOutputState;
end;

procedure TDrawEngine.ClearFlush;
begin
  FDrawCommand.Clear(True);
  FDrawExecute.Clear;
end;

procedure TDrawEngine.Flush;
begin
  Flush(True);
end;

procedure TDrawEngine.Flush(Prepare: Boolean);
begin
  if Prepare then
      PrepareFlush;

  if FDrawInterface <> nil then
    begin
      LockObject(FDrawExecute);
      try
        FDrawExecute.PickQueue(FDrawCommand);
        FCommandCounter := FCommandCounter + FDrawExecute.FCommandList.Count;
        FDrawExecute.Execute(FDrawInterface);
      finally
          UnLockObject(FDrawExecute);
      end;
    end
  else
      ClearFlush;
end;

procedure TDrawEngine.CopyFlushTo(Dst: TDrawExecute);
begin
  LockObject(Dst);
  try
      Dst.PickQueue(FDrawCommand);
  finally
      UnLockObject(Dst);
  end;
end;

procedure TDrawEngine.Progress(deltaTime: Double);
var
  i: Integer;
  SA: TSequenceAnimationBase;
  st: TScrollTextSource;
  p: TParticles;
begin
  i := 0;
  while i < FSequenceAnimationBuffer.Count do
    begin
      SA := FSequenceAnimationBuffer[i] as TSequenceAnimationBase;
      SA.Progress(deltaTime);
      SA.LastUsed := False;
      Inc(i);
    end;

  i := 0;
  while i < FScrollTextList.Count do
    begin
      st := FScrollTextList[i] as TScrollTextSource;
      if st.LifeTime - deltaTime < 0 then
        begin
          DisposeObject(st);
          FScrollTextList.Delete(i);
        end
      else
        begin
          if deltaTime > 0 then
              st.TextColor[3] := st.TextColor[3] - st.TextColor[3] * (deltaTime / st.LifeTime);
          st.LifeTime := st.LifeTime - deltaTime;
          Inc(i);
        end;
    end;

  i := 0;
  while i < FParticleBuffer.Count do
    begin
      try
        p := FParticleBuffer[i] as TParticles;

        p.Progress(deltaTime);

        try
          if (p.NoEnabledAutoFree) and (((not p.Enabled) and (p.Visible) and (p.VisibledParticle = 0)) or
            ((not p.Enabled) and (not p.Visible))) then
            begin
              p.Owner := nil;
              DisposeObject(p);
              FParticleBuffer.Delete(i);
            end
          else
            begin
              Inc(i);
            end;
        except
        end;
      except
      end;
    end;

  FLastDeltaTime := deltaTime;
  FLastNewTime := FLastNewTime + FLastDeltaTime;
end;

constructor TDrawEnginePool.Create;
begin
  inherited Create;
  FDefaultDrawEngineClass := TDrawEngine;
  FDrawEngineList := TCoreClassList.Create;
end;

destructor TDrawEnginePool.Destroy;
begin
  Clear;
  DisposeObject(FDrawEngineList);
  inherited Destroy;
end;

procedure TDrawEnginePool.Clear;
var
  i: Integer;
  p: PDrawEnginePoolData;
begin
  for i := 0 to FDrawEngineList.Count - 1 do
    begin
      p := FDrawEngineList[i];
      DisposeObject(p^.DrawEng);
      Dispose(p);
    end;
  FDrawEngineList.Clear;
end;

procedure TDrawEnginePool.ClearActivtedTimeOut(tickLen: Cardinal);
var
  i: Integer;
  p: PDrawEnginePoolData;
begin
  i := 0;
  while i < FDrawEngineList.Count do
    begin
      p := FDrawEngineList[i];
      if GetTimeTick - p^.LastActivted > tickLen then
        begin
          DisposeObject(p^.workObj);
          Dispose(p);
          FDrawEngineList.Delete(i);
        end
      else
          Inc(i);
    end;
end;

procedure TDrawEnginePool.Progress(deltaTime: Double);
var
  i: Integer;
begin
  for i := 0 to FDrawEngineList.Count - 1 do
      PDrawEnginePoolData(FDrawEngineList[i])^.DrawEng.Progress(deltaTime);
end;

function TDrawEnginePool.GetEng(const workObj: TCoreClassObject; const ADrawInterface: IDrawEngineInterface): TDrawEngine;
var
  i: Integer;
  p: PDrawEnginePoolData;
begin
  for i := 0 to FDrawEngineList.Count - 1 do
    begin
      p := FDrawEngineList[i];
      if p^.workObj = workObj then
        begin
          p^.LastActivted := GetTimeTick;
          if p^.DrawEng.FDrawInterface <> ADrawInterface then
              p^.DrawEng.FDrawInterface := ADrawInterface;

          p^.DrawEng.SetSize;
          Exit(p^.DrawEng);
        end;
    end;
  new(p);
  p^.DrawEng := FDefaultDrawEngineClass.Create(ADrawInterface);
  p^.DrawEng.ViewOptions := [];
  p^.workObj := workObj;
  p^.LastActivted := GetTimeTick;
  p^.DrawEng.SetSize;
  FDrawEngineList.Add(p);
  Result := p^.DrawEng;
end;

function TDrawEnginePool.GetEng(const workObj: TCoreClassObject): TDrawEngine;
var
  i: Integer;
  p: PDrawEnginePoolData;
begin
  for i := 0 to FDrawEngineList.Count - 1 do
    begin
      p := FDrawEngineList[i];
      if p^.workObj = workObj then
        begin
          p^.LastActivted := GetTimeTick;
          Exit(p^.DrawEng);
        end;
    end;
  new(p);
  p^.DrawEng := FDefaultDrawEngineClass.Create;
  p^.DrawEng.ViewOptions := [];
  p^.workObj := workObj;
  p^.LastActivted := GetTimeTick;
  FDrawEngineList.Add(p);
  Result := p^.DrawEng;
end;

function TDrawEngine_Raster.DEColor2RasterColor(const COLOR: TDEColor): TRasterColor;
begin
  Result := RasterAlphaColorF(RasterColorF(COLOR[0], COLOR[1], COLOR[2], COLOR[3]), COLOR[3]);
end;

function TDrawEngine_Raster.DEColor2RasterColor(const COLOR: TDEColor; const alpha: Byte): TRasterColor;
begin
  Result := RasterAlphaColor(RasterColorF(COLOR[0], COLOR[1], COLOR[2], COLOR[3]), alpha);
end;

constructor TDrawEngine_Raster.Create;
begin
  inherited Create;
  FEngine := nil;
  FMemory := DefaultTextureClass.Create;
//  FMemory.OpenAgg;

  FDebug := True;
end;

destructor TDrawEngine_Raster.Destroy;
begin
  DisposeObject(FMemory);
  if FEngine <> nil then
      DisposeObject(FEngine);
  inherited Destroy;
end;

procedure TDrawEngine_Raster.SetSize(R: TDERect);
begin
  FMemory.SetSize(Round(RectWidth(R)), Round(RectHeight(R)));
end;

procedure TDrawEngine_Raster.SetLineWidth(w: TDEFloat);
begin
//  FMemory.Agg.LineWidth := w;
end;

procedure TDrawEngine_Raster.DrawLine(pt1, pt2: TDEVec; COLOR: TDEColor);
begin
  FMemory.LineF(pt1, pt2, DEColor2RasterColor(COLOR), True);
end;

procedure TDrawEngine_Raster.DrawRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor);
begin
  FMemory.DrawRect(R, angle, DEColor2RasterColor(COLOR));
end;

procedure TDrawEngine_Raster.FillRect(R: TDERect; angle: TDEFloat; COLOR: TDEColor);
begin
  FMemory.FillRect(R, angle, DEColor2RasterColor(COLOR));
end;

procedure TDrawEngine_Raster.DrawEllipse(R: TDERect; COLOR: TDEColor);
var
  C: TDEVec;
begin
  C := RectCentre(R);
  FMemory.DrawEllipse(C, RectWidth(R) * 0.5, RectHeight(R) * 0.5, DEColor2RasterColor(COLOR));
end;

procedure TDrawEngine_Raster.FillEllipse(R: TDERect; COLOR: TDEColor);
var
  C: TDEVec;
begin
  C := RectCentre(R);
  FMemory.FillEllipse(C, RectWidth(R) * 0.5, RectHeight(R) * 0.5, DEColor2RasterColor(COLOR));
end;

procedure TDrawEngine_Raster.DrawText(Text: SystemString; Size: TDEFloat; R: TDERect; COLOR: TDEColor; center: Boolean; RotateVec: TDEVec; angle: TDEFloat);
var
  vSiz: TDEVec;
  X, Y: TDEFloat;
begin
  vSiz := FMemory.TextSize(Text, Size);
  if center then
    begin
      X := (RectWidth(R) - vSiz[0]) * 0.5;
      Y := (RectHeight(R) - vSiz[1]) * 0.5;
    end
  else
    begin
      X := 0;
      Y := Max((RectHeight(R) - vSiz[1]) * 0.5, R[0, 1]);
    end;
  FMemory.DrawText(Text, Round(X), Round(Y), RotateVec, angle, 1.0, Size, DEColor2RasterColor(COLOR));
end;

procedure TDrawEngine_Raster.DrawTexture(T: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat);
begin
  if T is TMemoryRaster then
      TMemoryRaster(T).ProjectionTo2DMap(FMemory, TV2Rect4.Init(sour.MakeRectV2, sour.angle), TV2Rect4.Init(dest.MakeRectV2, dest.angle), True, alpha);
end;

procedure TDrawEngine_Raster.Flush;
begin
end;

procedure TDrawEngine_Raster.ResetState;
begin
end;

procedure TDrawEngine_Raster.BeginDraw;
begin
end;

procedure TDrawEngine_Raster.EndDraw;
begin
end;

function TDrawEngine_Raster.CurrentScreenSize: TDEVec;
begin
  Result := FMemory.SizeOf2DPoint;
end;

function TDrawEngine_Raster.GetTextSize(Text: SystemString; Size: TDEFloat): TDEVec;
begin
  Result := FMemory.TextSize(Text, Size);
end;

function TDrawEngine_Raster.ReadyOK: Boolean;
begin
  Result := True;
end;

function TDrawEngine_Raster.EngineIntfObject: TCoreClassObject;
begin
  Result := Self;
end;

function TDrawEngine_Raster.Engine: TDrawEngine;
begin
  if FEngine = nil then
      FEngine := TDrawEngineClass.Create(Self);
  Result := FEngine;
end;

initialization

DefaultTextureClass := TDETexture;
EnginePool := TDrawEnginePool.Create;

finalization

if EnginePool <> nil then
  begin
    DisposeObject(EnginePool);
    EnginePool := nil;
  end;

end. 
 
