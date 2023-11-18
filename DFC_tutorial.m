
% This Matlab exercise will illustrate basic concepts relating to dynamic
% characterization of functional connectivity. 
% Catie Chang

% (1) Load ROI time courses (693 timepoints x 268 rois). The TR of
% this dataset is 2.1 sec, and ROIs are extracted from the atlas of
% Shen et al., 2013.
roi_data = load('roi_data_268.txt');

% (2) "Static" connectivity: calculate and visualize the
% region-to-region correlation matrix, calculated over the entire
% time course:
corrs_static = corr(roi_data);

figure;
imagesc(corrs_static,[-0.8 0.8]);
title('static FC'); xlabel('ROI'); ylabel('ROI');


% (3) Calculate correlations within shorter intervals (sliding windows)
% across the scan. Use a window size of 28 poins (~1 min), with a
% 50% overlap between successive windows. Store the results in a 3D
% matlab array, of dimensions (# rois x # rois x # windows) = (268
% x 268 x 48), in this case.

winsize = 28; 
winshift = 14; 
corrs_dyn = [];
s1 = 1; sn = s1+winsize-1; ct = 1;
while sn < size(roi_data,1)
    [s1 sn]
    data_win = roi_data(s1:sn,:); 
    corrs_dyn(:,:,ct) = corr(data_win);
    s1 = s1+winshift;
    sn = s1+winsize-1;
    ct = ct+1;
end

% (4) Visualize your sliding-window correlation matrices as a
% movie. It is helpful to use the same color scale for each image
% you display.

figure; 
for kk=1:size(corrs_dyn,3);
    imagesc(corrs_dyn(:,:,kk),[-0.8 0.8]); colorbar;
    title(['window # ',num2str(kk)]); 
    xlabel('ROI'); ylabel('ROI');
    axis square;
    pause; 
end

% (5) Report some of your observations. How do these dynamic
% correlation matrices compare to the static FC matrix?



% (6) Plot the time course of correlation between nodes (ROIs) #107
% and #113. Set the colorbar range to [-1,1].
ii = 107; jj = 113; 
ts_1 = squeeze(corrs_dyn(ii,jj,:));

figure; 
subplot(211); 
plot(ts_1,'r.-');
xlabel('window #'); ylabel('corr coeff');
ylim([-1 1]);


% (7) Repeat for ROIs #42 and 188.
% Set the colorbar range to [-1,1].

ii = 42; jj = 188; 
ts_2 = squeeze(corrs_dyn(ii,jj,:));

subplot(212);
plot(ts_2,'b.-');
xlabel('window #'); ylabel('corr coeff');
ylim([-1 1]);


% (8) Calculate the variance of the sliding window time courses
% derived in parts (6-7).

var(ts_1)
var(ts_2)

% (9) Apply k-means clustering to the series of sliding-window
% matrices. Use k=4 clusters, and use the "kmeans"
% function in matlab (with default options for now).
%
% (hint: to form the input 'X' to k-means,
% vectorize the upper or lower triangle of each
% sliding-window matrix. The vector corresponding to window "t" 
% will form the "t"th row of X.)
%
% For future reference, a helpful toolbox for carrying
% out an analysis of dynamic connectivity states (including methods
% for selecting the number of clusters) is the dFNC toolbox in
% GIFT:
% https://trendscenter.org/trends/software/gift/docs/v4.0b_gica_manual.pdf

nclust = 4;
X = []; % will be # windows x # unique correlation pairs
for w=1:size(corrs_dyn,3)
    matr_w = corrs_dyn(:,:,w)';
    idx_ut = logical(triu(ones(size(matr_w)), 1));
    vec_w = matr_w(idx_ut);
    X(w,:) = vec_w;
end
[idx,C,sumd,d] = kmeans(X, nclust);

% (10) Inspect the centroids (reshaped back into matrices).

figure; 
centroid_mats = [];
for ii=1:nclust
    centr_mat_ii = diag(0.5*ones(268,1));
    centr_mat_ii(idx_ut) = C(ii,:);
    centroid_mats(:,:,ii) = (centr_mat_ii + centr_mat_ii');
    subplot(2,nclust,ii);
    imagesc(centroid_mats(:,:,ii),[-0.6 0.6]);
    title(['cluster ',num2str(ii)]);
    axis square;
end
subplot(2,1,2); stem(idx); xlabel('time win'); ylabel('clust no');



















