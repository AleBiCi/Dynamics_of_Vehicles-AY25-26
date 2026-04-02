%% Initialisation
% ---------------------------------------------------------
%  _____                           _                      _       
% |_   _|  _ _ _ ___   ____ __ _ _(_)_ _  __ _   _ _ __ _| |_ ___ 
%   | || || | '_/ -_) (_-< '_ \ '_| | ' \/ _` | | '_/ _` |  _/ -_)
%   |_| \_, |_| \___| /__/ .__/_| |_|_||_\__, | |_| \__,_|\__\___|
%       |__/             |_|             |___/                    
% ---------------------------------------------------------
% In this script the raw data of a measured FSAE tyre are loaded and the
% pure longitudinal force coefficeints are fitted.
%
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
data_set_path = 'TTC_dataset/';
% dataset selection and loading

t_data = readtable([ data_set_path 'Run_464_23_spring-rate.txt'],'NumHeaderLines',2) ; 

Fz = t_data.NominalLoad*0.45; % (N)
P  = t_data.P; % (psi) 
Kt = t_data.SpringRate*0.45/0.0254;

figure()
tiledlayout(3,1)
nexttile
plot(Kt)
title('Spring rate')

nexttile
plot(P)
title('Pressure')
nexttile
plot(Fz)
title('Fz')

