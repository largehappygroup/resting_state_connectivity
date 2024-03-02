original = niftiread('utrun_01.nii');
corrected = niftiread('utprun_01.nii');

og_timecourse = squeeze(original(20,20,20,:));
new_timecourse = squeeze(corrected(20,20,20,:));



figure
hold on
subplot(2,1,1)
plot(og_timecourse)

subplot(2,1,2)
plot(new_timecourse)
