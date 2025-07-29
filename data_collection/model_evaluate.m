%% 🔹 1. 예측 결과 불러오기
fprintf("[INFO] 예측 결과 파일 불러오는 중...\n");
result = readtable("evaluation_result_20250706_132042.csv");  % ← 수정

%% 🔹 2. 정답값 불러오기
fprintf("[INFO] CFIS 정답 데이터 불러오는 중...\n");
truth = readtable("cfis_test_label.csv");

if ismember("Pspread", truth.Properties.VariableNames)
    Y_true = truth.Pspread;
else
    error("❌ cfis_test_label.csv에 Pspread 컬럼이 없습니다.");
end

Y_pred = result.pSpread_pred;

%% 🔹 3. 성능 평가
fprintf("[INFO] 성능 평가 중 (RMSE, MAE)...\n");
rmse = sqrt(mean((Y_true - Y_pred).^2));
mae = mean(abs(Y_true - Y_pred));

fprintf("\n[RESULT] 📉 RMSE: %.4f\n", rmse);
fprintf("[RESULT] 📉 MAE : %.4f\n", mae);

%% 🔹 4. 결과 테이블 구성 및 저장
result.Pspread_true = Y_true;
result.abs_error = abs(Y_true - Y_pred);

output_filename = ['evaluation_result_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv'];
writetable(result, output_filename);
fprintf("[완료] 평가 결과 저장됨 → %s\n", output_filename);

%% 🔹 5. 시각화 - 예측 지도
figure;
scatter(result.center_lon, result.center_lat, 20, result.pSpread_pred, 'filled');
colormap(jet); colorbar; caxis([0 1]);
xlabel('Longitude'); ylabel('Latitude');
title('🔥 예측 확산 확률 지도 (Gradient Boosting)');
grid on;

%% 🔹 6. 시각화 - 실제 지도
figure;
scatter(result.center_lon, result.center_lat, 20, result.Pspread_true, 'filled');
colormap(jet); colorbar; caxis([0 1]);
xlabel('Longitude'); ylabel('Latitude');
title('📍 실제 확산 확률 지도 (CFIS)');
grid on;

%% 🔹 7. 시각화 - 오차 지도
figure;
scatter(result.center_lon, result.center_lat, 20, result.abs_error, 'filled');
colormap(parula); colorbar;
xlabel('Longitude'); ylabel('Latitude');
title('🧭 예측 오차 지도 (절대 오차)');
grid on;

%% 🔹 8. 모델 불러오기 + 피처 중요도
fprintf("[INFO] 학습된 모델 로딩 중...\n");
load("gradient_boosting_pspread_model_300trees_20250706_131211.mat");  % ← 파일명 수정

fprintf("[INFO] 피처 중요도 분석 중...\n");
importance = predictorImportance(model);
varNames = model.PredictorNames;

[sortedImp, idx] = sort(importance, 'descend');
fprintf("\n🔍 Top 3 중요 피처 (Gradient Boosting 기준):\n");
for i = 1:3
    fprintf("%d. %s (Importance: %.4f)\n", i, varNames{idx(i)}, sortedImp(i));
end

% 중요도 시각화
figure;
bar(importance(idx));
xticklabels(varNames(idx));
xtickangle(45);
ylabel('Importance Score');
title('📊 Feature Importance (Gradient Boosting)');
grid on;

%% 🔹 9. 트리 수에 따른 학습 오차 그래프
fprintf("[INFO] 트리 수에 따른 학습 오차 계산 중...\n");
nTrees = model.NumTrained;
resubErrors = zeros(nTrees, 1);

for t = 1:nTrees
    resubErrors(t) = resubLoss(model, 'Mode', 'Ensemble', 'Learners', 1:t);
end

figure;
plot(1:nTrees, resubErrors, 'LineWidth', 2);
xlabel('Number of Trees');
ylabel('Resubstitution Loss');
title('📉 Gradient Boosting Learning Curve');
grid on;
