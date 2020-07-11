%% Load Data

FBE_Path = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\Scratch Data\';
FBE_File = 'SLB_FBE_WaterN2.mat';
load([FBE_Path FBE_File]);

Agg_Path = 'C:\Users\charl\OneDrive\Projects\NAS GRP\';
Agg_File = 'GRP_AggregateData.mat';
load([Agg_Path Agg_File]);

%% Reformat FBE Data

for Pair=1:4

    %concatenate the LowFreq with the FBE's
    FBE_Data = cat(3,FileSet(Pair).data,FileSet(Pair+4).data);
    
    %Fix last time being NaT
    FileSet(Pair).time(end) = FileSet(Pair).time(end-1) + seconds(10);  %add 10sec from last point
    FBE_Time = string(FileSet(Pair).time);                              %convert to datestrings
    
    %permute to get the dims aligned prior to timeseries construct
    FBE_DataRot = permute(FBE_Data,[1 3 2]);
    
    %make timeseries object
    ts = timeseries(FBE_DataRot,FBE_Time);
    
    %first one intializes, latter iterations append to make 1 object
    if (Pair == 1)
        FBE_ts = ts;
    else
        FBE_ts = append(FBE_ts,ts);
    end
    
end

FBE_ts.UserData.Depths = FileSet(1).depths;
FBE_ts.UserData.DepthUnit = 'ft';

%cleanup the import file, now that we have timeseries object
clear FileSet FBE_Data* Pair ts FBE_Time


%% Reformat DTS Data

DTS_ts = timeseries(DTS_Data,string(DTS_Time));
DTS_ts.UserData.Depths = table2array(DTS_Depths);
DTS_ts.UserData.DepthUnit = 'ft';

%cleanup the import file, now that we have timeseries object
clear DTS_Data

%% Cleanup the Pason Data

%issue with monotonic increasing
Pason_Total = sortrows(Pason_Total);

%% Select Data

%Which one you want to view: USER DEFINED
run = 6;
freq_band = 2;


%Trial Time and Number Descriptions
Trial_Demarc = {'1/8/2020 12:15:00 PM' '1/8/2020 3:15:00 PM';   %1
    '1/8/2020 6:22:00 PM' '1/8/2020 7:36:00 PM';                %2
    '1/8/2020 8:50:00 PM' '1/9/2020 12:01:00 AM';               %3
    '1/9/2020 1:15:00 PM' '1/9/2020 4:18:00 PM';                %4
    '1/9/2020 7:24:00 PM' '1/9/2020 10:24:00 PM';               %5
    '1/9/2020 11:25:00 PM' '1/10/2020 4:30:00 AM';              %6
    '1/10/2020 9:37:00 AM' '1/10/2020 1:17:00 PM';};            %7
Trial_Names = {'1' '2' '3' '4' '5' '7' '10'}';


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
Pason_ttout = Pason_Total(TR,:);

%PTGauges
PTGauge_ttout = PTGauge_Total(TR,:);        %Reuse the timerange from above



%STEP 2: Generate Matrices for Surf Presentation
%-------
%FBE
FBE_TimeVector = datetime(getabstime(FBE_tsout));
FBE_TimeMatrix = repmat(FBE_TimeVector,1,FBE_dim_depths);               %stamp cols
FBE_DepthMatrix = repmat(FBE_tsout.UserData.Depths',FBE_dim_time,1);    %stamp rows
FBE_DataMatrix = squeeze(FBE_tsout.Data(:,freq_band,:));                %pull freq   

%DTS
DTS_TimeVector = datetime(getabstime(DTS_tsout));
DTS_TimeMatrix = repmat(DTS_TimeVector,1,DTS_dim_depths);               %stamp cols
DTS_DepthMatrix = repmat(DTS_tsout.UserData.Depths',DTS_dim_time,1);    %stamp rows
DTS_DataMatrix = squeeze(DTS_tsout.Data);   




%% visualize it

close all

f(1) = figure; 

% set(f,'Position',[645,1481,1282,1480])

bins_v = 9;
filt_pts = 31;

h(1) = subplot(bins_v,1,[1 2]);
%Visualize the FBE Data in Surf Form
s = surf(FBE_TimeMatrix,FBE_DepthMatrix ,FBE_DataMatrix','FaceAlpha',1,'EdgeColor','none');
ylabel('Depth [ft]');zlabel('DAS [dB]');
set(gca,'xticklabel',{[]})
caxis([100 1E3]) %tighten coloration
view(0,-90)     %typical depth vs. time orientation with surface on top
%colorbar
colormap(jet)
ylim([0 5025])

title(['DAS Trial ' Trial_Names{run}])

h(2) = subplot(bins_v,1,3);
%Visualize the DTS in Surf Form
s = surf(DTS_TimeMatrix,DTS_DepthMatrix ,DTS_DataMatrix','FaceAlpha',1,'EdgeColor','none');
ylabel('Depth [ft]');zlabel('DAS [dB]');
set(gca,'xticklabel',{[]})
%title(['DAS Trial ' Trial_Names{run}])
%caxis([15 1E4]) %tighten coloration
view(0,-90)     %typical depth vs. time orientation with surface on top
%colorbar
colormap(jet)
ylim([0 5072])


% 5024ft sensor
h(3) = subplot(bins_v,1,bins_v-5);
hold on
yyaxis left
plot(PTGauge_ttout.TimeStamp,PTGauge_ttout.P5024ft,'DisplayName','P5024ft')
% ylim([500 450])
ylabel('P5024ft [PSI]');

% yyaxis right
% diff_P5024 = diff(medfilt1(PTGauge_ttout.P5024ft,filt_pts));
% plot(PTGauge_ttout.TimeStamp(1:end-1),diff_P5024,'r','DisplayName','dP5024ft')
% ylim([-1 1])
% ylabel('dP/dt [PSI/sec]');
% hold off
% set(gca,'xticklabel',{[]})


% 3502ft sensor
h(4) = subplot(bins_v,1,bins_v-4);
hold on
yyaxis left
plot(PTGauge_ttout.TimeStamp,PTGauge_ttout.P3502ft,'DisplayName','P3502ft')
% ylim([500 450])
ylabel('P3502ft [PSI]');

% yyaxis right
% diff_P3502 = diff(medfilt1(PTGauge_ttout.P3502ft,filt_pts));
% plot(PTGauge_ttout.TimeStamp(1:end-1),diff_P3502,'r','DisplayName','dP3502ft')
% ylim([-1 1])
% ylabel('dP/dt [PSI/sec]');
% hold off
% set(gca,'xticklabel',{[]})


% 2022ft sensor
h(5) = subplot(bins_v,1,bins_v-3);
hold on
yyaxis left
plot(PTGauge_ttout.TimeStamp,PTGauge_ttout.P2022ft,'DisplayName','P2022ft')
% ylim([500 450])
ylabel('P2022ft [PSI]');

% yyaxis right
% diff_P2022 = diff(medfilt1(PTGauge_ttout.P2022ft,filt_pts));
% plot(PTGauge_ttout.TimeStamp(1:end-1),diff_P2022,'r','DisplayName','dP2022ft')
% ylim([-1 1])
% ylabel('dP/dt [PSI/sec]');
% hold off
% set(gca,'xticklabel',{[]})



% 487ft sensor
h(6) = subplot(bins_v,1,bins_v-2);
hold on
yyaxis left
plot(PTGauge_ttout.TimeStamp,PTGauge_ttout.P487ft,'DisplayName','P487ft')
% ylim([250 450])
ylabel('P487ft [PSI]');

% yyaxis right
% diff_487 = diff(medfilt1(PTGauge_ttout.P487ft,filt_pts));
% plot(PTGauge_ttout.TimeStamp(1:end-1),diff_487,'r','DisplayName','dP487ft')
% ylim([-1 1])
% ylabel('dP/dt [PSI/sec]');
% hold off
% set(gca,'xticklabel',{[]})


% choke
h(7) = subplot(bins_v,1,bins_v-1);
hold on
yyaxis left
plot(Pason_ttout.Time,Pason_ttout.CORETECUPSTREAM,'DisplayName','Choke')
% ylim([-10 220])
ylabel('Choke Pressure [PSI]');
set(gca,'xticklabel',{[]})
% 
% yyaxis right
% diff_choke = diff(medfilt1(Pason_ttout.CORETECUPSTREAM,filt_pts));
% plot(Pason_ttout.Time(1:end-1),diff_choke,'r','DisplayName','dChoke')
% ylim([-1 1])
% ylabel('dP/dt [PSI/sec]');
% hold off
% set(gca,'xticklabel',{[]})


h(8) = subplot(bins_v,1,bins_v);
plot(Pason_ttout.Time,Pason_ttout.Strokes2)
ylabel('Pump 2 [SPM]');
%title('Pason Data')
xtickangle(45)
ylim([-10 1.1*max(Pason_ttout.Strokes2)])

linkaxes(h,'x');
xlim(datetime([Trial_Demarc{run,1};Trial_Demarc{run,2}]));
%title('Pressures')
% legend



