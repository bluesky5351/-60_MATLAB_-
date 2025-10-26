% SimulinkモデルにInportブロックを配置するスクリプト
% CSVファイルから名前を読み込み、縦方向に配置

% CSVファイルから名前を読み込み
% CSVファイル形式: 1列目に名前が記載されている
% 例: inport_names.csv
%     Input1
%     Input2
%     Input3
%     ...

csvFileName = 'inport_names.csv';

% CSVファイルの存在確認
if ~isfile(csvFileName)
    % CSVファイルが存在しない場合、サンプルファイルを作成
    fprintf('CSVファイルが見つかりません。サンプルファイルを作成します。\n');
    sampleNames = {'Input1'; 'Input2'; 'Input3'; 'Input4'; 'Input5'; ...
                   'Input6'; 'Input7'; 'Input8'; 'Input9'; 'Input10'};
    writecell(sampleNames, csvFileName);
    fprintf('サンプルファイル "%s" を作成しました。\n', csvFileName);
end

% CSVファイルを読み込み
portNames = readcell(csvFileName);

% セル配列を文字列配列に変換（必要に応じて）
if iscell(portNames)
    portNames = cellstr(portNames);
end

% ブロック数
numBlocks = length(portNames);

% 新しいSimulinkモデルを作成
modelName = 'InportModel';
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

% Inportブロックの配置パラメータ
startX = 100;        % 開始X座標
startY = 50;         % 開始Y座標
blockWidth = 30;     % ブロックの幅
blockHeight = 15;    % ブロックの高さ
verticalSpacing = 50; % 縦方向の間隔

% Inportブロックを縦方向に配置
for i = 1:numBlocks
    % Y座標を計算（縦方向に連番で配置）
    yPos = startY + (i - 1) * verticalSpacing;
    
    % ブロックの位置 [left top right bottom]
    position = [startX, yPos, startX + blockWidth, yPos + blockHeight];
    
    % Inportブロックのパス
    inportPath = [modelName '/' char(portNames{i})];
    
    % Inportブロックを追加
    add_block('simulink/Sources/In1', inportPath, ...
        'Position', position, ...
        'BackgroundColor', 'cyan', ...
        'Port', num2str(i));
    
    fprintf('ブロック %d: %s を配置しました (Y座標: %d)\n', i, char(portNames{i}), yPos);
end