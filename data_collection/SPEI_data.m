%% SPEI 전체 격자에 대한 최근 6개월 평균값 계산 (중간 저장/이어하기)

% 1. 격자 데이터 불러오기
grid_table = readtable('korea_grids_0.01deg.csv');
num_grids = height(grid_table);

% 2. NetCDF 데이터 불러오기
ncfile = 'spei06.nc';
lon = ncread(ncfile, 'lon');
lat = ncread(ncfile, 'lat');
time = ncread(ncfile, 'time');
spei = ncread(ncfile, 'spei');  % [lon x lat x time]

% 3. 최근 6개월 인덱스
recent_indices = (length(time)-5):length(time);

% 4. 체크포인트 불러오기 or 초기화
if exist('checkpoint.mat', 'file')
    load('checkpoint.mat', 'spei_recent_avg', 'start_idx');
    fprintf("🔄 체크포인트 감지: %d번 격자부터 이어서 계산 시작합니다.\n", start_idx);
else
    spei_recent_avg = nan(num_grids, 1);
    start_idx = 1;
end

% 5. 계산 루프
for g = start_idx:num_grids
    lat_c = mean([grid_table.lat_min(g), grid_table.lat_max(g)]);
    lon_c = mean([grid_table.lon_min(g), grid_table.lon_max(g)]);

    [~, lat_idx] = min(abs(lat - lat_c));
    [~, lon_idx] = min(abs(lon - lon_c));

    values = squeeze(spei(lon_idx, lat_idx, recent_indices));
    values(values > 1e30) = NaN;
    spei_recent_avg(g) = mean(values, 'omitnan');

    % 진행 로그
    if mod(g, 10000) == 0 || g == num_grids
        fprintf("🔁 %d / %d (%.1f%% 완료)\n", g, num_grids, 100 * g / num_grids);
    end

    % 5,000개마다 저장 (더 자주 저장하고 싶다면 줄이세요)
    if mod(g, 5000) == 0 || g == num_grids
        start_idx = g + 1;  % 다음에 이어서 시작할 인덱스
        save('checkpoint.mat', 'spei_recent_avg', 'start_idx');
    end
end

% 6. 최종 저장
result_table = table(grid_table.grid_id, spei_recent_avg, ...
    'VariableNames', {'grid_id', 'spei_recent_avg'});
writetable(result_table, 'korea_spei06_recent_avg_all.csv');

% 7. 완료 후 체크포인트 삭제
if exist('checkpoint.mat', 'file')
    delete('checkpoint.mat');
end

disp("✅ 전체 계산 완료. 결과 저장됨: korea_spei06_recent_avg_all.csv");
