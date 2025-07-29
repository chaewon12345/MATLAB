% ========== CFIS 시뮬레이션 (이웃 캐시 사용 + 진행률 UI 포함) ==========
N_SIM = 100;
CHECKPOINT_FILE = 'cfis_land_checkpoint.mat';
ALPHA = 1.0;

fprintf("🌍 육지 격자 CFIS 시뮬레이션 시작...\n");

% 1. 입력 불러오기
all_data = readtable('input_data_set.csv');
land_info = readtable('NDVI_land_only.csv');
land_ids = land_info.grid_id;

% 2. 육지 필터링
is_land = ismember(all_data.grid_id, land_ids);
data = all_data(is_land, :);
nGrids = height(data);

% 3. 발화 확률 계산
pIgnite = 1 ./ (1 + exp(-( ...
    1.2 * data.NDVI + ...
    1.5 * data.spei_recent_avg + ...
    data.temp_C - ...
    2.0 * data.smap_20250630_filled - ...
    1.5 * data.humidity - ...
    data.precip_mm)));

% 4. 확산 확률 계산
wind_norm = min(data.wind_speed / 10, 1);
slope_norm = min(data.mean_slope / 45, 1);
fuel_norm = min(data.avg_fuelload_pertree_kg, 1);
pSpread = ALPHA * (0.4 * wind_norm + 0.4 * slope_norm + 0.2 * fuel_norm);

% 5. 저장된 이웃 불러오기
load('neighbors_cache_land.mat', 'neighbors');
fprintf("📦 이웃 정보 로딩 완료 (%d개 격자)\n", numel(neighbors));

% 6. 시뮬레이션 반복
spread_count = zeros(nGrids, 1);
startSim = 1;

if exist(CHECKPOINT_FILE, 'file')
    load(CHECKPOINT_FILE, 'spread_count', 'startSim');
    fprintf("✅ 체크포인트 불러옴 → %d회부터 재시작\n", startSim);
end

for sim = startSim:N_SIM
    fprintf("\n🔥 시뮬레이션 %d / %d\n", sim, N_SIM);

    fire = rand(nGrids, 1) < pIgnite;
    burned = fire;

    for i = 1:nGrids
        if fire(i)
            for j = neighbors{i}
                if rand() < pSpread(i)
                    burned(j) = true;
                end
            end
        end
    end

    spread_count = spread_count + burned;

    % 진행률 바 출력
    percent = sim / N_SIM;
    bar_length = 40;
    filled = round(percent * bar_length);
    bar_str = ['[', repmat('#', 1, filled), repmat('-', 1, bar_length - filled), ']'];

    fprintf("📊 %s %.1f%% | 평균 확산률: %.4f\n", bar_str, percent * 100, mean(spread_count / sim));

    % 7. 중간 저장
    if mod(sim, 10) == 0
        startSim = sim + 1;
        save(CHECKPOINT_FILE, 'spread_count', 'startSim', '-v7.3');

        partial_result = table(data.grid_id, pIgnite, spread_count, ...
            repmat(sim, nGrids, 1), spread_count / sim, ...
            'VariableNames', {'grid_id', 'Pignite', 'BurnedCount', 'SimTotal', 'Pspread'});

        fname = sprintf('cfis_land_%d.csv', sim * nGrids);
        writetable(partial_result, fname);
        fprintf("💾 중간 저장 완료 → %s\n", fname);
    end
end

% 8. 최종 저장
result = table(data.grid_id, pIgnite, spread_count, ...
    repmat(N_SIM, nGrids, 1), spread_count / N_SIM, ...
    'VariableNames', {'grid_id', 'Pignite', 'BurnedCount', 'SimTotal', 'Pspread'});

writetable(result, 'cfis_land_result.csv');
fprintf("🎯 최종 결과 저장 완료 → cfis_land_result.csv\n");
