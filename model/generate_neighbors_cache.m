% ========== 육지 격자 기준 이웃 계산 및 캐싱 (체크포인트 + 진행률 바 포함) ==========
land_info = readtable('NDVI_land_only.csv');
land_ids = land_info.grid_id;

data = readtable('input_data_set.csv');
is_land = ismember(data.grid_id, land_ids);
data = data(is_land, :);  % 육지 격자만 필터링

nGrids = height(data);
neighbors = cell(nGrids, 1);
BLOCK_SIZE = 10000;
startIdx = 1;

% 중간 저장된 블록 불러오기
for b = 1:floor(nGrids / BLOCK_SIZE)
    fname = sprintf('neighbors_%d.mat', b * BLOCK_SIZE);
    if exist(fname, 'file')
        load(fname, 'block_neighbors');
        neighbors(((b-1)*BLOCK_SIZE + 1):(b*BLOCK_SIZE)) = block_neighbors;
        startIdx = b * BLOCK_SIZE + 1;
        fprintf("✅ %s 불러옴 → 체크포인트 적용\n", fname);
    else
        break;
    end
end

fprintf("📍 이웃 계산 시작 (startIdx: %d / 전체: %d개 격자)\n", startIdx, nGrids);

% 진행률 초기화
bar_length = 40;

for i = startIdx:nGrids
    neighbors{i} = getNeighbors(i, data.center_lat, data.center_lon);

    % 진행률 바 표시
    percent = i / nGrids;
    filled = round(percent * bar_length);
    bar_str = ['[', repmat('#', 1, filled), repmat('-', 1, bar_length - filled), ']'];
    fprintf("\r🚧 진행률: %s %.1f%% (%d / %d)", bar_str, percent * 100, i, nGrids);

    % 10,000개 단위 저장
    if mod(i, BLOCK_SIZE) == 0 || i == nGrids
        block_start = i - BLOCK_SIZE + 1;
        if block_start < 1, block_start = 1; end
        block_neighbors = neighbors(block_start:i);
        fname = sprintf('neighbors_%d.mat', i);
        save(fname, 'block_neighbors', '-v7.3');
        fprintf("\n💾 %s 저장 완료!\n", fname);
    end
end

% 전체 저장
save('neighbors_cache_land.mat', 'neighbors', '-v7.3');
fprintf("\n🎉 전체 이웃 정보 저장 완료 → neighbors_cache_land.mat\n");
