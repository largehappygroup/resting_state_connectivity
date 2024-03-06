% loading the nifti files
raw = "/home/zachkaras/fmri/three_studies_raw/001_151/utrun_01.nii";
unsmooth_path = "/home/zachkaras/fmri/three_studies_raw/out_001_151/raw_mc_epi2mni.nii.gz";
st_corrected = "st_corrected.nii";

raw_brain = niftiread(raw);
st_brain = niftiread(st_corrected);
unsmooth = niftiread(unsmooth_path);

% Slice Timing Corrected Images

% SLICE 29
% voxel 36,10,29,:
raw_series = squeeze(raw_brain(36, 10, 29, :));
st_series = squeeze(st_brain(36, 10, 29, :));
% st_series = squeeze(mid(36, 10, 29, :));

subplot(2,1,1);
plot(raw_series)
title("uncorrected time series for voxel (36,10,29)")

subplot(2,1,2);
plot(st_series);
title("slice timing correction for voxel (36,10,29)")
% saveas(gcf, "slice29_series.png")


% SLICE 30
% voxel (30,30,30,:)
raw_series = squeeze(raw_brain(30,30,30,:));
st_series = squeeze(st_brain(30,30,30,:));
st_series = squeeze(unsmooth(30,30,30,:));

subplot(2,1,1);
plot(raw_series)
title("uncorrected time series for voxel (30,30,30)")

subplot(2,1,2);
plot(st_series);
title("slice timing correction for voxel (30,30,30)")
% saveas(gcf, "slice30_series.png")


% SLICE 2
% voxel 3,48,2,:
raw_series = squeeze(raw_brain(3,48,2,:));
st_series = squeeze(st_brain(3,48,2,:));

% subplot(2,1,1);
% plot(raw_series)
% title("uncorrected time series for voxel (3,48,2)")
% 
% subplot(2,1,2);
% plot(st_series);
% title("slice timing correction for voxel (3,48,2)")
% saveas(gcf, "slice2_series.png")

% Motion Corrected Images
st_mc_brain = niftiread("st_mc.nii");

% MEAN
raw_avg = mean(raw_brain, 4); % averaging across 4th dimension of the data
st_mc_avg = mean(st_mc_brain, 4);

raw_slice = raw_avg(:,:,17);
st_mc_slice = st_mc_avg(:,:,17);

% subplot(2,1,1)
% imshow(raw_slice, [])
% colormap(jet);
% caxis([0 60]);
% title("Mean Uncorrected: Slice 17")
% set(gcf, 'Position', [100, 100, 800, 600])
% 
% subplot(2,1,2)
% imshow(st_mc_slice, [])
% colormap(jet);
% caxis([0 60]);
% title("Mean Motion Corrected: Slice 17")
% set(gcf, 'Position', [100, 100, 800, 600])
% saveas(gcf, "slice17_mean.png")

% STANDARD DEVIATION
% converting to double first
% raw_double = double(raw_brain);
raw_double = double(mid);
st_mc_double = double(unsmooth);

raw_stdev = std(raw_double,0,4);
st_mc_stdev = std(st_mc_double,0,4);

raw_slice = raw_stdev(:,:,35);
st_mc_slice = st_mc_stdev(:,:,35);

subplot(2,1,1)
imshow(raw_slice, [])
colormap(jet);
caxis([0 60]);
title("STD Uncorrected: Slice 17", 'FontSize', 18)
set(gcf, 'Position', [100, 100, 800, 600])

subplot(2,1,2)
imshow(st_mc_slice, [])
colormap(jet);
caxis([0 60]);
title("STD Motion Corrected: Slice 17", 'FontSize', 18)
set(gcf, 'Position', [100, 100, 800, 600])
% saveas(gcf, "slice17_std.png")

% TIME SERIES
raw_series = squeeze(raw_brain(15,20,17,:));
st_mc_series = squeeze(st_mc_brain(15,20,17,:));

% subplot(2,1,1)
% plot(raw_series)
% title("Raw Time series: voxel (15,20,17)", 'FontSize', 18)
% 
% subplot(2,1,2)
% plot(mc_series)
% title("Motion Corrected Time series: voxel(15,20,17)", 'FontSize', 18)
% saveas(gcf, "series_mc.png")

% Motion PARAMETERS
Motion = importdata("st_mc.nii.par");

% rotation
r = Motion(:,1);
p = Motion(:,2);
ya = Motion(:,3);

% translation
x = Motion(:,4);
y = Motion(:,5);
z = Motion(:,6);

% subplot(3,1,1)
% plot(r)
% title("Roll", 'FontSize', 16)
% 
% subplot(3,1,2)
% plot(p)
% title("Pitch", 'FontSize', 16)
% 
% subplot(3,1,3)
% plot(ya)
% title("Yaw", 'FontSize', 16)
% saveas(gcf, "rotations.png")


% subplot(3,1,1)
% plot(x)
% title("X-translation", 'FontSize', 16)
% 
% subplot(3,1,2)
% plot(y)
% title("Y-translation", 'FontSize', 16)
% 
% subplot(3,1,3)
% plot(z)
% title("Z-translation", 'FontSize', 16)
% saveas(gcf, "translations.png")

% Nuisance Regressors for One Voxel
n = size(Motion, 1); 
mean_offset = ones(n, 1); % storing mean offset as first column
linear_trend = (1:n)'; % capturing linear trends in the data
quad_trend = (1:n)'.^2; % quadratic trends in the data

X = [mean_offset, linear_trend, quad_trend, Motion]; % Full matrix of nuisance regressors
y = squeeze(st_mc_brain(12,20,1, :)); % timecourse to be corrected

model = fitlm(X, y); % finding the noise in the data
coefficients = model.Coefficients.Estimate(2:10); % coefficients for nuisance regressors

yhat = X*coefficients; % noise in the data
yr = y - yhat; % subtracting out the noise

% % plotting timecourses
% subplot(2,1,1)
% hold on
% p1 = plot(y, "blue", 'DisplayName', 'y');
% p2 = plot(yhat, "red", 'DisplayName', 'yhat');
% title("Uncorrected time course from voxel (12,20,1)", 'FontSize', 14)
% legend([p1,p2])
% hold off
% 
% subplot(2,1,2)
% plot(yr)
% title("Preprocessed data from voxel (12,20,1)", 'FontSize', 14)
% saveas(gcf, "preprocessed_series.png")

% Derivatives of Motion Parameters
dMP = diff(Motion);
dMP = [dMP(1,:); dMP];
Xp = [X, dMP];

model = fitlm(Xp, y); % finding the noise in the data
coefficients = model.Coefficients.Estimate(2:end); % coefficients for nuisance regressors

yhat = Xp*coefficients; % noise in the data
yr = y - yhat; % subtracting out the noise

% % plotting timecourses
% subplot(2,1,1)
% hold on
% p1 = plot(y, "blue", 'DisplayName', 'y');
% p2 = plot(yhat, "red", 'DisplayName', 'yhat');
% title("Uncorrected time course from voxel (12,20,1)", 'FontSize', 14)
% legend([p1,p2])
% hold off
% 
% subplot(2,1,2)
% plot(yr)
% title("Preprocessed data (with first derivative)", 'FontSize', 14)
% saveas(gcf, "preprocessed_series_deriv.png")

%% Nuisance Regression for All Voxels
Y = reshape(st_mc_brain, [(52*80*30),141])';

% Fitting all parameters simultaneously by solving the system of linear equations 
b = Xp\Y;

Yhat = Xp*b;
YC = Y-Yhat;

% reshaping data back to original dimensions
YC = reshape(YC', [52,80,30,141]);

% yc_double = double(YC);
yc_double = double(test);
yc_stdev = std(yc_double,0,4);
yc_slice = yc_stdev(:,:,40);

imshow(yc_slice, [])
colormap(jet);
caxis([0 60]);
title("STD Nuisance Regressed: Slice 17", 'FontSize', 18)
set(gcf, 'Position', [100, 100, 800, 600])
% saveas(gcf, "nuisance_regressed.png")

