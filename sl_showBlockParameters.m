function showBlockParameters()
% showBlockParameters - 選択されているブロックのパラメータ一覧を表示
%
% 使用方法:
%   Simulinkモデルでブロックを1つ選択してから実行
%   >> showBlockParameters()

    % 現在選択されているブロックを取得
    selectedBlock = gcb;
    
    % ブロックが選択されているか確認
    if isempty(selectedBlock)
        disp('ブロックが選択されていません');
        return;
    end
    
    disp('=========================================');
    disp(['選択ブロック: ', selectedBlock]);
    disp('=========================================');
    
    % ブロックタイプを取得
    blockType = get_param(selectedBlock, 'BlockType');
    disp(['ブロックタイプ: ', blockType]);
    
    % すべてのパラメータを取得
    try
        % ダイアログパラメータを取得
        dialogParams = get_param(selectedBlock, 'DialogParameters');
        
        if ~isempty(dialogParams)
            disp(' ');
            disp('--- ダイアログパラメータ ---');
            paramNames = fieldnames(dialogParams);
            
            for i = 1:length(paramNames)
                paramName = paramNames{i};
                try
                    paramValue = get_param(selectedBlock, paramName);
                    
                    % 値を文字列として表示
                    if ischar(paramValue)
                        disp([paramName, ': ', paramValue]);
                    elseif isnumeric(paramValue)
                        disp([paramName, ': ', num2str(paramValue)]);
                    else
                        disp([paramName, ': [', class(paramValue), ']']);
                    end
                catch
                    disp([paramName, ': (取得不可)']);
                end
            end
        end
        
        % オブジェクトパラメータも取得
        disp(' ');
        disp('--- オブジェクトパラメータ ---');
        objectParams = get_param(selectedBlock, 'ObjectParameters');
        
        if ~isempty(objectParams)
            paramNames = fieldnames(objectParams);
            
            for i = 1:length(paramNames)
                paramName = paramNames{i};
                try
                    paramValue = get_param(selectedBlock, paramName);
                    
                    if ischar(paramValue)
                        disp([paramName, ': ', paramValue]);
                    elseif isnumeric(paramValue)
                        disp([paramName, ': ', num2str(paramValue)]);
                    else
                        disp([paramName, ': [', class(paramValue), ']']);
                    end
                catch
                    % 表示をスキップ
                end
            end
        end
        
    catch ME
        disp(['エラー: ', ME.message]);
    end
    
    disp('=========================================');
end