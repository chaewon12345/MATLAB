% 1. 원본 격자 파일과 SPEI 결과 파일 불러오기
grid_table = readtable('korea_grids_0.01deg.csv');           % 전체 격자 정보
spei_table = readtable('korea_spei06_recent_avg_all.csv');   % SPEI 평균 결과

% 2. grid_id 기준 병합 (outer join 아님, left join처럼)
merged_table = outerjoin(grid_table, spei_table, ...
    'Keys', 'grid_id', ...
    'MergeKeys', true, ...
    'Type', 'left');

% 3. 확인 및 저장
disp("✅ 병합 완료. 미리보기:");
disp(head(merged_table))

writetable(merged_table, 'korea_grids_with_spei.csv');
disp("💾 저장 완료: korea_grids_with_spei.csv");
