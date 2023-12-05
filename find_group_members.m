function indices = find_group_members(members, all_ids)
    % [~,indices] = ismember(all_ids, members);
    % indices = indices(indices > 0);
    on_the_list = ismember(all_ids, members);
    indices = find(on_the_list);
end