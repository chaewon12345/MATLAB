% ========== 1. 두 파일 불러오기 ==========
grids = readtable('korea_grids_0.01deg.csv');       % 기준 격자
slope = readtable('slope_by_grid.csv');             % 평균 경사도

% ========== 2. grid_id 기준으로 병합 ==========
% slope_by_grid의 mean_slope를 기준 그리드로 join
merged = outerjoin(grids, slope, ...
    'Keys', 'grid_id', ...
    'MergeKeys', true);

% ========== 3. 저장 ==========
writetable(merged, 'korea_grids_with_slope.csv');
fprintf("✅ 병합 완료: korea_grids_with_slope.csv\n");