# router-packages

[English README](README.md)

ファームウェア構築で使うパッケージレシピと、パッケージ単位の設定を管理します。上流ソースの固定とパッチ方針は `router-upstream`、機種設定は `router-platform`、イメージ組立は `router-firmware` の責務です。

ビルドは、クリーンな `router-upstream` と、`status: locked`・不変リビジョン・取得根拠・SHA-256 が揃ったローカルキャッシュだけを使います。ネットワークから取得したり、ミラーや移動する参照へ置き換えたりしません。

詳細は [POLICY.ja.md](POLICY.ja.md) を参照してください。
