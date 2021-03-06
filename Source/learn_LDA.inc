{ ****************************************************************************** }
{ * Linear discriminant analysis support, by QQ 600585@qq.com                  * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }


(* ************************************************************************
  N-dimensional multiclass Fisher LDA

  Subroutine finds coefficients of linear combinations which optimally separates
  training set on classes. It returns N-dimensional basis whose vector are sorted
  by quality of training set separation (in descending order).

  INPUT PARAMETERS:
  XY          -   training set, array[0..NPoints-1,0..NVars].
                  First NVars columns store values of independent variables,
                  next column stores number of class (from 0 to NClasses-1) which dataset element belongs to.
                  Fractional values are rounded to nearest TLInt.
  NPoints     -   training set size, NPoints>=0
  NVars       -   number of independent variables, NVars>=1
  NClasses    -   number of classes, NClasses>=2


  OUTPUT PARAMETERS:
  Info        -   return code:
  * -4, if internal EVD subroutine hasn't converged
  * -2, if there is a point with class number
  outside of [0..NClasses-1].
  * -1, if incorrect parameters was passed (NPoints<0, NVars<1, NClasses<2)
  *  1, if task has been solved
  *  2, if there was a multicollinearity in training set, but task has been solved.
  W           -   basis, array[0..NVars-1,0..NVars-1] columns of matrix stores basis vectors, sorted by quality of training set separation (in descending order)
  ************************************************************************ *)
procedure FisherLDAN(const xy: TLMatrix; NPoints: TLInt; NVars: TLInt; NClasses: TLInt; var Info: TLInt; var w: TLMatrix); {$IFDEF INLINE_ASM} inline; {$ENDIF}
var
  i     : TLInt;
  J     : TLInt;
  k     : TLInt;
  M     : TLInt;
  v     : TLFloat;
  C     : TLIVec;
  MU    : TLVec;
  MuC   : TLMatrix;
  NC    : TLIVec;
  SW    : TLMatrix;
  st    : TLMatrix;
  Z     : TLMatrix;
  z2    : TLMatrix;
  TM    : TLMatrix;
  SBRoot: TLMatrix;
  A     : TLMatrix;
  XYProj: TLMatrix;
  WProj : TLMatrix;
  TF    : TLVec;
  d     : TLVec;
  d2    : TLVec;
  Work  : TLVec;
  i_    : TLInt;
begin

  //
  // Test data
  //
  if (NPoints < 0) or (NVars < 1) or (NClasses < 2) then
    begin
      Info := -1;
      Exit;
    end;
  i := 0;
  while i <= NPoints - 1 do
    begin
      if (Round(xy[i, NVars]) < 0) or (Round(xy[i, NVars]) >= NClasses) then
        begin
          Info := -2;
          Exit;
        end;
      Inc(i);
    end;
  Info := 1;

  //
  // Special case: NPoints<=1
  // Degenerate task.
  //
  if NPoints <= 1 then
    begin
      Info := 2;
      SetLength(w, NVars (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
      i := 0;
      while i <= NVars - 1 do
        begin
          J := 0;
          while J <= NVars - 1 do
            begin
              if i = J then
                begin
                  w[i, J] := 1;
                end
              else
                begin
                  w[i, J] := 0;
                end;
              Inc(J);
            end;
          Inc(i);
        end;
      Exit;
    end;

  //
  // Prepare temporaries
  //
  SetLength(TF, NVars (* - 1 + 1 // optimized compiler *) );
  SetLength(Work, Max(NVars, NPoints) + 1);

  //
  // Convert class labels from reals to integers (just for convenience)
  //
  SetLength(C, NPoints (* - 1 + 1 // optimized compiler *) );
  i := 0;
  while i <= NPoints - 1 do
    begin
      C[i] := Round(xy[i, NVars]);
      Inc(i);
    end;

  //
  // Calculate class sizes and means
  //
  SetLength(MU, NVars (* - 1 + 1 // optimized compiler *) );
  SetLength(MuC, NClasses (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
  SetLength(NC, NClasses (* - 1 + 1 // optimized compiler *) );
  J := 0;
  while J <= NVars - 1 do
    begin
      MU[J] := 0;
      Inc(J);
    end;
  i := 0;
  while i <= NClasses - 1 do
    begin
      NC[i] := 0;
      J := 0;
      while J <= NVars - 1 do
        begin
          MuC[i, J] := 0;
          Inc(J);
        end;
      Inc(i);
    end;
  i := 0;
  while i <= NPoints - 1 do
    begin
      APVAdd(@MU[0], 0, NVars - 1, @xy[i][0], 0, NVars - 1);
      APVAdd(@MuC[C[i]][0], 0, NVars - 1, @xy[i][0], 0, NVars - 1);
      NC[C[i]] := NC[C[i]] + 1;
      Inc(i);
    end;
  i := 0;
  while i <= NClasses - 1 do
    begin
      v := AP_Float(1) / NC[i];
      APVMul(@MuC[i][0], 0, NVars - 1, v);
      Inc(i);
    end;
  v := AP_Float(1) / NPoints;
  APVMul(@MU[0], 0, NVars - 1, v);

  //
  // Create ST matrix
  //
  SetLength(st, NVars (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
  i := 0;
  while i <= NVars - 1 do
    begin
      J := 0;
      while J <= NVars - 1 do
        begin
          st[i, J] := 0;
          Inc(J);
        end;
      Inc(i);
    end;
  k := 0;
  while k <= NPoints - 1 do
    begin
      APVMove(@TF[0], 0, NVars - 1, @xy[k][0], 0, NVars - 1);
      APVSub(@TF[0], 0, NVars - 1, @MU[0], 0, NVars - 1);
      i := 0;
      while i <= NVars - 1 do
        begin
          v := TF[i];
          APVAdd(@st[i][0], 0, NVars - 1, @TF[0], 0, NVars - 1, v);
          Inc(i);
        end;
      Inc(k);
    end;

  //
  // Create SW matrix
  //
  SetLength(SW, NVars (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
  i := 0;
  while i <= NVars - 1 do
    begin
      J := 0;
      while J <= NVars - 1 do
        begin
          SW[i, J] := 0;
          Inc(J);
        end;
      Inc(i);
    end;
  k := 0;
  while k <= NPoints - 1 do
    begin
      APVMove(@TF[0], 0, NVars - 1, @xy[k][0], 0, NVars - 1);
      APVSub(@TF[0], 0, NVars - 1, @MuC[C[k]][0], 0, NVars - 1);
      i := 0;
      while i <= NVars - 1 do
        begin
          v := TF[i];
          APVAdd(@SW[i][0], 0, NVars - 1, @TF[0], 0, NVars - 1, v);
          Inc(i);
        end;
      Inc(k);
    end;

  //
  // Maximize ratio J=(w'*ST*w)/(w'*SW*w).
  //
  // First, make transition from w to v such that w'*ST*w becomes v'*v:
  // v  = root(ST)*w = R*w
  // R  = root(D)*Z'
  // w  = (root(ST)^-1)*v = RI*v
  // RI = Z*inv(root(D))
  // J  = (v'*v)/(v'*(RI'*SW*RI)*v)
  // ST = Z*D*Z'
  //
  // so we have
  //
  // J = (v'*v) / (v'*(inv(root(D))*Z'*SW*Z*inv(root(D)))*v)  =
  // = (v'*v) / (v'*A*v)
  //
  if not SMatrixEVD(st, NVars, 1, True, d, Z) then
    begin
      Info := -4;
      Exit;
    end;
  SetLength(w, NVars (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
  if AP_FP_Less_Eq(d[NVars - 1], 0) or
    AP_FP_Less_Eq(d[0], 1000 * MachineEpsilon * d[NVars - 1]) then
    begin

      //
      // Special case: D[NVars-1]<=0
      // Degenerate task (all variables takes the same value).
      //
      if AP_FP_Less_Eq(d[NVars - 1], 0) then
        begin
          Info := 2;
          i := 0;
          while i <= NVars - 1 do
            begin
              J := 0;
              while J <= NVars - 1 do
                begin
                  if i = J then
                    begin
                      w[i, J] := 1;
                    end
                  else
                    begin
                      w[i, J] := 0;
                    end;
                  Inc(J);
                end;
              Inc(i);
            end;
          Exit;
        end;

      //
      // Special case: degenerate ST matrix, multicollinearity found.
      // Since we know ST eigenvalues/vectors we can translate task to
      // non-degenerate form.
      //
      // Let WG is orthogonal basis of the non zero variance subspace
      // of the ST and let WZ is orthogonal basis of the zero variance
      // subspace.
      //
      // Projection on WG allows us to use LDA on reduced M-dimensional
      // subspace, N-M vectors of WZ allows us to update reduced LDA
      // factors to full N-dimensional subspace.
      //
      M := 0;
      k := 0;
      while k <= NVars - 1 do
        begin
          if AP_FP_Less_Eq(d[k], 1000 * MachineEpsilon * d[NVars - 1]) then
            begin
              M := k + 1;
            end;
          Inc(k);
        end;
      Assert(M <> 0, 'FisherLDAN: internal error #1');
      SetLength(XYProj, NPoints (* - 1 + 1 // optimized compiler *) , NVars - M + 1);
      MatrixMatrixMultiply(xy, 0, NPoints - 1, 0, NVars - 1, False, Z, 0,
        NVars - 1, M, NVars - 1, False, 1.0, XYProj, 0, NPoints - 1, 0,
        NVars - M - 1, 0.0, Work);
      i := 0;
      while i <= NPoints - 1 do
        begin
          XYProj[i, NVars - M] := xy[i, NVars];
          Inc(i);
        end;
      FisherLDAN(XYProj, NPoints, NVars - M, NClasses, Info, WProj);
      if Info < 0 then
        begin
          Exit;
        end;
      MatrixMatrixMultiply(Z, 0, NVars - 1, M, NVars - 1, False, WProj, 0,
        NVars - M - 1, 0, NVars - M - 1, False, 1.0, w, 0, NVars - 1, 0,
        NVars - M - 1, 0.0, Work);
      k := NVars - M;
      while k <= NVars - 1 do
        begin
          for i_ := 0 to NVars - 1 do
            begin
              w[i_, k] := Z[i_, k - (NVars - M)];
            end;
          Inc(k);
        end;
      Info := 2;
    end
  else
    begin

      //
      // General case: no multicollinearity
      //
      SetLength(TM, NVars (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
      SetLength(A, NVars (* - 1 + 1 // optimized compiler *) , NVars (* - 1 + 1 // optimized compiler *) );
      MatrixMatrixMultiply(SW, 0, NVars - 1, 0, NVars - 1, False, Z, 0, NVars - 1,
        0, NVars - 1, False, 1.0, TM, 0, NVars - 1, 0, NVars - 1, 0.0, Work);
      MatrixMatrixMultiply(Z, 0, NVars - 1, 0, NVars - 1, True, TM, 0, NVars - 1,
        0, NVars - 1, False, 1.0, A, 0, NVars - 1, 0, NVars - 1, 0.0, Work);
      i := 0;
      while i <= NVars - 1 do
        begin
          J := 0;
          while J <= NVars - 1 do
            begin
              A[i, J] := A[i, J] / Sqrt(d[i] * d[J]);
              Inc(J);
            end;
          Inc(i);
        end;
      if not SMatrixEVD(A, NVars, 1, True, d2, z2) then
        begin
          Info := -4;
          Exit;
        end;
      k := 0;
      while k <= NVars - 1 do
        begin
          i := 0;
          while i <= NVars - 1 do
            begin
              TF[i] := z2[i, k] / Sqrt(d[i]);
              Inc(i);
            end;
          i := 0;
          while i <= NVars - 1 do
            begin
              v := APVDotProduct(@Z[i][0], 0, NVars - 1, @TF[0], 0, NVars - 1);
              w[i, k] := v;
              Inc(i);
            end;
          Inc(k);
        end;
    end;

  //
  // Post-processing:
  // * normalization
  // * converting to non-negative form, if possible
  //
  k := 0;
  while k <= NVars - 1 do
    begin
      v := 0.0;
      for i_ := 0 to NVars - 1 do
        begin
          v := v + w[i_, k] * w[i_, k];
        end;
      v := 1 / Sqrt(v);
      for i_ := 0 to NVars - 1 do
        begin
          w[i_, k] := v * w[i_, k];
        end;
      v := 0;
      i := 0;
      while i <= NVars - 1 do
        begin
          v := v + w[i, k];
          Inc(i);
        end;
      if AP_FP_Less(v, 0) then
        begin
          for i_ := 0 to NVars - 1 do
            begin
              w[i_, k] := -1 * w[i_, k];
            end;
        end;
      Inc(k);
    end;
end;

(* ************************************************************************
  Multiclass Fisher LDA

  Subroutine finds coefficients of linear combination which optimally separates
  training set on classes.

  INPUT PARAMETERS:
  XY          -   training set, array[0..NPoints-1,0..NVars]. First NVars columns store values of independent variables,
                  next column stores number of class (from 0 to NClasses-1) which dataset element belongs to.
                  Fractional values are rounded to nearest TLInt.
  NPoints     -   training set size, NPoints>=0
  NVars       -   number of independent variables, NVars>=1
  NClasses    -   number of classes, NClasses>=2


  OUTPUT PARAMETERS:
  Info        -   return code:
  * -4, if internal EVD subroutine hasn't converged
  * -2, if there is a point with class number outside of [0..NClasses-1].
  * -1, if incorrect parameters was passed (NPoints<0, NVars<1, NClasses<2)
  *  1, if task has been solved
  *  2, if there was a multicollinearity in training set, but task has been solved.
  W           -   linear combination coefficients, array[0..NVars-1]
  ************************************************************************ *)
procedure FisherLDA(const xy: TLMatrix; NPoints: TLInt; NVars: TLInt; NClasses: TLInt; var Info: TLInt; var w: TLVec); {$IFDEF INLINE_ASM} inline; {$ENDIF}
var
  W2: TLMatrix;
  i_: TLInt;
begin
  FisherLDAN(xy, NPoints, NVars, NClasses, Info, W2);
  if Info > 0 then
    begin
      SetLength(w, NVars (* - 1 + 1 // optimized compiler *) );
      for i_ := 0 to NVars - 1 do
          w[i_] := W2[i_, 0];
    end;
end;
 
