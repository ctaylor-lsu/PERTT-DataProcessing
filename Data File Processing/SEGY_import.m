


path='P:\DAS Data';
list=dir([path,'\*.sgy']);

NFFT=1024;
Volume = zeros(NFFT,4233,length(list));

for idx = 1:length(list)

    file = [list(idx).folder,'\',list(idx).name];

    [Data,SegyTraceHeaders,SegyHeader]=ReadSegy(file);
    
    Y = fft(Data,NFFT,1); 
    
    Volume(:,:,idx) = abs(Y);

end

