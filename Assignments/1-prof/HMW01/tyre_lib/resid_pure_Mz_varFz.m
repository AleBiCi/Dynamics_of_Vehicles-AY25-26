function res = resid_pure_Mz_varFz(P,MZ,ALPHA,GAMMA,FZ,tyre_data,R0)

    % ----------------------------------------------------------------------
    %% Compute the residuals - least squares approach - to fit the Mz curve 
    %  with Fz variable, IA=0, Fy experimental. Pacejka 1996 Magic Formula
    % ----------------------------------------------------------------------

    % Define MF coefficients
    
    tmp_tyre_data = tyre_data;
       
    tmp_tyre_data.qBz2 = P(1); 
    tmp_tyre_data.qBz3 = P(2);
    tmp_tyre_data.qDz2= P(3);
    tmp_tyre_data.qDz7 = P(4);
    tmp_tyre_data.qEz2 = P(5);
    tmp_tyre_data.qEz3 = P(6);
    tmp_tyre_data.qEz4 = P(7);
    tmp_tyre_data.qHz2 = P(8);
    
   %dfz = (Z - Fz0)./Fz0 ;
    
    % Pure Self-Aligning moment residuals
    res = 0;
    for i=1:length(ALPHA)
       mz0  = MF96_MZ0(0, ALPHA(i), GAMMA, FZ(i), tmp_tyre_data, R0);
       res = res+(mz0-MZ(i))^2;
    end
    
    % Compute the residuals
    res = res/sum(MZ.^2);
    

end

