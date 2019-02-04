# kibela2esa

## 概要
kibelaからexportされたファイル、記事をesaへインポートするスクリプトになります。

## 使いかた
### 1. API tokenの取得
esaに対してwrite権限があるAPI tokenを発行し、環境変数 `ESA_TOKEN` へ格納してください。

![create token with write scope](https://user-images.githubusercontent.com/4487291/52120119-ae9fcb80-265e-11e9-8557-fe63afa6a08a.png)

### 2. 環境変数の定義
`.env.sample` を参考に、 `ESA_TEAM` と `KIBELA_TEAM` を設定してください。
(dotenvを読むようにはなっていないことに注意してください。)

### 3. kibela -> esa におけるユーザー名のmappingを行なうHashの定義

```ruby
KIBELA_ESA_USER_MAP = {
  'kibela_user_name1' => 'esa_user_name1',
  'kibela_user_name2' => 'esa_user_name2',
  # ...
}
```

### 4. dry runで実行し、移行が問題ないか確認する
```shell
$ bundle exec ruby script.rb
```

上記コマンドを実行すると、migraterがnewされた時点でpry consoleに入ります。

この時点で、 `migrater.migrate` を実行すると、API callするparamsをlogに表示して終了します。このlogを見て、移行が正しく行なわれそうかを確認するようにしてください。

### 5. migrateを実行する
`migrater.migrate(dry_run: false)` により、実際にAPI callを行ない移行を開始します。

移行対象のオブジェクトが多い場合にはAPIの利用制限がかかることがあります。`sleep` の値を調整したり、サポートに連絡を行うなどで対応してください。

