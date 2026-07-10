# pro-catalog

shizai pro の Component Catalog。静的 HTML + Tailwind CSS v4 browser CDN（`@tailwindcss/browser@4`）。
公開: https://skrt.github.io/pro-catalog/ （GitHub Pages。**push しないと反映されない**。反映は1〜2分）

## 構成

- `components.json` — 唯一のデータソース。index.html が実行時に読んで描画（ビルド工程なし）
- `previews/*.html` — Variants 本体と（demo があるものは）`#demo-section`
- spec のレンダラー対応キー: `states` / `behavior` / `keyboard`

## ルール

- コンポーネント挙動仕様はここ（components.json の spec / tokens）が正。
  shizai-pro の screens.yml には画面固有の仕様のみ書く（lube 方式）
- バリデーション文言は Validator ページ（previews/validator.html）が正。トーンは「〜しましょう」
- ボタンラベルは名詞形（「保存」「発注」）。「〜する」は付けない
- コンポーネント追加時: preview + components.json エントリ（usage 必須。demo は `#demo-section` + `hasDemo: true` をペアで）+
  shizai-pro/CLAUDE.md のコンポーネント一覧更新をセットで行う
- `@theme` トークンは shizai-pro の `app/assets/tailwind/application.css` と同一に保つ

## コマンド

- `bash scripts/check-demo-sync.sh` — demo と States の同期チェック（preview 編集後に実行）
- 反映確認: `curl -s "https://skrt.github.io/pro-catalog/<path>?cb=$(date +%s)" | grep <変更内容>`

## 落とし穴

- CDN 環境ではコンパイル済みユーティリティが plain `<style>` より先に注入される。
  移植プラグイン CSS（form-checkbox 等）のデフォルト値がユーティリティに勝つため、
  トークン値は specificity を上げて確定させる（previews/table.html の実例参照）
- shizai-pro セッションも絶対パスでこのリポジトリを編集する。
  同時作業の気配（直近の mtime・コミット）があれば shizai-pro/.planning/sessions.md を確認
