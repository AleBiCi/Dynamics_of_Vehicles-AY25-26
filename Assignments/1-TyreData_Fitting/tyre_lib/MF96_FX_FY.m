% Combined longitudinal and lateral forces
function [fx, fy] = MF96_FX_FY(kappa, alpha, gamma__w, Fz, tyre_data)

 % precode

  [kappa__x, Bx, Cx, Dx, Ex, SVx]     = MF96_FX0_coeffs(kappa, alpha, gamma__w, Fz, tyre_data);
  [alpha__y, By, Cy, Dy, Ey, SVy,Kya] = MF96_FY0_coeffs(kappa, alpha, gamma__w, Fz, tyre_data);
  [Gxa, Gyk, SVyk]                    = MF96_FXFYCOMB_coeffs(kappa,alpha,gamma__w,Fz, tyre_data);
  

 % main code

  fx0 = magic_formula(kappa__x, Bx, Cx, Dx, Ex, SVx);
  fy0 = magic_formula(alpha__y, By, Cy, Dy, Ey, SVy);
  fx= Gxa.*fx0;
  fy= Gyk.*fy0+SVyk;
  
 end
