% 


%% Load data
load('Water-N2_Trials_Parsed.mat','PTGauge_Total')

%% Process and test

%convert timetable to array for operations
GaugeData = table2array(PTGauge_Total);

%create logical array of NaN points
missing_records = isnan(GaugeData);

%sum the logical array to determine how many there are
missing_totals = sum(missing_records)';

%initialize list 
missing_list=cell([sum(missing_totals),2]);

%indexing variable for list
missing_tally = 1;

%Loop through time points (rows) and iterate across sensors (cols) testing 
%for NaN's in record and record time and sensor that dropped
% THERE IS AN ARRAY METHOD IF THIS IS GOING TO BE A REGULAR CALL
for i=1:length(PTGauge_Total.TimeStamp)
    
    for sensor=1:8
        if (missing_records(i,sensor))
            missing_list{missing_tally,1} = datestr(PTGauge_Total.TimeStamp(i));
            missing_list{missing_tally,2} = PTGauge_Total.Properties.VariableNames{1,sensor};
            missing_tally = missing_tally+1;
        else
            
        end
        
     end
        
end

%

%% Output

%by time
fid = fopen('MissingRecords.txt','w');
CT = missing_list.';
fprintf(fid,'%s %s\n', CT{:});
fclose(fid)
