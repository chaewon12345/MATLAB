% ========== 1. 데이터 불러오기 ==========
data = readtable('korea_grids_with_slope.csv');

% 평균 경사도 NaN 제거 (바다 제거)
valid_idx = ~isnan(data.mean_slope);

% 중심 위도/경도 계산
center_lat = (data.lat_min + data.lat_max) / 2;
center_lon = (data.lon_min + data.lon_max) / 2;

lat = center_lat(valid_idx);
lon = center_lon(valid_idx);
val = data.mean_slope(valid_idx);

% -99999 같은 이상값 제거 (보통 바다 영역)
val(val < -1000) = NaN;
lat = lat(~isnan(val));
lon = lon(~isnan(val));
val = val(~isnan(val));

% ========== 2. 색상 구간 수동 지정 ==========
% 조밀한 구간: 0 ~ 30도 사이에서 색상 세분화
edges = [-1000, 0, 2, 4, 6, 8, 10, 13, 16, 20, 25, 30, 90];  % 사용자 정의 구간
numColors = length(edges) - 1;

% 색상 맵 구성
cmap = turbo(numColors);  % 또는 parula(numColors), jet(numColors)

% 각 데이터에 해당하는 색상 인덱스 계산
[~, bin] = histc(val, edges);

% ========== 3. 한반도 지도 설정 ==========
figure;
worldmap([32, 39.5], [124.5, 131]);
load coastlines
geoshow(coastlat, coastlon, 'DisplayType', 'line', 'Color', 'black');

% ========== 4. 색상 시각화 ==========
hold on;
for i = 1:numColors
    idx = (bin == i);
    scatterm(lat(idx), lon(idx), 10, repmat(cmap(i,:), sum(idx), 1), 'filled');
end

% ========== 5. 색상 범례 설정 ==========
colormap(cmap);
cb = colorbar;
cb.Ticks = linspace(0, 1, numColors + 1);  % 균등하게 보이도록
cb.TickLabels = strcat(string(edges(1:end-1)), '–', string(edges(2:end)));
cb.Label.String = '평균 경사도 (°)';
title('한반도 격자별 평균 경사도 (세분화된 컬러맵)');
