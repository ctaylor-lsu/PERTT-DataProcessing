function [Output] = FBE_Flatten(FBEtensor,filter)

if nargin < 2 
    %Good balance filter for frequencies
    filter = [0 .1 5 5 1 1 1 0 0];
else
end

%Reorder tensor to have time,depth,frequency band order
Data = permute(FBEtensor,[1,3,2]);
[m,n,p] = size(Data);

%initialize filter and populate with weights
filter_z = ones(1,1,9);
filter_z(1,1,:) = filter;

%replicate filter to size of data tensor
filter_n = repmat(filter_z,[m,n,1]);

%permute weights and compress to 2D matrix
Output = mean(filter_n.*Data,3);

end




