% This script cleans up the processed data from GRP_DataCompilation
% Issues found with the data:

% 1) Time alignment when plotting was best resolved by using timeseries 
%     objects for the FBE and DTS.
% 2) Pason data had a monotonic increasing issue with the 10 second data; 
%     all the timestamps were there but there was an ordering issue.
% 3) SLB PT Gauges has a lot of dropped timestamps and 08JAN had timestamp 
%     issues.


%% Load Data

FBE_Path = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\Scratch Data\';
FBE_File = 'SLB_FBE_WaterN2.mat';
load([FBE_Path FBE_File]);

Agg_Path = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\Scratch Data\';
Agg_File = 'GRP_AggregateData.mat';
load([Agg_Path Agg_File]);

%% Reformat FBE Data to timeseries object

for Pair=1:4

    %concatenate the LowFreq with the FBE's
    FBE_Data = cat(3,FileSet(Pair).data,FileSet(Pair+4).data);
    
    %Fix last time being NaT
    FileSet(Pair).time(end) = FileSet(Pair).time(end-1) + seconds(10);  %add 10sec from penultimate point
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
FBE_ts.UserData.Bands = {'LowFreqFBE','Band-00','Band-01','Band-02','Band-03',...
    'Band-04','Band-05','Band-06','Band-07'};

%cleanup the import file, now that we have timeseries object
clear FileSet FBE_Data* Pair ts FBE_Time


%% Reformat DTS Data  to timeseries object

DTS_ts = timeseries(DTS_Data,string(DTS_Time));
DTS_ts.UserData.Depths = table2array(DTS_Depths);
DTS_ts.UserData.DepthUnit = 'ft';

%cleanup the import file, now that we have timeseries object
clear DTS_Data

%% Cleanup the Pason Data

%issue with monotonic increasing, but everything has timestamps
Pason_Total_10sec = sortrows(Pason_Total);

%% Correct the PT Gauge 3502ft sensor fro 08JAN 
% the sensor only had readings every minute, with NaN between

FolderLoc = 'C:\Users\charl\Louisiana State University\Team-PETE-GRP - General\Well 2 Circulation Trials 1.8.2020-1.10.2020\SLB_DTS_Gauge_Data_Day1-3_Jan8-10_2020\LSU_Gauge_PT_Data\';
FileList = {'LSU_Gauge_PT_3502.22_.ftMD_Jan8-10_2020_rev.xlsx'};

TargetFile = [FolderLoc,FileList{1}];

%import extents of sheet
Data = PTGaugeImport(TargetFile,1,[2,999999]);

PTGauge_Record = table2timetable(Data);

%remove entries with no timestamp (end of data to extent)
TF = ismissing(PTGauge_Record.TimeStamp);
PTGauge_RecordTrimmed = PTGauge_Record(~TF,:);

%remove the fields that are there now
PTGauge_Total = removevars(PTGauge_Total,{'P3502ft','T3502ft'});

%add the data that Toba resent with all the timestamps corrected
PTGauge_Total = synchronize(PTGauge_Total,PTGauge_RecordTrimmed);

%add names to these new fields
PTGauge_Total.Properties.VariableNames(7:8)= {'P3502ft','T3502ft'};

%rearrange the columns so that the depths are arranged correctly
PTGauge_Total = movevars(PTGauge_Total,{'P3502ft','T3502ft'},'Before',5);

%% Save the output

% Variables = {'DTS_ts','FBE_ts','Pason_Total_10sec','PTGauge_Total'};

save([Agg_Path,'20200725_GRP_WaterN2.mat'],'DTS_ts','FBE_ts','Pason_Total_10sec','PTGauge_Total','-v7.3');




