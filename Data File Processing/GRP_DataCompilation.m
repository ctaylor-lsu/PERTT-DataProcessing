%% Prep

clear all
close all

%% Parse Pason Data

FolderLoc = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\Well 2 SLB Trials 1-8-2020\';
FileList = {'Well 2 Flow Trial 1 SLB 1-8-2020.txt',...
    'Well 2 Flow Trial 2 SLB 1-8-2020.txt',...
    'Well 2 Flow Trial 3 SLB 1-8-2020.txt',...
    'Well 2 Flow Trial 4 SLB 1-9-2020.txt',...
    'Well 2 Flow Trial 7 SLB 1-9-2020.txt',...
    'Well 2 Flow Trial 100gpm-300psi-5bbl SLB 1-10-2020.txt',...
    'Well 2 Flow Trial 100gpm-300psi-5bbl SLB 1-10-2020 - 2.txt'};

FilesNum = length(FileList);

for File=1:FilesNum
    
    TargetFile = [FolderLoc,FileList{File}];
    
    Data = PasonImport(TargetFile);
    
    %Combine date and time columns to form datestamp
    Data.DATE.Format = 'uuuu-MM-dd HH:mm:ss';
    Data.TIME.Format = 'uuuu-MM-dd HH:mm:ss';
    myDatetime = Data.DATE + timeofday(Data.TIME);

    %build timetable from record data and datestamp
    Pason_Record = table2timetable(Data(:,3:13),'RowTimes',myDatetime);

    if(File==1)
        Pason_Total = Pason_Record; %intilize timetable
    else
        Pason_Total = [Pason_Total;Pason_Record];   %append timetable
    end
        
end

%cleanup workspace to preserve only needed timetables
clearvars -except Pason_Total

%% Parse SLB P-T Array

FolderLoc = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\LSU_Gas_Kick_Test_DTS_Gauge_Data_Day1-3_Jan8-10_2020\LSU_Gauge_PT_Data\';
FileList = {'LSU_Gauge_PT_487.35_ftMD_Jan8-10_2020.xlsx'...
    'LSU_Gauge_PT_2022.89_ftMD_Jan8-10_2020.xlsx',...
    'LSU_Gauge_PT_3502.22_.ftMD_Jan8-10_2020.xlsx',...
    'LSU_Gauge_PT_5024.06_.ftMD_Jan8-10_2020.xlsx'};

FilesNum = length(FileList);

for File=1:FilesNum
    
    TargetFile = [FolderLoc,FileList{File}];
    
    for Sheet=1:3
        
        %import extents of sheet
        Data = PTGaugeImport(TargetFile,Sheet,[2,99999]);

        PTGauge_Record = table2timetable(Data);

        %remove entries with no timestamp (end of data to extent)
        TF = ismissing(PTGauge_Record.TimeStamp);
        PTGauge_RecordTrimmed = PTGauge_Record(~TF,:);

        if(Sheet==1)
            PTGauge_DepthTotal = PTGauge_RecordTrimmed;
        else
            PTGauge_DepthTotal = [PTGauge_DepthTotal;PTGauge_RecordTrimmed];
        end
        
    end
    
    % Synchronize Times
    if(File==1)
        PTGauge_Total = PTGauge_DepthTotal; %initiliaze timetable
    else
        PTGauge_Total = synchronize(PTGauge_Total,PTGauge_DepthTotal);
    end
    
end

%Rename table fields
PTGauge_Total.Properties.VariableNames={'P487ft','T487ft',...
    'P2022ft','T2022ft',...
    'P3502ft','T3502ft',...
    'P5024ft','T5024ft'};

%Populate units
PTGauge_Total.Properties.VariableUnits = {'PSI','F','PSI','F','PSI','F','PSI','F'};

%cleanup workspace to preserve only needed timetables
clearvars -except PTGauge_Total Pason_Total

%% Parse SLB DTS Data

FolderLoc = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\LSU_Gas_Kick_Test_DTS_Gauge_Data_Day1-3_Jan8-10_2020\LSU_DTS_Data\';
FileList = {'LSU_DTS_Test_Data_Jan08_10_2020_NO HEADERS.csv'...
   'ColumnHeaders.csv',...
   'RowHeaders.csv'};

TargetFile = [FolderLoc,FileList{1}];

DataCSV = csvread(TargetFile,0,0);

TargetFile = [FolderLoc,FileList{2}];

TimeCSV = csvread(TargetFile,0,0);
TimeStr = strcat(string(TimeCSV{:,1}),'|',string(TimeCSV{:,2}),'|',string(TimeCSV{:,3}));
Time = datetime(TimeStr,'InputFormat','MM/dd/yyyy|hh:mm:ss|aa');

DataTable = array2table(DataCSV');

DTS_Total = timetable(Time,DataTable);
DTS_Total.Properties
DTS_Total.Properties.VariableNames = {'DTS'};

% load('DTSdata.mat')
%% Parse SLB hDVS FBE data

Path = 'C:\Users\charl\Documents\HI SPEED SYNC\GRP_Public\Scratch Data\';
Folders = {'LSU_Day1_Test_Jan08_2020\LowFreqFbe_DM_TZ_Corrected',...
    'LSU_Day1_Test_Jan08_2020_Overnight\LowFreqFbe_DM_TZ_Corrected'...
    'LSU_Day2_Test_Jan09_2020\LowFreqFbe_DM_TZ_Corrected',...
    'LSU_Day3_Test_Jan10_2020\LowFreqFbe_DM_TZ_Corrected'...   
    'LSU_Day1_Test_Jan08_2020\FbePhase_DM_TZ_Corrected',...
    'LSU_Day1_Test_Jan08_2020_Overnight\FbePhase_DM_TZ_Corrected',...
    'LSU_Day2_Test_Jan09_2020\FbePhase_DM_TZ_Corrected',...
    'LSU_Day3_Test_Jan10_2020\FbePhase_DM_TZ_Corrected'};

%Some identifying info for the resultant structure
Day = [1,1,2,3,1,1,2,3]';
Type = {'LowFreqFbe','LowFreqFbe','LowFreqFbe','LowFreqFbe',...
    'FbePhase','FbePhase','FbePhase','FbePhase'}';

FileSet(:).Day = Type';

for DirNum=1:length(Folders)
    
    FolderLoc = [Path,Folders{DirNum}];
    
    FileList = dir(FolderLoc);
    FileList = FileList(3:end);

    %start the clock...
    tic

    disp(['Starting: ',Folders{DirNum}])
    
    for file=1:length(FileList)

        TargetFile = [FolderLoc,'\',FileList(file).name];

        % Parse the file
        FBEdata = SLV_FBEcsv_Import(TargetFile);

        % Pack the 3-dim matrix: X time, Y depth, Z freq band
        if(file==1)
            HVDS_Results = FBEdata.data;            %first band init matrix
        else
            HVDS_Results(:,:,file) = FBEdata.data;  %pack em in
        end

        %display progress of import
        disp(['   Completed ',num2str(file),' of ',num2str(length(FileList))])
        toc

        clear HVDS_Data*

    end

    %Pack the structure 
    FileSet(DirNum).data = HVDS_Results;
    FileSet(DirNum).depths = FBEdata.depths;
    FileSet(DirNum).time = FBEdata.time;
    FileSet(DirNum).files = FileList;

    %Give update on the directory progress
    disp('     Completed Dir')
    
    %cleanup a little before next iteration
    clear FBEdata
    
end


save([Path,'SLB_FBE_WaterN2.mat'],'FileSet','-v7.3');

%% SLB hDVS FBE and SEGY FileLists

FolderLoc = 'C:\Users\charl\OneDrive\Projects\NAS GRP\';
FileList = {'FileListProject.log'};

%Arrays to populate
fbephase={{},{}};
lowfreqfbe={{},{}};
segyphase={{},{}};

%time method
tic
    
for Files=1:length(FileList)
    
    FileNames = importFileList(FileList{Files});

    lines = size(FileNames,1);

    for row=1:lines

        if (strcmp(FileNames.code{row}(1:3),'LSU'))         %FOLDER

            FolderString = FileNames.code{row};

            %ID the folder type and set STATE variable for sorting
            % Ignore the "corrected" folder contents
            if (sum(strfind(FolderString,'FbePhase')) ~= 0 && sum(strfind(lower(FolderString),'corrected')) == 0)
                STATE_Folder = 'FbePhase';
                DispString = sprintf('Found: %s',FolderString);
                disp(DispString)
                Time = toc;
%                DispString = sprintf('\t%d sec elapsed',Time);
%                disp(DispString)

            elseif (sum(strfind(FolderString,'LowFreqFbe')) ~= 0 && sum(strfind(lower(FolderString),'corrected')) == 0)
                STATE_Folder = 'LowFreqFbe';
                DispString = sprintf('Found: %s',FolderString);
                disp(DispString)
                Time = toc;
%                DispString = sprintf('\t%d sec elapsed',Time);
%                disp(DispString)

            elseif (sum(strfind(FolderString,'Segy')) ~= 0)
                STATE_Folder = 'SegyPhase';
                DispString = sprintf('Found: %s',FolderString);
                disp(DispString)
                Time = toc;
%                DispString = sprintf('\t%d sec elapsed',Time);
%                disp(DispString)

            else
                STATE_Folder = 'NoInterest';
                DispString = sprintf('Ignoring: %s',FolderString);
                disp(DispString)
            end      

        elseif (strcmp(FileNames.code{row},'-rwxrwxrwx'))   %FILE

            FileString = FileNames.name{row};

            %evaluate filtype and parse if it is of interest
            if(sum([strfind(FileString,'.fbe'),strfind(FileString,'.sgy')]) ~= 0)

                %parse filename based on Time and Date locations 
                T_pts = length(FileNames.name{row})-[32,14];    %time start/end
                Time = FileNames.name{row}(T_pts(1):T_pts(2));
    %             DateStamp = datetime(Time,'InputFormat','yyyyMMdd_HHmmss.SSS');

                switch lower(STATE_Folder)
                    case {'fbephase'}
                        fbephase = [fbephase;{Time,FileNames.name{row}}];

                    case {'lowfreqfbe'}
                        lowfreqfbe = [lowfreqfbe;{Time,FileNames.name{row}}];

                    case {'segyphase'}
                        segyphase = [segyphase;{Time,FileNames.name{row}}]; 

                    case {'nointerest'}
                        %Do nothing, folder is not of interest
                end

            else
                %Not of interest file (e.g. txt or log)
            end


        else
            %NOT folder/file

        end     %End file/folder IF sorting

    end         %End log file loop
end         %End file loop
toc         %Stop timing

%Create Timetables and combine each filelist into one

Inter_TZ = 'UTC';   %timezone for interrogator timestamps

times_fbe = datetime(fbephase(2:end,1),'InputFormat','yyyyMMdd_HHmmss.SSS','TimeZone',Inter_TZ);
times_fbe.TimeZone = 'America/Chicago';
TT_fbe = timetable(times_fbe,cell2mat(fbephase(2:end,2)));
TT_fbe.Properties.VariableNames = {'fbe'};

times_lowfreqfbe = datetime(lowfreqfbe(2:end,1),'InputFormat','yyyyMMdd_HHmmss.SSS','TimeZone',Inter_TZ);
times_lowfreqfbe.TimeZone = 'America/Chicago';
TT_lowfreqfbe = timetable(times_lowfreqfbe,cell2mat(lowfreqfbe(2:end,2)));
TT_lowfreqfbe.Properties.VariableNames = {'lowfreqfbe'};

times_segy= datetime(segyphase(2:end,1),'InputFormat','yyyyMMdd_HHmmss.SSS','TimeZone',Inter_TZ);
times_segy.TimeZone = 'America/Chicago';
TT_segyphase = timetable(times_segy,cell2mat(segyphase(2:end,2)));
TT_segyphase.Properties.VariableNames = {'segyphase'};

%combine
FileNameTable = synchronize(TT_fbe,TT_lowfreqfbe,TT_segyphase);

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


