function neighbors = getNeighbors(idx, center_lat, center_lon)
R = 6371;  % 지구 반지름 (km)
lat1 = deg2rad(center_lat(idx));
lon1 = deg2rad(center_lon(idx));

neighbors = [];
for j = 1:length(center_lat)
    if j == idx, continue; end
    lat2 = deg2rad(center_lat(j));
    lon2 = deg2rad(center_lon(j));
    dlat = lat2 - lat1;
    dlon = lon2 - lon1;
    a = sin(dlat/2)^2 + cos(lat1)*cos(lat2)*sin(dlon/2)^2;
    c = 2 * asin(sqrt(a));
    d = R * c;
    if d <= 2.0
        neighbors = [neighbors, j];
    end
end
end
