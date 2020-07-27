%% Load data

%test if all the data objects are present, load if not
try 
    isobject(DTS_ts);
    isobject(FBE_ts);
    isobject(Pason_Total_10sec);
    isobject(PTGauge_Total);
catch
    disp('Data is not loaded')
    
    Agg_Path = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\Scratch Data\';
    disp(['Loading from: ' Agg_Path])
    
    load([Agg_Path,'20200725_GRP_WaterN2.mat'])
    disp('Data is now in Workspace')
end


%% Select Data

%Which one you want to view: USER DEFINED
run = 6;

%Trial Time and Number Descriptions
Trial_Demarc = {'1/8/2020 12:15:00 PM' '1/8/2020 3:15:00 PM';   %1
    '1/8/2020 6:22:00 PM' '1/8/2020 7:40:00 PM';                %2
    '1/8/2020 8:50:00 PM' '1/9/2020 12:01:00 AM';               %3
    '1/9/2020 1:15:00 PM' '1/9/2020 4:18:00 PM';                %4
    '1/9/2020 8:08:00 PM' '1/9/2020 10:24:00 PM';               %5
    '1/9/2020 11:25:00 PM' '1/10/2020 4:30:00 AM';              %6
    '1/10/2020 10:47:00 AM' '1/10/2020 1:17:00 PM';};           %7
Trial_Names = {'1' '2' '3' '4' '5' '7' '10'}';

%Visualization preferences
Run(1).plims = [-10 250 850 1500 2150];       %lower limits pressure plot
Run(1).pwidth = 200;                          %pressure plot height
Run(1).dpwindow = [-1200 1200];               %derivative plot limits
Run(1).FBEfilter = [0 0 0 0 0 0 1 0 0];       %FBE band weighting
Run(1).deltaT = 5;                            %time tick mark delta
Run(1).DAScolor = [0 70];                     %caxis for DAS

Run(2).plims = [-10 250 850 1500 2150];       
Run(2).pwidth = 200;                          
Run(2).dpwindow = [-1200 1200];               
Run(2).FBEfilter = [0 0 0 0 0 0 1 0 0];       
Run(2).deltaT = 5;
Run(2).DAScolor = [0 70];                     

Run(3).plims = [-10 250 850 1450 2150];
Run(3).pwidth = 200;
Run(3).dpwindow = [-350 350];
Run(3).FBEfilter = [0 0 .45 .45 0 .05 .05 0 0];
Run(3).deltaT = 10;
Run(3).DAScolor = [0 70];

Run(4).plims = [-10 250 850 1500 2150];
Run(4).pwidth = 300;
Run(4).dpwindow = [-1800 1800];
Run(4).FBEfilter = [0 0 0 0 0 1 0 0 0];
Run(4).deltaT = 10;
Run(4).DAScolor = [0 300];

Run(5).plims = [-10 250 850 1500 2150];
Run(5).pwidth = 500;
Run(5).dpwindow = [-1800 1800];
Run(5).FBEfilter = [0 0 0 0 0 1 0 0 0];
Run(5).deltaT = 10;
Run(5).DAScolor = [0 300];

Run(6).plims = [-10 250 850 1450 2150];
Run(6).pwidth = 400;
Run(6).dpwindow = [-250 250];
Run(6).FBEfilter = [0 0 .45 .45 0 .05 .05 0 0];
Run(6).deltaT = 10;
Run(6).DAScolor = [0 70];

Run(7).plims = [-10 250 850 1450 2150];
Run(7).pwidth = 700;
Run(7).dpwindow = [-1200 1200];
Run(7).FBEfilter = [0 0 0 0 0 1 0 0 0];
Run(7).deltaT = 10;
Run(7).DAScolor = [0 1000];

%% Process

%STEP 1: Process the higher dim data of DAS and DTS
%-------
%pull the timeseries subset and query dimensions for higher dim data
%FBE
FBE_tsout = getsampleusingtime(FBE_ts,Trial_Demarc{run,1},Trial_Demarc{run,2});
[FBE_dim_depths,FBE_dim_bands,FBE_dim_time]=size(FBE_tsout.Data);

%DTS
DTS_tsout = getsampleusingtime(DTS_ts,Trial_Demarc{run,1},Trial_Demarc{run,2});
[DTS_dim_depths,DTS_dim_bands,DTS_dim_time]=size(DTS_tsout.Data);

%Pason
start = datetime(Trial_Demarc{run,1},'Format','MM/dd/uuuu hh:mm:ss aa');
stop = datetime(Trial_Demarc{run,2},'InputFormat','MM/dd/uuuu hh:mm:ss aa');
TR = timerange(start,stop);
Pason_ttout = Pason_Total_10sec(TR,:);

%PTGauges
PTGauge_ttout = PTGauge_Total(TR,:);        %Reuse the timerange from above

%STEP 2: Convert timestamp to minutes of test
%-------
PTGauge_ttout.TimeMin = minutes(PTGauge_ttout.TimeStamp-PTGauge_ttout.TimeStamp(1));
Pason_ttout.TimeMin = minutes(Pason_ttout.Time-Pason_ttout.Time(1));
FBE_tsout.UserData.TimeMin = minutes(1440*(FBE_tsout.Time-FBE_tsout.Time(1)));
DTS_tsout.UserData.TimeMin = minutes(1440*(DTS_tsout.Time-DTS_tsout.Time(1)));


%STEP 3: Generate Matrices for Surf Presentation
%-------
%FBE
FBE_TimeMatrix = repmat(FBE_tsout.UserData.TimeMin,1,FBE_dim_depths);   %stamp cols
FBE_DepthMatrix = repmat(FBE_tsout.UserData.Depths',FBE_dim_time,1);    %stamp rows
FBE_DataMatrix = FBE_Flatten(FBE_tsout.Data,Run(run).FBEfilter);      %select display bands

%DTS
DTS_TimeMatrix = repmat(DTS_tsout.UserData.TimeMin,1,DTS_dim_depths);   %stamp cols
DTS_DepthMatrix = repmat(DTS_tsout.UserData.Depths',DTS_dim_time,1);    %stamp rows
DTS_DataMatrix = squeeze(DTS_tsout.Data);   

%% Get sensor derivates

Signal = table2array(fillmissing(PTGauge_ttout,'linear'));
DiffFilt = zeros(1,60);
DiffFilt(1)=1;
DiffFilt(end)=-1;
PTGauge_ttoutd1 = 60*filter(DiffFilt,1,Signal);

DiffFilt2 = zeros(1,6);
DiffFilt2(1)=1;
DiffFilt2(end)=-1;
Pason_ttoutd1 = 60*filter(DiffFilt2,1,table2array(Pason_ttout));

%% visualize it

close all

f(1) = figure; 

%Some control variables across the plots
plims = Run(run).plims;
pwidth = Run(run).pwidth;
dpwindow = Run(run).dpwindow;
deltaT = Run(run).deltaT;
DAScolor = Run(run).DAScolor;

bins_v = 9;
LineThick = 1.5;
ticks = minutes([Pason_ttout.TimeMin(1):deltaT:Pason_ttout.TimeMin(end)]);

%Visualize the FBE Data in Surf Form
h(1) = subplot(bins_v,1,[1 2]);    
    s = surf(FBE_TimeMatrix,FBE_DepthMatrix ,FBE_DataMatrix','EdgeColor','none');
    ylabel('Depth [ft]');zlabel('DAS [dB]');
    view(0,-90)     %typical depth vs. time orientation with surface on top
    %colorbar
    colormap(jet)
    caxis(DAScolor) %tighten coloration
    ylim([0 5025])
    xticks(ticks)
    % set(gca,'xticklabel',{[]})
    c1 = colorbar;
    c1.Location = 'East';
    c1.Position = [.91 .77 .005 .15];
    c1.Label.String = 'Acoustic Energy';
    c1.Label.Position = [3.75 35.5 0];
    title(['Trial ' Trial_Names{run}])
    % alpha(s,'z')
    % set(s,'alphadatamapping','scaled')
    % h(1).ALim = [0 1E3];

%Visualize the DTS in Surf Form
h(2) = subplot(bins_v,1,3);   
    s = surf(DTS_TimeMatrix,DTS_DepthMatrix ,DTS_DataMatrix','FaceAlpha',1,'EdgeColor','none');
    ylabel('Depth [ft]');zlabel('DAS [dB]');
    xticks(ticks)
    % set(gca,'xticklabel',{[]})
    %title(['DAS Trial ' Trial_Names{run}])
    %caxis([15 1E4]) %tighten coloration
    view(0,-90)     %typical depth vs. time orientation with surface on top
    c2 = colorbar;
    c2.Location = 'East';
    c2.Position = [.91 .6837 .005 .05];
    c2.Label.String = [char(176) 'F'];
    c2.Label.Position = [3.75 91.5 0];
    colormap(jet)
    ylim([0 5072])


% 5024ft sensor
h(3) = subplot(bins_v,1,bins_v-5);
    hold on
    yyaxis left
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttout.P5024ft,'DisplayName','P5024ft','LineWidth',LineThick)
    ylim([plims(5),plims(5)+pwidth])
    ylabel('P5024ft [PSI]');
    grid on
    xticks(ticks)
    yticks([plims(5):(pwidth/4):plims(5)+pwidth])

    yyaxis right
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttoutd1(:,1),'r','DisplayName','dP5024ft')
    ylim(dpwindow)
    yticks([dpwindow(1):(dpwindow(2)-dpwindow(1))/4:dpwindow(2)])
    ylabel('dP/dt [PSI/min]');
    set(gca,'xticklabel',{[]})
    hold off

% 3502ft sensor
h(4) = subplot(bins_v,1,bins_v-4);
    hold on
    yyaxis left
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttout.P3502ft,'DisplayName','P3502ft','LineWidth',LineThick)
    ylim([plims(4),plims(4)+pwidth])
    ylabel('P3502ft [PSI]');
    grid on
    xticks(ticks)
    yticks([plims(4):(pwidth/4):plims(4)+pwidth])

    yyaxis right
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttoutd1(:,3),'r','DisplayName','dP3502ft')
    ylim(dpwindow)
    yticks([dpwindow(1):(dpwindow(2)-dpwindow(1))/4:dpwindow(2)])
    ylabel('dP/dt [PSI/min]');
    set(gca,'xticklabel',{[]})
    hold off


% 2022ft sensor
h(5) = subplot(bins_v,1,bins_v-3);
    hold on
    yyaxis left
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttout.P2022ft,'DisplayName','P2022ft','LineWidth',LineThick)
    ylim([plims(3),plims(3)+pwidth])
    ylabel('P2022ft [PSI]');
    grid on
    xticks(ticks)
    yticks([plims(3):(pwidth/4):plims(3)+pwidth])

    yyaxis right
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttoutd1(:,5),'r','DisplayName','dP2022ft')
    ylim(dpwindow)
    yticks([dpwindow(1):(dpwindow(2)-dpwindow(1))/4:dpwindow(2)])
    ylabel('dP/dt [PSI/min]');
    set(gca,'xticklabel',{[]})
    hold off



% 487ft sensor
h(6) = subplot(bins_v,1,bins_v-2);
    hold on
    yyaxis left
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttout.P487ft,'DisplayName','P487ft','LineWidth',LineThick)
    ylim([plims(2),plims(2)+pwidth])
    ylabel('P487ft [PSI]');
    grid on
    xticks(ticks)
    yticks([plims(2):(pwidth/4):plims(2)+pwidth])

    yyaxis right
    plot(minutes(PTGauge_ttout.TimeMin),PTGauge_ttoutd1(:,7),'r','DisplayName','dP487ft')
    ylim(dpwindow)
    yticks([dpwindow(1):(dpwindow(2)-dpwindow(1))/4:dpwindow(2)])
    ylabel('dP/dt [PSI/min]');
    set(gca,'xticklabel',{[]})
    hold off



% choke
h(7) = subplot(bins_v,1,bins_v-1);
    hold on
    yyaxis left
    plot(minutes(Pason_ttout.TimeMin),Pason_ttout.CORETECUPSTREAM,'DisplayName','Choke','LineWidth',LineThick)
    ylim([plims(1),plims(1)+pwidth])
    ylabel('Choke [PSI]');
    set(gca,'xticklabel',{[]})
    grid on
    xticks(ticks)
    yticks([plims(1):(pwidth/4):plims(1)+pwidth])

    yyaxis right
    plot(minutes(Pason_ttout.TimeMin),Pason_ttoutd1(:,7),'r','DisplayName','dchoke')
    ylim(dpwindow)
    yticks([dpwindow(1):(dpwindow(2)-dpwindow(1))/4:dpwindow(2)])
    ylabel('dP/dt [PSI/min]');
    set(gca,'xticklabel',{[]})
    hold off

%Pump strokes
h(8) = subplot(bins_v,1,bins_v);
    plot(minutes(Pason_ttout.TimeMin),Pason_ttout.Strokes2,'k','LineWidth',LineThick)
    ylabel('Pump 2 [SPM]');
    %title('Pason Data')
%     xtickangle(45)
    ylim([-10 max(Pason_ttout.Strokes2)+10])
    grid on
    xticks(ticks)

%Link all the time axes and crop to the time window of interest
linkaxes(h,'x');
xlim(minutes([Pason_ttout.TimeMin(1),Pason_ttout.TimeMin(end)]));




