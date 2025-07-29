% 1. 전체 데이터 불러오기
data = readtable('cfis_land_result_percell_6_with_coords.csv');

% 2. NaN 처리: Pignite NaN → 0
data.Pignite(isnan(data.Pignite)) = 0;

% 3. Pspread의 NaN 개수 확인
n_nan_pspread = sum(isnan(data.Pspread));
fprintf("⚠️ Pspread 열의 NaN 개수: %d개\n", n_nan_pspread);

% 4. 무작위 섞기 (seed 고정)
rng(42);
n = height(data);
indices = randperm(n);

% 5. 7:3 분할
n_train = round(0.7 * n);
train_idx = indices(1:n_train);
test_idx = indices(n_train+1:end);

% 6. 데이터 분할
train_data = data(train_idx, :);
test_data = data(test_idx, :);

% 7. 파일 저장
writetable(train_data, 'cfis_train_label.csv');
writetable(test_data, 'cfis_test_label.csv');

fprintf("✅ 학습용 데이터 저장 완료 → cfis_train_label.csv (%d개)\n", height(train_data));
fprintf("✅ 테스트용 데이터 저장 완료 → cfis_test_label.csv (%d개)\n", height(test_data));
