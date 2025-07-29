%% ========== 1. 파일 불러오기 ==========
grids = readtable('korea_grids_0.01deg.csv');               % 전체 격자
spei = readtable('korea_spei06_recent_avg_all.csv');        % 육지 판단용 (NaN 여부 기준)
file_path = 'SMAP_L3_SM_P_20250630_R19240_001.h5';          % SMAP .h5 파일

%% ========== 2. 육지 격자만 추출 ==========
is_land = ~isnan(spei.spei_recent_avg);             % 육지 여부
land_ids = spei.grid_id(is_land);                   % 육지 grid_id 리스트
land_grids = grids(ismember(grids.grid_id, land_ids), :);  % 육지 격자만 추출
nGrids = height(land_grids);

%% ========== 3. SMAP 데이터 불러오기 ==========
lat = h5read(file_path, '/Soil_Moisture_Retrieval_Data_AM/latitude');
lon = h5read(file_path, '/Soil_Moisture_Retrieval_Data_AM/longitude');
sm  = h5read(file_path, '/Soil_Moisture_Retrieval_Data_AM/soil_moisture');

% 한반도 영역 필터링
mask = lat >= 33 & lat <= 39 & lon >= 124 & lon <= 132;
lat_k = lat(mask); lon_k = lon(mask); sm_k = sm(mask);

%% ========== 4. 육지 격자에 SMAP 수분값 매핑 ==========
smap_values = NaN(nGrids, 1);
for i = 1:nGrids
    dists = (lat_k - land_grids.center_lat(i)).^2 + ...
            (lon_k - land_grids.center_lon(i)).^2;
    [~, idx] = min(dists);
    smap_values(i) = sm_k(idx);
end

%% ========== 5. 최근접 보간기 준비 ==========
interp = scatteredInterpolant( ...
    land_grids.center_lon(~isnan(smap_values)), ...
    land_grids.center_lat(~isnan(smap_values)), ...
    smap_values(~isnan(smap_values)), ...
    'nearest', 'none');

%% ========== 6. 전체 격자에 대해 최종 수분값 생성 ==========
final_smap = NaN(height(grids), 1);

for i = 1:height(grids)
    gid = grids.grid_id(i);
    if ismember(gid, land_ids)
        % 육지인 경우
        match_idx = find(land_grids.grid_id == gid);
        val = smap_values(match_idx);
        if isnan(val)
            final_smap(i) = interp(grids.center_lon(i), grids.center_lat(i));  % 보간
        else
            final_smap(i) = val;  % 원본 사용
        end
    else
        % 바다는 무조건 NaN 유지
        final_smap(i) = NaN;
    end
end

%% ========== 7. 결과 저장 ==========
grids.smap_20250630_filled = final_smap;
writetable(grids, 'smap_20250630_all_grids_with_interpolated_land.csv');
fprintf("✅ 저장 완료: smap_20250630_all_grids_with_interpolated_land.csv\n");
