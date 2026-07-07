# 設計

PR ごとに Cloud Run 上へ隔離されたプレビュー環境を作り、PR クローズで破棄する
(Terraform + GitHub Actions + Artifact Registry)。使い方は README を参照。

## ライフサイクル

- 作成: PR に preview ラベル付与で deploy(labeled トリガーのみ)。
- 破棄(2 系統・独立):
  - Cloud Run + tfstate … PR クローズ / 手動 / 3 日アイドル日次 GC → tofu destroy。
  - AR イメージ … AR サーバサイド cleanup policy(age ベース、既定 7 日)。
- インバリアント: AR 7 日 > stale sweep 3 日(使用中イメージが先に消えない)。

## トポロジ

プレビューは 1 つの Cloud Run マルチコンテナサービス。
ingress = `frontend`(SPA + `/api/*` → `localhost:8081` プロキシ)、
サイドカー = `backend`(PORT=8081)+ `postgres`(5432)。

IAP Cookie はホストスコープなのでクロスオリジン呼び出し不可 → 同一オリジン必須。
Cloud Run は `PORT` を ingress にのみ注入するため、backend は `PORT=8081` を明示。

## ユースケース

prenv は、複数リポジトリが 1 つの管理用 project を共有して使う前提で構成する。

Terraform は `terraform/modules/preview` を module として公開する。
各 repo の `terraform/env/preview` は
`source = "git::https://github.com/gawakawa/prenv.git//terraform/modules/preview?ref=<REF>"`
でこれを呼び出し、自身のコンテナ構成だけを渡す。

GitHub Actions は deploy/destroy のロジックを `workflow_call` の reusable workflow として
prenv 内に置く。各 repo は `uses:` で参照する薄いトリガー workflow だけを持つ。

onboard 手順は `.claude/skills/setup-prenv` が自動化する。
tofu output から 6 つの値を取得し、GitHub 環境変数の設定、`preview` label の作成、
上記 2 つを呼び出す最小構成のファイル一式の配置までを行う。

## 命名規則

tfstate prefix、イメージ名、Cloud Run サービス名は、共通して owner/repo でリソースを
分離する。N repo が同じ project / bucket / AR を共有しても衝突しない。

- tfstate prefix: `<owner>/<repo>/pr/<N>`
- イメージ名: `<owner>/<repo>/<container>:<content-hash>`
- Cloud Run サービス名: `<owner>-<repo>-pr-<N>`

## アクセス制御

- プレビューは IAP で保護。許可された identity のみアクセス可、公開(allUsers)は無し。
- base はプロジェクトの所有者(インフラ)が管理し、ephemeral は利用者(開発)が管理する。
  運用主体が違うため `terraform/base/` と `terraform/env/preview/` に分ける。
- IAP に必要な IAM は所有者側(base)が付与し、利用者側(ephemeral)には与えない。

## キャッシュ戦略

content-hash タグ = context + Dockerfile の内容ハッシュ。commit から再計算でき追跡可。
image ごとに独立 build し、content-hash タグで既存確認して不要な build を省く。
3 image の build は並列実行(CI オーケストレーション側で制御)。

### アプリ

- 層1 registry buildcache で依存層(go mod download 等)を全 PR 共有の固定タグで再利用。
- 本体 build(go build / next build)はソース変更で毎回再実行。増分キャッシュは
  使い捨てランナーで持ち越せない。

### DB

- runtime initdb.d(初回起動でマイグレーション/シード)はキャッシュ不可。
  現状のシード規模なら軽いが、データ量に比例して初回起動が遅くなる。
- 重くなれば、(a) pre-bake(build 時に datadir 焼き込み、postgres/MySQL 共通)、
  または (b) 共用 Cloud SQL インスタンスにデータを置き各プレビューが接続(per-env のシード不要)。
