% Visualize the datasets from PERTT for JAN2020 Water:N2 Trials
% Dependencies: 'GRP_AggregateData.mat' with timetables of data

% Author: Charles E. Taylor
% Date: 23JAN2020

%% Load Data

load('GRP_AggregateData.mat')

%% Visualize

%prep DTS visualization dataset for SURF (meshgrid-type dataform)
TimeMatrix = repmat(DTS_Time,1,3093);
DepthVector=table2array(DTS_Depths)';
DepthMatrix = repmat(DepthVector,13415,1);

figure 

h(1) = subplot(3,1,1);
s = surf(TimeMatrix,DepthMatrix,DTS_Data','FaceAlpha',0.5,'EdgeColor','none');
xlabel('Time');ylabel('Depth [ft]');zlabel('Temp [F]');
title('DTS')
view(2) %2D topdown view

h(2) = subplot(3,1,2);
plot(PTGauge_Total.TimeStamp,PTGauge_Total.P487ft)
ylabel('PTGauge P 487ft [PSI]');
title('PT Gauges')

h(3) = subplot(3,1,3);
plot(Pason_Total.Time,Pason_Total.Strokes2)
ylabel('Pump 2 [SPM]');
title('Pason Data')

linkaxes(h,'x');
