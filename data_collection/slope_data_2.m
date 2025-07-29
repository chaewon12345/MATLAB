% ========== 1. 데이터 불러오기 ==========
load('latlon_grids.mat');  % lat_grid, lon_grid
[Z, R] = readgeoraster('Slope_All.tif', 'OutputType', 'single', 'StandardizeMissing', false);
grids = readtable('korea_grids_0.01deg.csv');  % 전체 격자
spei = readtable('korea_spei06_recent_avg_all.csv');  % 육지 마스크용

% ========== 2. 육지 마스크 설정 ==========
is_land = ~isnan(spei.spei_recent_avg);
land_ids = spei.grid_id(is_land);  % 유효한 grid_id 추출
is_valid = ismember(grids.grid_id, land_ids);  % 육지 격자만 true

% ========== 3. 설정 ==========
saveStep = 5000;
checkpoint_file = 'checkpoint.mat';
savePrefix = 'slope_partial_';
numGrids = height(grids);
meanSlope = nan(numGrids, 1);  % 결과 배열

% ========== 4. 체크포인트 불러오기 or 초기화 ==========
if isfile(checkpoint_file)
    load(checkpoint_file, 'lastIndex', 'meanSlope');
    fprintf("🔁 이전 체크포인트 불러옴 (lastIndex = %d)\n", lastIndex);
    startIdx = lastIndex + 1;
else
    fprintf("🆕 새로운 계산 시작\n");
    startIdx = 1;
end

% ========== 5. 루프 시작 ==========
tic
for i = startIdx:numGrids
    % 바다인 경우 스킵
    if ~is_valid(i)
        continue
    end

    latMin = grids.lat_min(i);
    latMax = grids.lat_max(i);
    lonMin = grids.lon_min(i);
    lonMax = grids.lon_max(i);

    mask = (lat_grid >= latMin) & (lat_grid <= latMax) & ...
           (lon_grid >= lonMin) & (lon_grid <= lonMax);

    values = Z(mask);
    values = values(~isnan(values));

    if ~isempty(values)
        meanSlope(i) = mean(values);
    end

    % 진행 이모지
    if mod(i, 100) == 0
        fprintf("📦 진행 중: %6d / %6d (%.2f%%)\n", i, numGrids, i/numGrids*100);
    end

    % 주기적 저장
    if mod(i, saveStep) == 0
        partial = table(grids.grid_id(1:i), meanSlope(1:i), ...
            'VariableNames', {'grid_id', 'mean_slope'});
        fname = sprintf('%s%d.csv', savePrefix, i);
        writetable(partial, fname);
        fprintf("✅ 저장 완료: %s\n", fname);

        % 체크포인트 저장
        lastIndex = i;
        save(checkpoint_file, 'lastIndex', 'meanSlope');
    end
end
toc

% ========== 6. 최종 저장 ==========
result = table(grids.grid_id, meanSlope, ...
    'VariableNames', {'grid_id', 'mean_slope'});
writetable(result, 'slope_by_grid.csv');
fprintf("🎉 전체 평균 경사도 저장 완료: slope_by_grid.csv\n");

% 체크포인트 삭제
if isfile(checkpoint_file)
    delete(checkpoint_file);
end

