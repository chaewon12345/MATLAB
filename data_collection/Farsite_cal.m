% 1️⃣ 입력 데이터 로딩
disp('🔍 1단계: 입력 CSV 파일 불러오는 중...');
data = readtable('input_data_land_only.csv');  % ← 파일명 수정

% 2️⃣ 격자 방향 설정
dirs = [ -1,  1;  0, 1;  1, 1;
         -1,  0;        1, 0;
         -1, -1; 0, -1; 1, -1 ];
dir_labels = {'NW','N','NE','W','E','SW','S','SE'};

results = table();

% 파라미터 설정
sigma = 1.0;
alpha = 0.5;
beta = 0.5;
slope_dir = 135;

disp('✅ 2단계: 전이 확률 계산 시작...');

% 3️⃣ 각 격자에 대해 반복
for i = 1:height(data)
    row = data(i,:);
    
    lat = row.center_lat;
    lon = row.center_lon;
    wind_dir = row.wind_deg;
    ros = 0.001 * row.avg_fuelload_pertree_kg;  % 예시 ROS

    P = zeros(8,1);
    
    for d = 1:8
        dx = dirs(d,1);
        dy = dirs(d,2);
        d_ij = sqrt(dx^2 + dy^2);
        theta_ij = atan2d(dy, dx);
        if theta_ij < 0
            theta_ij = theta_ij + 360;
        end
        
        G = alpha * cosd(theta_ij - wind_dir) + beta * cosd(theta_ij - slope_dir);
        P(d) = exp(-(d_ij^2)/(sigma^2)) * (1 + G) * ros;
    end
    
    P = P / sum(P);
    
    new_row = table(row.grid_id, row.center_lat, row.center_lon, ...
        'VariableNames', {'grid_id','center_lat','center_lon'});
    
    for d = 1:8
        new_row.(sprintf('P_%s', dir_labels{d})) = P(d);
    end
    
    results = [results; new_row];
    
    % 💬 상태 출력 (10개마다)
    if mod(i, 10) == 0 || i == height(data)
        fprintf('▶ 진행 중: %d / %d 격자 처리 완료\n', i, height(data));
    end
end

% 4️⃣ 결과 저장
disp('📁 3단계: 결과를 CSV로 저장 중...');
writetable(results, 'farsite_transfer_probs.csv');
disp('🎉 완료! → 결과 파일: farsite_transfer_probs.csv');
