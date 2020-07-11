%% Setup and make datasets

load WaterN2-Data.mat

%pull the relevant sections and combine
Fill = RiseAndFill(:,1:120,3:9);
Rise = RiseAndFill(:,235:1387,3:9);
Bullhead1 = Bullhead(:,:,2:8);

Total = [Fill,3*Bullhead1,Rise];

dims = size(Total);

% Smooth out the data
Filtered = uint8(zeros(dims));

for i = 1:dims(3)
    
    Filtered(:,:,i) = medfilt2(Total(:,:,i),[3,3]);
    
end

%knock out bottom hole effects
F1 = Filtered(1:625,:,:);

%don't use the high frequency range
F2 = Filtered(1:625,:,1:5);

%% Render

% Create an array of camera positions around the unit circle
vec = linspace(0,2*pi(),120)';
myPosition = [cos(vec) sin(vec) ones(size(vec))];

%show volume
h = volshow(F1,Vconfig);
set(h,View)

v = VideoWriter('Rise.avi');
open(v);

for idx = 1:120
    % Update current view
    h.CameraPosition = myPosition(idx,:);
    
    Frame(idx) = getframe(gcf);
    writeVideo(v,Frame(idx));
end
   
close(v);


% fig = figure;
% movie(fig,Frame,2)
