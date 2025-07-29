%% 1. 모델 불러오기
load('random_forest_pspread_model_300trees_20250706_101534.mat');  % 최신 모델 파일명으로 대체

%% 2. 테스트 데이터 불러오기
X_raw = readtable('farsite_test_label.csv');
Y_true = readtable('cfis_test_label.csv');  % 정답값: pSpread

% grid_id와 중심좌표 저장 (시각화용)
grid_id = X_raw.grid_id;
center_lat = X_raw.center_lat;
center_lon = X_raw.center_lon;

% 입력 피처만 추출 (21개)
excludeCols = {'grid_id', 'lat_min', 'lat_max', ...
               'lon_min', 'lon_max', 'center_lat', 'center_lon'};
X_test = removevars(X_raw, intersect(X_raw.Properties.VariableNames, excludeCols));

%% 예측 수행
Y_pred = predict(Mdl, X_test);
Y_true = Y_true.Pspread;

%% 성능 평가 (RMSE, MAE)
rmse = sqrt(mean((Y_true - Y_pred).^2));
mae = mean(abs(Y_true - Y_pred));

fprintf('[RESULT] RMSE: %.4f\n', rmse);
fprintf('[RESULT] MAE : %.4f\n', mae);

%% 오차 테이블 생성
result_table = table(grid_id, center_lat, center_lon, Y_true, Y_pred, ...
                     abs(Y_true - Y_pred), ...
                     'VariableNames', {'grid_id', 'lat', 'lon', 'Pspread_true', 'Pspread_pred', 'abs_error'});

%% 지도 위 격자 시각화 - 예측값
figure;
scatter(result_table.lon, result_table.lat, 20, result_table.Pspread_pred, 'filled');
colorbar;
xlabel('Longitude'); ylabel('Latitude');
title('Predicted pSpread Map');

%% 지도 위 격자 시각화 - 실제값
figure;
scatter(result_table.lon, result_table.lat, 20, result_table.Pspread_true, 'filled');
colorbar;
xlabel('Longitude'); ylabel('Latitude');
title('True Pspread Map');

% OOB Error over number of trees
figure;
plot(oobError(Mdl), 'LineWidth', 2);
xlabel('Number of Trees');
ylabel('Out-of-Bag Error');
title('OOB Error vs. Number of Trees');
grid on;

%% 컬러 범위 고정 & 컬러맵 명시
min_val = 0;
max_val = 1;

% 예측 지도
figure;
scatter(result_table.lon, result_table.lat, 20, result_table.Pspread_pred, 'filled');
colormap(jet);          % jet 컬러맵 사용
caxis([min_val max_val]);  % 색상 범위 고정
colorbar;
xlabel('Longitude'); ylabel('Latitude');
title('🔥 Predicted Pspread Map (Random Forest)');
grid on;

% 실제 정답 지도
figure;
scatter(result_table.lon, result_table.lat, 20, result_table.Pspread_true, 'filled');
colormap(jet);
caxis([min_val max_val]);
colorbar;
xlabel('Longitude'); ylabel('Latitude');
title('📍 True Pspread Map');
grid on;

% 중요도 추출
importance = Mdl.OOBPermutedPredictorDeltaError;
varNames = Mdl.PredictorNames;

% 중요도 기준 정렬
[sortedImp, idx] = sort(importance, 'descend');
% Top 3 출력
fprintf('\n🔍 Top 3 중요 피처:\n');
for i = 1:3
    fprintf('%d. %s (Importance: %.4f)\n', i, varNames{idx(i)}, sortedImp(i));
end

writetable(result_table, 'test_prediction_results.csv');
fprintf('[✅ 완료] 성능 평가 파일 저장됨 ');