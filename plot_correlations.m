function plot_correlations(seed_masks, seed_vals, group_brain_matrix, mni_brain, empty_brain, brain_idx, studyname)
    
    mean_brain = mean(group_brain_matrix, 3); % mean correlation values for all participants in a study
    
    % disp(slices)
    
    % disp(num_slices)
    
    for j=1:numel(seed_masks)
        brain = mean_brain(j,:);
        % 
        % threshold = bonferroni(pvals(i,:));
        correlation_mask = empty_brain;
        correlation_mask(brain_idx) = brain;
        reshaped_brain = reshape(correlation_mask,[91,109,91]);
        num_slices = size(reshaped_brain,3);
        slices = round(linspace(15,num_slices-20, 6));
        t = tiledlayout(1,6, 'Padding','compact', 'TileSpacing','compact');
        disp(slices)
        for i=1:numel(slices)
            disp(slices(i))
            ax = nexttile(t);
            slice = reshaped_brain(:,:,slices(i));
            % mni_slice = mni_brain(:,:,slices(i));
            % [rows,cols] = find(slice);
            % subplot(1,6,i);
            % imshow(mni_slice, 'InitialMagnification', 'fit');
            hold on;
            imshow(slice)
            colormap("jet")
            % plot(cols, rows, 'r.');
            camroll(+90)
            hold off;
        end
        save_title = sprintf("/home/zachkaras/fmri/results/%s_seed_%d_correlation_slices.png", studyname, seed_vals(j));
        saveas(gcf, save_title);
    end
end