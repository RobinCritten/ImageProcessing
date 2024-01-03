clear; close all;

% Task 1: Pre-processing -----------------------
% Step-1: Load input image
I = imread('IMG_01.jpg');

% Step-2: Covert image to grayscale
I_gray = rgb2gray(I);

% Step-3: Rescale image
[old_height, old_width] = size(I_gray); %get old height and width
scalar = 2; %scalar for which the image is being resized
new_height = floor(old_height / 2); %calculate new height
new_width = floor(old_width / 2); %calculate new width
new_I = zeros(new_height, new_width); %create array of zeros in which the new image will be stored

for i = 1:new_height %loop through each individual element of the new image array
    for j = 1:new_width

        y = i * scalar; %find corresponding coordinates in old image
        x = j * scalar;
        
        %find the nearest pixels the the corresponding coordinates
        y_floor = y - 1;
        if y == old_height %checks to prevent non existing pixels being used in calculations
            y_ceil = old_height;
        else
            y_ceil = y + 1;
        end        
        x_floor = x - 1;
        if x == old_width
            x_ceil = old_width;
        else
            x_ceil = x + 1;
        end
        
        %interpolation calculation to find pixel value
        p = ((y_ceil - y)/(y_ceil-y_floor))*(((x_ceil - x)/(x_ceil-x_floor))*(I_gray(y_floor,x_floor)) ...
            + ((x - x_floor)/(x_ceil-x_floor))*(I_gray(y_floor,x_ceil))) + ...
        ((y - y_floor)/(y_ceil-y_floor))*(((x_ceil - x)/(x_ceil-x_floor))*(I_gray(y_ceil,x_floor)) + ...
        ((x - x_floor)/(x_ceil-x_floor))*(I_gray(y_ceil,x_ceil)));

        new_I(i,j) = p; %asign pixel value to new array of zeros
    end
end

interpolated_I = mat2gray(new_I); %turn the aray into a recognised image format
%Display Resized image
figure("Name","Interpolated image and Histogram"),subplot(2,1,1),imshow(interpolated_I); 

% Step-4: Produce histogram before enhancing
subplot(2,1,2),imhist(interpolated_I); %histogram of interpolated image

% Step-5: Enhance image before binarisation
I2 = interpolated_I; %reasign image to I2 variable name for convenience
I2 = im2uint8(I2); %change to unit8 format so used image functions work
I2 = imcomplement(I2); %invert image so image functions work as intended
se = strel("disk",20); %structured element used in image functions
background = imopen(I2,se); %remove forground and save to new variable
I2 = I2 - background; %remove the background
I2 = imadjust(I2); %contrast image
I2 = imsharpen(I2,"Radius",2,"Amount",5); %sharpen borders of forground objects
figure("Name","Enhanced Image and Histogram"),subplot(2,1,1),imshow(I2); %show enhanced image


% Step-6: Histogram after enhancement
subplot(2,1,2),imhist(I2); %show histogram of enhanced image

% Step-7: Image Binarisation
bw = imbinarize(I2); %binarize image

%remove background noise and close any open borders
bw2 = bwareaopen(bw,50);
se = strel("disk",3);
bw2 = imclose(bw2,se);

bw2 = imfill(bw2,"holes"); %fill holes
figure("Name","Binarized Image"),imshow(bw2); %show binarzed image

% Task 2: Edge detection ------------------------





boundaries = bwboundaries(bw2); %create list of boundaries
figure("Name","Boundaries"),imshow(bw2)
hold on
for k=1:numel(boundaries) %iterate through list and layer them onto the image
    b = boundaries{k};
    plot(b(:,2),b(:,1),"g",LineWidth=3);
end


% Task 3: Simple segmentation -------------------

L = bwlabel(bw2, 8); %label all blobs
coloredLabelsImage = label2rgb (L, 'hsv', 'k', 'shuffle'); %colour each blob a random colour
figure("Name","Segmented Image"),imshow(coloredLabelsImage); %display segmented image


% Task 4: Object Recognition --------------------


labeled_bw2 = zeros(new_height,new_width,3); %empty matrix

%get stats of blobs
stats = regionprops("table",bw2, ...
    "MajorAxisLength","MinorAxisLength");
numberOfBlobs = size(stats, 1);
major = stats.MajorAxisLength;
minor = stats.MinorAxisLength;

%itterate through each blob
for i=1:numberOfBlobs
    ratio = round(minor(i)/major(i)); %calculate ratio of minor and major axis
    %asign colour depending on result of ratio
    if ratio == 1
        c = "r";
    end
    if ratio == 0
        c = "g";
    end
    [a,b] = find(L==i);
    ab = [a b];

    [m,n] = size(ab);
    %loop through coords of blob
    %asign colour to pixels
    for k=1:m
        if c == "r"
            labeled_bw2(ab(k,1),ab(k,2),1) = 1;
        end
        if c == "g"
            labeled_bw2(ab(k,1),ab(k,2),2) = 1;
        end
    end
end

figure("Name","Object Recognition"),imshow(labeled_bw2); %display image


