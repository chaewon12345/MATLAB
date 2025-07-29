% 1. CSV 불러오기
T = readtable('korea_grids_with_spei.csv');

% 2. 중심 위도/경도 계산
T.lat_center = (T.lat_min + T.lat_max) / 2;
T.lon_center = (T.lon_min + T.lon_max) / 2;

% 3. 유효 데이터 필터
valid = ~isnan(T.spei_recent_avg);

% 4. 지도 기반 시각화
figure;
geoscatter(T.lat_center(valid), T.lon_center(valid), 6, T.spei_recent_avg(valid), 's', 'filled');
geobasemap topographic;  % 다른 옵션: 'grayland', 'streets', 'satellite'
colorbar;
colormap jet;
caxis([-2.5 2.5]);  % SPEI 표준 범위
title('최근 6개월 평균 SPEI (지도 위 격자 시각화)');


