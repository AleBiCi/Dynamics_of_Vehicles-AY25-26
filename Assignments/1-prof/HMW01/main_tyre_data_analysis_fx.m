%% Initialisation
% ---------------------------------------------------------
%  ___                ___        __ _ _   _   _
% | _ \_  _ _ _ ___  | __|_ __  / _(_) |_| |_(_)_ _  __ _
% |  _/ || | '_/ -_) | _|\ \ / |  _| |  _|  _| | ' \/ _` |
% |_|  \_,_|_| \___| |_| /_\_\ |_| |_|\__|\__|_|_||_\__, |
%                                                   |___/
% ---------------------------------------------------------
% In this script the raw data of a measured FSAE tyre are loaded and the
% pure longitudinal force coefficients are fitted.

clc
clearvars
close all

% Set LaTeX as default interpreter for axis labels, ticks and legends
set(0,'defaulttextinterpreter','latex')
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

set(0,'DefaultFigureWindowStyle','docked');
set(0,'defaultAxesFontSize',  16)
set(0,'DefaultLegendFontSize',16)

addpath('tyre_lib/')

to_rad = pi/180;
to_deg = 180/pi;

%% Select tyre dataset

%dataset path
data_set_path = ['dataset_VD' filesep 'Hoosier 18.0 LCO'];

% dataset selection and loading
data_set = 'longitudinal_dataset';

% tyre geometric data:
% Hoosier	18.0x6.0-10
% 18 diameter in inches
% 6.0 section width in inches
% tread width in inches
diameter = 18*2.54; %
Fz0      = 700;     % [N] nominal load is given
R0       = diameter/2/100; % [m] get from nominal load R0 (m) *** TO BE CHANGED ***

% !! If you change the dataset the cut_start and cut_end may change, select
% the nominal pressure and change accordingly the values
fprintf('Loading dataset ...')
switch data_set
  case 'lateral_dataset'
    load (['..', filesep, data_set_path, filesep, 'lateral_dataset.mat']); % pure lateral
    cut_start = 1;
    cut_end   = 21953;
  case 'longitudinal_dataset'
    load (['..', filesep, data_set_path, filesep, 'longitudinal_dataset.mat']); % pure longitudinal
    cut_start = 1;
    cut_end   = 19083;
  otherwise
    error('Not found dataset: `%s`\n', data_set) ;
end
fprintf('completed!\n')

% select dataset portion
smpl_range = cut_start:cut_end;

%% Plot raw data

figure('Name','raw data')
tiledlayout(6,1)

ax_list(1) = nexttile; y_range = [min(min(-FZ),0) round(max(-FZ)*1.1)];
plot(-FZ)
hold on
plot([cut_start cut_start],y_range,'--r')
plot([cut_end cut_end],y_range,'--r')
title('Vertical force')
xlabel('Samples [-]')
ylabel('[N]')

ax_list(2) = nexttile; y_range = [min(min(IA),0) round(max(IA)*1.1)];
plot(IA)
hold on
plot([cut_start cut_start],y_range,'--r')
plot([cut_end cut_end],y_range,'--r')
title('Camber angle')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(3) = nexttile; y_range = [min(min(SA),0) round(max(SA)*1.1)];
plot(SA)
hold on
plot([cut_start cut_start],y_range,'--r')
plot([cut_end cut_end],y_range,'--r')
title('Side slip')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(4) = nexttile; y_range = [min(min(SL),0) round(max(SL)*1.1)];
plot(SL)
hold on
plot([cut_start cut_start],y_range,'--r')
plot([cut_end cut_end],y_range,'--r')
title('Longitudinal slip')
xlabel('Samples [-]')
ylabel('[-]')

ax_list(5) = nexttile; y_range = [min(min(P),0) round(max(P)*1.1)];
plot(P)
hold on
plot([cut_start cut_start],y_range,'--r')
plot([cut_end cut_end],y_range,'--r')
title('Tyre pressure')
xlabel('Samples [-]')
ylabel('[psi]')

ax_list(6) = nexttile;  y_range = [min(min(TSTC),0) round(max(TSTC)*1.1)];
plot(TSTC,'DisplayName','Center')
hold on
plot(TSTI,'DisplayName','Internal')
plot(TSTO,'DisplayName','Outboard')
hold on
plot([cut_start cut_start],y_range,'--r')
plot([cut_end cut_end],y_range,'--r')
title('Tyre temperatures')
xlabel('Samples [-]')
ylabel('[degC]')

linkaxes(ax_list,'x')

%% Select some specific data
% Cut crappy data and select only 12 psi data

vec_samples = 1:1:length(smpl_range);
tyre_data = table(); % create empty table

% store raw data in table
tyre_data.SL =  SL(smpl_range);
tyre_data.SA =  SA(smpl_range)*to_rad;
tyre_data.FZ = -FZ(smpl_range);
tyre_data.FX =  FX(smpl_range);
tyre_data.FY =  FY(smpl_range);
tyre_data.MZ =  MZ(smpl_range);
tyre_data.IA =  IA(smpl_range)*to_rad;

% Extract points at constant inclination angle
GAMMA_tol = 0.05*to_rad;
idx.GAMMA_0 = 0.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 0.0*to_rad+GAMMA_tol;
idx.GAMMA_1 = 1.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 1.0*to_rad+GAMMA_tol;
idx.GAMMA_2 = 2.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 2.0*to_rad+GAMMA_tol;
idx.GAMMA_3 = 3.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 3.0*to_rad+GAMMA_tol;
idx.GAMMA_4 = 4.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 4.0*to_rad+GAMMA_tol;
idx.GAMMA_5 = 5.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 5.0*to_rad+GAMMA_tol;
GAMMA_0  = tyre_data( idx.GAMMA_0, : );
GAMMA_1  = tyre_data( idx.GAMMA_1, : );
GAMMA_2  = tyre_data( idx.GAMMA_2, : );
GAMMA_3  = tyre_data( idx.GAMMA_3, : );
GAMMA_4  = tyre_data( idx.GAMMA_4, : );
GAMMA_5  = tyre_data( idx.GAMMA_5, : );

% Extract points at constant vertical load
% Test data done at:
%  - 50lbf  ( 50*0.453592*9.81 =  223N )
%  - 150lbf (150*0.453592*9.81 =  667N )
%  - 200lbf (200*0.453592*9.81 =  890N )
%  - 250lbf (250*0.453592*9.81 = 1120N )

FZ_tol = 100;
idx.FZ_220  = 220-FZ_tol < tyre_data.FZ & tyre_data.FZ < 220+FZ_tol;
idx.FZ_440  = 440-FZ_tol < tyre_data.FZ & tyre_data.FZ < 440+FZ_tol;
idx.FZ_700  = 700-FZ_tol < tyre_data.FZ & tyre_data.FZ < 700+FZ_tol;
idx.FZ_900  = 900-FZ_tol < tyre_data.FZ & tyre_data.FZ < 900+FZ_tol;
idx.FZ_1120 = 1120-FZ_tol < tyre_data.FZ & tyre_data.FZ < 1120+FZ_tol;
FZ_220  = tyre_data( idx.FZ_220, : );
FZ_440  = tyre_data( idx.FZ_440, : );
FZ_700  = tyre_data( idx.FZ_700, : );
FZ_900  = tyre_data( idx.FZ_900, : );
FZ_1120 = tyre_data( idx.FZ_1120, : );

% The slip angle is varied continuously between -4 and +12° and then
% between -12° and +4° for the pure slip case

% The slip angle is varied step wise for longitudinal slip tests
% 0° , - 3° , -6 °
SA_tol = 0.5*to_rad;
idx.SA_0    =  0-SA_tol          < tyre_data.SA & tyre_data.SA < 0+SA_tol;
idx.SA_3neg = -(3*to_rad+SA_tol) < tyre_data.SA & tyre_data.SA < -3*to_rad+SA_tol;
idx.SA_6neg = -(6*to_rad+SA_tol) < tyre_data.SA & tyre_data.SA < -6*to_rad+SA_tol;
SA_0     = tyre_data( idx.SA_0, : );
SA_3neg  = tyre_data( idx.SA_3neg, : );
SA_6neg  = tyre_data( idx.SA_6neg, : );

figure('Name', 'selected data')
tiledlayout(3,1)

ax_list(1) = nexttile;
plot(tyre_data.IA*to_deg)
hold on
plot(vec_samples(idx.GAMMA_0),GAMMA_0.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_1),GAMMA_1.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_2),GAMMA_2.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_3),GAMMA_3.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_4),GAMMA_4.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_5),GAMMA_5.IA*to_deg,'.');
title('Camber angle')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(2) = nexttile;
plot(tyre_data.FZ)
hold on
plot(vec_samples(idx.FZ_220),FZ_220.FZ,'.');
plot(vec_samples(idx.FZ_440),FZ_440.FZ,'.');
plot(vec_samples(idx.FZ_700),FZ_700.FZ,'.');
plot(vec_samples(idx.FZ_900),FZ_900.FZ,'.');
plot(vec_samples(idx.FZ_1120),FZ_1120.FZ,'.');
title('Vertical force')
xlabel('Samples [-]')
ylabel('[N]')

ax_list(3) = nexttile;
plot(tyre_data.SA*to_deg)
hold on
plot(vec_samples(idx.SA_0),   SA_0.SA*to_deg,'.');
plot(vec_samples(idx.SA_3neg),SA_3neg.SA*to_deg,'.');
plot(vec_samples(idx.SA_6neg),SA_6neg.SA*to_deg,'.');
title('Side slip')
xlabel('Samples [-]')
ylabel('[deg]')

%% FITTING
% initialise tyre data
tyre_coeffs = initialise_tyre_data(R0, Fz0);

%% Fitting with Fz = Fz_nom = 700N and camber = 0, alpha = 0, Vx = 10
% ---------------------------------------
%  _  _           _           _   ___
% | \| |___ _ __ (_)_ _  __ _| | | __|__
% | .` / _ \ '  \| | ' \/ _` | | | _|_ /
% |_|\_\___/_|_|_|_|_||_\__,_|_| |_|/__|
% ---------------------------------------
% long slip is varied
% Fit the coeffs {pCx1, pDx1, pEx1, pEx4, pKx1, pHx1, pVx1}

% Intersect tables to obtain specific sub-datasets
% data with
% - side slip angle (SA) = 0
% - camber angle =0
% - Nominal load (around 700 N)
[TData0, ~] = intersect_table_data( SA_0, GAMMA_0, FZ_700 );

% plot_selected_data
figure('Name','data-FZ0')
plot_selected_data(TData0);

FZ0 = mean(TData0.FZ);

% Vector of zeros and ones
zeros_vec = zeros(size(TData0.SL));
ones_vec  = ones(size(TData0.SL));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec; % vector of nominal load
% Vector of data: longitudinal slip and longitudinal force for nominal
% load.
KAPPA_vec = TData0.SL;
FX_vec    = TData0.FX;

% Evaluate the MF for Fx0 with guess data on experimental slip points
FX0_guess = MF96_FX0_vec(KAPPA_vec,zeros_vec , zeros_vec,...
  FZ0_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Guess vs raw')
plot(KAPPA_vec,FX_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(KAPPA_vec,FX0_guess,'-','Linewidth',2,'DisplayName','Fx0 guess')
legend
xlabel('$\kappa$ [-]')
ylabel('$F_{x0}$ [N]')

% Guess values for parameters to be optimised
%    [pCx1 pDx1 pEx1 pEx4  pHx1  pKx1  pVx1
P0 = [  1,   2,   1,  0,   0,   1,   0];

% NOTE: many local minima => limits on parameters are fundamentals
% Limits for parameters to be optimised
% 1< pCx1 < 2
% 0< pEx1 < 1
%    [pCx1 pDx1 pEx1 pEx4  pHx1  pKx1  pVx1
lb = [1,   0.1,   0,   0,  -10,    0,   -10];
ub = [2,    4,   1,   1,   10,   100,  10];

% % check guess
% SL_vec = -0.3:0.001:0.3;
% FX0_fz_nom_vec = MF96_FX0_vec(SL_vec,zeros_vec , zeros_vec, ...
%                               FZ0_vec,tyre_coeffs);

[P_fz_nom,fval,exitflag] = fmincon(@(P)resid_pure_Fx(P, FX_vec, KAPPA_vec, 0,...
  FZ0, tyre_coeffs),...
  P0,[],[],[],[],lb,ub);

% Update tyre data with new optimal values
tyre_coeffs.pCx1 = P_fz_nom(1);
tyre_coeffs.pDx1 = P_fz_nom(2);
tyre_coeffs.pEx1 = P_fz_nom(3);
tyre_coeffs.pEx4 = P_fz_nom(4);
tyre_coeffs.pHx1 = P_fz_nom(5);
tyre_coeffs.pKx1 = P_fz_nom(6);
tyre_coeffs.pVx1 = P_fz_nom(7);

% Update Fx0 coefficients for the experimental value of long. slips
FX0_fz_nom_vec = MF96_FX0_vec(KAPPA_vec,zeros_vec , zeros_vec, ...
  FZ0_vec,tyre_coeffs);

figure('Name','Fx0(Fz0)')
plot(KAPPA_vec,TData0.FX,'o','DisplayName','Fx(raw)')
hold on
%plot(TDataSub.KAPPA,FX0_fz_nom_vec,'-')
plot(KAPPA_vec,FX0_fz_nom_vec,'-','LineWidth',2,'DisplayName','Fx-fit')
xlabel('$\kappa$ [-]')
ylabel('$F_{x0}$ [N]')
legend

%% Fit coefficient with variable load
% -----------------------------------------
%  ___                      ___
% | __|_ __ __ ____ _ _ _  | __|__
% | _|\ \ / \ V / _` | '_| | _|_ /
% |_| /_\_\  \_/\__,_|_|   |_|/__|
% -----------------------------------------
% extract data with variable load
[TDataDFz, ~] = intersect_table_data( SA_0, GAMMA_0 );

% Fit the coeffs {pCx1, pDx1, pEx1, pEx4, pKx1, pHx1, pVx1}

% plot_selected_data
figure('Name','data-FZ var.')
plot_selected_data(TDataDFz);

FZ0 = mean(TData0.FZ);

% Vector of zeros and ones
zeros_vec = zeros(size(TDataDFz.SL));
ones_vec  = ones(size(TDataDFz.SL));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec; % vector of nominal load

% Vector of data: longitudinal slip and longitudinal force for nominal
% load.
KAPPA_vec = TDataDFz.SL;
FX_vec    = TDataDFz.FX;
FZ_vec    = TDataDFz.FZ;

% Evaluate the MF for Fx0 with guess data on experimental slip points
FX0_guess = MF96_FX0_vec(KAPPA_vec, zeros_vec , zeros_vec,...
  FZ0_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Guess vs raw')
plot(KAPPA_vec,FX_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(KAPPA_vec,FX0_guess,'-','Linewidth',2,'DisplayName','Fx0 guess')
legend
xlabel('$\kappa$ [-]')
ylabel('$F_{x0}$ [N]')

% Guess values for parameters to be optimised
%    [pDx2 pEx2 pEx3 pHx2  pKx2  pKx3  pVx2]
P0 = [  0,   0,   0,  0,   0,   0,   0];

% NOTE: many local minima => limits on parameters are fundamentals
% Limits for parameters to be optimised
% 1< pCx1 < 2
% 0< pEx1 < 1
%    [pCx1 pDx1 pEx1 pEx4  pHx1  pKx1  pVx1
lb = [];
ub = [];

[P_dfz,fval,exitflag] = fmincon(@(P)resid_pure_Fx_varFz(P,FX_vec, KAPPA_vec, 0, FZ_vec, tyre_coeffs),...
  P0,[],[],[],[],lb,ub);

disp(exitflag)

% Change tyre data with new optimal values
tyre_coeffs.pDx2 = P_dfz(1);
tyre_coeffs.pEx2 = P_dfz(2);
tyre_coeffs.pEx3 = P_dfz(3);
tyre_coeffs.pHx2 = P_dfz(4);
tyre_coeffs.pKx2 = P_dfz(5);
tyre_coeffs.pKx3 = P_dfz(6);
tyre_coeffs.pVx2 = P_dfz(7);

res_FX0_dfz_vec = resid_pure_Fx_varFz(P_dfz,FX_vec,KAPPA_vec,0 , FZ_vec,tyre_coeffs);

% Compute Fx for the four load conditions with fitted parameters
FX0_fz_var_vec1 = MF96_FX0_vec(KAPPA_vec, zeros_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec,tyre_coeffs);
FX0_fz_var_vec2 = MF96_FX0_vec(KAPPA_vec, zeros_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec,tyre_coeffs);
FX0_fz_var_vec3 = MF96_FX0_vec(KAPPA_vec, zeros_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec,tyre_coeffs);
FX0_fz_var_vec4 = MF96_FX0_vec(KAPPA_vec, zeros_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec,tyre_coeffs);

figure('Name','Fx0-var Fz')
plot(TDataDFz.SL,TDataDFz.FX,'o','DisplayName','Fx(raw)')
hold on
%plot(TDataSub.KAPPA,FX0_fz_nom_vec,'-')
%plot(SL_vec,FX0_dfz_vec,'-','LineWidth',2)
plot(KAPPA_vec,FX0_fz_var_vec1,'-','LineWidth',2,'DisplayName','F_Z = 220N')
plot(KAPPA_vec,FX0_fz_var_vec2,'-','LineWidth',2,'DisplayName','F_Z = 700N')
plot(KAPPA_vec,FX0_fz_var_vec3,'-','LineWidth',2,'DisplayName','F_Z = 900N')
plot(KAPPA_vec,FX0_fz_var_vec4,'-','LineWidth',2,'DisplayName','F_Z = 1120N')
xlabel('$\kappa$ [-]')
ylabel('$F_{x0}$ [N]')
legend

% Compute Fx coefficients for each load condition
[kappa__x, Bx, Cx, Dx, Ex, SVx] = MF96_FX0_coeffs(0, 0, 0, mean(FZ_220.FZ), tyre_coeffs);
Calfa_vec1_0 = magic_formula_stiffness(kappa__x, Bx, Cx, Dx, Ex, SVx);
[kappa__x, Bx, Cx, Dx, Ex, SVx] = MF96_FX0_coeffs(0, 0, 0, mean(FZ_700.FZ), tyre_coeffs);
Calfa_vec2_0 = magic_formula_stiffness(kappa__x, Bx, Cx, Dx, Ex, SVx);
[kappa__x, Bx, Cx, Dx, Ex, SVx] = MF96_FX0_coeffs(0, 0, 0, mean(FZ_900.FZ), tyre_coeffs);
Calfa_vec3_0 = magic_formula_stiffness(kappa__x, Bx, Cx, Dx, Ex, SVx);
[kappa__x, Bx, Cx, Dx, Ex, SVx] = MF96_FX0_coeffs(0, 0, 0, mean(FZ_1120.FZ), tyre_coeffs);
Calfa_vec4_0 = magic_formula_stiffness(kappa__x, Bx, Cx, Dx, Ex, SVx);

% Compute cornering stiffness for each load condition
Calfa_vec1 = MF96_CorneringStiffness(KAPPA_vec,zeros_vec ,zeros_vec, mean(FZ_220.FZ)*ones_vec,tyre_coeffs);
Calfa_vec2 = MF96_CorneringStiffness(KAPPA_vec,zeros_vec ,zeros_vec, mean(FZ_700.FZ)*ones_vec,tyre_coeffs);
Calfa_vec3 = MF96_CorneringStiffness(KAPPA_vec,zeros_vec ,zeros_vec, mean(FZ_900.FZ)*ones_vec,tyre_coeffs);
Calfa_vec4 = MF96_CorneringStiffness(KAPPA_vec,zeros_vec ,zeros_vec, mean(FZ_1120.FZ)*ones_vec,tyre_coeffs);

figure('Name','C_alpha')
subplot(2,1,1)
hold on
%plot(TDataSub.KAPPA,FX0_fz_nom_vec,'-')
plot(mean(FZ_220.FZ),Calfa_vec1_0,'+','LineWidth',2)
plot(mean(FZ_700.FZ),Calfa_vec2_0,'+','LineWidth',2)
plot(mean(FZ_900.FZ),Calfa_vec3_0,'+','LineWidth',2)
plot(mean(FZ_1120.FZ),Calfa_vec4_0,'+','LineWidth',2)
legend({'$Fz_{220}$','$Fz_{700}$','$Fz_{900}$','$Fz_{1120}$'})
xlabel('$Fz$ [N]')
ylabel('$C_{\alpha}$ [N/-]')
legend

subplot(2,1,2)
hold on
%plot(TDataSub.KAPPA,FX0_fz_nom_vec,'-')
plot(KAPPA_vec,Calfa_vec1,'-','LineWidth',2)
plot(KAPPA_vec,Calfa_vec2,'-','LineWidth',2)
plot(KAPPA_vec,Calfa_vec3,'-','LineWidth',2)
plot(KAPPA_vec,Calfa_vec4,'-','LineWidth',2)
legend({'$Fz_{220}$','$Fz_{700}$','$Fz_{900}$','$Fz_{1120}$'})
xlabel('$\kappa$ [N]')
ylabel('$C_{\alpha}$ [N/-]')


%% Fit coefficient with variable camber
% ----------------------------------------------------
%  ___                                    _
% | __|_ __ __ ____ _ _ _   __ __ _ _ __ | |__  ___ _ _
% | _|\ \ / \ V / _` | '_| / _/ _` | '  \| '_ \/ -_) '_|
% |_| /_\_\  \_/\__,_|_|   \__\__,_|_|_|_|_.__/\___|_|
% ----------------------------------------------------
% extract data with variable camber
[TDataGamma, ~] = intersect_table_data( SA_0, FZ_700 );

% Fit the coeffs { pDx3}

% Guess values for parameters to be optimised
P0 = [0];

% NOTE: many local minima => limits on parameters are fundamentals
% Limits for parameters to be optimised
% 1< pCx1 < 2
% 0< pEx1 < 1
%lb = [0, 0,  0, 0,  0,  0,  0];
%ub = [2, 1e6,1, 1,1e1,1e2,1e2];
lb = [];
ub = [];

zeros_vec = zeros(size(TDataGamma.SL));
ones_vec  = ones(size(TDataGamma.SL));

KAPPA_vec = TDataGamma.SL;
GAMMA_vec = TDataGamma.IA;
FX_vec    = TDataGamma.FX;
FZ_vec    = TDataGamma.FZ;

% Evaluate the MF for Fx0 with guess data on experimental slip points
FX0_guess = MF96_FX0_vec(KAPPA_vec,zeros_vec , GAMMA_vec,...
  FZ_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Guess vs raw')
plot(KAPPA_vec,FX_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(KAPPA_vec,FX0_guess,'-','Linewidth',2,'DisplayName','Fx0 guess')
legend
xlabel('$\kappa$ [-]')
ylabel('$F_{x0}$ [N]')

% LSM_pure_Fx returns the residual, so minimize the residual varying X. It
% is an unconstrained minimization problem
[P_varGamma,fval,exitflag] = fmincon(@(P)resid_pure_Fx_varGamma(P,FX_vec, KAPPA_vec,GAMMA_vec,tyre_coeffs.FZ0, tyre_coeffs),...
  P0,[],[],[],[],lb,ub);

% Change tyre data with new optimal values
tyre_coeffs.pDx3 = P_varGamma(1);

FX0_varGamma_vec0 = MF96_FX0_vec(KAPPA_vec, zeros_vec, mean(GAMMA_0.IA)*ones_vec, tyre_coeffs.FZ0*ones_vec, tyre_coeffs);
FX0_varGamma_vec1 = MF96_FX0_vec(KAPPA_vec, zeros_vec, mean(GAMMA_1.IA)*ones_vec, tyre_coeffs.FZ0*ones_vec, tyre_coeffs);
FX0_varGamma_vec2 = MF96_FX0_vec(KAPPA_vec, zeros_vec, mean(GAMMA_2.IA)*ones_vec, tyre_coeffs.FZ0*ones_vec, tyre_coeffs);
FX0_varGamma_vec3 = MF96_FX0_vec(KAPPA_vec, zeros_vec, mean(GAMMA_3.IA)*ones_vec, tyre_coeffs.FZ0*ones_vec, tyre_coeffs);
FX0_varGamma_vec4 = MF96_FX0_vec(KAPPA_vec, zeros_vec, mean(GAMMA_4.IA)*ones_vec, tyre_coeffs.FZ0*ones_vec, tyre_coeffs);
FX0_varGamma_vec5 = MF96_FX0_vec(KAPPA_vec, zeros_vec, mean(GAMMA_5.IA)*ones_vec, tyre_coeffs.FZ0*ones_vec, tyre_coeffs);

figure('Name','Fx0 vs Gamma')
plot(KAPPA_vec,TDataGamma.FX,'o','Linewidth',2,'DisplayName','Fx raw')
hold on
plot(KAPPA_vec,FX0_varGamma_vec0,'-','Linewidth',2,'DisplayName','IA = 0\degree')
plot(KAPPA_vec,FX0_varGamma_vec1,'-','Linewidth',2,'DisplayName','IA = 1\degree')
plot(KAPPA_vec,FX0_varGamma_vec2,'-','Linewidth',2,'DisplayName','IA = 2\degree')
plot(KAPPA_vec,FX0_varGamma_vec3,'-','Linewidth',2,'DisplayName','IA = 3\degree')
plot(KAPPA_vec,FX0_varGamma_vec4,'-','Linewidth',2,'DisplayName','IA = 4\degree')
plot(KAPPA_vec,FX0_varGamma_vec5,'-','Linewidth',2,'DisplayName','IA = 5\degree')
xlabel('$\kappa$ [-]')
ylabel('$F_{x0}$ [N]')
legend

% Calculate the residuals with the optimal solution found above
res_Fx0_varGamma  = resid_pure_Fx_varGamma(P_varGamma,FX_vec, KAPPA_vec,GAMMA_vec,tyre_coeffs.FZ0, tyre_coeffs);

%% R-squared is
% 1-SSE/SST
% SSE/SST = res_Fx0_nom

% SSE is the sum of squared error,  SST is the sum of squared total
fprintf('R-squared = %6.3f\n',1-res_Fx0_varGamma);

[kappa__x, Bx, Cx, Dx, Ex, SVx] = MF96_FX0_coeffs(0, 0, GAMMA_vec(3), tyre_coeffs.FZ0, tyre_coeffs);

fprintf('Bx      = %6.3f\n',Bx);
fprintf('Cx      = %6.3f\n',Cx);
fprintf('mux     = %6.3f\n',Dx/tyre_coeffs.FZ0);
fprintf('Ex      = %6.3f\n',Ex);
fprintf('SVx     = %6.3f\n',SVx);
fprintf('kappa_x = %6.3f\n',kappa__x);
fprintf('Kx      = %6.3f\n',Bx*Cx*Dx/tyre_coeffs.FZ0);

%% Save tyre data structure to mat file
save(['tyre_' data_set,'.mat'],'tyre_coeffs');

%% Save longitudinal dataset data points to .mat file
save([data_set, '.mat'], "tyre_data");