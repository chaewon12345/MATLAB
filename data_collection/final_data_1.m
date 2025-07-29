% === 1. 파일 불러오기 ===
land = readtable('only_land_grid.csv');  % 육지 격자 ID 목록
cfis = readtable('cfis_land_result_percell_6.csv');  % CFIS 시뮬레이션 결과
input = readtable('input_data_set.csv');  % 전체 지표 포함 원본 데이터

% === 2. 육지 격자만 필터링 ===
is_land = ismember(cfis.grid_id, land.grid_id);
cfis_land = cfis(is_land, :);

% === 3. 필요한 위치 정보만 추출 ===
vars_to_add = {'grid_id', 'lat_min', 'lat_max', 'lon_min', 'lon_max', 'center_lat', 'center_lon'};
input_coords = input(:, vars_to_add);

% === 4. 병합 (grid_id 기준) ===
merged = outerjoin(cfis_land, input_coords, 'Keys', 'grid_id', ...
    'MergeKeys', true, 'Type', 'left');

% === 5. 열 순서 조정: grid_id 바로 뒤에 위치 정보 배치 ===
% 기존 열 목록
original_vars = merged.Properties.VariableNames;

% 위치 정보 열
coord_vars = {'lat_min', 'lat_max', 'lon_min', 'lon_max', 'center_lat', 'center_lon'};

% 새 순서: grid_id → 위치정보 → 나머지 열
grid_idx = find(strcmp(original_vars, 'grid_id'));
rest_vars = setdiff(original_vars, ['grid_id', coord_vars], 'stable');
new_order = [{'grid_id'}, coord_vars, rest_vars];

% 열 순서 재정렬
final = merged(:, new_order);

% === 6. 결과 저장 ===
writetable(final, 'cfis_land_result_percell_6_with_coords.csv');
fprintf("✅ 최종 결과 저장 완료 → cfis_land_result_percell_6_with_coords.csv\n");
