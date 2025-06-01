see [https://blog.weizlogy.com/pages/tos-addon/#dice](https://blog.weizlogy.com/pages/tos-addon/#dice)

### v1.1.0

#### カスタムレンジ対応

チャットコマンドで /random set <最小> <最大> と打つと、ランダムの範囲を変更できます。

```lua
/random set 1 6  -- ６面ダイス状態
/random set 1 10 -- １０面ダイス状態
/random set      -- デフォルトに戻ります
```

### v1.0.1

#### itos対応

### v1.0.0

#### 新規作成

アドオンがロードされると、チャットコマンドで /random と打つと、
0～999の値をランダムに決定し、一般チャット範囲に結果を送信します。
