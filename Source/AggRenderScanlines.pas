{ ****************************************************************************** }
{ * memory Rasterization with AGG support                                      * }
{ * by QQ 600585@qq.com                                                        * }
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

(*
  ////////////////////////////////////////////////////////////////////////////////
  //                                                                            //
  //  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
  //    Maintained by Christian-W. Budde (Christian@pcjv.de)                    //
  //    Copyright (c) 2012-2017                                                 //
  //                                                                            //
  //  Based on:                                                                 //
  //    Pascal port by Milan Marusinec alias Milano (milan@marusinec.sk)        //
  //    Copyright (c) 2005-2006, see http://www.aggpas.org                      //
  //                                                                            //
  //  Original License:                                                         //
  //    Anti-Grain Geometry - Version 2.4 (Public License)                      //
  //    Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)     //
  //    Contact: McSeem@antigrain.com / McSeemAgg@yahoo.com                     //
  //                                                                            //
  //  Permission to copy, use, modify, sell and distribute this software        //
  //  is granted provided this copyright notice appears in all copies.          //
  //  This software is provided "as is" without express or implied              //
  //  warranty, and with no claim as to its suitability for any purpose.        //
  //                                                                            //
  ////////////////////////////////////////////////////////////////////////////////
*)
unit AggRenderScanlines;

interface

{$INCLUDE AggCompiler.inc}


uses
  AggBasics,
  AggColor32,
  AggRasterizerScanLine,
  AggScanline,
  AggRendererScanLine,
  AggVertexSource;

procedure RenderScanLines(Ras: TAggRasterizerScanLine; SL: TAggCustomScanLine; Ren: TAggCustomRendererScanLine);
procedure RenderAllPaths(Ras: TAggRasterizerScanLine; SL: TAggCustomScanLine; R: TAggCustomRendererScanLineSolid; Vs: TAggVertexSource; cs: PAggColor; PathID: PCardinal; PathCount: Cardinal);

implementation

procedure RenderScanLines(Ras: TAggRasterizerScanLine; SL: TAggCustomScanLine;
  Ren: TAggCustomRendererScanLine);
var
  SlEm: TAggEmbeddedScanLine;
begin
  if Ras.RewindScanLines then
    begin
      SL.Reset(Ras.MinimumX, Ras.MaximumX);
      Ren.Prepare(Cardinal(Ras.MaximumX - Ras.MinimumX + 2));

      { if Sl.IsEmbedded then
        while Ras.SweepScanLineEm(Sl) do
        Ren.Render(Sl)
        else }
      if SL is TAggEmbeddedScanLine then
        begin
          SlEm := SL as TAggEmbeddedScanLine;
          while Ras.SweepScanLine(SlEm) do
              Ren.Render(SlEm)
        end
      else
        while Ras.SweepScanLine(SL) do
            Ren.Render(SL);
    end;
end;

procedure RenderAllPaths(Ras: TAggRasterizerScanLine; SL: TAggCustomScanLine;
  R: TAggCustomRendererScanLineSolid; Vs: TAggVertexSource; cs: PAggColor;
  PathID: PCardinal; PathCount: Cardinal);
var
  i: Cardinal;
begin
  i := 0;

  while i < PathCount do
    begin
      Ras.Reset;
      Ras.AddPath(Vs, PathID^);
      R.SetColor(cs);

      RenderScanLines(Ras, SL, R);

      Inc(PtrComp(cs), SizeOf(TAggColor));
      Inc(PtrComp(PathID), SizeOf(Cardinal));
      Inc(i);
    end;
end;

end. 
