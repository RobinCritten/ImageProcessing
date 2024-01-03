% Task 5: Robust method --------------------------
clear; close all;

%Load input images
I = imread('IMG_08.jpg');
GT = imread("IMG_08_GT.png");
%problems with 4,5,6,10

%Covert image to grayscale
I_gray = rgb2gray(I);

%Rescale image
[old_height, old_width] = size(I_gray); %get old height and width
scalar = 2; %scalar for which the image is being resized
new_height = ceil(old_height / 2); %calculate new height
new_width = ceil(old_width / 2); %calculate new width
new_I = zeros(new_height, new_width); %create array of zeros in which the new image will be stored

for i = 1:new_height %loop through each individual element of the new image array
    for j = 1:new_width

        y = i * scalar; %find corresponding coordinates in old image
        x = j * scalar;
        if y > old_height %checks to prevent non existing pixels being used in calculations
            y = old_height;
        end
        if x > old_width %checks to prevent non existing pixels being used in calculations
            x = old_width;
        end
        
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

%Enhance image before binarisation
I2 = interpolated_I; %reasign image to I2 variable name for convenience
I2 = im2uint8(I2); %change to unit8 format so used image functions work
I2 = imcomplement(I2); %invert image so image functions work as intended

se = strel("disk",30); %structured element used in image functions
background = imopen(I2,se); %remove forground and save to new variable
I2 = I2 - background; %remove the background

I2 = imadjust(I2,[0 1],[0 1],0.6);
I2 = imsharpen(I2,"Radius",2,"Amount",11); %sharpen borders

bw = imbinarize(I2,0.65); %binarize image

se = strel("disk",6);
bw = imclose(bw,se); %close holes
bw = imfill(bw,"holes"); %fill holes
se = strel("disk",2);
bw = imerode(bw,se); %erode noise and seperate joined objects
se = strel("arbitrary",4);
bw = imopen(bw,se);
bw = bwareaopen(bw,70); %remove salt


L = bwlabel(bw, 8); %label all blobs
labeled_bw = zeros(new_height,new_width,3); %empty matrix
%get stats of blobs
stats = regionprops("table",bw, ...
    "MajorAxisLength","MinorAxisLength");
numberOfBlobs = size(stats, 1);
major = stats.MajorAxisLength;
minor = stats.MinorAxisLength;

ratios = []; %list of ratios

%itterate through each blob
for i=1:numberOfBlobs
    ratio = (minor(i)/major(i)); %calculate ratio of minor and major axis
    %asign colour depending on result of ratio
    if ratio >= 0.8
        c = "r";
    end
    if 0.2 <= ratio && ratio < 0.8
        c = "g";
    end
    if ratio < 0.2
        c = "b";
    end
    [a,b] = find(L==i);
    ab = [a b];

    [m,n] = size(ab);
    %loop through coords of blob
    %asign colour to pixels
    for k=1:m
        if c == "r"
            labeled_bw(ab(k,1),ab(k,2),1) = 1;
        end
        if c == "g"
            labeled_bw(ab(k,1),ab(k,2),2) = 1;
        end
        if c == "b"
            labeled_bw(ab(k,1),ab(k,2),3) = 1;
        end
    end
end

figure("Name","Object Recognition"),imshow(labeled_bw); %display image
figure("Name","Montage"),subplot(2,2,1),imshow(interpolated_I)
subplot(2,2,2),imshow(I2)
subplot(2,2,3),imshow(bw)
subplot(2,2,4),imshow(labeled_bw)

% Task 6: Performance evaluation -----------------
% Step 1: Load ground truth data
%GT = imread("IMG_04_GT.png");

% To visualise the ground truth image, you can
% use the following code.
L_GT = label2rgb(GT, 'prism','k','shuffle');
figure, imshow(L_GT);

%Dice Score
%GT2 = im2double(GT);
GT2 = im2bw(GT,0.001);
diceScore = dice(bw,GT2) %Accuracy of image segments

realPos = (GT2==1);
realNeg = ~realPos;
predictedPos = (bw==1);
predictedNeg = ~predictedPos;
TP = sum(predictedPos & realPos); %Real and Predicted Values are both positive  
FP = sum(predictedPos & realNeg); %Prediction was positive but the real was negative
TN = sum(predictedNeg & realNeg); %Both real and prediction were negative
FN = sum(predictedNeg & realPos); %Negative Prediciton but real positive

Precision = TP/(TP+FP) %Accuracy of positive predictions
Recal = TP/(TP+FN) %Completeness of Positive Predictions

