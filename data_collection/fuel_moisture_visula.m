% 1. CSV 파일 읽기
T = readtable('fuel_moisture_nearest.csv');

% 2. NaN 값이 아닌 행 필터링
valid = ~isnan(T.FFMC);  % FFMC로 필터링 (DMC, DC도 가능)
lat = (T.min_lat(valid) + T.max_lat(valid)) / 2;
lon = (T.min_lon(valid) + T.max_lon(valid)) / 2;
ffmc = T.FFMC(valid);

% 3. 시각화
scatter(lon, lat, 20, ffmc, 'filled');
colormap('hot'); colorbar;
xlabel('Longitude');
ylabel('Latitude');
title('FFMC (Fine Fuel Moisture Code)');
