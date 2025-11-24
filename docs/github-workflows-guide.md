# GitHub Workflows 入門ガイド

## GitHub Workflowsとは

GitHub Workflowsは、GitHub Actionsの中核となる自動化の仕組みです。コードのビルド、テスト、デプロイなどを自動的に実行できます。

## 基本的な仕組み

### ワークフローの構成要素

1. **イベント（Events）**: ワークフローをトリガーする契機
   - `push`: コードがプッシュされた時
   - `pull_request`: プルリクエストが作成・更新された時
   - `schedule`: 定期実行（cron形式）
   - `workflow_dispatch`: 手動実行

2. **ジョブ（Jobs）**: 実行される一連のステップ
   - 並列または順次実行が可能
   - 異なる環境（OS）で実行可能

3. **ステップ（Steps）**: ジョブ内の個別タスク
   - アクションの実行
   - シェルコマンドの実行

4. **ランナー（Runners）**: ワークフローを実行する仮想環境
   - GitHub提供のホスティッドランナー
   - セルフホストランナー

## 実装例

### 例1: 基本的なCI/CDワークフロー

```yaml
name: CI/CD Pipeline

# イベントトリガー
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

# 実行するジョブ
jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    # リポジトリをチェックアウト
    - name: コードをチェックアウト
      uses: actions/checkout@v4

    # Node.js環境をセットアップ
    - name: Node.jsをセットアップ
      uses: actions/setup-node@v4
      with:
        node-version: '18'

    # 依存関係をインストール
    - name: 依存関係をインストール
      run: npm ci

    # テストを実行
    - name: テストを実行
      run: npm test

    # ビルドを実行
    - name: ビルド
      run: npm run build
```

### 例2: 複数のジョブを持つワークフロー

```yaml
name: Multi-Job Workflow

on:
  push:
    branches: [ main ]

jobs:
  # 最初のジョブ: リント
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: リント実行
      run: |
        npm ci
        npm run lint

  # 2番目のジョブ: テスト（lintが成功したら実行）
  test:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16, 18, 20]

    steps:
    - uses: actions/checkout@v4
    - name: Node.js ${{ matrix.node-version }} をセットアップ
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}

    - name: テスト実行
      run: |
        npm ci
        npm test

  # 3番目のジョブ: デプロイ（testが成功したら実行）
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v4
    - name: デプロイ
      run: |
        echo "本番環境にデプロイ中..."
        # デプロイスクリプトをここに追加
```

### 例3: スケジュール実行とキャッシュの活用

```yaml
name: Scheduled Tasks

on:
  # 毎日午前2時（UTC）に実行
  schedule:
    - cron: '0 2 * * *'
  # 手動実行も可能
  workflow_dispatch:

jobs:
  cleanup:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    # 依存関係をキャッシュ
    - name: 依存関係キャッシュ
      uses: actions/cache@v3
      with:
        path: ~/.npm
        key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
        restore-keys: |
          ${{ runner.os }}-node-

    - name: クリーンアップタスク実行
      run: |
        npm ci
        npm run cleanup
```

### 例4: シークレットの使用

```yaml
name: Deploy with Secrets

on:
  push:
    branches: [ production ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    # 環境変数にシークレットを設定
    - name: デプロイ
      env:
        API_KEY: ${{ secrets.API_KEY }}
        DATABASE_URL: ${{ secrets.DATABASE_URL }}
      run: |
        echo "シークレットを使用してデプロイ中..."
        npm run deploy
```

## ワークフローファイルの配置

ワークフローファイルは以下の場所に配置します：

```
.github/
  workflows/
    ci.yml
    deploy.yml
    scheduled-tasks.yml
```

## よく使われるユースケース

### 1. 継続的インテグレーション（CI）
- コードのリント
- 単体テストの実行
- ビルドの確認

### 2. 継続的デプロイメント（CD）
- ステージング環境へのデプロイ
- 本番環境へのデプロイ
- コンテナイメージのビルドとプッシュ

### 3. 自動化タスク
- 定期的なデータバックアップ
- 依存関係の更新チェック
- レポートの自動生成

### 4. コード品質管理
- コードカバレッジの計測
- セキュリティスキャン
- パフォーマンステスト

## ベストプラクティス

1. **ジョブを小さく保つ**: 各ジョブは単一の責務を持つようにする
2. **キャッシュを活用**: 依存関係のインストール時間を短縮
3. **並列実行**: 可能な限りジョブを並列実行して時間を節約
4. **条件付き実行**: 必要な場合のみジョブを実行（`if`条件の活用）
5. **シークレットの管理**: 機密情報はGitHub Secretsに保存
6. **マトリックス戦略**: 複数の環境でテストする場合に活用

## まとめ

GitHub Workflowsは、以下のような強力な機能を提供します：

- ✅ 自動化されたビルド・テスト・デプロイ
- ✅ 柔軟なトリガー設定
- ✅ 並列実行による高速化
- ✅ 豊富なアクションエコシステム
- ✅ 簡単な設定（YAMLファイル）

これらの機能を活用することで、開発プロセスを大幅に効率化できます。
