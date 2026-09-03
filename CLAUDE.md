# pro-catalog

shizai pro の Component Catalog。静的 HTML + Tailwind CSS v4 browser CDN（`@tailwindcss/browser@4`）。
公開: https://skrt.github.io/pro-catalog/ （GitHub Pages。**push しないと反映されない**。反映は1〜2分）

## 構成

**カタログの構造仕様（7セクションの固定順・点灯条件・配置判断マップ・preview / spec の記述規約・不変則・追加手順・top-script）の正は共通スキル `~/.claude/skills/catalog-structure/SKILL.md`**（2026-09-03 に lube-catalog と共通化・claude-base へ昇格）。preview / components.json を追加・編集する前に読む。構造を変える時はそちらを編集し、ビューアの変更は lube-catalog の index.html にも入れる（同型実装）。ここには pro 固有の差分だけ残す:

- `components.json` — 唯一のデータソース。index.html が実行時に読んで描画（ビルド工程なし）
- `previews/*.html` — Variants 本体と、demo があるものは `#demo-section`（`hasDemo: true`）、利用パターンがあるものは `#examples-section`（`hasExamples: true`・2026-09-03 に badge / modal / approval-tracker で採用。旧「Usage Patterns」小見出しを Variants から分離）
- `category` は6種: `actions / data-display / feedback / forms / layout / design-tokens`（lube は navigation ありの7種）
- フラグ（`hasDemo` / `hasExamples`）は true のものだけ持つ運用（false を明示していない）。旧スキーマの `notes` キーは 2026-09-03 に削除済み＝復活させない（内容は usage.vs / description / preview に置く）
- `llms.txt` — AI エージェント向けインデックス（役割・読み方・誤解しやすい規約）。公開 URL: https://skrt.github.io/pro-catalog/llms.txt 。**規約・トークン・spec キーを変えたらここも更新する**（lube-catalog と対称・2026-09-03 移植）
- spec のレンダラー対応キー: `states` / `behavior` / `keyboard`
- **`tokens` の category は部位軸（`Table / Header`・`Message / Send`・`Upper Area` 等）を含む**＝lube の「役割軸で分ける」規約とは違う。共通スキルの記述規約でも昇格対象外にしてある（2026-09-03 クロスレビュー #22）

## ルール

- コンポーネント挙動仕様はここ（components.json の spec / tokens）が正。
  shizai-pro の screens.yml には画面固有の仕様のみ書く（lube 方式）
- バリデーション文言は Validator ページ（previews/validator.html）が正。トーンは「〜しましょう」
- ボタンラベルは名詞形（「保存」「発注」）。「〜する」は付けない
- コンポーネント追加時: 共通スキル `catalog-structure` の手順 0〜3 に従う（usage 必須。demo は `#demo-section` + `hasDemo: true`、利用例は `#examples-section` + `hasExamples: true` をペアで）+
  shizai-pro/CLAUDE.md のコンポーネント一覧更新をセットで行う
- `@theme` トークンは shizai-pro の `app/assets/tailwind/application.css` と同一に保つ
- usage/spec の Do/Can't の情報源: shizai-pro の CLAUDE.md・figma/CLAUDE.md（コンポーネント別ルール）・figma/.claude/skills/。
  使用実態は shizai-pro ビューの参照コメント（`Catalog: xxx.html — md/tertiary` 形式）を grep 集計して確認する
  （コメント漏れがあるのでマークアップ直接の grep も併用）
- demo（hasDemo）は Alpine.js 3 CDN 製、Rails 実装は Stimulus。コンポーネント挙動を変えるときは両方に反映する
- spec は実装より先行してよい（カタログが正）。未実装の仕様を書いたら実装タスクをセットで起こす
- props の default は Figma の variant 順で推奨値ではない。推奨サイズ・色は usage の表に書く

## コマンド

- `bash scripts/check-demo-sync.sh` — demo と States の同期チェック（preview 編集後に実行）
- `jq empty components.json` — components.json 編集後の構文チェック
- 反映確認: `curl -s "https://skrt.github.io/pro-catalog/<path>?cb=$(date +%s)" | grep <変更内容>`

## Alpine デモ実装の定石（クロスレビュー #20・lube から移植 2026-09-03）

demo（`hasDemo`）は Alpine.js 3 CDN 製。lube 側で事故になった罠のうち、フレームワークに依存せず pro-catalog でも踏むものだけを持ち込んでいる。

- **色・枠線を `:class` だけに持たせない＝初期描画の FOUC になる**。Alpine は `defer` で読み込むため、ブート前は `:class` が未評価＝枠線なしの状態が一瞬見える。対策はこのリポの定石に寄せる: **デモの x-data 要素に `x-cloak` を付け、`<style>[x-cloak] { display: none !important; }</style>` を Alpine の script 直後に置く**（checkbox / radio-group / modal / drawer / colors が元からこの形。2026-09-03 に select / combobox / number-input / input / text-area / datepicker も揃えた）
  - 静的 class と `:class` に同じ色ユーティリティを共存させる回避は**しない**（同詳細度＝CSS 定義順依存で不確実）
- **ページ読込時の初期化処理で `el.focus()` しない**（スクリプト起点のフォーカスは `:focus-visible` 扱いになり ring が出る）。クリック起点のフォーカス移動なら出ないので、`@click` 内の `$refs.x.focus()` は問題ない
- **`x-for` の中に `x-data` を持つ要素（カード等）を並べる時は `:key` にインデックスを使わない**（削除時にネストしたコンポーネントの状態が隣の要素へズレる）。行データに固有 id を振って `:key="item.id"` にする。ループ内に `x-data` が無い場合は `:key="i"` でよい（checkbox / datepicker が該当）

## 落とし穴

- CDN 環境ではコンパイル済みユーティリティが plain `<style>` より先に注入される。
  移植プラグイン CSS（form-checkbox 等）のデフォルト値がユーティリティに勝つため、
  トークン値は specificity を上げて確定させる（previews/table.html の実例参照）
- shizai-pro セッションも絶対パスでこのリポジトリを編集する。
  同時作業の気配（直近の mtime・コミット）があれば shizai-pro/.planning/sessions.md を確認
