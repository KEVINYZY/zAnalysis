{ ****************************************************************************** }
{ * Pyramid Space support                                                      * }
{ * create by QQ 600585@qq.com                                                 * }
{ ****************************************************************************** }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }
unit PyramidSpace;

interface

{$INCLUDE zDefine.inc}


uses Math, CoreClasses, MemoryRaster, Geometry2DUnit, UnicodeMixedLib, DataFrameEngine, LearnTypes;

{$REGION 'PyramidTypes'}


type
  TGFloat = Single;

  TGSamplerMode = (gsmColor, gsmGray);

  TSigmaBuffer = array [0 .. MaxInt div SizeOf(TGFloat) - 1] of TGFloat;
  PSigmaBuffer = ^TSigmaBuffer;

  TSigmaKernel = packed record
    SigmaWidth, SigmaCenter: TLInt;
    Weights: PSigmaBuffer;
  end;

  TGaussVec   = packed array of TGFloat;
  PGaussVec   = ^TGaussVec;
  TGaussSpace = packed array of TGaussVec;
  PGaussSpace = ^TGaussSpace;

  TGaussSpaceIntegral = packed array of TGaussSpace;
  PGaussSpaceIntegral = ^TGaussSpaceIntegral;

  TPyramids = class;

  TExtremaCoor = packed record
    PyramidCoor: TVec2; // absolute coordinate in the pyramid(scale space)
    RealCoor: TVec2;    // absolute coordinate in the pyramid(scale space)
    pyr_id: TLInt;      // pyramid id
    scale_id: TLInt;    // scale layer id
    Owner: TPyramids;   // owner
  end;

  PExtremaCoor = ^TExtremaCoor;

  TPyramidCoor = packed record
    PyramidCoor: TVec2;   // absolute coordinate in the pyramid(scale space)
    RealCoor: TVec2;      // real scaled [0,1] coordinate in the original image
    pyr_id: TLInt;        // pyramid id
    scale_id: TLInt;      // scale layer id
    Scale: TGFloat;       // scale space
    Orientation: TGFloat; // Orientation information
    OriFinish: Boolean;   // finish Orientation
    Owner: TPyramids;     // owner
    class function Init: TPyramidCoor; static; {$IFDEF INLINE_ASM} inline; {$ENDIF}
  end;

  PPyramidCoor = ^TPyramidCoor;

  TPyramidCoorList = class(TCoreClassObject)
  private
    FList: TCoreClassList;
    function GetItems(idx: TLInt): PPyramidCoor;
  public
    constructor Create;
    destructor Destroy; override;

    function Add(Value: TPyramidCoor): TLInt; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function Add(Value: PPyramidCoor): TLInt; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure Add(pl: TPyramidCoorList; const NewCopy: Boolean); overload;
    procedure Delete(idx: TLInt); {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure Clear; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function Count: TLInt; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure Assign(Source: TPyramidCoorList);

    procedure SaveToDataFrame(df: TDataFrameEngine);
    procedure LoadFromDataFrame(df: TDataFrameEngine);

    property Items[idx: TLInt]: PPyramidCoor read GetItems; default;
  end;

  PPyramidLayer = ^TPyramidLayer;

  TPyramidLayer = packed record
  public
    numScale, width, height: TLInt;
    // scale space(SS)
    SigmaIntegral, MagIntegral, OrtIntegral: TGaussSpaceIntegral;
    // difference of Gaussian Space(DOG)
    Diffs: TGaussSpaceIntegral;
  private
    class procedure ComputeMagAndOrt(const w, h: TLInt; const OriSamplerP, MagP, OrtP: PGaussSpace); static;
    class procedure ComputeDiff(const w, h: TLInt; const s1, s2, DiffOut: PGaussSpace); static;

    procedure Build(var OriSampler: TGaussSpace; const factorWidth, factorHeight, NScale: TLInt; const GaussSigma: TGFloat);
    procedure Free;
  end;

  TPyramids = class(TCoreClassObject)
  private
    GaussTransformSpace: TGaussSpace;
    FWidth, FHeight: TLInt;

    Pyramids: packed array of TPyramidLayer;
    SamplerXY: packed array of Byte;
    FViewer: TMemoryRaster;

    function isExtrema(const X, Y: TLInt; const pyr_id, scale_id: TLInt): Boolean; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure BuildLocalExtrema(const pyr_id, scale_id: TLInt; const Transform: Boolean; v2List: TVec2List); overload;
    procedure BuildLocalExtrema(const pyr_id, scale_id: TLInt; ExtremaCoorList: TCoreClassList); overload;

    function KPIntegral(const dogIntegral: PGaussSpaceIntegral; const X, Y, s: TLInt; var Offset, Delta: TLVec): Boolean;
    function ComputeKeyPoint(const ExtremaCoor: TVec2; const pyr_id, scale_id: TLInt; var output: TPyramidCoor): Boolean; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function ComputeEndgeReponse(const ExtremaCoor: TVec2; const p: PGaussSpace): Boolean; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function ComputePyramidCoor(const FilterEndge, FilterOri: Boolean; const ExtremaV2: TVec2; const pyr_id, scale_id: TLInt): TPyramidCoorList;
  public
    constructor CreateWithRaster(const raster: TMemoryRaster); overload;
    constructor CreateWithRaster(const fn: string); overload;
    constructor CreateWithRaster(const stream: TCoreClassStream); overload;
    constructor CreateWithGauss(const spr: PGaussSpace);
    destructor Destroy; override;

    property width: TLInt read FHeight;
    property height: TLInt read FHeight;

    procedure SetRegion(const Clip: TVec2List); overload;
    procedure SetRegion(var mat: TLBMatrix); overload;

    procedure BuildPyramid;

    function BuildAbsoluteExtrema: TVec2List;
    function BuildPyramidExtrema(const FilterOri: Boolean): TPyramidCoorList;

    function BuildViewer(const v2List: TVec2List; const radius: TGFloat; const COLOR: TRasterColor): TMemoryRaster; overload;
    function BuildViewer(const cList: TPyramidCoorList; const radius: TGFloat; const COLOR: TRasterColor): TMemoryRaster; overload;
    class procedure BuildToViewer(const cList: TPyramidCoorList; const radius: TGFloat; const COLOR: TRasterColor; const RasterViewer: TMemoryRaster); overload;
    class procedure BuildToViewer(const cList: TPyramidCoorList; const radius: TGFloat; const RasterViewer: TMemoryRaster); overload;
  end;

  TFeature = class;

  PDescriptor = ^TDescriptor;

  TDescriptor = packed record
    descriptor: TLVec;    // feature vector
    coor: TVec2;          // real scaled [0,1] coordinate in the original image
    AbsCoor: TVec2;       // absolute sampler coordinal in the original image
    Orientation: TGFloat; // Orientation information
    index: TLInt;         // index in Fetature
    Owner: TFeature;      // owner
  end;

  PMatchInfo = ^TMatchInfo;

  TMatchInfo = packed record
    d1, d2: PDescriptor;
    Dist: TGFloat; // Descriptor distance
  end;

  TArrayMatchInfo = array of TMatchInfo;
  PArrayMatchInfo = ^TArrayMatchInfo;

  // feature on sift
  TFeature = class(TCoreClassObject)
  private const
    CPI2               = 2 * pi;
    CSQRT1_2           = 0.707106781186547524401;
    CDESC_HIST_BIN_NUM = 8;
    CNUM_BIN_PER_RAD   = CDESC_HIST_BIN_NUM / CPI2;
    CDESC_HIST_WIDTH   = 4;
    DESCRIPTOR_LENGTH  = CDESC_HIST_WIDTH * CDESC_HIST_WIDTH * CDESC_HIST_BIN_NUM;
  protected
    FDescriptorBuff: packed array of TDescriptor;
    FPyramidCoordList: TPyramidCoorList;
    FWidth, FHeight: TLInt;
    // gray format
    FViewer: packed array of Byte;
    // internal used
    FInternalVec: TVec2;
    // user custom
    FUserData: Pointer;

    procedure ComputeDescriptor(const p: PPyramidCoor; var Desc: TLVec); {$IFDEF INLINE_ASM} inline; {$ENDIF}
    procedure BuildFeature(Pyramids: TPyramids);
  public
    constructor CreateWithPyramids(Pyramids: TPyramids);
    constructor CreateWithRaster(const raster: TMemoryRaster; const Clip: TVec2List); overload;
    constructor CreateWithRaster(const raster: TMemoryRaster; var mat: TLBMatrix); overload;
    constructor CreateWithRaster(const raster: TMemoryRaster); overload;
    constructor CreateWithRaster(const fn: string); overload;
    constructor CreateWithRaster(const stream: TCoreClassStream); overload;
    constructor CreateWithSampler(const spr: PGaussSpace);
    constructor Create;
    destructor Destroy; override;

    function Count: TLInt; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function GetFD(const index: TLInt): PDescriptor;
    property FD[const index: TLInt]: PDescriptor read GetFD; default;

    procedure SaveToStream(stream: TCoreClassStream);
    procedure LoadFromStream(stream: TCoreClassStream);

    function CreateViewer: TMemoryRaster;
    function CreateFeatureViewer(const FeatureRadius: TGFloat; const COLOR: TRasterColor): TMemoryRaster;

    property width: TLInt read FHeight;
    property height: TLInt read FHeight;
    property UserData: Pointer read FUserData write FUserData;
  end;

{$ENDREGION 'PyramidTypes'}

{$REGION 'PyramidFunctions'}


function Diff(const f1, f2: TGFloat): TGFloat; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function between(const idx, Start, OVER: TLInt): Boolean; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function between(const idx, Start, OVER: TGFloat): Boolean; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure CopySampler(var Source, dest: TGaussSpace); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure SamplerAlpha(const Source: TMemoryRaster; var dest: TGaussSpace); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure SamplerAlpha(var Source: TGaussSpace; const dest: TMemoryRaster); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure Sampler(const Source: TMemoryRaster; const WR, WG, wb: TGFloat; const ColorSap: TLInt; var dest: TGaussSpace); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure Sampler(const Source: TMemoryRaster; var dest: TGaussSpace); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure Sampler(var Source: TGaussSpace; const dest: TMemoryRaster); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure Sampler(var Source: TGaussSpace; var dest: TByteRaster); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure ZoomLine(const Source, dest: PGaussSpace; const pass, SourceWidth, SourceHeight, DestWidth, DestHeight: TLInt); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure ZoomSampler(var Source, dest: TGaussSpace; const DestWidth, DestHeight: TLInt);
procedure BuildSigmaKernel(const SIGMA: TGFloat; var kernel: TSigmaKernel); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure SigmaRow(var theRow, destRow: TGaussVec; var k: TSigmaKernel); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure SigmaSampler(var Source, dest: TGaussSpace; const SIGMA: TGFloat);
procedure SaveSampler(var Source: TGaussSpace; fileName: string); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure SaveSamplerToJpegLS(var Source: TGaussSpace; fileName: string); {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure ComputeSamplerSize(var width, height: TLInt);

// square of euclidean
// need avx + sse or GPU
function e_sqr(const sour, dest: PDescriptor): TGFloat; {$IFDEF INLINE_ASM} inline; {$ENDIF}

// feature match
function MatchFeature(const Source, dest: TFeature; var MatchInfo: TArrayMatchInfo): TLFloat;
function BuildMatchInfoView(var MatchInfo: TArrayMatchInfo; const RectWidth: TLInt; const ViewFeature: Boolean): TMemoryRaster;

procedure TestPyramidSpace;

{$ENDREGION 'PyramidFunctions'}

{$REGION 'Options'}


var
  // sampler
  CRED_WEIGHT_SAMPLER: TGFloat;
  CGREEN_WEIGHT_SAMPLER: TGFloat;
  CBLUE_WEIGHT_SAMPLER: TGFloat;
  CSAMPLER_MODE: TGSamplerMode;
  CMAX_GRAY_COLOR_SAMPLER: TLInt;
  CMAX_SAMPLER_WIDTH: TLInt;
  CMAX_SAMPLER_HEIGHT: TLInt;

  // gauss kernal
  CGAUSS_KERNEL_FACTOR: TLInt;

  // pyramid octave
  CNUMBER_OCTAVE: TLInt;

  // scale space(SS) and difference of Gaussian Space(DOG)
  CNUMBER_SCALE: TLInt;

  // pyramid scale space factor
  CSCALE_FACTOR: TGFloat;
  CSIGMA_FACTOR: TGFloat;

  // Extrema
  CGRAY_THRESHOLD: TGFloat;
  CEXTREMA_DIFF_THRESHOLD: TGFloat;
  CFILTER_MAX_KEYPOINT_ENDGE: TLInt;

  // orientation
  COFFSET_DEPTH: TLInt;
  COFFSET_THRESHOLD: TGFloat;
  CCONTRAST_THRESHOLD: TGFloat;
  CEDGE_RATIO: TGFloat;
  CORIENTATION_RADIUS: TGFloat;
  CORIENTATION_SMOOTH_COUNT: TLInt;

  // feature
  CMATCH_REJECT_NEXT_RATIO: TGFloat;
  CDESC_SCALE_FACTOR: TGFloat;
  CDESC_PROCESS_LIGHT: Boolean;

{$ENDREGION 'Options'}

implementation

uses
{$IFDEF parallel}
{$IFDEF FPC}
  mtprocs,
{$ELSE FPC}
  Threading,
{$ENDIF FPC}
{$ENDIF parallel}
  SyncObjs, Learn;

const
  cPI: TGFloat = pi;

function Diff(const f1, f2: TGFloat): TGFloat;
begin
  if f1 < f2 then
      Result := fabs(f2 - f1)
  else
      Result := fabs(f1 - f2);
end;

function between(const idx, Start, OVER: TLInt): Boolean;
begin
  Result := ((idx >= Start) and (idx <= OVER - 1));
end;

function between(const idx, Start, OVER: TGFloat): Boolean;
begin
  Result := ((idx >= Start) and (idx <= OVER - 1));
end;

procedure CopySampler(var Source, dest: TGaussSpace);
var
  i, J: TLInt;
begin
  if length(dest) <> length(Source) then
      SetLength(dest, length(Source));

  for J := 0 to length(Source) - 1 do
    begin
      if length(dest[J]) <> length(Source[J]) then
          SetLength(dest[J], length(Source[J]));
      for i := 0 to length(Source[J]) - 1 do
          dest[J, i] := Source[J, i];
    end;
end;

procedure SamplerAlpha(const Source: TMemoryRaster; var dest: TGaussSpace);
var
  i, J: TLInt;
begin
  SetLength(dest, Source.height, Source.width);
  for J := 0 to Source.height - 1 do
    for i := 0 to Source.width - 1 do
        dest[J, i] := Source.PixelAlpha[i, J] / 255;
end;

procedure SamplerAlpha(var Source: TGaussSpace; const dest: TMemoryRaster);
var
  i, J: TLInt;
begin
  dest.SetSize(length(Source[0]), length(Source));
  for J := 0 to dest.height - 1 do
    for i := 0 to dest.width - 1 do
        dest.PixelAlpha[i, J] := Round(Clamp(Source[J, i], 0.0, 1.0) * 255);
end;

procedure Sampler(const Source: TMemoryRaster; const WR, WG, wb: TGFloat; const ColorSap: TLInt; var dest: TGaussSpace);
var
  i, J, C, F, w, wf: TLInt;
  R, g, b: TGFloat;
begin
  SetLength(dest, Source.height, Source.width);
  if ColorSap > 255 then
      C := 256
  else if ColorSap < 1 then
      C := 2
  else
      C := ColorSap;

  F := 256 div C;

  for J := 0 to Source.height - 1 do
    for i := 0 to Source.width - 1 do
      begin
        RasterColor2F(Source.Pixel[i, J], R, g, b);
        w := Trunc((R * WR + g * WG + b * wb) / (WR + WG + wb) * 256);
        wf := (w div F) * F;
        dest[J, i] := Clamp(Round(wf) / 256, 0.0, 1.0);
      end;
end;

procedure Sampler(const Source: TMemoryRaster; var dest: TGaussSpace);
var
  i, J: TLInt;
  R, g, b: TGFloat;
begin
  SetLength(dest, Source.height, Source.width);
  for J := 0 to Source.height - 1 do
    for i := 0 to Source.width - 1 do
      begin
        if CSAMPLER_MODE = TGSamplerMode.gsmColor then
          begin
            RasterColor2F(Source.Pixel[i, J], R, g, b);
            dest[J, i] := Max(R, Max(g, b));
          end
        else
            dest[J, i] := Source.PixelGrayS[i, J];
      end;
end;

procedure Sampler(var Source: TGaussSpace; const dest: TMemoryRaster);
var
  i, J: TLInt;
begin
  dest.SetSize(length(Source[0]), length(Source));
  for J := 0 to dest.height - 1 do
    for i := 0 to dest.width - 1 do
        dest.PixelGrayS[i, J] := Source[J, i];
end;

procedure Sampler(var Source: TGaussSpace; var dest: TByteRaster);
var
  i, J: TLInt;
begin
  SetLength(dest, length(Source), length(Source[0]));
  for J := 0 to length(Source) - 1 do
    for i := 0 to length(Source[J]) - 1 do
        dest[J, i] := Round(Clamp(Source[J, i], 0, 1) * 255);
end;

procedure ZoomLine(const Source, dest: PGaussSpace; const pass, SourceWidth, SourceHeight, DestWidth, DestHeight: TLInt);
var
  J: TLInt;
  SourceIInt, SourceJInt: TLInt;
begin
  for J := 0 to DestHeight - 1 do
    begin
      SourceIInt := Round(pass / (DestWidth - 1) * (SourceWidth - 1));
      SourceJInt := Round(J / (DestHeight - 1) * (SourceHeight - 1));

      dest^[J, pass] := Source^[SourceJInt, SourceIInt];
    end;
end;

procedure ZoomSampler(var Source, dest: TGaussSpace; const DestWidth, DestHeight: TLInt);
var
  SourceWidth, SourceHeight: TLInt;
  SourceP, DestP: PGaussSpace;

  {$IFDEF parallel}
  {$IFDEF FPC}
    procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    begin
      ZoomLine(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
    end;
  {$ENDIF FPC}
  {$ELSE parallel}
    procedure DoFor;
    var
      pass: TLInt;
    begin
      for pass := 0 to DestWidth - 1 do
          ZoomLine(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
    end;
  {$ENDIF parallel}

begin
  SourceWidth := length(Source[0]);
  SourceHeight := length(Source);
  SetLength(dest, DestHeight, DestWidth);

  if (SourceWidth > 1) and (SourceWidth > 1) and (DestWidth > 1) and (DestHeight > 1) then
    begin
      SourceP := @Source;
      DestP := @dest;

{$IFDEF parallel}
{$IFDEF FPC}
      ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, DestWidth - 1);
{$ELSE FPC}
      TParallel.for(0, DestWidth - 1, procedure(pass: Integer)
        begin
          ZoomLine(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
        end);
{$ENDIF FPC}
{$ELSE parallel}
      DoFor;
{$ENDIF parallel}
    end;
end;

procedure BuildSigmaKernel(const SIGMA: TGFloat; var kernel: TSigmaKernel);
var
  exp_coeff, wsum, fac: TGFloat;
  i: TLInt;
  p: PSigmaBuffer;
begin
  kernel.SigmaWidth := Ceil(0.3 * (SIGMA * 0.5 - 1) + 0.8) * CGAUSS_KERNEL_FACTOR;
  if (kernel.SigmaWidth mod 2 = 0) then
      Inc(kernel.SigmaWidth);

  kernel.Weights := System.GetMemory(SizeOf(TGFloat) * kernel.SigmaWidth);

  kernel.SigmaCenter := kernel.SigmaWidth div 2;
  p := @kernel.Weights^[kernel.SigmaCenter];
  p^[0] := 1;

  exp_coeff := -1.0 / (SIGMA * SIGMA * 2);
  wsum := 1;

  for i := 1 to kernel.SigmaCenter do
    begin
      p^[i] := Exp(i * i * exp_coeff);
      wsum := wsum + p^[i] * 2;
    end;

  fac := 1.0 / wsum;
  p^[0] := fac;

  for i := 1 to kernel.SigmaCenter do
    begin
      kernel.Weights^[i + kernel.SigmaCenter] := p^[i] * fac;
      kernel.Weights^[-i + kernel.SigmaCenter] := p^[i];
    end;
end;

procedure SigmaRow(var theRow, destRow: TGaussVec; var k: TSigmaKernel);
  function kOffset(const v, L, h: TLInt): TLInt; {$IFDEF INLINE_ASM} inline; {$ENDIF}
  begin
    Result := v;
    if Result > h then
        Result := h
    else if Result < L then
        Result := L;
  end;

var
  J, n: TLInt;
  TB: TGFloat;
begin
  for J := low(theRow) to high(theRow) do
    begin
      TB := 0;
      for n := -k.SigmaCenter to k.SigmaCenter do
          TB := TB + theRow[kOffset(J + n, 0, high(theRow))] * k.Weights^[n + k.SigmaCenter];
      destRow[J] := TB;
    end;
end;

procedure SigmaSampler(var Source, dest: TGaussSpace; const SIGMA: TGFloat);
var
  w, h: TLInt;
  k: TSigmaKernel;
  SourceP, DestP: PGaussSpace;

  {$IFDEF parallel}
  {$IFDEF FPC}
    procedure Nested_ParallelForH(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    begin
      SigmaRow(SourceP^[pass], DestP^[pass], k);
    end;
    procedure Nested_ParallelForW(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    var
      J: TLInt;
      LPixels: TGaussVec;
    begin
      SetLength(LPixels, h);
      for J := 0 to h - 1 do
          LPixels[J] := DestP^[J, pass];

      SigmaRow(LPixels, LPixels, k);

      for J := 0 to h - 1 do
          DestP^[J, pass] := LPixels[J];

      SetLength(LPixels, 0);
    end;
  {$ENDIF FPC}
  {$ELSE parallel}
    procedure DoFor;
    var
      pass: TLInt;
      J: TLInt;
      LPixels: TGaussVec;
    begin
      for pass := 0 to h - 1 do
          SigmaRow(SourceP^[pass], DestP^[pass], k);

      SetLength(LPixels, h);
      for pass := 0 to w - 1 do
        begin
          for J := 0 to h - 1 do
              LPixels[J] := DestP^[J, pass];

          SigmaRow(LPixels, LPixels, k);

          for J := 0 to h - 1 do
              DestP^[J, pass] := LPixels[J];
        end;

      SetLength(LPixels, 0);
    end;
  {$ENDIF parallel}


begin
  w := length(Source[0]);
  h := length(Source);

  if @Source <> @dest then
      SetLength(dest, h, w);

  BuildSigmaKernel(SIGMA, k);

  SourceP := @Source;
  DestP := @dest;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelForH, 0, h - 1);
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelForW, 0, w - 1);
{$ELSE FPC}
  TParallel.for(0, h - 1, procedure(pass: Integer)
    begin
      SigmaRow(SourceP^[pass], DestP^[pass], k);
    end);
  TParallel.for(0, w - 1, procedure(pass: Integer)
    var
      J: TLInt;
      LPixels: TGaussVec;
    begin
      SetLength(LPixels, h);
      for J := 0 to h - 1 do
          LPixels[J] := DestP^[J, pass];

      SigmaRow(LPixels, LPixels, k);

      for J := 0 to h - 1 do
          DestP^[J, pass] := LPixels[J];

      SetLength(LPixels, 0);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
  System.FreeMemory(k.Weights);
end;

procedure SaveSampler(var Source: TGaussSpace; fileName: string);
var
  mr: TMemoryRaster;
begin
  mr := NewRaster();
  Sampler(Source, mr);
  SaveRaster(mr, fileName);
  DisposeObject(mr);
end;

procedure SaveSamplerToJpegLS(var Source: TGaussSpace; fileName: string);
var
  gray: TByteRaster;
  fs: TCoreClassFileStream;
begin
  Sampler(Source, gray);
  try
    fs := TCoreClassFileStream.Create(fileName, fmCreate);
    EncodeJpegLSGrayRasterToStream(@gray, fs);
  except
  end;
  DisposeObject(fs);
end;

procedure ComputeSamplerSize(var width, height: TLInt);
var
  F: TGFloat;
begin
  if (width > CMAX_SAMPLER_WIDTH) then
    begin
      F := CMAX_SAMPLER_WIDTH / width;
      width := Round(width * F);
      height := Round(height * F);
    end;
  if (height > CMAX_SAMPLER_HEIGHT) then
    begin
      F := CMAX_SAMPLER_HEIGHT / height;
      width := Round(width * F);
      height := Round(height * F);
    end;
end;

class function TPyramidCoor.Init: TPyramidCoor;
begin
  Result.PyramidCoor := NULLPoint;
  Result.RealCoor := NULLPoint;
  Result.pyr_id := -1;
  Result.scale_id := -1;
  Result.Scale := 0;
  Result.Orientation := 0;
  Result.OriFinish := False;
  Result.Owner := nil;
end;

function e_sqr(const sour, dest: PDescriptor): TGFloat;
var
  i: TLInt;
  D0, d1, d2, d3, d4, d5, d6, d7: TGFloat;
begin
  // pure pascal
  Result := 0;
  if length(sour^.descriptor) <> length(dest^.descriptor) then
      Exit;

  // sqr x8 extract
  // need avx + sse or GPU
  i := 0;
  while i < length(sour^.descriptor) do
    begin
      D0 := dest^.descriptor[i + 0] - sour^.descriptor[i + 0];
      D0 := D0 * D0;

      d1 := dest^.descriptor[i + 1] - sour^.descriptor[i + 1];
      d1 := d1 * d1;

      d2 := dest^.descriptor[i + 2] - sour^.descriptor[i + 2];
      d2 := d2 * d2;

      d3 := dest^.descriptor[i + 3] - sour^.descriptor[i + 3];
      d3 := d3 * d3;

      d4 := dest^.descriptor[i + 4] - sour^.descriptor[i + 4];
      d4 := d4 * d4;

      d5 := dest^.descriptor[i + 5] - sour^.descriptor[i + 5];
      d5 := d5 * d5;

      d6 := dest^.descriptor[i + 6] - sour^.descriptor[i + 6];
      d6 := d6 * d6;

      d7 := dest^.descriptor[i + 7] - sour^.descriptor[i + 7];
      d7 := d7 * d7;

      Result := Result + D0 + d1 + d2 + d3 + d4 + d5 + d6 + d7;
      Inc(i, 8);
    end;
end;

function MatchFeature(const Source, dest: TFeature; var MatchInfo: TArrayMatchInfo): TLFloat;
var
  L: TCoreClassList;
  pf1_len, pf2_len: TLInt;
  pf1, pf2: TFeature;
  sqr_memory: array of array of TGFloat;
  reject_ratio_sqr: TGFloat;

  {$IFDEF parallel}
  {$IFDEF FPC}
    procedure Nested_ParallelFor_sqr(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    var
      J: TLInt;
    begin
      for J := 0 to pf2_len - 1 do
          sqr_memory[pass, J] := e_sqr(pf1[pass], pf2[J]);
    end;

    procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    var
      m_idx, J: TLInt;
      dsc1, dsc2: PDescriptor;
      minf, next_minf: TLFloat;
      d: Double;
      PD: PMatchInfo;
    begin
      dsc1 := pf1[pass];
      m_idx := -1;
      minf := MaxRealNumber;
      next_minf := minf;
      // find dsc1 from feat2
      for J := 0 to pf2_len - 1 do
        begin
          d := Min(sqr_memory[pass, J], next_minf);
          if (d < minf) then
            begin
              next_minf := minf;
              minf := d;
              m_idx := J;
            end
          else
              next_minf := Min(next_minf, d);
        end;

      /// bidirectional rejection
      if (minf > reject_ratio_sqr * next_minf) then
          Exit;

      // fix m_idx
      dsc2 := pf2[m_idx];
      for J := 0 to pf1_len - 1 do
        if J <> pass then
          begin
            d := Min(sqr_memory[J, m_idx], next_minf);
            next_minf := Min(next_minf, d);
          end;
      if (minf > reject_ratio_sqr * next_minf) then
          Exit;

      new(PD);
      PD^.d1 := pf1[pass];
      PD^.d2 := pf2[m_idx];
      LockObject(L);
      L.Add(PD);
      UnLockObject(L);
    end;
  {$ENDIF FPC}
  {$ELSE parallel}
    procedure DoFor;
    var
      pass: TLInt;
      m_idx, J: TLInt;
      dsc1, dsc2: PDescriptor;
      minf, next_minf: TLFloat;
      d: Double;
      PD: PMatchInfo;
    begin
      for pass := 0 to pf1_len - 1 do
        for J := 0 to pf2_len - 1 do
            sqr_memory[pass, J] := e_sqr(pf1[pass], pf2[J]);

      for pass := 0 to pf1_len - 1 do
        begin
          dsc1 := pf1[pass];
          m_idx := -1;
          minf := MaxRealNumber;
          next_minf := minf;
          // find dsc1 from feat2
          for J := 0 to pf2_len - 1 do
            begin
              d := Min(sqr_memory[pass, J], next_minf);
              if (d < minf) then
                begin
                  next_minf := minf;
                  minf := d;
                  m_idx := J;
                end
              else
                  next_minf := Min(next_minf, d);
            end;

          /// bidirectional rejection
          if (minf > reject_ratio_sqr * next_minf) then
              Continue;

          // fix m_idx
          dsc2 := pf2[m_idx];
          for J := 0 to pf1_len - 1 do
            if J <> pass then
              begin
                d := Min(sqr_memory[J, m_idx], next_minf);
                next_minf := Min(next_minf, d);
              end;
          if (minf > reject_ratio_sqr * next_minf) then
              Continue;

          new(PD);
          PD^.d1 := pf1[pass];
          PD^.d2 := pf2[m_idx];
          L.Add(PD);
        end;
    end;
  {$ENDIF parallel}

  procedure FillMatchInfoAndFreeTemp;
  var
    i: TLInt;
    PD: PMatchInfo;
  begin
    SetLength(MatchInfo, L.Count);
    for i := 0 to L.Count - 1 do
      begin
        PD := PMatchInfo(L[i]);
        MatchInfo[i] := PD^;
        Dispose(PD);
      end;
  end;

begin
  Result := 0;
  pf1_len := Source.Count;
  pf2_len := dest.Count;

  if (pf1_len = 0) or (pf2_len = 0) then
      Exit;

  if pf1_len > pf2_len then
    begin
      Swap(pf1_len, pf2_len);
      pf1 := dest;
      pf2 := Source;
    end
  else
    begin
      pf1 := Source;
      pf2 := dest;
    end;

  L := TCoreClassList.Create;
  SetLength(sqr_memory, pf1_len, pf2_len);
  reject_ratio_sqr := CMATCH_REJECT_NEXT_RATIO * CMATCH_REJECT_NEXT_RATIO;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor_sqr, 0, pf1_len - 1);
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, pf1_len - 1);
{$ELSE FPC}
  TParallel.for(0, pf1_len - 1, procedure(pass: Integer)
    var
      J: TLInt;
    begin
      for J := 0 to pf2_len - 1 do
          sqr_memory[pass, J] := e_sqr(pf1[pass], pf2[J]);
    end);

  TParallel.for(0, pf1_len - 1, procedure(pass: Integer)
    var
      m_idx, J: TLInt;
      dsc1, dsc2: PDescriptor;
      minf, next_minf: TLFloat;
      d: Double;
      PD: PMatchInfo;
    begin
      dsc1 := pf1[pass];
      m_idx := -1;
      minf := MaxRealNumber;
      next_minf := minf;
      // find dsc1 from feat2
      for J := 0 to pf2_len - 1 do
        begin
          d := Min(sqr_memory[pass, J], next_minf);
          if (d < minf) then
            begin
              next_minf := minf;
              minf := d;
              m_idx := J;
            end
          else
              next_minf := Min(next_minf, d);
        end;

      // bidirectional rejection
      if (minf > reject_ratio_sqr * next_minf) then
          Exit;

      // fix m_idx
      dsc2 := pf2[m_idx];
      for J := 0 to pf1_len - 1 do
        if J <> pass then
          begin
            d := Min(sqr_memory[J, m_idx], next_minf);
            next_minf := Min(next_minf, d);
          end;
      if (minf > reject_ratio_sqr * next_minf) then
          Exit;

      new(PD);
      PD^.d1 := pf1[pass];
      PD^.d2 := pf2[m_idx];
      PD^.Dist := sqr_memory[pass, m_idx];
      LockObject(L);
      L.Add(PD);
      UnLockObject(L);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF}
  // free cache
  SetLength(sqr_memory, 0, 0);
  // fill result
  Result := L.Count;
  FillMatchInfoAndFreeTemp;

  DisposeObject(L);
end;

function BuildMatchInfoView(var MatchInfo: TArrayMatchInfo; const RectWidth: TLInt; const ViewFeature: Boolean): TMemoryRaster;
var
  mr1, mr2: TMemoryRaster;
  FT1, FT2: TFeature;
  C: Byte;
  i, J: TLInt;

  bV1, bV2: TVec2;

  p: PMatchInfo;
  RC: TRasterColor;
  v1, v2: TVec2;
begin
  if length(MatchInfo) = 0 then
    begin
      Result := nil;
      Exit;
    end;
  Result := NewRaster();

  FT1 := MatchInfo[0].d1^.Owner;
  FT2 := MatchInfo[0].d2^.Owner;

  if ViewFeature then
    begin
      mr1 := FT1.CreateFeatureViewer(8, RasterColorF(0.4, 0.1, 0.1, 0.5));
      mr2 := FT2.CreateFeatureViewer(8, RasterColorF(0.4, 0.1, 0.1, 0.5));
    end
  else
    begin
      mr1 := FT1.CreateViewer;
      mr2 := FT2.CreateViewer;
    end;

  Result.SetSize(mr1.width + mr2.width, Max(mr1.height, mr2.height), RasterColor(0, 0, 0, 0));
  Result.Draw(0, 0, mr1);
  Result.Draw(mr1.width, 0, mr2);
  Result.OpenAgg;

  bV1 := FT1.FInternalVec;
  bV2 := FT2.FInternalVec;

  FT1.FInternalVec := vec2(0, 0);
  FT2.FInternalVec := vec2(mr1.width, 0);

  for i := 0 to length(MatchInfo) - 1 do
    begin
      p := @MatchInfo[i];
      RC := RasterColor(RandomRange(0, 255), RandomRange(0, 255), RandomRange(0, 255), 255);

      v1 := Vec2Add(p^.d1^.AbsCoor, p^.d1^.Owner.FInternalVec);
      v2 := Vec2Add(p^.d2^.AbsCoor, p^.d2^.Owner.FInternalVec);

      Result.FillCircle(v1, RectWidth * 0.5, RC);
      Result.FillCircle(v2, RectWidth * 0.5, RC);

      Result.LineF(v1, v2, RC, True);
    end;

  FT1.FInternalVec := bV1;
  FT2.FInternalVec := bV2;
  DisposeObject([mr1, mr2]);
end;

function TPyramidCoorList.GetItems(idx: TLInt): PPyramidCoor;
begin
  Result := PPyramidCoor(FList[idx]);
end;

constructor TPyramidCoorList.Create;
begin
  inherited Create;
  FList := TCoreClassList.Create;
end;

destructor TPyramidCoorList.Destroy;
begin
  Clear;
  DisposeObject(FList);
  inherited Destroy;
end;

function TPyramidCoorList.Add(Value: TPyramidCoor): TLInt;
var
  p: PPyramidCoor;
begin
  new(p);
  p^ := Value;
  Result := FList.Add(p);
end;

function TPyramidCoorList.Add(Value: PPyramidCoor): TLInt;
begin
  if Value <> nil then
      Result := FList.Add(Value)
  else
      Result := -1;
end;

procedure TPyramidCoorList.Add(pl: TPyramidCoorList; const NewCopy: Boolean);
var
  i: TLInt;
  p: PPyramidCoor;
begin
  for i := 0 to pl.Count - 1 do
    begin
      if NewCopy then
        begin
          new(p);
          p^ := pl[i]^;
        end
      else
          p := pl[i];

      FList.Add(p);
    end;
  if not NewCopy then
      pl.FList.Clear;
end;

procedure TPyramidCoorList.Delete(idx: TLInt);
begin
  Dispose(PPyramidCoor(FList[idx]));
  FList.Delete(idx);
end;

procedure TPyramidCoorList.Clear;
var
  i: TLInt;
begin
  for i := 0 to FList.Count - 1 do
      Dispose(PPyramidCoor(FList[i]));
  FList.Clear;
end;

function TPyramidCoorList.Count: TLInt;
begin
  Result := FList.Count;
end;

procedure TPyramidCoorList.Assign(Source: TPyramidCoorList);
var
  i: TLInt;
  p: PPyramidCoor;
begin
  Clear;
  for i := 0 to Source.Count - 1 do
    begin
      new(p);
      p^ := Source[i]^;
      Add(p);
    end;
end;

procedure TPyramidCoorList.SaveToDataFrame(df: TDataFrameEngine);
var
  i: Integer;
  p: PPyramidCoor;
  d: TDataFrameEngine;
begin
  for i := 0 to Count - 1 do
    begin
      p := GetItems(i);
      d := TDataFrameEngine.Create;
      d.WriteVec2(p^.PyramidCoor);
      d.WriteVec2(p^.RealCoor);
      d.WriteInteger(p^.pyr_id);
      d.WriteInteger(p^.scale_id);
      d.WriteSingle(p^.Scale);
      d.WriteSingle(p^.Orientation);
      d.WriteBool(p^.OriFinish);
      df.WriteDataFrame(d);
      DisposeObject(d);
    end;
end;

procedure TPyramidCoorList.LoadFromDataFrame(df: TDataFrameEngine);
var
  p: PPyramidCoor;
  d: TDataFrameEngine;
begin
  Clear;
  while df.Reader.NotEnd do
    begin
      new(p);
      p^.Init;
      d := TDataFrameEngine.Create;
      df.Reader.ReadDataFrame(d);
      p^.PyramidCoor := d.Reader.ReadVec2;
      p^.RealCoor := d.Reader.ReadVec2;
      p^.pyr_id := d.Reader.ReadInteger;
      p^.scale_id := d.Reader.ReadInteger;
      p^.Scale := d.Reader.ReadSingle;
      p^.Orientation := d.Reader.ReadSingle;
      p^.OriFinish := d.Reader.ReadBool;
      Add(p);
      DisposeObject(d);
    end;
end;

class procedure TPyramidLayer.ComputeMagAndOrt(const w, h: TLInt; const OriSamplerP, MagP, OrtP: PGaussSpace);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  var
    X: TLInt;
    mag_row, ort_row, orig_row, orig_plus, orig_minus: PGaussVec;
    dy, dx: TGFloat;
  begin
    mag_row := @MagP^[pass];
    ort_row := @OrtP^[pass];
    orig_row := @OriSamplerP^[pass];

    mag_row^[0] := 0;
    ort_row^[0] := cPI;

    if between(pass, 1, h - 1) then
      begin
        orig_plus := @OriSamplerP^[pass + 1];
        orig_minus := @OriSamplerP^[pass - 1];

        for X := 1 to w - 2 do
          begin
            dy := orig_plus^[X] - orig_minus^[X];
            dx := orig_row^[X + 1] - orig_row^[X - 1];
            mag_row^[X] := Hypot(dx, dy);
            ort_row^[X] := ArcTan2(dy, dx) + cPI;
          end;
      end
    else
      for X := 1 to w - 2 do
        begin
          mag_row^[X] := 0;
          ort_row^[X] := cPI;
        end;

    mag_row^[w - 1] := 0;
    ort_row^[w - 1] := cPI;
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor;
  var
    pass, X: TLInt;
    mag_row, ort_row, orig_row, orig_plus, orig_minus: PGaussVec;
    dy, dx: TGFloat;
  begin
    for pass := 0 to h - 1 do
      begin
        mag_row := @MagP^[pass];
        ort_row := @OrtP^[pass];
        orig_row := @OriSamplerP^[pass];

        mag_row^[0] := 0;
        ort_row^[0] := cPI;

        if between(pass, 1, h - 1) then
          begin
            orig_plus := @OriSamplerP^[pass + 1];
            orig_minus := @OriSamplerP^[pass - 1];

            for X := 1 to w - 2 do
              begin
                dy := orig_plus^[X] - orig_minus^[X];
                dx := orig_row^[X + 1] - orig_row^[X - 1];
                mag_row^[X] := Hypot(dx, dy);
                ort_row^[X] := ArcTan2(dy, dx) + cPI;
              end;
          end
        else
          for X := 1 to w - 2 do
            begin
              mag_row^[X] := 0;
              ort_row^[X] := cPI;
            end;

        mag_row^[w - 1] := 0;
        ort_row^[w - 1] := cPI;
      end;
  end;
{$ENDIF parallel}

begin
{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, h - 1);
{$ELSE FPC}
  TParallel.for(0, h - 1, procedure(pass: Integer)
    var
      X: TLInt;
      mag_row, ort_row, orig_row, orig_plus, orig_minus: PGaussVec;
      dy, dx: TGFloat;
    begin
      mag_row := @MagP^[pass];
      ort_row := @OrtP^[pass];
      orig_row := @OriSamplerP^[pass];

      mag_row^[0] := 0;
      ort_row^[0] := cPI;

      if between(pass, 1, h - 1) then
        begin
          orig_plus := @OriSamplerP^[pass + 1];
          orig_minus := @OriSamplerP^[pass - 1];

          for X := 1 to w - 2 do
            begin
              dy := orig_plus^[X] - orig_minus^[X];
              dx := orig_row^[X + 1] - orig_row^[X - 1];
              mag_row^[X] := Hypot(dx, dy);
              ort_row^[X] := ArcTan2(dy, dx) + cPI;
            end;
        end
      else
        for X := 1 to w - 2 do
          begin
            mag_row^[X] := 0;
            ort_row^[X] := cPI;
          end;

      mag_row^[w - 1] := 0;
      ort_row^[w - 1] := cPI;
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
end;

class procedure TPyramidLayer.ComputeDiff(const w, h: TLInt; const s1, s2, DiffOut: PGaussSpace);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(J: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  var
    i: TLInt;
  begin
    for i := 0 to w - 1 do
        DiffOut^[J, i] := Diff(s1^[J, i], s2^[J, i]);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor;
  var
    J, i: TLInt;
  begin
    for J := 0 to h - 1 do
      for i := 0 to w - 1 do
          DiffOut^[J, i] := Diff(s1^[J, i], s2^[J, i]);
  end;
{$ENDIF parallel}

begin
{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, h - 1);
{$ELSE FPC}
  TParallel.for(0, h - 1, procedure(J: Integer)
    var
      i: TLInt;
    begin
      for i := 0 to w - 1 do
          DiffOut^[J, i] := Diff(s1^[J, i], s2^[J, i]);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
end;

procedure TPyramidLayer.Build(var OriSampler: TGaussSpace; const factorWidth, factorHeight, NScale: TLInt; const GaussSigma: TGFloat);
var
  Sap: TGaussSpace;
  oriW, oriH: TLInt;
  i, J: TLInt;
  k: TGFloat;
begin
  oriW := length(OriSampler[0]);
  oriH := length(OriSampler);

  width := factorWidth;
  height := factorHeight;

  numScale := NScale;
  SetLength(SigmaIntegral, numScale, height, width);
  SetLength(MagIntegral, numScale - 1, height, width);
  SetLength(OrtIntegral, numScale - 1, height, width);
  SetLength(Diffs, numScale - 1, height, width);

  if (width <> oriW) or (height <> oriH) then
    begin
      SigmaSampler(OriSampler, Sap, GaussSigma);
      ZoomSampler(Sap, SigmaIntegral[0], width, height);
      SetLength(Sap, 0, 0);
    end
  else
      SigmaSampler(OriSampler, SigmaIntegral[0], GaussSigma);

  k := GaussSigma * GaussSigma;
  for i := 1 to numScale - 1 do
    begin
      SigmaSampler(SigmaIntegral[0], SigmaIntegral[i], k);
      TPyramidLayer.ComputeMagAndOrt(width, height, @SigmaIntegral[i], @MagIntegral[i - 1], @OrtIntegral[i - 1]);
      k := k * CSCALE_FACTOR;
    end;

  for i := 1 to numScale - 1 do
      TPyramidLayer.ComputeDiff(width, height, @SigmaIntegral[i - 1], @SigmaIntegral[i], @Diffs[i - 1]);
end;

procedure TPyramidLayer.Free;
begin
  SetLength(SigmaIntegral, 0, 0, 0);
  SetLength(MagIntegral, 0, 0, 0);
  SetLength(OrtIntegral, 0, 0, 0);
  SetLength(Diffs, 0, 0, 0);
end;

function TPyramids.isExtrema(const X, Y: TLInt; const pyr_id, scale_id: TLInt): Boolean;
var
  dog: PGaussSpace;
  center, cmp1, cmp2, newval: TGFloat;
  bMax, bMin: Boolean;
  di, dj, i: TLInt;
begin
  Result := False;

  dog := @Pyramids[pyr_id].Diffs[scale_id];
  center := dog^[Y, X];
  if (center < CGRAY_THRESHOLD) then
      Exit;
  bMax := True;
  bMin := True;
  cmp1 := center - CEXTREMA_DIFF_THRESHOLD;
  cmp2 := center + CEXTREMA_DIFF_THRESHOLD;
  // try same scale
  for di := -1 to 1 do
    for dj := -1 to 1 do
      begin
        if (di = 0) and (dj = 0) then
            Continue;
        newval := dog^[Y + di, X + dj];
        if (newval >= cmp1) then
            bMax := False;
        if (newval <= cmp2) then
            bMin := False;
        if (not bMax) and (not bMin) then
            Exit;
      end;

  if not between(scale_id, 1, length(Pyramids[pyr_id].Diffs) - 1) then
      Exit(False);

  // try adjacent scale top
  dog := @Pyramids[pyr_id].Diffs[scale_id - 1];
  for di := -1 to 1 do
    for i := 0 to 2 do
      begin
        newval := dog^[Y + di][X - 1 + i];
        if (newval >= cmp1) then
            bMax := False;
        if (newval <= cmp2) then
            bMin := False;
        if (not bMax) and (not bMin) then
            Exit;
      end;

  // try adjacent scale bottom
  dog := @Pyramids[pyr_id].Diffs[scale_id + 1];
  for di := -1 to 1 do
    for i := 0 to 2 do
      begin
        newval := dog^[Y + di][X - 1 + i];
        if (newval >= cmp1) then
            bMax := False;
        if (newval <= cmp2) then
            bMin := False;
        if (not bMax) and (not bMin) then
            Exit;
      end;

  Result := True;
end;

procedure TPyramids.BuildLocalExtrema(const pyr_id, scale_id: TLInt; const Transform: Boolean; v2List: TVec2List);
var
  w, h: TLInt;

  {$IFDEF parallel}
  {$IFDEF FPC}
    procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    var
      X: TLInt;
    begin
      for X := 1 to w - 2 do
        if isExtrema(X, pass, pyr_id, scale_id) then
          begin
            LockObject(v2List);

            if Transform then
                v2List.Add(fabs(X / w * FWidth), fabs(pass / h * FHeight))
            else
                v2List.Add(X, pass);

            UnLockObject(v2List);
          end;
    end;
  {$ENDIF FPC}
  {$ELSE parallel}
    procedure DoFor;
    var
      pass, X: TLInt;
    begin
      for pass := 1 to h - 2 do
        for X := 1 to w - 2 do
          if isExtrema(X, pass, pyr_id, scale_id) then
            begin
              if Transform then
                  v2List.Add(fabs(X / w * FWidth), fabs(pass / h * FHeight))
              else
                  v2List.Add(X, pass);
            end;
    end;
  {$ENDIF parallel}

begin
  w := Pyramids[pyr_id].width;
  h := Pyramids[pyr_id].height;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 1, h - 2);
{$ELSE FPC}
  TParallel.for(1, h - 2, procedure(pass: Integer)
    var
      X: TLInt;
    begin
      for X := 1 to w - 2 do
        if isExtrema(X, pass, pyr_id, scale_id) then
          begin
            LockObject(v2List);

            if Transform then
                v2List.Add(fabs(X / w * FWidth), fabs(pass / h * FHeight))
            else
                v2List.Add(X, pass);

            UnLockObject(v2List);
          end;
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
end;

procedure TPyramids.BuildLocalExtrema(const pyr_id, scale_id: TLInt; ExtremaCoorList: TCoreClassList);
var
  w, h: TLInt;

  {$IFDEF parallel}
  {$IFDEF FPC}
    procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    var
      X: TLInt;
      p: PExtremaCoor;
    begin
      for X := 1 to w - 2 do
        if isExtrema(X, pass, pyr_id, scale_id) then
          begin
            LockObject(ExtremaCoorList);

            new(p);
            p^.PyramidCoor := vec2(X / w, pass / h);
            p^.RealCoor := vec2(X, pass);
            p^.pyr_id := pyr_id;
            p^.scale_id := scale_id;
            ExtremaCoorList.Add(p);

            UnLockObject(ExtremaCoorList);
          end;
    end;
  {$ENDIF FPC}
  {$ELSE parallel}
    procedure DoFor;
    var
      pass, X: TLInt;
      p: PExtremaCoor;
    begin
      for pass := 1 to h - 2 do
        for X := 1 to w - 2 do
          if isExtrema(X, pass, pyr_id, scale_id) then
            begin
              new(p);
              p^.PyramidCoor := vec2(X / w, pass / h);
              p^.RealCoor := vec2(X, pass);
              p^.pyr_id := pyr_id;
              p^.scale_id := scale_id;
              ExtremaCoorList.Add(p);
            end;
    end;
  {$ENDIF parallel}

begin
  w := Pyramids[pyr_id].width;
  h := Pyramids[pyr_id].height;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 1, h - 2);
{$ELSE FPC}
  TParallel.for(1, h - 2, procedure(pass: Integer)
    var
      X: TLInt;
      p: PExtremaCoor;
    begin
      for X := 1 to w - 2 do
        if isExtrema(X, pass, pyr_id, scale_id) then
          begin
            LockObject(ExtremaCoorList);

            new(p);
            p^.PyramidCoor := vec2(X / w, pass / h);
            p^.RealCoor := vec2(X, pass);
            p^.pyr_id := pyr_id;
            p^.scale_id := scale_id;
            ExtremaCoorList.Add(p);

            UnLockObject(ExtremaCoorList);
          end;
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
end;

// key-pointer integral
function TPyramids.KPIntegral(const dogIntegral: PGaussSpaceIntegral; const X, Y, s: TLInt; var Offset, Delta: TLVec): Boolean;
var
  v, dxx, dyy, dss, DXY, dys, DSX: TLFloat;
  M: TLMatrix;
  Info: TLInt;
  mRep: TMatInvReport;
begin
  // hessian matrix 3x3
  v := dogIntegral^[s, Y, X];
  Delta[0] := (dogIntegral^[s, Y, X + 1] - dogIntegral^[s, Y, X - 1]) * 0.5;
  Delta[1] := (dogIntegral^[s, Y + 1, X] - dogIntegral^[s, Y - 1, X]) * 0.5;
  Delta[2] := (dogIntegral^[s + 1, Y, X] - dogIntegral^[s - 1, Y, X]) * 0.5;

  dxx := dogIntegral^[s, Y, X + 1] + dogIntegral^[s, Y, X - 1] - v - v;
  dyy := dogIntegral^[s, Y + 1, X] + dogIntegral^[s, Y - 1, X] - v - v;
  dss := dogIntegral^[s + 1, Y, X] + dogIntegral^[s - 1, Y, X] - v - v;

  DXY := (dogIntegral^[s, Y + 1, X + 1] - dogIntegral^[s, Y - 1, X + 1] - dogIntegral^[s, Y + 1, X - 1] + dogIntegral^[s, Y - 1, X - 1]) * 0.25;
  dys := (dogIntegral^[s + 1, Y + 1, X] - dogIntegral^[s + 1, Y - 1, X] - dogIntegral^[s - 1, Y + 1, X] + dogIntegral^[s - 1, Y - 1, X]) * 0.25;
  DSX := (dogIntegral^[s + 1, Y, X + 1] - dogIntegral^[s + 1, Y, X - 1] - dogIntegral^[s - 1, Y, X + 1] + dogIntegral^[s - 1, Y, X - 1]) * 0.25;

  SetLength(M, 3, 3);
  M[0, 0] := dxx;
  M[1, 1] := dyy;
  M[2, 2] := dss;

  M[0, 1] := DXY;
  M[1, 0] := DXY;

  M[0, 2] := DSX;
  M[2, 0] := DSX;

  M[1, 2] := dys;
  M[2, 1] := dys;

  // Inversion of a matrix given by its LU decomposition and Inverse
  Learn.RMatrixInverse(M, 3, Info, mRep);

  // detect a svd matrix
  Result := Info = 1;
  if Result then
      Learn.MatrixVectorMultiply(M, 0, 2, 0, 2, False, Delta, 0, 2, 1, Offset, 0, 2, 0);

  SetLength(M, 0, 0);
end;

function TPyramids.ComputeKeyPoint(const ExtremaCoor: TVec2; const pyr_id, scale_id: TLInt; var output: TPyramidCoor): Boolean;
var
  dog: PGaussSpace;
  w, h, NScale, i: TLInt;
  nowx, nowy, nows: TLInt;
  dpDone: Boolean;
  Offset, Delta: TLVec;
begin
  Result := False;

  dog := @Pyramids[pyr_id].Diffs[scale_id];
  w := Pyramids[pyr_id].width;
  h := Pyramids[pyr_id].height;
  NScale := Pyramids[pyr_id].numScale;

  nowx := Round(ExtremaCoor[0]);
  nowy := Round(ExtremaCoor[1]);
  nows := scale_id;

  Offset := lvec(3);
  Delta := lvec(3);
  dpDone := False;
  for i := 1 to COFFSET_DEPTH do
    begin
      if (not between(nowx, 1, w - 1)) or (not between(nowy, 1, h - 1)) or (not between(nows, 1, NScale - 2)) then
          Exit;
      if not KPIntegral(@Pyramids[pyr_id].Diffs, nowx, nowy, nows, Offset, Delta) then
          Exit;

      dpDone := Learn.LAbsMaxVec(Offset) < COFFSET_THRESHOLD;
      // found
      if dpDone then
          Break;

      Inc(nowx, Round(Offset[0]));
      Inc(nowy, Round(Offset[1]));
      Inc(nows, Round(Offset[2]));
    end;
  if not dpDone then
      Exit;

  if dog^[nowy, nowx] + Learn.APVDotProduct(@Offset, 0, 2, @Delta, 0, 2) * 0.5 < CCONTRAST_THRESHOLD then
      Exit;

  // update coordinate
  output.Init;
  output.PyramidCoor[0] := nowx;
  output.PyramidCoor[1] := nowy;
  output.Scale := CSIGMA_FACTOR * Power(CSCALE_FACTOR, (nows + Offset[2]) / (NScale - 1));
  output.RealCoor[0] := (nowx + Offset[0]) / w;
  output.RealCoor[1] := (nowy + Offset[1]) / h;
  output.pyr_id := pyr_id;
  output.scale_id := nows;
  output.Owner := Self;
  Result := True;
end;

function TPyramids.ComputeEndgeReponse(const ExtremaCoor: TVec2; const p: PGaussSpace): Boolean;
var
  dxx, DXY, dyy, v, det: TLFloat;
  X, Y: TLInt;
begin
  X := Round(ExtremaCoor[0]);
  Y := Round(ExtremaCoor[1]);

  // hessian matrix
  v := p^[Y, X];

  dxx := p^[Y, X + 1] + p^[Y, X - 1] - v - v;
  dyy := p^[Y + 1, X] + p^[Y - 1, X] - v - v;
  DXY := (p^[Y + 1, X + 1] + p^[Y - 1, X - 1] - p^[Y + 1, X - 1] - p^[Y - 1, X + 1]) / 4;

  det := (dxx * dyy) - (DXY * DXY);

  if det <= 0 then
      Exit(True);

  // compute principal curvature by hessian
  Result := ((Learn.AP_Sqr(dxx + dyy) / det) > Learn.AP_Sqr(CEDGE_RATIO + 1) / CEDGE_RATIO);
end;

function TPyramids.ComputePyramidCoor(const FilterEndge, FilterOri: Boolean; const ExtremaV2: TVec2; const pyr_id, scale_id: TLInt): TPyramidCoorList;
var
  RetCoords: TPyramidCoorList;

  procedure ComputeOrientation(const PC: TPyramidCoor);
  const
    ORI_WINDOW_FACTOR                  = 1.5;
    Orientation_Histogram_Binomial_Num = 36;
    Orientation_Histogram_Peak_Ratio   = 0.8;
    CHalfPI                            = 0.5 / pi;
  var
    Pyramid: PPyramidLayer;
    mag: PGaussSpace;
    ort: PGaussSpace;
    X, Y: TLInt;
    gauss_weight_sigma, exp_denom, orient, Weight, Prev, Next, fBinomial, thres: TLFloat;
    Rad, xx, yy, newx, newy, iBinomial, k, i: TLInt;
    hist: TLVec;
    np: PPyramidCoor;
  begin
    Pyramid := @Pyramids[PC.pyr_id];
    mag := @Pyramid^.MagIntegral[PC.scale_id - 1];
    ort := @Pyramid^.OrtIntegral[PC.scale_id - 1];

    X := Round(PC.PyramidCoor[0]);
    Y := Round(PC.PyramidCoor[1]);

    gauss_weight_sigma := PC.Scale * ORI_WINDOW_FACTOR;
    exp_denom := 2 * Learn.AP_Sqr(gauss_weight_sigma);
    Rad := Round(PC.Scale * CORIENTATION_RADIUS);

    hist := lvec(Orientation_Histogram_Binomial_Num);

    // compute gaussian weighted histogram with inside a circle
    for xx := -Rad to Rad do
      begin
        newx := X + xx;
        if not between(newx, 1, Pyramid^.width - 1) then
            Continue;

        for yy := -Rad to Rad do
          begin
            newy := Y + yy;
            if not between(newy, 1, Pyramid^.height - 1) then
                Continue;
            // use a circular gaussian window
            if Learn.AP_Sqr(xx) + Learn.AP_Sqr(yy) > Learn.AP_Sqr(Rad) then
                Continue;
            orient := ort^[newy, newx];
            iBinomial := Round(Orientation_Histogram_Binomial_Num * CHalfPI * orient);
            if (iBinomial = Orientation_Histogram_Binomial_Num) then
                iBinomial := 0;
            // overflow detect
            if (iBinomial > Orientation_Histogram_Binomial_Num) then
                Exit;
            Weight := Exp(-(Learn.AP_Sqr(xx) + Learn.AP_Sqr(yy)) / exp_denom);
            LAdd(hist[iBinomial], Weight * mag^[newy, newx]);
          end;
      end;

    // smooth the histogram
    for k := CORIENTATION_SMOOTH_COUNT - 1 downto 0 do
      for i := 0 to Orientation_Histogram_Binomial_Num - 1 do
        begin
          Prev := hist[IfThen(i = 0, Orientation_Histogram_Binomial_Num - 1, i - 1)];
          Next := hist[IfThen(i = Orientation_Histogram_Binomial_Num - 1, 0, i + 1)];
          LMul(hist[i], 0.5);
          LAdd(hist[i], (Prev + Next) * 0.25);
        end;

    thres := LMaxVec(hist) * Orientation_Histogram_Peak_Ratio;

    // choose extreme orientation
    for i := 0 to Orientation_Histogram_Binomial_Num - 1 do
      begin
        Prev := hist[IfThen(i = 0, Orientation_Histogram_Binomial_Num - 1, i - 1)];
        Next := hist[IfThen(i = Orientation_Histogram_Binomial_Num - 1, 0, i + 1)];

        if (hist[i] > thres) and (hist[i] > Max(Prev, Next)) then
          begin
            // interpolation
            fBinomial := i - 0.5 + (hist[i] - Prev) / (Prev + Next - 2 * hist[i]);

            if (fBinomial < 0) then
                LAdd(fBinomial, Orientation_Histogram_Binomial_Num)
            else if (fBinomial >= Orientation_Histogram_Binomial_Num) then
                LSub(fBinomial, Orientation_Histogram_Binomial_Num);

            if RetCoords = nil then
                RetCoords := TPyramidCoorList.Create;

            new(np);
            np^ := PC;
            np^.Orientation := fBinomial / Orientation_Histogram_Binomial_Num * 2 * cPI;
            np^.OriFinish := True;
            RetCoords.Add(np);
          end;
      end;

    SetLength(hist, 0);
  end;

var
  T: TPyramidCoor;
begin
  Result := nil;
  RetCoords := nil;

  if not ComputeKeyPoint(ExtremaV2, pyr_id, scale_id, T) then
      Exit;

  if FilterEndge then
    if not ComputeEndgeReponse(T.PyramidCoor, @Pyramids[T.pyr_id].Diffs[T.scale_id]) then
        Exit;

  ComputeOrientation(T);

  if (RetCoords = nil) and (not FilterOri) then
    begin
      RetCoords := TPyramidCoorList.Create;
      RetCoords.Add(T);
    end;

  Result := RetCoords;
end;

constructor TPyramids.CreateWithRaster(const raster: TMemoryRaster);
var
  F: TGFloat;
  w, h: TLInt;
begin
  inherited Create;

  FViewer := NewRaster();
  FViewer.Assign(raster);

  w := FViewer.width;
  h := FViewer.height;

  if (w > CMAX_SAMPLER_WIDTH) then
    begin
      F := CMAX_SAMPLER_WIDTH / w;
      w := Round(w * F);
      h := Round(h * F);
    end;
  if (h > CMAX_SAMPLER_HEIGHT) then
    begin
      F := CMAX_SAMPLER_HEIGHT / h;
      w := Round(w * F);
      h := Round(h * F);
    end;

  if (w <> FViewer.width) and (h <> FViewer.height) then
      FViewer.Zoom(w, h);

  // gray sampler
  if (CMAX_GRAY_COLOR_SAMPLER <= 0) or (CMAX_GRAY_COLOR_SAMPLER >= 255) then
      Sampler(FViewer, GaussTransformSpace)
  else
      Sampler(FViewer,
      CRED_WEIGHT_SAMPLER, CGREEN_WEIGHT_SAMPLER, CBLUE_WEIGHT_SAMPLER,
      CMAX_GRAY_COLOR_SAMPLER, GaussTransformSpace);

  FWidth := FViewer.width;
  FHeight := FViewer.height;

  SetLength(SamplerXY, FHeight * FWidth);
  FillPtrByte(@SamplerXY[0], FHeight * FWidth, 1);
  SetLength(Pyramids, 0);
end;

constructor TPyramids.CreateWithRaster(const fn: string);
var
  raster: TMemoryRaster;
begin
  raster := NewRasterFromFile(fn);
  CreateWithRaster(raster);
  DisposeObject(raster);
end;

constructor TPyramids.CreateWithRaster(const stream: TCoreClassStream);
var
  raster: TMemoryRaster;
begin
  raster := NewRasterFromStream(stream);
  CreateWithRaster(raster);
  DisposeObject(raster);
end;

constructor TPyramids.CreateWithGauss(const spr: PGaussSpace);
var
  F: TGFloat;
  w, h: TLInt;
begin
  inherited Create;

  FViewer := NewRaster();

  w := length(spr^[0]);
  h := length(spr^);

  if (w > CMAX_SAMPLER_WIDTH) then
    begin
      F := CMAX_SAMPLER_WIDTH / w;
      w := Round(w * F);
      h := Round(h * F);
    end;
  if (h > CMAX_SAMPLER_HEIGHT) then
    begin
      F := CMAX_SAMPLER_HEIGHT / h;
      w := Round(w * F);
      h := Round(h * F);
    end;

  if (w <> length(spr^[0])) and (h <> length(spr^)) then
      ZoomSampler(spr^, GaussTransformSpace, w, h)
  else
      CopySampler(spr^, GaussTransformSpace);

  // gray sampler
  Sampler(GaussTransformSpace, FViewer);

  FWidth := w;
  FHeight := h;

  SetLength(SamplerXY, FHeight * FWidth);
  FillPtrByte(@SamplerXY[0], FHeight * FWidth, 1);
  SetLength(Pyramids, 0);
end;

destructor TPyramids.Destroy;
var
  i: TLInt;
begin
  if length(Pyramids) > 0 then
    begin
      for i := low(Pyramids) to high(Pyramids) do
          Pyramids[i].Free;
      SetLength(Pyramids, 0);
    end;
  SetLength(SamplerXY, 0);
  DisposeObject(FViewer);
  inherited Destroy;
end;

procedure TPyramids.SetRegion(const Clip: TVec2List);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  var
    i: TLInt;
  begin
    for i := 0 to FWidth - 1 do
        SamplerXY[i + pass * FWidth] := IfThen(Clip.PointInHere(vec2(i, pass)), 1, 0);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor;
  var
    pass, i: TLInt;
  begin
    for pass := 0 to FHeight - 1 do
      for i := 0 to FWidth - 1 do
          SamplerXY[i + pass * FWidth] := IfThen(Clip.PointInHere(vec2(i, pass)), 1, 0);
  end;
{$ENDIF parallel}

begin
  if Clip.Count > 0 then
    begin
{$IFDEF parallel}
{$IFDEF FPC}
      ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, FHeight - 1);
{$ELSE FPC}
      TParallel.for(0, FHeight - 1, procedure(pass: Integer)
        var
          i: TLInt;
        begin
          for i := 0 to FWidth - 1 do
              SamplerXY[i + pass * FWidth] := IfThen(Clip.PointInHere(vec2(i, pass)), 1, 0);
        end);
{$ENDIF FPC}
{$ELSE parallel}
      DoFor;
{$ENDIF parallel}
    end;
end;

procedure TPyramids.SetRegion(var mat: TLBMatrix);
var
  nmat: TLBMatrix;
  J, i: TLInt;
begin
  if (length(nmat) = length(mat)) and (length(nmat[0]) = length(mat[0])) then
      nmat := LMatrixCopy(mat)
  else
      LZoomMatrix(mat, nmat, FWidth, FHeight);

  for J := 0 to FHeight - 1 do
    for i := 0 to FWidth - 1 do
      if nmat[J, i] then
          SamplerXY[i + J * FWidth] := 1
      else
          SamplerXY[i + J * FWidth] := 0;

  SetLength(nmat, 0, 0);
end;

procedure TPyramids.BuildPyramid;
var
  i: TLInt;
  factor: TGFloat;
begin
  if length(Pyramids) > 0 then
    begin
      for i := low(Pyramids) to high(Pyramids) do
          Pyramids[i].Free;
      SetLength(Pyramids, 0);
    end;

  SetLength(Pyramids, CNUMBER_OCTAVE);

  Pyramids[0].Build(GaussTransformSpace, FWidth, FHeight, CNUMBER_SCALE, CSIGMA_FACTOR);
  for i := 1 to CNUMBER_OCTAVE - 1 do
    begin
      factor := Power(CSCALE_FACTOR, -i);

      Pyramids[i].Build(
        GaussTransformSpace,
        Ceil(FWidth * factor),
        Ceil(FHeight * factor),
        CNUMBER_SCALE, CSIGMA_FACTOR);
    end;
end;

function TPyramids.BuildAbsoluteExtrema: TVec2List;
var
  i, J: TLInt;
  v: TVec2;
  X, Y: TLInt;
begin
  if length(Pyramids) = 0 then
      BuildPyramid;
  Result := TVec2List.Create;
  for i := 0 to CNUMBER_OCTAVE - 1 do
    for J := 0 to CNUMBER_SCALE - 2 do
        BuildLocalExtrema(i, J, True, Result);

  i := 0;
  while i < Result.Count do
    begin
      v := Result[i]^;
      X := Round(v[0]);
      Y := Round(v[1]);
      J := X + Y * FWidth;
      if between(J, 0, length(SamplerXY)) and (SamplerXY[J] = 0) then
          Result.Delete(i)
      else
          Inc(i);
    end;
end;

function TPyramids.BuildPyramidExtrema(const FilterOri: Boolean): TPyramidCoorList;
var
  ExtremaList: TCoreClassList;
  PyramidCoordOutput: TPyramidCoorList;

  {$IFDEF parallel}
  {$IFDEF FPC}
    procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
    var
      EP: PExtremaCoor;
      p: TPyramidCoorList;
    begin
      EP := PExtremaCoor(ExtremaList[pass]);
      p := ComputePyramidCoor(ExtremaList.Count > CFILTER_MAX_KEYPOINT_ENDGE, FilterOri, EP^.RealCoor, EP^.pyr_id, EP^.scale_id);
      if p <> nil then
        begin
          LockObject(PyramidCoordOutput);
          PyramidCoordOutput.Add(p, False);
          UnLockObject(PyramidCoordOutput);
          DisposeObject(p);
        end;
    end;
  {$ENDIF FPC}
  {$ELSE parallel}
    procedure DoFor;
    var
      pass: TLInt;
      EP: PExtremaCoor;
      p: TPyramidCoorList;
    begin
      for pass := 0 to ExtremaList.Count - 1 do
        begin
          EP := PExtremaCoor(ExtremaList[pass]);
          p := ComputePyramidCoor(ExtremaList.Count > CFILTER_MAX_KEYPOINT_ENDGE, FilterOri, EP^.RealCoor, EP^.pyr_id, EP^.scale_id);
          if p <> nil then
            begin
              PyramidCoordOutput.Add(p, False);
              DisposeObject(p);
            end;
        end;
    end;
  {$ENDIF parallel}

var
  J, i: TLInt;
  X, Y: TLInt;
begin
  if length(Pyramids) = 0 then
      BuildPyramid;

  PyramidCoordOutput := TPyramidCoorList.Create;

  ExtremaList := TCoreClassList.Create;
  for J := 0 to CNUMBER_OCTAVE - 1 do
    for i := 0 to CNUMBER_SCALE - 2 do
        BuildLocalExtrema(J, i, ExtremaList);

  i := 0;
  while i < ExtremaList.Count do
    begin
      with PExtremaCoor(ExtremaList[i])^ do
        begin
          X := Round(RealCoor[0] * FWidth);
          Y := Round(RealCoor[1] * FHeight);
        end;
      J := X + Y * FWidth;
      if between(J, 0, length(SamplerXY)) and (SamplerXY[J] = 0) then
          ExtremaList.Delete(i)
      else
          Inc(i);
    end;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, ExtremaList.Count - 1);
{$ELSE FPC}
  TParallel.for(0, ExtremaList.Count - 1, procedure(pass: Integer)
    var
      EP: PExtremaCoor;
      p: TPyramidCoorList;
    begin
      EP := PExtremaCoor(ExtremaList[pass]);
      p := ComputePyramidCoor(ExtremaList.Count > CFILTER_MAX_KEYPOINT_ENDGE, FilterOri, EP^.RealCoor, EP^.pyr_id, EP^.scale_id);
      if p <> nil then
        begin
          LockObject(PyramidCoordOutput);
          PyramidCoordOutput.Add(p, False);
          UnLockObject(PyramidCoordOutput);
          DisposeObject(p);
        end;
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
  for i := 0 to ExtremaList.Count - 1 do
      Dispose(PExtremaCoor(ExtremaList[i]));

  DisposeObject(ExtremaList);

  i := 0;
  while i < PyramidCoordOutput.Count do
    begin
      with PyramidCoordOutput[i]^ do
        begin
          X := Round(RealCoor[0] * FWidth);
          Y := Round(RealCoor[1] * FHeight);
        end;
      J := X + Y * FWidth;
      if between(J, 0, length(SamplerXY)) and (SamplerXY[J] = 0) then
          PyramidCoordOutput.Delete(i)
      else
          Inc(i);
    end;

  Result := PyramidCoordOutput;
end;

function TPyramids.BuildViewer(const v2List: TVec2List; const radius: TGFloat; const COLOR: TRasterColor): TMemoryRaster;
var
  i: TLInt;
  L: TGFloat;
begin
  if length(Pyramids) = 0 then
      BuildPyramid;
  Result := NewRaster();
  Result.Assign(FViewer);
  L := radius * 2;

  for i := 0 to v2List.Count - 1 do
      Result.DrawCrossF(v2List[i]^, L, COLOR);
end;

function TPyramids.BuildViewer(const cList: TPyramidCoorList; const radius: TGFloat; const COLOR: TRasterColor): TMemoryRaster;
var
  i: TLInt;
  L: TLInt;
  invColor: TRasterColor;
  p: PPyramidCoor;
  v1, v2: TVec2;
begin
  if length(Pyramids) = 0 then
      BuildPyramid;
  Result := NewRaster();
  Result.Assign(FViewer);
  L := Round(radius * 2);

  invColor := RasterColorInv(COLOR);

  for i := 0 to cList.Count - 1 do
    begin
      p := cList[i];
      v2[0] := p^.RealCoor[0] * FWidth;
      v2[1] := p^.RealCoor[1] * FHeight;
      Result.FillRect(v2, Max(L div 2, 3), COLOR);

      if p^.OriFinish then
        begin
          v1[0] := v2[0] + (radius) * p^.Scale * Cos(p^.Orientation);
          v1[1] := v2[1] + (radius) * p^.Scale * Sin(p^.Orientation);
          Result.LineF(v2, v1, invColor, False);
        end;
    end;
end;

class procedure TPyramids.BuildToViewer(const cList: TPyramidCoorList; const radius: TGFloat; const COLOR: TRasterColor; const RasterViewer: TMemoryRaster);
var
  i: TLInt;
  L: TLInt;
  invColor: TRasterColor;
  p: PPyramidCoor;
  v1, v2: TVec2;
begin
  L := Round(radius * 2);

  invColor := RasterColorInv(COLOR);

  for i := 0 to cList.Count - 1 do
    begin
      p := cList[i];
      v2[0] := p^.RealCoor[0] * RasterViewer.width;
      v2[1] := p^.RealCoor[1] * RasterViewer.height;
      RasterViewer.FillRect(v2, Max(L div 2, 3), COLOR);

      if p^.OriFinish then
        begin
          v1[0] := v2[0] + (radius) * p^.Scale * Cos(p^.Orientation);
          v1[1] := v2[1] + (radius) * p^.Scale * Sin(p^.Orientation);
          RasterViewer.LineF(v2, v1, invColor, False);
        end;
    end;
end;

class procedure TPyramids.BuildToViewer(const cList: TPyramidCoorList; const radius: TGFloat; const RasterViewer: TMemoryRaster);
var
  i: TLInt;
  L: TLInt;
  COLOR, invColor: TRasterColor;
  p: PPyramidCoor;
  v1, v2: TVec2;
begin
  L := Round(radius * 2);

  for i := 0 to cList.Count - 1 do
    begin
      COLOR := RasterColor(Random(255), Random(255), Random(255), 255);
      invColor := RasterColorInv(COLOR);

      p := cList[i];
      v2[0] := p^.RealCoor[0] * RasterViewer.width;
      v2[1] := p^.RealCoor[1] * RasterViewer.height;
      RasterViewer.FillRect(v2, Max(L div 2, 3), COLOR);

      if p^.OriFinish then
        begin
          v1[0] := v2[0] + (radius) * p^.Scale * Cos(p^.Orientation);
          v1[1] := v2[1] + (radius) * p^.Scale * Sin(p^.Orientation);
          RasterViewer.LineF(v2, v1, invColor, False);
        end;
    end;
end;

procedure TFeature.ComputeDescriptor(const p: PPyramidCoor; var Desc: TLVec);

  procedure Compute_Interpolate(const ybin, xbin, hbin, Weight: TLFloat; var hist: TLMatrix); {$IFDEF INLINE_ASM} inline; {$ENDIF}
  var
    ybinf, xbinf, hbinf: TLInt;
    ybind, xbind, hbind, w_y, w_x: TLFloat;
    dy, dx, bin_2d_idx: TLInt;
  begin
    ybinf := Floor(ybin);
    xbinf := Floor(xbin);
    hbinf := Floor(hbin);
    ybind := ybin - ybinf;
    xbind := xbin - xbinf;
    hbind := hbin - hbinf;

    for dy := 0 to 1 do
      if between(ybinf + dy, 0, CDESC_HIST_WIDTH) then
        begin
          w_y := Weight * (IfThen(dy <> 0, ybind, 1 - ybind));
          for dx := 0 to 1 do
            if between(xbinf + dx, 0, CDESC_HIST_WIDTH) then
              begin
                w_x := w_y * (IfThen(dx <> 0, xbind, 1 - xbind));
                bin_2d_idx := (ybinf + dy) * CDESC_HIST_WIDTH + (xbinf + dx);
                LAdd(hist[bin_2d_idx, hbinf mod CDESC_HIST_BIN_NUM], w_x * (1 - hbind));
                LAdd(hist[bin_2d_idx, (hbinf + 1) mod CDESC_HIST_BIN_NUM], w_x * hbind);
              end;
        end;
  end;

var
  mag: PGaussSpace;
  ort: PGaussSpace;
  w, h, coorX, coorY: TLInt;
  Orientation, hist_w, exp_denom, y_rot, x_rot, cosort, sinort, ybin, xbin, now_mag, now_ort, Weight, hist_bin: TLFloat;
  radius, i, J, xx, yy, nowx, nowy: TLInt;
  hist: TLMatrix;
  Sum: TLFloat;
begin
  mag := @(p^.Owner.Pyramids[p^.pyr_id].MagIntegral[p^.scale_id - 1]);
  ort := @(p^.Owner.Pyramids[p^.pyr_id].OrtIntegral[p^.scale_id - 1]);

  w := p^.Owner.Pyramids[p^.pyr_id].width;
  h := p^.Owner.Pyramids[p^.pyr_id].height;
  coorX := Trunc(p^.PyramidCoor[0]);
  coorY := Trunc(p^.PyramidCoor[1]);
  Orientation := p^.Orientation;
  hist_w := p^.Scale * CDESC_SCALE_FACTOR;
  exp_denom := 2 * Learn.AP_Sqr(CDESC_HIST_WIDTH);
  radius := Round(CSQRT1_2 * hist_w * (CDESC_HIST_WIDTH + 1));
  hist := LMatrix(CDESC_HIST_WIDTH * CDESC_HIST_WIDTH, CDESC_HIST_BIN_NUM);
  cosort := Cos(Orientation);
  sinort := Sin(Orientation);

  for xx := -radius to radius do
    begin
      nowx := coorX + xx;
      if not between(nowx, 1, w - 1) then
          Continue;
      for yy := -radius to radius do
        begin
          nowy := coorY + yy;

          if not between(nowy, 1, h - 1) then
              Continue;

          // to be circle
          if (xx * xx + yy * yy) > (radius * radius) then
              Continue;

          // coordinate change, relative to major orientation
          // major orientation become (x, 0)
          y_rot := (-xx * sinort + yy * cosort) / hist_w;
          x_rot := (xx * cosort + yy * sinort) / hist_w;

          // calculate 2d bin idx (which bin do I fall into)
          // -0.5 to make the center of bin 1st (x=1.5) falls fully into bin 1st
          ybin := y_rot + CDESC_HIST_WIDTH / 2 - 0.5;
          xbin := x_rot + CDESC_HIST_WIDTH / 2 - 0.5;

          if (not between(ybin, -1, CDESC_HIST_WIDTH)) or (not between(xbin, -1, CDESC_HIST_WIDTH)) then
              Continue;

          now_mag := mag^[nowy, nowx];
          now_ort := ort^[nowy, nowx];

          // gaussian & magnitude weight on histogram
          Weight := Exp(-(Learn.AP_Sqr(x_rot) + Learn.AP_Sqr(y_rot)) / exp_denom) * now_mag;

          LSub(now_ort, Orientation); // for rotation invariance

          if (now_ort < 0) then
              LAdd(now_ort, CPI2);
          if (now_ort > CPI2) then
              LSub(now_ort, CPI2);

          hist_bin := now_ort * CNUM_BIN_PER_RAD;

          // all three bin idx are float, do Compute_Interpolate
          Compute_Interpolate(xbin, ybin, hist_bin, Weight, hist);
        end;
    end;

  Desc := lvec(hist);
  SetLength(hist, 0, 0);

  if CDESC_PROCESS_LIGHT then
    begin
      Sum := 0;
      for i := 0 to length(Desc) - 1 do
          LAdd(Sum, Desc[i]);
      for i := 0 to length(Desc) - 1 do
          Desc[i] := Learn.AP_Sqr(Desc[i] / Sum);
    end;
end;

procedure TFeature.BuildFeature(Pyramids: TPyramids);

{$IFDEF parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  begin
    ComputeDescriptor(FPyramidCoordList[pass], FDescriptorBuff[pass].descriptor);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor;
  var
    pass: TLInt;
  begin
    for pass := 0 to FPyramidCoordList.Count - 1 do
        ComputeDescriptor(FPyramidCoordList[pass], FDescriptorBuff[pass].descriptor);
  end;
{$ENDIF parallel}


var
  i, J: TLInt;
  p: PDescriptor;
begin
  if FPyramidCoordList <> nil then
    begin
      DisposeObject(FPyramidCoordList);
      FPyramidCoordList := nil;
    end;
  if length(Pyramids.Pyramids) = 0 then
      Pyramids.BuildPyramid;

  FPyramidCoordList := Pyramids.BuildPyramidExtrema(True);

  SetLength(FDescriptorBuff, FPyramidCoordList.Count);

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, FPyramidCoordList.Count - 1);
{$ELSE FPC}
  TParallel.for(0, FPyramidCoordList.Count - 1, procedure(pass: Integer)
    begin
      ComputeDescriptor(FPyramidCoordList[pass], FDescriptorBuff[pass].descriptor);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
  for i := 0 to length(FDescriptorBuff) - 1 do
    begin
      FDescriptorBuff[i].coor := FPyramidCoordList[i]^.RealCoor;
      FDescriptorBuff[i].AbsCoor[0] := FPyramidCoordList[i]^.RealCoor[0] * Pyramids.FWidth;
      FDescriptorBuff[i].AbsCoor[1] := FPyramidCoordList[i]^.RealCoor[1] * Pyramids.FHeight;
      FDescriptorBuff[i].Orientation := FPyramidCoordList[i]^.Orientation;
      FDescriptorBuff[i].index := i;
      FDescriptorBuff[i].Owner := Self;
    end;

  FWidth := Pyramids.FWidth;
  FHeight := Pyramids.FHeight;
  SetLength(FViewer, FHeight * FWidth);
  for J := 0 to FHeight - 1 do
    for i := 0 to FWidth - 1 do
      begin
        FViewer[i + J * FWidth] := Pyramids.FViewer.PixelGray[i, J];
        // FViewer[i + j * FWidth] := Round(Clamp(Pyramids.GaussTransformSpace[j, i], 0, 1) * 255);
      end;
end;

constructor TFeature.CreateWithPyramids(Pyramids: TPyramids);
begin
  inherited Create;
  FWidth := 0;
  FHeight := 0;
  SetLength(FViewer, 0);
  FInternalVec := ZeroVec2;
  FUserData := nil;
  FPyramidCoordList := nil;
  BuildFeature(Pyramids);
end;

constructor TFeature.CreateWithRaster(const raster: TMemoryRaster; const Clip: TVec2List);
var
  Pyramids: TPyramids;
begin
  Pyramids := TPyramids.CreateWithRaster(raster);
  Pyramids.SetRegion(Clip);
  CreateWithPyramids(Pyramids);
  DisposeObject(Pyramids);
end;

constructor TFeature.CreateWithRaster(const raster: TMemoryRaster; var mat: TLBMatrix);
var
  Pyramids: TPyramids;
begin
  Pyramids := TPyramids.CreateWithRaster(raster);
  Pyramids.SetRegion(mat);
  CreateWithPyramids(Pyramids);
  DisposeObject(Pyramids);
end;

constructor TFeature.CreateWithRaster(const raster: TMemoryRaster);
var
  Pyramids: TPyramids;
begin
  Pyramids := TPyramids.CreateWithRaster(raster);
  CreateWithPyramids(Pyramids);
  DisposeObject(Pyramids);
end;

constructor TFeature.CreateWithRaster(const fn: string);
var
  Pyramids: TPyramids;
begin
  Pyramids := TPyramids.CreateWithRaster(fn);
  CreateWithPyramids(Pyramids);
  DisposeObject(Pyramids);
end;

constructor TFeature.CreateWithRaster(const stream: TCoreClassStream);
var
  Pyramids: TPyramids;
begin
  Pyramids := TPyramids.CreateWithRaster(stream);
  CreateWithPyramids(Pyramids);
  DisposeObject(Pyramids);
end;

constructor TFeature.CreateWithSampler(const spr: PGaussSpace);
var
  Pyramids: TPyramids;
begin
  Pyramids := TPyramids.CreateWithGauss(spr);
  CreateWithPyramids(Pyramids);
  DisposeObject(Pyramids);
end;

constructor TFeature.Create;
begin
  inherited Create;
  FWidth := 0;
  FHeight := 0;
  SetLength(FViewer, 0);
  FInternalVec := ZeroVec2;
  FUserData := nil;
  FPyramidCoordList := nil;
  SetLength(FDescriptorBuff, 0);
end;

destructor TFeature.Destroy;
begin
  SetLength(FDescriptorBuff, 0);
  if FPyramidCoordList <> nil then
      DisposeObject(FPyramidCoordList);
  SetLength(FViewer, 0);
  inherited Destroy;
end;

function TFeature.Count: TLInt;
begin
  Result := length(FDescriptorBuff);
end;

function TFeature.GetFD(const index: TLInt): PDescriptor;
begin
  Result := @FDescriptorBuff[index];
end;

procedure TFeature.SaveToStream(stream: TCoreClassStream);
var
  i, L: Integer;
  p: PDescriptor;
begin
  L := Count;
  stream.write(L, 4);

  for i := 0 to L - 1 do
    begin
      p := @FDescriptorBuff[i];
      stream.write(p^.descriptor[0], DESCRIPTOR_LENGTH * SizeOf(TLFloat));
      stream.write(p^.coor[0], SizeOf(TVec2));
      stream.write(p^.AbsCoor[0], SizeOf(TVec2));
      stream.write(p^.Orientation, SizeOf(TGFloat));
    end;

  stream.write(FWidth, 4);
  stream.write(FHeight, 4);
  stream.write(FViewer[0], FHeight * FWidth);
end;

procedure TFeature.LoadFromStream(stream: TCoreClassStream);
var
  i, L: Integer;
begin
  stream.read(L, 4);
  SetLength(FDescriptorBuff, L);

  for i := 0 to L - 1 do
    begin
      SetLength(FDescriptorBuff[i].descriptor, DESCRIPTOR_LENGTH);
      stream.read(FDescriptorBuff[i].descriptor[0], DESCRIPTOR_LENGTH * SizeOf(TLFloat));
      stream.read(FDescriptorBuff[i].coor[0], SizeOf(TVec2));
      stream.read(FDescriptorBuff[i].AbsCoor[0], SizeOf(TVec2));
      stream.read(FDescriptorBuff[i].Orientation, SizeOf(TGFloat));
      FDescriptorBuff[i].index := i;
      FDescriptorBuff[i].Owner := Self;
    end;

  stream.read(FWidth, 4);
  stream.read(FHeight, 4);
  SetLength(FViewer, FHeight * FWidth);
  stream.read(FViewer[0], FHeight * FWidth);
end;

function TFeature.CreateViewer: TMemoryRaster;
var
  i: TLInt;
  C: Byte;
begin
  Result := NewRaster();
  Result.SetSize(FWidth, FHeight);
  for i := FWidth * FHeight - 1 downto 0 do
    begin
      C := FViewer[i];
      Result.Bits^[i] := RasterColor(C, C, C);
    end;
end;

function TFeature.CreateFeatureViewer(const FeatureRadius: TGFloat; const COLOR: TRasterColor): TMemoryRaster;
var
  i: TLInt;
  L: TLInt;
  invColor: TRasterColor;
  p: PDescriptor;
  v1, v2: TVec2;
begin
  Result := CreateViewer;
  if Count = 0 then
      Exit;

  Result.OpenAgg;
  L := Round(FeatureRadius * 2);

  invColor := RasterColorInv(COLOR);

  for i := 0 to Count - 1 do
    begin
      p := GetFD(i);
      v2 := p^.AbsCoor;
      Result.DrawCircle(v2, Max(L div 2, 3) - 1, COLOR);

      v1[0] := v2[0] + (FeatureRadius) * Cos(p^.Orientation);
      v1[1] := v2[1] + (FeatureRadius) * Sin(p^.Orientation);
      Result.LineF(p^.AbsCoor, v1, invColor, False);
    end;
end;

procedure TestPyramidSpace;
var
  f1, f2: TFeature;
  M: TArrayMatchInfo;
  raster: TMemoryRaster;
  F: TLFloat;
begin
  f1 := TFeature.CreateWithRaster('c:\1.bmp');
  f2 := TFeature.CreateWithRaster('c:\2.bmp');
  F := MatchFeature(f1, f2, M);

  raster := BuildMatchInfoView(M, 10, True);
  if raster <> nil then
    begin
      SaveRaster(raster, 'c:\4.bmp');
      DisposeObject(raster);
    end;

  DisposeObject(f1);
  DisposeObject(f2);
end;

initialization

// sampler
CRED_WEIGHT_SAMPLER := 1.0;
CGREEN_WEIGHT_SAMPLER := 1.0;
CBLUE_WEIGHT_SAMPLER := 1.0;
CSAMPLER_MODE := TGSamplerMode.gsmGray;
CMAX_GRAY_COLOR_SAMPLER := 255;
CMAX_SAMPLER_WIDTH := 1024;
CMAX_SAMPLER_HEIGHT := 1024;

// gauss kernal
CGAUSS_KERNEL_FACTOR := 3;

// pyramidoctave
CNUMBER_OCTAVE := 5;

// scalespace(SS) and difference of Gaussian Space(DOG)
CNUMBER_SCALE := 7;

// pyramid scale space factor
CSCALE_FACTOR := 1.4142135623730950488;
CSIGMA_FACTOR := 1.4142135623730950488;

// Extrema
CGRAY_THRESHOLD := 5.0E-2;
CEXTREMA_DIFF_THRESHOLD := 2.0E-5;
CFILTER_MAX_KEYPOINT_ENDGE := 3000;

// orientation
COFFSET_DEPTH := 15;
COFFSET_THRESHOLD := 0.6;
CCONTRAST_THRESHOLD := 3.0E-2;
CEDGE_RATIO := 2.0;
CORIENTATION_RADIUS := 15;
CORIENTATION_SMOOTH_COUNT := 256;

// feature
CMATCH_REJECT_NEXT_RATIO := 0.8;
CDESC_SCALE_FACTOR := 16;
CDESC_PROCESS_LIGHT := True;

finalization

end. 
 
