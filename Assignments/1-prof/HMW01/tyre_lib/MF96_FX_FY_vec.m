% Combined longitudinal and lateral forces
function [fx_vec, fy_vec, Gxa, Gyk] = MF96_FX_FY_vec(kappa_vec, alpha_vec, gamma_vec, Fz_vec, tyre_data)

 fx0_vec = zeros(size(kappa_vec));
 fy0_vec = zeros(size(alpha_vec));
 fx_vec = zeros(size(kappa_vec));
 fy_vec = zeros(size(alpha_vec));
 
 for i=1:length(alpha_vec)
 % precode
  [kappa__x, Bx, Cx, Dx, Ex, SVx]     = MF96_FX0_coeffs(kappa_vec(i), alpha_vec(i), gamma_vec(i), Fz_vec(i), tyre_data);
  [alpha__y, By, Cy, Dy, Ey, SVy,Kya] = MF96_FY0_coeffs(kappa_vec(i), alpha_vec(i), gamma_vec(i), Fz_vec(i), tyre_data);
  [Gxa, Gyk, SVyk]                    = MF96_FXFYCOMB_coeffs(kappa_vec(i), alpha_vec(i), gamma_vec(i), Fz_vec(i), tyre_data);
 
 % main code

  fx0_vec(i) = magic_formula(kappa__x, Bx, Cx, Dx, Ex, SVx);
  fy0_vec(i) = magic_formula(alpha__y, By, Cy, Dy, Ey, SVy);
  fx_vec(i)= Gxa.*fx0_vec(i);
  fy_vec(i)= Gyk.*fy0_vec(i)+SVyk;
 
 end

  
 end
