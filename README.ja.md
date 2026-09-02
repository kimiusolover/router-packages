# router-packages

[English README](README.md)

ファームウェア構築で使うパッケージレシピと、パッケージ単位の設定を管理します。上流ソースの固定とパッチ方針は `router-upstream`、機種設定は `router-platform`、イメージ組立は `router-firmware` の責務です。

ビルドは、クリーンな `router-upstream` と、`status: locked`・不変リビジョン・取得根拠・SHA-256 が揃ったローカルキャッシュだけを使います。ネットワークから取得したり、ミラーや移動する参照へ置き換えたりしません。

詳細は [POLICY.ja.md](POLICY.ja.md) を参照してください。

## AX23V 向けビルド入口

AX23V 向けには汎用の `build-%` を使わず、`build-ax23v-<package>` を使います。この
入口は `router-upstream/cross/verify-ax23v-build` を必ず実行し、AX23V 専用 target record、
MIPS toolchain record、kernel/source/ABI の locked 条件を通過した場合だけレシピを起動します。
現時点では AX23V target と toolchain が `pending-verification` のため、入口は安全に拒否します。
image、flash、RF 送信はこの入口の責務外であり、許可しません。
