%% メインカスタマイズ関数：Simulinkのカスタムメニューを設定
function sl_customization(cm)
  % PreContextMenuにカスタムメニューを追加
  cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMyMenuItems);
end

%% カスタムメニュー項目を定義：5つのメニュー項目を返す
function schemaFcns = getMyMenuItems(callbackInfo) 
  schemaFcns = {@getItem1,@getItem2,@getItem3,@getItem4,@alignBlocksMenu}; 
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

function schema = alignBlocksMenu(callbackInfo)
    % メニュー項目のスキーマを作成
    schema = sl_action_schema;
    schema.label = '横位置を揃える';
    schema.userdata = 'align_blocks';
    schema.callback = @alignBlocksCallback;
    
    % 複数のブロックが選択されている場合のみ有効化
    selected_blocks = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
    selected_blocks = setdiff(selected_blocks, gcs);
    schema.state = 'Enabled';
    if length(selected_blocks) < 2
        schema.state = 'Disabled';
    end
end

function alignBlocksCallback(callbackInfo)
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