T = readtable('smap_20250630_all_grids_with_interpolated_land.csv');

% 유효한 육지 격자만 선택
valid = ~isnan(T.smap_20250630_filled);
lat = T.center_lat(valid);
lon = T.center_lon(valid);
sm  = T.smap_20250630_filled(valid);

% 시각화
figure;
geoscatter(lat, lon, 10, sm, 'filled');
geobasemap streets
colormap(parula(256));    % parula 그대로 사용해도 유사함
caxis([0.25 0.55])        % 색상 범위 고정
colorbar;
title('2025.06.30 한반도 토양 수분 (보간 포함)');
