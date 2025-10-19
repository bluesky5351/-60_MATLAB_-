function PortInfoExtractorGUI()
    % ポート情報取得GUIアプリケーション
    % 使用方法: コマンドウィンドウで PortInfoExtractorGUI を実行
    
    % メインフィギュアの作成
    fig = uifigure('Name', 'Simulinkポート情報抽出ツール', ...
                   'Position', [100, 100, 800, 600], ...
                   'Resize', 'on');
    
    % グリッドレイアウトの作成
    grid = uigridlayout(fig, [5, 3]);
    grid.RowHeight = {30, 30, '1x', 40, 30};
    grid.ColumnWidth = {'1x', '1x', '1x'};
    
    % タイトルラベル
    titleLabel = uilabel(grid);
    titleLabel.Text = 'Simulinkブロック ポート情報抽出ツール';
    titleLabel.FontSize = 16;
    titleLabel.FontWeight = 'bold';
    titleLabel.HorizontalAlignment = 'center';
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1, 3];
    
    % モデル選択部分
    modelLabel = uilabel(grid);
    modelLabel.Text = '現在のモデル:';
    modelLabel.Layout.Row = 2;
    modelLabel.Layout.Column = 1;
    
    modelField = uieditfield(grid, 'text');
    modelField.Value = '';
    modelField.Editable = 'off';
    modelField.Layout.Row = 2;
    modelField.Layout.Column = 2;
    
    refreshButton = uibutton(grid, 'Text', 'モデル更新', ...
                            'ButtonPushedFcn', @(btn, event) refreshModel());
    refreshButton.Layout.Row = 2;
    refreshButton.Layout.Column = 3;
    
    % テーブル作成
    dataTable = uitable(grid);
    dataTable.Layout.Row = 3;
    dataTable.Layout.Column = [1, 3];
    dataTable.ColumnName = {'No', 'ブロック名', 'タイプ', 'ポート番号', ...
                            'データ型', '次元', '信号名', '接続先', '位置'};
    dataTable.ColumnWidth = {40, 150, 70, 70, 100, 70, 100, 150, 80};
    dataTable.RowName = {};
    dataTable.ColumnEditable = [false, false, false, false, false, false, false, false, true]; % 位置列のみ編集可能
    
    % ボタンパネル
    buttonPanel = uipanel(grid);
    buttonPanel.Layout.Row = 4;
    buttonPanel.Layout.Column = [1, 3];
    buttonPanel.BorderType = 'none';
    
    % ボタン配置用のフローレイアウト
    btnGrid = uigridlayout(buttonPanel, [1, 6]);
    btnGrid.ColumnWidth = {'1x', 130, 130, 130, 130, '1x'};
    
    % 取得ボタン
    extractButton = uibutton(btnGrid, 'Text', '情報取得', ...
                            'ButtonPushedFcn', @(btn, event) extractPortInfo());
    extractButton.Layout.Row = 1;
    extractButton.Layout.Column = 2;
    extractButton.BackgroundColor = [0.3, 0.6, 1];
    extractButton.FontColor = 'white';
    
    % 変更反映ボタン
    applyButton = uibutton(btnGrid, 'Text', '変更を反映', ...
                          'ButtonPushedFcn', @(btn, event) applyPositionChanges());
    applyButton.Layout.Row = 1;
    applyButton.Layout.Column = 3;
    applyButton.BackgroundColor = [1, 0.6, 0.2];
    applyButton.FontColor = 'white';
    
    % CSV出力ボタン
    csvButton = uibutton(btnGrid, 'Text', 'CSV出力', ...
                        'ButtonPushedFcn', @(btn, event) exportToCSV());
    csvButton.Layout.Row = 1;
    csvButton.Layout.Column = 4;
    csvButton.BackgroundColor = [0.4, 0.8, 0.4];
    csvButton.FontColor = 'white';
    
    % クリアボタン
    clearButton = uibutton(btnGrid, 'Text', 'クリア', ...
                          'ButtonPushedFcn', @(btn, event) clearTable());
    clearButton.Layout.Row = 1;
    clearButton.Layout.Column = 5;
    
    % ステータスバー
    statusLabel = uilabel(grid);
    statusLabel.Text = '準備完了';
    statusLabel.Layout.Row = 5;
    statusLabel.Layout.Column = [1, 3];
    statusLabel.BackgroundColor = [0.95, 0.95, 0.95];
    
    % アプリデータの初期化
    setappdata(fig, 'csvData', {});
    setappdata(fig, 'portHandles', {}); % ポートハンドルを保存
    setappdata(fig, 'blockPaths', {}); % ブロックパスを保存
    setappdata(fig, 'statusLabel', statusLabel);
    setappdata(fig, 'dataTable', dataTable);
    setappdata(fig, 'modelField', modelField);
    
    % 初回のモデル更新
    refreshModel();
    
    % --- ネストされた関数 ---
    
    function refreshModel()
        try
            model_name = gcs;
            if ~isempty(model_name)
                modelField.Value = model_name;
                statusLabel.Text = sprintf('モデル "%s" を検出しました', model_name);
            else
                modelField.Value = '(モデルが開かれていません)';
                statusLabel.Text = 'Simulinkモデルを開いてください';
            end
        catch
            modelField.Value = '(モデルが開かれていません)';
            statusLabel.Text = 'Simulinkモデルを開いてください';
        end
    end
    
    function extractPortInfo()
        try
            statusLabel.Text = '処理中...';
            drawnow;
            
            % 現在選択されているブロックを取得
            selected_blocks = find_system(gcs, 'SearchDepth', 1, 'Selected', 'on');
            
            if isempty(selected_blocks)
                statusLabel.Text = 'エラー: ブロックが選択されていません';
                uialert(fig, 'Simulinkモデルでブロックを選択してから実行してください', ...
                       '選択エラー');
                return;
            end
            
            % データ収集
            csv_data = {};
            port_handles_list = {}; % ポートハンドルを保存
            block_paths_list = {};  % ブロックパスを保存
            row_count = 1;
            
            for i = 1:length(selected_blocks)
                block_path = selected_blocks{i};
                port_handles = get_param(block_path, 'PortHandles');
                
                % Inport処理
                inport_handles = port_handles.Inport;
                for j = 1:length(inport_handles)
                    port_data = getPortData(inport_handles(j), block_path, 'Inport', row_count);
                    csv_data(end+1, :) = port_data;
                    port_handles_list{end+1} = inport_handles(j);
                    block_paths_list{end+1} = block_path;
                    row_count = row_count + 1;
                end
                
                % Outport処理
                outport_handles = port_handles.Outport;
                for j = 1:length(outport_handles)
                    port_data = getPortData(outport_handles(j), block_path, 'Outport', row_count);
                    csv_data(end+1, :) = port_data;
                    port_handles_list{end+1} = outport_handles(j);
                    block_paths_list{end+1} = block_path;
                    row_count = row_count + 1;
                end
            end
            
            % テーブルに表示
            if ~isempty(csv_data)
                dataTable.Data = csv_data;
                setappdata(fig, 'csvData', csv_data);
                setappdata(fig, 'portHandles', port_handles_list);
                setappdata(fig, 'blockPaths', block_paths_list);
                statusLabel.Text = sprintf('%d件のポート情報を取得しました（位置列は編集可能）', size(csv_data, 1));
            else
                statusLabel.Text = 'ポート情報が見つかりませんでした';
            end
            
        catch ME
            statusLabel.Text = sprintf('エラー: %s', ME.message);
            uialert(fig, ME.message, 'エラー');
        end
    end
    
    function port_data = getPortData(port_handle, block_path, port_type, row_num)
        % ポート情報を取得
        port_number = get_param(port_handle, 'PortNumber');
        port_position = get_param(port_handle, 'Position');
        position_str = sprintf('[%d,%d]', round(port_position(1)), round(port_position(2)));
        
        % データ型と次元
        try
            data_type = get_param(port_handle, 'CompiledPortDataType');
            dimensions = get_param(port_handle, 'CompiledPortDimensions');
            dim_str = sprintf('[%s]', num2str(dimensions));
        catch
            data_type = '(未コンパイル)';
            dim_str = '(未コンパイル)';
        end
        
        % 信号名と接続情報
        signal_name = '';
        connection = '';
        line_handle = get_param(port_handle, 'Line');
        
        if line_handle ~= -1
            signal_name = get_param(line_handle, 'Name');
            if isempty(signal_name)
                signal_name = '(未設定)';
            end
            
            if strcmp(port_type, 'Inport')
                src_port = get_param(line_handle, 'SrcPortHandle');
                if src_port ~= -1
                    src_block = get_param(src_port, 'Parent');
                    src_port_num = get_param(src_port, 'PortNumber');
                    connection = sprintf('%s:Port%d', src_block, src_port_num);
                end
            else % Outport
                dst_ports = get_param(line_handle, 'DstPortHandle');
                connections = {};
                for k = 1:length(dst_ports)
                    if dst_ports(k) ~= -1
                        dst_block = get_param(dst_ports(k), 'Parent');
                        dst_port_num = get_param(dst_ports(k), 'PortNumber');
                        connections{end+1} = sprintf('%s:Port%d', dst_block, dst_port_num);
                    end
                end
                if ~isempty(connections)
                    connection = strjoin(connections, '; ');
                end
            end
        else
            signal_name = '(未接続)';
            connection = '(未接続)';
        end
        
        port_data = {row_num, block_path, port_type, port_number, ...
                    data_type, dim_str, signal_name, connection, position_str};
    end
    
    function exportToCSV()
        csv_data = getappdata(fig, 'csvData');
        
        if isempty(csv_data)
            uialert(fig, 'エクスポートするデータがありません', 'エラー');
            return;
        end
        
        try
            % デスクトップパス取得
            if ispc
                desktop_path = fullfile(getenv('USERPROFILE'), 'Desktop');
            else
                desktop_path = fullfile(getenv('HOME'), 'Desktop');
            end
            
            % ファイル名生成
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            model_name = get_param(gcs, 'Name');
            filename = sprintf('port_info_%s_%s.csv', model_name, timestamp);
            filepath = fullfile(desktop_path, filename);
            
            % CSV書き込み
            fid = fopen(filepath, 'w', 'n', 'UTF-8');
            fprintf(fid, '%c%c%c', 239, 187, 191); % BOM
            
            % ヘッダー
            headers = {'No', 'ブロック名', 'タイプ', 'ポート番号', ...
                      'データ型', '次元', '信号名', '接続先', '位置'};
            fprintf(fid, '%s\n', strjoin(headers, ','));
            
            % データ
            for i = 1:size(csv_data, 1)
                row_str = '';
                for j = 1:size(csv_data, 2)
                    if j > 1
                        row_str = [row_str, ','];
                    end
                    value = csv_data{i, j};
                    if isnumeric(value)
                        value = num2str(value);
                    end
                    % カンマを含む場合の処理
                    if contains(value, ',') || contains(value, '"')
                        value = ['"', strrep(value, '"', '""'), '"'];
                    end
                    row_str = [row_str, value];
                end
                fprintf(fid, '%s\n', row_str);
            end
            
            fclose(fid);
            
            statusLabel.Text = sprintf('CSV出力完了: %s', filename);
            
            % 確認ダイアログ
            selection = uiconfirm(fig, sprintf('CSVファイルを出力しました。\n%s\n\nファイルを開きますか？', filepath), ...
                                 'エクスポート完了', ...
                                 'Options', {'開く', 'OK'}, ...
                                 'DefaultOption', 'OK');
            if strcmp(selection, '開く') && ispc
                winopen(filepath);
            end
            
        catch ME
            uialert(fig, ME.message, 'エクスポートエラー');
        end
    end
    
    function clearTable()
        dataTable.Data = {};
        setappdata(fig, 'csvData', {});
        setappdata(fig, 'portHandles', {});
        setappdata(fig, 'blockPaths', {});
        statusLabel.Text = 'テーブルをクリアしました';
    end
    
    function applyPositionChanges()
        % 位置の変更をSimulinkモデルに反映
        try
            table_data = dataTable.Data;
            block_paths = getappdata(fig, 'blockPaths');
            
            if isempty(table_data)
                uialert(fig, '反映するデータがありません', 'エラー');
                return;
            end
            
            statusLabel.Text = '位置の変更を反映中...';
            drawnow;
            
            changed_count = 0;
            error_count = 0;
            
            % 各ブロックの新しい位置を収集
            block_new_positions = containers.Map();
            
            for i = 1:size(table_data, 1)
                block_path = block_paths{i};
                position_str = table_data{i, 9};
                
                % 位置文字列をパース [x,y] -> [x1, y1, x2, y2]
                try
                    % [x,y]形式から座標を抽出
                    position_str = strrep(position_str, '[', '');
                    position_str = strrep(position_str, ']', '');
                    coords = str2double(strsplit(position_str, ','));
                    
                    if length(coords) ~= 2
                        error_count = error_count + 1;
                        continue;
                    end
                    
                    new_x = coords(1);
                    new_y = coords(2);
                    
                    % ブロックごとに位置を集約
                    if ~isKey(block_new_positions, block_path)
                        block_new_positions(block_path) = [];
                    end
                    current_positions = block_new_positions(block_path);
                    block_new_positions(block_path) = [current_positions; new_x, new_y];
                    
                catch
                    error_count = error_count + 1;
                    continue;
                end
            end
            
            % 各ブロックの位置を更新
            keys_list = keys(block_new_positions);
            for i = 1:length(keys_list)
                block_path = keys_list{i};
                new_positions = block_new_positions(block_path);
                
                try
                    % 現在のブロック位置を取得
                    current_pos = get_param(block_path, 'Position');
                    width = current_pos(3) - current_pos(1);
                    height = current_pos(4) - current_pos(2);
                    
                    % ポート位置の平均から新しいブロック位置を計算
                    avg_x = mean(new_positions(:, 1));
                    avg_y = mean(new_positions(:, 2));
                    
                    % ブロックの中心を基準に移動
                    new_block_pos = [avg_x - width/2, avg_y - height/2, ...
                                    avg_x + width/2, avg_y + height/2];
                    
                    % 位置を整数に丸める
                    new_block_pos = round(new_block_pos);
                    
                    % ブロック位置を更新
                    set_param(block_path, 'Position', new_block_pos);
                    changed_count = changed_count + 1;
                    
                catch ME
                    error_count = error_count + 1;
                    fprintf('警告: %s の位置更新に失敗: %s\n', block_path, ME.message);
                end
            end
            
            if changed_count > 0
                statusLabel.Text = sprintf('位置の変更を反映しました（成功: %d ブロック, エラー: %d 件）', ...
                                         changed_count, error_count);
                
                % モデルを更新して変更を反映
                set_param(gcs, 'SimulationCommand', 'update');
                
                % 確認メッセージ
                uialert(fig, sprintf('%d個のブロックの位置を更新しました。\nモデルを確認してください。', ...
                              changed_count), '更新完了', 'Icon', 'success');
                              
                % 情報を再取得して表示を更新
                extractPortInfo();
            else
                statusLabel.Text = '位置の変更はありませんでした';
            end
            
        catch ME
            statusLabel.Text = sprintf('エラー: %s', ME.message);
            uialert(fig, ME.message, '反映エラー');
        end
    end
end