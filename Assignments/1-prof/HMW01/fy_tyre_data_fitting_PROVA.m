%% Initialisation
% -------------------------------------------------------------------------
%  ____                   _____         __ _ _   _   _
% |  _ \ _   _ _ __ ___  |  ___|   _   / _(_) |_| |_(_)_ __   __ _
% | |_) | | | | '__/ _ \ | |_ | | | | | |_| | __| __| | '_ \ / _` |
% |  __/| |_| | | |  __/ |  _|| |_| | |  _| | |_| |_| | | | | (_| |
% |_|    \__,_|_|  \___| |_|   \__, | |_| |_|\__|\__|_|_| |_|\__, |
%                              |___/                         |___/
% -------------------------------------------------------------------------
% In this script the raw data of a measured FSAE tyre are loaded and the
% pure lateral force coefficients are fitted.

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
data_set = 'lateral_dataset';

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

ax_list(1) = nexttile;
plot(-FZ)
title('Vertical force')
xlabel('Samples [-]')
ylabel('[N]')

ax_list(2) = nexttile;
plot(IA)
title('Camber angle')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(3) = nexttile;
plot(SA)
title('Side slip')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(4) = nexttile;
plot(SL)
title('Longitudinal slip')
xlabel('Samples [-]')
ylabel('[-]')

ax_list(5) = nexttile;
plot(P)
title('Tyre pressure')
xlabel('Samples [-]')
ylabel('[psi]')

ax_list(6) = nexttile;
plot(TSTC,'DisplayName','Center')
hold on
plot(TSTI,'DisplayName','Internal')
plot(TSTO,'DisplayName','Outboard')
title('Tyre temperatures')
xlabel('Samples [-]')
ylabel('[degC]')

linkaxes(ax_list,'x')

%% Select portion of data
% Cut crappy data and select only 12 psi data

vec_samples = 1:1:length(smpl_range);
tyre_data = table(); % create empty table

% store raw data in table
tyre_data.SL =  SL(smpl_range);
tyre_data.SA =  SA(smpl_range)*to_rad; % side slip angle in RADIANS
tyre_data.FZ = -FZ(smpl_range);
tyre_data.FX =  FX(smpl_range);
tyre_data.FY =  FY(smpl_range);
tyre_data.MZ =  MZ(smpl_range);
tyre_data.IA =  IA(smpl_range)*to_rad; % inclination angle in RADIANS

% IA is increased by 1 degree linearly from 0 to 6
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

% Longitudinal slip is constant
SL_tol   = 0.001;
idx.SL_0 =  0-SL_tol < tyre_data.SL & tyre_data.SL < 0+SL_tol;
SL_0     = tyre_data( idx.SL_0, : );

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
plot(tyre_data.SL)
hold on
plot(vec_samples(idx.SL_0), SL_0.SL,'.');
title('Longitudinal slip')
xlabel('Samples [-]')
ylabel('[-]')

% comments

%% FITTING
% initialise tyre data
tyre_coeffs = initialise_tyre_data(R0, Fz0);

%% Fitting with Fz = Fz_nom = 700N and camber = 0, kappa = 0, Vx = 10
% ---------------------------------------
%  _  _           _           _   ___
% | \| |___ _ __ (_)_ _  __ _| | | __|__
% | .` / _ \ '  \| | ' \/ _` | | | _|_ /
% |_|\_\___/_|_|_|_|_||_\__,_|_| |_|/__|
% ---------------------------------------
% side slip is varied
% Fit the pure lateral coefficients

% Optimizer options
options = optimoptions('fmincon', ...
                       'Algorithm', 'interior-point', ...
                       'MaxFunctionEvaluations', 3000, ...
                       'StepTolerance', 1e-8);

% Intersect tables to obtain specific sub-datasets
% data with
% - side slip angle (SA) = 0
% - camber angle =0
% - nominal load
[TData0, ~] = intersect_table_data( SL_0, GAMMA_0, FZ_700 );
% Sort table rows in ascending order according to SA values
TData0 = sortrows(TData0, "SA");

% plot_selected_data
figure('Name', 'Nominal load data');
plot_selected_data(TData0);
FZ0 = mean(TData0.FZ);

% Vector of zeros and ones
zeros_vec = zeros(size(TData0.SA));
ones_vec  = ones(size(TData0.SA));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec; % vector of nominal load

% Vector of data: slip angle and lateral force for FZ0 (nominal vertical load)
ALPHA_vec = TData0.SA;
FY_vec = TData0.FY;

% MF for FY0 with guess data on experimental slip points
FY0_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Guess vs raw')
plot(ALPHA_vec,FY_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(ALPHA_vec,-FY0_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [rad]')
ylabel('$F_{y0}$ [N]')


% Fit coefficients (pCy1  pDy1   pEy1  pKy1  pKy2  pHy1  pVy1, Fz01)

% Guess values for parameters to be optimised
%    [pCy1  pDy1   pEy1  pHy1  pKy1  pKy2  pVy1, Fz01]
P0 = [ 1.3,  2.,   1.,    0.,    0.,    1.,    0.,    700.];

% NOTE: many local minima => limits on parameters are fundamentals
% Limits for parameters to be optimised
% 1 < pCy1 < 2
%    [pCy1  pDy1   pEy1  pKy1  pKy2  pHy1  pVy1, Fz01]
lb = [ 1.0,  0.5,  -1.0,    1,  0.1,  -10,  -10, 0.];
ub = [ 2.0,  5.0,   1.0,  100,   10,   10,   10, 0.];

% Force the raw data to match the model's positive/negative convention
% (If your model outputs positive forces for positive slip, ensure FY_vec does too)
% FY_vec_aligned = abs(FY_vec) .* sign(ALPHA_vec);

% Run the optimizer
% [P_fz_nom, fval, exitflag] = fmincon(@(P)resid_pure_Fy(P, FY_vec_aligned, ALPHA_vec, 0, FZ0, tyre_coeffs),...
%                                      P0, [], [], [], [], lb, ub, [], options);
[P_fz_nom, fval, exitflag] = fmincon(@(P)resid_pure_Fy(P, FY_vec, ALPHA_vec, 0, FZ0, tyre_coeffs),...
                                     P0, [], [], [], [], [], [], [], options);

% Update tyre data with new optimal values
tyre_coeffs.pCy1 = P_fz_nom(1);
tyre_coeffs.pDy1 = P_fz_nom(2);
tyre_coeffs.pEy1 = P_fz_nom(3);
tyre_coeffs.pHy1 = P_fz_nom(4);
tyre_coeffs.pKy1 = P_fz_nom(5);
tyre_coeffs.pKy2 = P_fz_nom(6);
tyre_coeffs.pVy1 = P_fz_nom(7);
tyre_coeffs.Fz01 = P_fz_nom(8);

% Update Fy0 coefficients for the experimental value of side slips
FY0_fz_nom_vec = MF96_FY0(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot the results
figure('Name','Fy0(Fz0)', 'Color', 'w')
plot(ALPHA_vec.*to_deg, TData0.FY, 'o', 'DisplayName', 'Fy (raw)')
hold on
plot(ALPHA_vec.*to_deg, FY0_fz_nom_vec, 'r-', 'LineWidth', 2, 'DisplayName', 'Fy (fitted)')
xlabel('Slip Angle $\alpha$ [deg]')
ylabel('Lateral Force $F_{y0}$ [N]')
title('Pure Lateral Force Fitting (Nominal Load)')
legend('Location', 'best')


% comments
% Unconstrained minimization gave best fitting results;

%% Fit coefficient with variable load
% -----------------------------------------
 %  ________     __              ______ ______
 % |  ____\ \   / /             |  ____|___  /
 % | |__   \ \_/ /  __   _____  | |__     / / 
 % |  __|   \   /   \ \ / / __| |  __|   / /  
 % | |       | |     \ V /\__ \ | |     / /__ 
 % |_|       |_|      \_/ |___/ |_|    /_____|
 % 
% -----------------------------------------
% extract data with variable load
[TDataDFz, ~] = intersect_table_data( SL_0, GAMMA_0 );
TDataDFz = sortrows(TDataDFz, "SA");

% side slip

zeros_vec = zeros(size(TDataDFz.SA));
ones_vec  = ones(size(TDataDFz.SA));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec;

ALPHA_vec = TDataDFz.SA;
FY_vec = TDataDFz.FY;
% Vector of all FZ values
FZ_vec = TDataDFz.FZ;

% First approximate guess
FY0_DFz_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Var Fz Guess vs raw')
plot(ALPHA_vec.*to_deg,FY_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(ALPHA_vec.*to_deg,FY0_DFz_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')

% Fit the pure lateral coefficients (pDy2, pEy2, pHy2, pKy2, pVy2)
% plot_selected_data

%    [pDy2 pEy2 pHy2 pKy2  pVy2]
P0 = [-0.1 , 0 , 0 , 2 , 0];

[P_dfz,fval,exitflag] = fmincon(@(P)resid_pure_Fy_varFz(P,FY_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs),...
  P0,[],[],[],[],[],[]);

disp(exitflag);
disp(fval);

% Change tyre data with new optimal values
tyre_coeffs.pDy2 = P_dfz(1);
tyre_coeffs.pEy2 = P_dfz(2);
tyre_coeffs.pEy3 = P_dfz(3);
tyre_coeffs.pHy2 = P_dfz(4);
tyre_coeffs.pVy2 = P_dfz(5);

res_FY0_dfz_vec = resid_pure_Fy_varFz(P_dfz,FY_vec,ALPHA_vec,0 , FZ_vec,tyre_coeffs);

FY0_fz_var_vec1 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec2 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_440.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec3 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec4 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec5 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec,tyre_coeffs);

figure('Name','Fy0-var Fz')
plot(ALPHA_vec.*to_deg,TDataDFz.FY,'o','DisplayName','Fy(raw)')
hold on
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec1,'-','LineWidth',2,'DisplayName','F_Z = 220N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec2,'-','LineWidth',2,'DisplayName','F_Z = 440N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec3,'-','LineWidth',2,'DisplayName','F_Z = 700N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec4,'-','LineWidth',2,'DisplayName','F_Z = 900N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec5,'-','LineWidth',2,'DisplayName','F_Z = 1120N')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')

% comments


%% Fit coefficient with variable camber
% -----------------------------------------
% FY vs Camber
% -----------------------------------------
% extract data with variable camber
[TDataGamma, ~] = intersect_table_data( SL_0, FZ_700 );
TDataGamma = sortrows(TDataGamma, "SA");

% side slip
zeros_vec = zeros(size(TDataGamma.SA));
ones_vec = ones(size(TDataGamma.SA));

ALPHA_vec = TDataGamma.SA;
GAMMA_vec = TDataGamma.IA;
FY_vec = TDataGamma.FY;
FZ_vec = TDataGamma.FZ;
FZ0_vec = tyre_coeffs.FZ0*ones_vec;

% First guess of MF parameters for Fy0 with experimental inclination angles
FY0_varGamma_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Var IA Guess vs raw')
plot(ALPHA_vec.*to_deg,FY_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(ALPHA_vec.*to_deg,FY0_varGamma_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')

% Fit the pure lateral coefficients (pDy3 pEy4 pHy3 pKy3 pVy3 pVy4)

% First guess of variable gamma params
%    (pDy3 pEy4 pHy3 pKy3 pVy3 pVy4)
P0 = [0.,  0.,  0.,  0.,  0.,  0.];

% Run "unconstrained" minimization
[P_varGamma, fval, exitflag] = fmincon(@(P)resid_pure_Fy_varGamma(P, FY_vec, ALPHA_vec,...
    GAMMA_vec, tyre_coeffs.FZ0, tyre_coeffs), P0, [],[],[],[],[],[]);

% Assign computed best parameters
tyre_coeffs.pDy3 = P_varGamma(1);
tyre_coeffs.pEy4 = P_varGamma(2);
tyre_coeffs.pHy3 = P_varGamma(3);
tyre_coeffs.pKy3 = P_varGamma(4);
tyre_coeffs.pVy3 = P_varGamma(5);
tyre_coeffs.pVy4 = P_varGamma(6);

% Recompute FY0 for each Gamma value and nominal load
FY0_varGamma_vec0 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec1 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec2 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec3 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec4 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec5 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ0_vec,tyre_coeffs);

% Plot results
figure('Name','Fy0 vs Gamma')
plot(ALPHA_vec.*to_deg,FY_vec,'o','Linewidth',2,'DisplayName','Fy raw')
hold on
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec0,'-','Linewidth',2,'DisplayName','IA = 0°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec1,'-','Linewidth',2,'DisplayName','IA = 1°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec2,'-','Linewidth',2,'DisplayName','IA = 2°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec3,'-','Linewidth',2,'DisplayName','IA = 3°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec4,'-','Linewidth',2,'DisplayName','IA = 4°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec5,'-','Linewidth',2,'DisplayName','IA = 5°')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend

% comments

%% Combined FX FY using normalised theoretical slip
% Using Combined FX and FY with normalised theoretical slip plot and comments
% the ellipse of adherence.


%% Re-init tyre coefficients
tyre_coeffs_Mz = initialise_tyre_data(R0, Fz0);

%% Pure Self-aligning Moment MZ
% -------------
%    Pure Mz
% -------------

% Keep data with nominal vertical load, k=0 and Gamma=0
[TDataM_varFz, ~] = intersect_table_data( SL_0, GAMMA_0, FZ_700 );
% Sort rows by SA
TDataM_varFz = sortrows(TDataM_varFz, "SA");

zeros_vec = zeros(size(TDataM_varFz.SA));
ones_vec = ones(size(TDataM_varFz.SA));

ALPHA_vec = TDataM_varFz.SA;
FY_vec = TDataM_varFz.FY;
FZ_vec = TDataM_varFz.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varFz.MZ;

% First guess of MF parameters for Mz0 with nominal values
MZ0_guess = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs_Mz, R0);

% Plot guess data check guess
figure('Name','Pure M_z Guess vs raw')
plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','raw (Mz0)')
hold on
plot(ALPHA_vec.*to_deg,MZ0_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N*m]')

% Fit the Mz coefficients for nominal conditions
% (qBz1 qBz9 qBz10 qCz1 qDz1 qDz6 qEz1 qHz1)
P0 = [10., 0., 0., 1.2, 0.12, 0.001, -1.5, 0.];

[P_mz_varFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz(P, MZ_vec, ALPHA_vec, 0, tyre_coeffs_Mz.FZ0, tyre_coeffs_Mz, R0),...
    P0, [], [], [], [], [], []);
disp(fval)
disp(exitflag)
% Update the coefficients after fitting
tyre_coeffs_Mz.qBz1 = P_mz_varFz(1); 
tyre_coeffs_Mz.qBz9 = P_mz_varFz(2);
tyre_coeffs_Mz.qBz10= P_mz_varFz(3);
tyre_coeffs_Mz.qCz1 = P_mz_varFz(4);
tyre_coeffs_Mz.qDz1 = P_mz_varFz(5);
tyre_coeffs_Mz.qDz6 = P_mz_varFz(6);
tyre_coeffs_Mz.qEz1 = P_mz_varFz(7);
tyre_coeffs_Mz.qHz1 = P_mz_varFz(8);
% Recompute MZ0 with fitted coefficients
MZ0_nominal = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs_Mz, R0);

% Plot the results
figure('Name','Mz0', 'Color', 'w')
plot(ALPHA_vec.*to_deg, MZ_vec, 'o', 'DisplayName', 'Mz (raw)')
hold on
plot(ALPHA_vec.*to_deg, MZ0_nominal, 'r-', 'LineWidth', 2, 'DisplayName', 'Mz (fitted)')
xlabel('Slip Angle $\alpha$ [deg]')
ylabel('Self-aligning Moment $M_{z0}$ [N]')
title('Mz Fitting (Nominal Load)')
legend('Location', 'best')


%% Mz with variable Vertical Load Fz
% k=0, IA=0, variable load
[TDataM_varFz, ~] = intersect_table_data( SL_0, GAMMA_0 );

% Sort rows by SA
TDataM_varFz = sortrows(TDataM_varFz, "SA");

zeros_vec = zeros(size(TDataM_varFz.SA));
ones_vec = ones(size(TDataM_varFz.SA));

ALPHA_vec = TDataM_varFz.SA;
FY_vec = TDataM_varFz.FY;
FZ_vec = TDataM_varFz.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varFz.MZ;

% First guess of MF parameters for Mz0 with variable load --> NOT REALLY
% IMPORTANT, AS WE'D BE GUESSING MZ0 (w/ Fz = Fz0)
% MZ0_guess = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs_Mz, R0);
% 
% % Plot guess data check guess
% figure('Name','Pure M_z Guess vs raw')
% plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','raw (Mz0)')
% hold on
% plot(ALPHA_vec.*to_deg,MZ0_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
% legend
% xlabel('$\alpha$ [deg]')
% ylabel('$M_{z0}$ [N*m]')

% Fit the Mz coefficients for nominal conditions
% (qBz2 qBz3 qDz2 qDz7 qEz2 qEz3 qEz4 qHz2)
P0 = [-1.1, 0., -0.01, 0., 0., 0., 0., 0.];

[P_mz_varFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varFz(P, MZ_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs_Mz, R0),...
    P0, [], [], [], [], [], []);
disp(fval)
disp(exitflag)
% Update the coefficients after fitting
tyre_coeffs_Mz.qBz2 = P_mz_varFz(1); 
tyre_coeffs_Mz.qBz3 = P_mz_varFz(2);
tyre_coeffs_Mz.qDz2 = P_mz_varFz(3);
tyre_coeffs_Mz.qDz7 = P_mz_varFz(4);
tyre_coeffs_Mz.qEz2 = P_mz_varFz(5);
tyre_coeffs_Mz.qEz3 = P_mz_varFz(6);
tyre_coeffs_Mz.qEz4 = P_mz_varFz(7);
tyre_coeffs_Mz.qHz2 = P_mz_varFz(8);
% Recompute MZ0 with fitted coefficients for each load
MZ0_Fz_220 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_440 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_440.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_700 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_900 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_1120 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec, tyre_coeffs_Mz, R0);

% Plot the results
figure('Name','Mz0-var Fz')
plot(ALPHA_vec.*to_deg,TDataM_varFz.MZ,'o','DisplayName','Fy(raw)')
hold on
plot(ALPHA_vec.*to_deg,MZ0_Fz_220 ,'-','LineWidth',2,'DisplayName','F_Z = 220N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_440 ,'-','LineWidth',2,'DisplayName','F_Z = 440N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_700 ,'-','LineWidth',2,'DisplayName','F_Z = 700N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_900 ,'-','LineWidth',2,'DisplayName','F_Z = 900N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_1120,'-','LineWidth',2,'DisplayName','F_Z = 1120N')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N]')


%% Mz with variable Load Fz and Camber Gamma
% data with k=0
% [TDataM_varGammaFz, ~] = intersect_table_data( SL_0 );

% N.B. The tyre coefficients are now fitted for variable load and zero long slip

% Sort rows by SA
TDataM_varGammaFz = sortrows(tyre_data, "SA");

zeros_vec = zeros(size(TDataM_varGammaFz.SA));
ones_vec = ones(size(TDataM_varGammaFz.SA));

ALPHA_vec = TDataM_varGammaFz.SA;
GAMMA_vec = TDataM_varGammaFz.IA;
FY_vec = TDataM_varGammaFz.FY;
FZ_vec = TDataM_varGammaFz.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varGammaFz.MZ;

% Plot guess data check guess
figure('Name','M_z raw varFz varGamma')
plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','raw (Mz0)')
legend
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N*m]')

% Fit the parameters (
% First guess of variable gamma params
%    (qBz4 qBz5 qDz3 qDz4 qDz8 qEz5 qHz3 qDz9 qHz4) --> Last 2 are COMBINED
%    varFz and varGamma
P0 = [0., 0., 0., 0., 0.2, 0.03, 0., 0., 0.];

% Run "unconstrained" minimization
[P_varGammaFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varGammaFz(P, MZ_vec, ALPHA_vec,...
    GAMMA_vec, FZ_vec, tyre_coeffs, R0), P0, [],[],[],[],[],[]);

% Assign computed best parameters
tyre_coeffs.qBz4 = P_varGammaFz(1);
tyre_coeffs.qBz5 = P_varGammaFz(2);
tyre_coeffs.qDz3 = P_varGammaFz(3);
tyre_coeffs.qDz4 = P_varGammaFz(4);
tyre_coeffs.qDz8 = P_varGammaFz(5);
tyre_coeffs.qEz5 = P_varGammaFz(6);
tyre_coeffs.qHz3 = P_varGammaFz(7);
tyre_coeffs.qDz9 = P_varGammaFz(8);
tyre_coeffs.qHz4 = P_varGammaFz(9);

% Recompute FY0 for each Gamma value and variable load
MZ0_varGammaFz_vec0 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ_vec, tyre_coeffs_Mz, R0);
MZ0_varGammaFz_vec1 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ_vec, tyre_coeffs_Mz, R0);
MZ0_varGammaFz_vec2 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ_vec, tyre_coeffs_Mz, R0);
MZ0_varGammaFz_vec3 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ_vec, tyre_coeffs_Mz, R0);
MZ0_varGammaFz_vec4 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ_vec, tyre_coeffs_Mz, R0);
MZ0_varGammaFz_vec5 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ_vec, tyre_coeffs_Mz, R0);
%%
% Plot results
figure('Name','Mz0 vs Gamma')
plot(ALPHA_vec.*to_deg,MZ_vec,'o','Linewidth',2,'DisplayName','Mz raw')
hold on
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec0,'-','Linewidth',2,'DisplayName','IA = 0°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec1,'-','Linewidth',2,'DisplayName','IA = 1°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec2,'-','Linewidth',2,'DisplayName','IA = 2°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec3,'-','Linewidth',2,'DisplayName','IA = 3°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec4,'-','Linewidth',2,'DisplayName','IA = 4°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec5,'-','Linewidth',2,'DisplayName','IA = 5°')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N*m]')
legend

% COMMIT THE resid_pure_Mz_varFz FILE FOR F***K'S SAKE

%% Save tyre data structure to mat file
%
%save(['tyre_' data_set,'.mat'],'tyre_coeffs');
