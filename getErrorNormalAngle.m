%% Get error Normal angle
function error_normal_angle = getErrorNormalAngle(N, N_desired)
    fields = fieldnames(N);
    num_fields = length(fields);
    [row, col, ~] = size(N_desired);
    all_errors = zeros(row, col, num_fields);
    for i = 1:num_fields
        N_current = N.(fields{i}); 
        all_errors(:, :, i) = acos(min(max(sum(N_current .* N_desired, 3), -1), 1));
    end
    error_normal_angle = min(all_errors, [], 3);
end