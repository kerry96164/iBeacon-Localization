% Clear workspace and close all figures
clear;
clc;
close all;

% Define the filename
filename = 'coordinate-location_data.txt';
%filename = 'area-location_data.txt';

% Read the data from the file
data = readmatrix(filename);

% Extract X and Y coordinates
X = data(:, 1);
Y = data(:, 2);
[Xq, Yq] = meshgrid(unique(X), unique(Y));
[~,n] = size(data);
% Extract the Z values for each surface
for i = 3:n
    figure(i-2);
    Z = data(:, i);
    Zq = griddata(X, Y, Z, Xq, Yq, 'linear');
    surf(Xq, Yq, Zq, 'FaceAlpha', 0.5);
    zlim([-90 -50]);%coordinate
    %zlim([-75 -35]);%area
    xlabel('X');
    ylabel('Y');
    zlabel('RSSI');
    title(['Coordinate (iBeacon ',num2str(i-2),')']);
    saveas(gcf,['Coordinate',num2str(i-2)],'png')
end

