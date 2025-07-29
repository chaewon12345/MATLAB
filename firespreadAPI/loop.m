function loop()
    clear model_gbm  % 매 실행마다 초기화 (예외적으로 허용)
    persistent model_gbm

    while true
        pause(0.2);  % 🔁 1초 주기 폴링

        try
            % 🔍 FastAPI로부터 입력 격자 데이터 요청
            inputs = webread("https://firespread-api.onrender.com/check_input");

            if isempty(inputs)
                continue;
            end

            disp("✅ 예측 시작 (총 " + length(inputs) + "개 격자)");

            % 🔁 모델 로드 (캐시 방식)
            if isempty(model_gbm)
                modelData = load('gradient_boosting_pspread_model_300trees_20250706_131211.mat');
                model_gbm = modelData.model;
            end

            % 📦 예측 결과 저장용
            grid_results = [];
% 👇 이 라인을 try 블록 안, for i 루프 시작 전에 추가
            

            % 🔁 각 격자에 대해 예측
            for i = 1:length(inputs)
                input = inputs(i);

                 X = [safeVal(input.avg_fuelload_pertree_kg), ...
         safeVal(input.FFMC), safeVal(input.DMC), safeVal(input.DC), ...
         safeVal(input.NDVI), safeVal(input.smap_20250630_filled), ...
         safeVal(input.temp_C), safeVal(input.humidity), ...
         safeVal(input.wind_speed), safeVal(input.wind_deg), ...
         safeVal(input.precip_mm), safeVal(input.mean_slope), ...
         safeVal(input.spei_recent_avg), safeVal(input.farsite_prob)];


                pSpread = predict(model_gbm, X);

                % 예측 결과 저장
                grid_results = [grid_results; struct( ...
                    "grid_id", input.grid_id, ...
                    "center_lat", input.center_lat, ...
                    "center_lon", input.center_lon, ...
                    "lat_min", input.lat_min, ...
                    "lat_max", input.lat_max, ...
                    "lon_min", input.lon_min, ...
                    "lon_max", input.lon_max, ...
                    "pSpread", pSpread ...
                )];
            end

            % 🔝 전체 기준 중요 피처 Top 3 계산
            importance = predictorImportance(model_gbm);
            [~, sorted_idx] = sort(importance, 'descend');
            feature_names = {
                'avg_fuelload_pertree_kg', 'FFMC', 'DMC', 'DC', ...
                'NDVI', 'smap_20250630_filled', 'temp_C', 'humidity', ...
                'wind_speed', 'wind_deg', 'precip_mm', 'mean_slope', ...
                'spei_recent_avg', 'farsite_prob'
            };
            global_top3 = feature_names(sorted_idx(1:3));

            % 📤 FastAPI 전송용 payload 구성 (단일 객체로!)
            payload = struct( ...
                "problem_id", "1", ...
                "grid_results", grid_results, ...
                "global_top3", {global_top3} ...
            );

            % 🔗 서버 전송
            options = weboptions("MediaType", "application/json");
            response = webwrite("https://firespread-api.onrender.com/upload_result", payload, options);

            disp("✅ 전송 완료:");
            disp(response);
            break;  % ✅ 테스트 용도: 첫 번째 처리 후 루프 종료

            

        catch e
            disp("❌ 오류 발생:");
            disp(e.message);
        end
    end
    function out = safeVal(v)
    if isempty(v)
        out = 0;
    elseif isnumeric(v)
        if isnan(v)
            out = 0;
        else
            out = v;
        end
    else
        % 혹시 다른 타입이 들어와도 0으로
        out = 0;
    end
end

end
