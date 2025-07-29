% ========== 1. 데이터 불러오기 ==========
grids = readtable('korea_grids_0.01deg.csv');
weather = readtable('weather_by_grid_20250624.csv');

lat = grids.center_lat;
lon = grids.center_lon;

% ========== 2. 각 지표 데이터 추출 ==========
temp      = weather.temp_C;
humidity  = weather.humidity;
wind_spd  = weather.wind_speed;
wind_deg  = weather.wind_deg;
precip    = weather.precip_mm;

% ========== 3. 육지만 필터링 ==========
is_land = ~isnan(temp);
lat = lat(is_land);
lon = lon(is_land);
temp = temp(is_land);
humidity = humidity(is_land);
wind_spd = wind_spd(is_land);
wind_deg = wind_deg(is_land);
precip = precip(is_land);

% ========== 4. 공통 지도 설정 ==========
lat_lim = [33.5 39];
lon_lim = [124.5 131];

% ========== 5. 기온 시각화 ==========
figure;
worldmap(lat_lim, lon_lim);
load coastlines
geoshow(coastlat, coastlon, 'Color', 'k');
scatterm(lat, lon, 20, temp, 'filled');
colorbar;
colormap(parula);
title('기온 [℃] (ERA5)', 'FontSize', 14);

% ========== 6. 습도 시각화 ==========
figure;
worldmap(lat_lim, lon_lim);
geoshow(coastlat, coastlon, 'Color', 'k');
scatterm(lat, lon, 20, humidity, 'filled');
colorbar;
colormap(turbo);
title('상대 습도 [%] (ERA5)', 'FontSize', 14);

% ========== 7. 풍속 시각화 ==========
figure;
worldmap(lat_lim, lon_lim);
geoshow(coastlat, coastlon, 'Color', 'k');
scatterm(lat, lon, 20, wind_spd, 'filled');
colorbar;
colormap(summer);
title('풍속 [m/s] (ERA5)', 'FontSize', 14);

% ========== 8. 풍향 시각화 ==========
figure;
worldmap(lat_lim, lon_lim);
geoshow(coastlat, coastlon, 'Color', 'k');
scatterm(lat, lon, 20, wind_deg, 'filled');
colorbar;
colormap(hsv);
title('풍향 [°] (ERA5)', 'FontSize', 14);

% ========== 9. 강수량 시각화 ==========
figure;
worldmap(lat_lim, lon_lim);
geoshow(coastlat, coastlon, 'Color', 'k');
scatterm(lat, lon, 20, precip, 'filled');
colorbar;
colormap(winter);
title('강수량 [mm] (ERA5)', 'FontSize', 14);
