function [Output] = FBE_Flatten(FBEtensor,filter)

% Accept the FBE M x N x P tensor that is organized as depth x freq band x
% time. Accept the filter to create the weighted mean of across the
% frequency bands; multiple acoustic energy by filter coefficient and get
% the mean.

% Author: Charles Taylor, 14JUL2020


%Test arguments in and create filter if not given
if nargin < 2 
    %Good balance filter for frequencies with no flow (static rise)
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




