% 📌 1. 데이터 불러오기
T = readtable('input_data_farsite_Nan.csv');
dirs = {'P_NW','P_N','P_NE','P_W','P_E','P_SW','P_S','P_SE'};

% 📌 2. 방향별 평균 전이 확률 계산 (NaN 제외)
mean_probs = zeros(1,8);
for i = 1:8
    mean_probs(i) = mean(T.(dirs{i}), 'omitnan');
end

% 📌 3. 역비율 기반 가중치 계산
inv_weights = 1 ./ mean_probs;

% 📌 4. 정규화 (최댓값 기준)
inv_weights = inv_weights / max(inv_weights);

% 📌 5. 보정된 전이 확률 계산 및 정규화
corrected = T(:, {'grid_id','center_lat','center_lon'});  % 결과 테이블 초기화
N = height(T);
progress_interval = round(N / 20);  % 5% 단위로 진행상황 출력

fprintf("📡 전체 %d개 중 보정 진행 중...\n", N);

for i = 1:N
    row_probs = zeros(1,8);

    % 각 방향에 대해 보정 가중치 적용
    for d = 1:8
        p = T.(dirs{d})(i);
        if isnan(p)
            row_probs(d) = NaN;
        else
            row_probs(d) = p * inv_weights(d);
        end
    end

    % 정규화
    if all(isnan(row_probs))
        row_probs_norm = NaN(1,8);
    else
        total = nansum(row_probs);
        row_probs_norm = row_probs / total;
    end

    % 저장
    for d = 1:8
        corrected.(dirs{d})(i) = row_probs_norm(d);
    end

    % 📢 진행률 출력 (5% 단위)
    if mod(i, progress_interval) == 0 || i == N
        fprintf("  → %.0f%% 완료 (%d / %d)\n", i / N * 100, i, N);
    end
end

% 📌 6. CSV 저장
writetable(corrected, 'corrected_farsite_probs.csv');
fprintf("✅ 보정 완료! 'corrected_farsite_probs.csv' 파일로 저장됐어요.\n");

% 📌 7. 자동 계산된 가중치 출력
fprintf("\n📌 자동 계산된 방향별 가중치:\n");
for i = 1:8
    fprintf("  %s: %.3f\n", dirs{i}, inv_weights(i));
end
