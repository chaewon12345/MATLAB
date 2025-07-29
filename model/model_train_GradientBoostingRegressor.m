%% 🔹 1. 학습 데이터 불러오기 및 전처리
fprintf("[INFO] Train 데이터 불러오는 중...\n");
train = readtable("train_label.csv");

fprintf("[INFO] FARSITE 8방향 확산 확률 평균 계산 중...\n");
farsite_cols = {'P_NW','P_N','P_NE','P_W','P_E','P_SW','P_S','P_SE'};
farsite_vals = train{:, farsite_cols};
train.farsite_prob = mean(farsite_vals, 2);  % NaN 없으니 omitnan 불필요

fprintf("[INFO] 입력 피처(X) 및 정답(y) 추출 중...\n");
X = train{:, {
    'avg_fuelload_pertree_kg', ...
    'FFMC', 'DMC', 'DC', ...
    'NDVI', 'smap_20250630_filled', ...
    'temp_C', 'humidity', ...
    'wind_speed', 'wind_deg', ...
    'precip_mm', 'mean_slope', 'spei_recent_avg', ...
    'farsite_prob'
}};
y = train.Pspread;

%% 1. 모델 템플릿 생성 (tree)
tree = templateTree('MaxNumSplits', 10);

%% 2. 모델 학습
fprintf("[INFO] Gradient Boosting 모델 학습 시작 (트리 수: 300)...\n");
model = fitrensemble(X, y, ...
    'Method', 'LSBoost', ...
    'NumLearningCycles', 300, ...
    'LearnRate', 0.1, ...
    'Learners', tree);

fprintf("[✅ 완료] 모델 학습 완료!\n");

%% 🔹 3. 모델 저장
timestamp = datestr(now,'yyyymmdd_HHMMSS');
model_filename = ['gradient_boosting_pspread_model_300trees_', timestamp, '.mat'];

save(model_filename, 'model');
fprintf("[INFO] 모델 저장됨: %s\n", model_filename);
