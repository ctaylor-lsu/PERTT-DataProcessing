function [FBEdata] = SLV_FBEcsv_Import(FILENAME)
%SLV_FBEcsv_Import Import SLB FBE data from a csv file
%  hDvs_data = SLV_FBEcsv_Import(FILENAME) reads FBE data processed from a
%  DAS acquisition system (Interrogator).  First row is an identifier that
%  has the frequency band number the data is from; just a numbering, no
%  indication of the actual frequency values.  First column are the depths,
%  starting at row 3.  The second row, starting at column 2, are the
%  timestamps in MM/dd/yyyy hh:mm:ss'.  The data values are the FFT bin
%  values for that frequency band; floating point precision to the 1E-3.  
%
%  [FBEdata] = SLV_FBEcsv_Import(FILENAME) reads FBE csv in FILENAME, determines the
%  depths and the time values dimensions, imports the FBE data table.
%  Formats the time values to datetimes, packs the structure 'FBEdata' and
%  returns it: FBEdata.depths, FBEdata.time, FBEdata.data
%
%  Example:
%  [FBEdata] = SLV_FBEcsv_Import('Day1.csv')
%

% Function call parameters check
 if(nargin==0)
     error('There was no filename given')
 else
 end
 

 opts = detectImportOptions(FILENAME);
 
 %Determine number of columns (timestamps), import and format to datetime
 TimePts = length(opts.SelectedVariableNames)-1;    %empty first column on row 2

 TimeImport = readmatrix(FILENAME,'Range',[2 2 2 TimePts],'OutputType','datetime');
 
 time = datetime(TimeImport','InputFormat','dd/MMM/yyyy hh:mm:ss');
 
 FBEdata.time = time;
 
 %Read in the numerical data: depths and FBE data
 opts.DataLines(1) = 3;     %start at row below timestamps
 
 NumImport = readmatrix(FILENAME,opts);
 
 
 %Get dimensions of imported data, test format of last column
 %  last column should be all NaN
 
 NumImport_dims = size(NumImport);
 
 if(NumImport_dims(2)>TimePts && isnan(NumImport(1,end)))
     
     FBEdata.depths = NumImport(:,1);
     FBEdata.data = NumImport(:,2:(NumImport_dims(2)-1));
 else
     error('last column of numerical data was not formatted as expected')
 end
 
 
 
 
end