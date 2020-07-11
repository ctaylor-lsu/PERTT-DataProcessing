
clear all
%% Import 

Folder='C:\Users\charl\OneDrive\Projects\NAS GRP\Water-N2 Data\N2_Gas_Fill_Gas_Rise\';

Contents=dir([Folder,'*.JPG']);
Items = length(Contents);


Images=1;
for img=1:Items
    
    if ~Contents(img).isdir
        
        File = [Folder,Contents(img).name];

        data=importdata(File);
        
        ImageBulk(Images).image = data;
        
        Images=Images+1;
        
    else 
    end
         
end

%% Crop and Recolor

% get Jet colormap
JetMap=colormap('Jet');
% Order=[1 3 7 2 5 8 4 6];

for Item=1:(Images-1)

    ImageCrop = ImageBulk(Item).image(190:834,195:1581,:);
    
    Numeric(:,:,Item) = rgb2ind(ImageCrop,JetMap);

end


%% Visualize

figure

h(1) = subplot(1,2,1);
image(ImageCrop)
colormap('gray')

h(2) = subplot(1,2,2);
imshow(squeeze(Numeric(:,:,8)))
%% Volume

Smoothed = smooth3(Numeric,'box',7);
fv = isosurface(Smoothed,10);
p1 = patch(fv,'FaceColor','red','EdgeColor','none');
xlabel('Time')
ylabel('Depth')
zlabel('Band')
%%
figure
contourslice(Smoothed,[],[],[1:8],8);

view(-10,-50) 
axis tight 
daspect([1,1,.2])
xlabel('Time')
ylabel('Depth')
zlabel('Band')

%% 
figure
volshow(Smoothed,config)





