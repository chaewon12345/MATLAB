%% 🔹 1. 데이터 불러오기
fprintf('[INFO] 데이터 불러오는 중...\n');
X_raw = readtable('farsite_train_label.csv');  % 전체 입력 데이터
Y = readtable('cfis_train_label.csv');         % 정답 데이터 (pSpread)

% 정답 벡터 추출
if ismember('Pspread', Y.Properties.VariableNames)
    Y = Y.Pspread;
else
    error('❌ cfis_train_label.csv에 Pspread 컬럼이 없습니다.');
end

%% 🔹 2. 입력 피처만 추출 (21개 지표)
% 나중에 예측 결과 매핑용 grid_id 저장
grid_ids = X_raw.grid_id;

% 학습에서 제외할 컬럼들
excludeCols = {'grid_id', 'lat_min', 'lat_max', ...
               'lon_min', 'lon_max', 'center_lat', 'center_lon'};

% 21개 입력 피처만 추출
X = removevars(X_raw, intersect(X_raw.Properties.VariableNames, excludeCols));

%% 🔹 3. 모델 학습 설정
nTrees = 300;
fprintf('[INFO] Random Forest 모델 학습 시작 (트리 수: %d)...\n', nTrees);

opts = statset('UseParallel', false);  % 병렬 옵션 꺼버림

tic
Mdl = TreeBagger(nTrees, X, Y, ...
    'Method', 'regression', ...
    'OOBPrediction', 'on', ...
    'OOBPredictorImportance', 'on', ...
    'Options', opts, ...
    'NumPrint', 10);  % 10개 단위 진행률 출력
toc

%% 🔹 4. 모델 저장
timestamp = datestr(now,'yyyymmdd_HHMMSS');
model_filename = ['random_forest_pspread_model_300trees_', timestamp, '.mat'];

save(model_filename, 'Mdl', 'grid_ids');  % grid_ids도 함께 저장
fprintf('[✅ 완료] 모델 저장됨 → "%s"\n', model_filename);
