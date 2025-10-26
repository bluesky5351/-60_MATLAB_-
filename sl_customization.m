%% メインカスタマイズ関数：Simulinkのカスタムメニューを設定
function sl_customization(cm)
  % PreContextMenuにカスタムメニューを追加
  cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMyMenuItems);
end

%% カスタムメニュー項目を定義：5つのメニュー項目を返す
function schemaFcns = getMyMenuItems(callbackInfo) 
  schemaFcns = {@getItem1,@getItem2,@getItem3,@getItem4,@alignBlocksHorizontalMenu, @alignBlocksVerticalMenu, @getItem5}; 

end

%% メニュー項目1：テスト用の基本メニュー
function schema = getItem1(callbackInfo)
  schema = sl_action_schema;
  schema.label = 'Item One';
  schema.userdata = 'item one';	
  schema.callback = @myCallback1; 
end

function myCallback1(callbackInfo)
  disp(['Callback for item ' callbackInfo.userdata ' was called']);
end

%% メニュー項目2：選択ブロックのパスをコピー
function schema = getItem2(callbackInfo)
  schema = sl_action_schema;
  schema.label = 'Get path';
  schema.callback = @myCallback2;
end

function myCallback2(callbackInfo)
  clipboard('copy',gcb);
end

%% メニュー項目3：ブロックの背景色を白に設定
function schema = getItem3(callbackInfo)
  schema = sl_action_schema;
  schema.label = 'white';
  schema.callback = @myCallback3;
end

function myCallback3(callbackInfo)
  try
    set_param(gcb, 'BackgroundColor', 'white');
  catch ME
    disp(['Cannot set background color for this block: ' ME.message]);
  end
end

%% メニュー項目4：Inportブロックを自動配置
function schema = getItem4(callbackInfo)
  schema = sl_action_schema;
  schema.label = 'inport_put';
  schema.callback = @myCallback4;
end

function myCallback4(callbackInfo)

% SimulinkモデルにInportブロックを10個自動配置するスクリプト

% Inportブロックの配置位置  (Positions of Inport blocks)
positions = [
    50, 50, 80, 65;
    150, 50, 180, 65;
    250, 50, 280, 65;
    350, 50, 380, 65;
    450, 50, 480, 65;
    50, 150, 80, 165;
    150, 150, 180, 165;
    250, 150, 280, 165;
    350, 150, 380, 165;
    450, 150, 480, 165
];

% Inportブロックの名前
portNames = {
    'Input1';
    'Input2';
    'Input3';
    'Input4';
    'Input5';
    'Input6';
    'Input7';
    'Input8';
    'Input9';
    'Input10'
};

% 10個のInportブロックを追加
for i = 1:10
    inportPath = [gcs '/' portNames{i}];
    
    % Add Inport block
    add_block('simulink/Sources/In1', inportPath, ...
        'Position', positions(i, :), ...
        'Port', num2str(i));
end

end

function schema = alignBlocksHorizontalMenu(callbackInfo)
    % 横位置を揃えるメニュー項目のスキーマを作成
    schema = sl_action_schema;
    schema.label = '横位置を揃える（一番上基準）';
    schema.userdata = 'align_blocks_horizontal';
    schema.callback = @alignBlocksHorizontalCallback;
    
    % 複数のブロックが選択されている場合のみ有効化
    selected_blocks = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
    selected_blocks = setdiff(selected_blocks, gcs);
    schema.state = 'Enabled';
    if length(selected_blocks) < 2
        schema.state = 'Disabled';
    end
end

function schema = alignBlocksVerticalMenu(callbackInfo)
    % 縦位置を揃えるメニュー項目のスキーマを作成
    schema = sl_action_schema;
    schema.label = '縦位置を揃える（一番左基準）';
    schema.userdata = 'align_blocks_vertical';
    schema.callback = @alignBlocksVerticalCallback;
    
    % 複数のブロックが選択されている場合のみ有効化
    selected_blocks = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
    selected_blocks = setdiff(selected_blocks, gcs);
    schema.state = 'Enabled';
    if length(selected_blocks) < 2
        schema.state = 'Disabled';
    end
end

function alignBlocksHorizontalCallback(callbackInfo)
    % 横位置を揃える処理
    selected_blocks = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
    selected_blocks = setdiff(selected_blocks, gcs);
    
    if length(selected_blocks) < 2
        return;
    end
    
    % 各ブロックの位置を取得
    positions = zeros(length(selected_blocks), 4);
    for i = 1:length(selected_blocks)
        positions(i, :) = get_param(selected_blocks{i}, 'Position');
    end
    
    % 一番上のブロック(Y座標が最小)を見つける
    [~, top_index] = min(positions(:, 2));
    
    % 基準となるX座標(左端)
    target_x = positions(top_index, 1);
    
    % すべてのブロックのX座標を合わせる
    for i = 1:length(selected_blocks)
        current_pos = positions(i, :);
        block_width = current_pos(3) - current_pos(1);
        new_pos = [target_x, current_pos(2), target_x + block_width, current_pos(4)];
        set_param(selected_blocks{i}, 'Position', new_pos);
    end
    
    disp(['ブロックの横位置を "' get_param(selected_blocks{top_index}, 'Name') '" に合わせました']);
end

function alignBlocksVerticalCallback(callbackInfo)
    % 縦位置を揃える処理
    selected_blocks = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
    selected_blocks = setdiff(selected_blocks, gcs);
    
    if length(selected_blocks) < 2
        return;
    end
    
    % 各ブロックの位置を取得
    positions = zeros(length(selected_blocks), 4);
    for i = 1:length(selected_blocks)
        positions(i, :) = get_param(selected_blocks{i}, 'Position');
    end
    
    % 一番左のブロック(X座標が最小)を見つける
    [~, left_index] = min(positions(:, 1));
    
    % 基準となるY座標(上端)
    target_y = positions(left_index, 2);
    
    % すべてのブロックのY座標を合わせる
    for i = 1:length(selected_blocks)
        current_pos = positions(i, :);
        block_height = current_pos(4) - current_pos(2);
        new_pos = [current_pos(1), target_y, current_pos(3), target_y + block_height];
        set_param(selected_blocks{i}, 'Position', new_pos);
    end
    
    disp(['ブロックの縦位置を "' get_param(selected_blocks{left_index}, 'Name') '" に合わせました']);
end

%% メニュー項目5：ブロックパラメータを取得
function schema = getItem5(callbackInfo)
  schema = sl_action_schema;
  schema.label = 'Get Parameter';
  schema.callback = @showBlockParameters;
end

function showBlockParameters(callbackInfo)
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