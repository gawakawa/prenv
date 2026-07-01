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

## アクセス制御

- プレビューは IAP で保護。許可された identity のみアクセス可、公開(allUsers)は無し。
- CI は WIF で deploy SA を impersonate。単一 repo 限定・最小権限。

## キャッシュ戦略

共通: イメージ名 `<AR_REPO>/<owner>/<repo>/{backend,db,frontend}:<content-hash>`
(AR は複数 repo 共有のため owner/repo をパス分離し混在・誤再利用を防ぐ)。
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
