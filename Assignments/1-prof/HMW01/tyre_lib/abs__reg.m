% Implements the regularised sign function
function [res] = abs__reg(x)
  epsilon = 0.001; % regularisation parameter
  %  x/abs(x)
  res = sqrt(x.^2+epsilon);
 end
