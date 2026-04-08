% Pure longitudinal force FX0
function [fx0] = MF96_FX0(kappa, alpha, gamma__w, Fz, tyre_data)

 % precode

  [kappa__x, Bx, Cx, Dx, Ex, SVx] = MF96_FX0_coeffs(kappa, alpha, gamma__w, Fz, tyre_data);

 % main code

  fx0 = magic_formula(kappa__x, Bx, Cx, Dx, Ex, SVx);
  
 end
