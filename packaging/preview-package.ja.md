# 固定内製ソースからのpreviewパッケージ

`build-preview-package` はクリーンな `router-packages` のHEADをgit archiveで固定し、
`router-prefix` のレシピを一時領域で実行する。外部ソースに偽装したlockは作らない。
出力は未署名 `.pkg.tar.zst`、同じコミットのソースアーカイブ、`candidate.json`。
出力先は新規ディレクトリに限り、作業中ソースと既存成果物を上書きしない。

```sh
python3 packaging/build-preview-package \
  --source /path/to/clean/router-packages \
  --upstream /path/to/clean/router-upstream \
  --cache /path/to/verified-cache \
  --output /path/to/new-unsigned-candidate
```

x86-64-musl toolchain recordと実際に展開するarchiveのSHA-256を検証し、
隔離展開したコンパイラ・sysrootでビルドする。STAGING_DIRも同じsysrootへ固定し、
OpenWrtコンパイラによるホストの/usr/lib・/usr/includeへの追加探索を防ぐ。入力がなければ拒否し、取得しない。
既存 `router-upstream/cross/verify-toolchain` の検証関数を再利用する。
Python 3のtarfileがロック済みarchiveの圧縮形式に対応している必要がある。

開発ホストでパッケージ・署名経路だけを試す場合は、明示的に以下を使う。

```sh
python3 packaging/build-preview-package \
  --source /path/to/clean/router-packages \
  --development-host --output /path/to/new-development-candidate
```

このモードは `x86_64-glibc-development` と記録し、ホストツールチェーンが
未ロックであることを保持する。muslや実機用のビルド成功とは扱わない。
環境変数からコンパイラ・フラグを引き継がず、レシピには選定したCCを渡す。
ソースのコミット時刻をtar時刻に使用し、同じ入力のローカル再ビルドを照合できる。
完全なビルド環境固定や独立ビルダーによる再現性証明は別途必要。

`bash`、`coreutils`、`gawk`、`sed`、`systemd`、対応libcの依存をPKGINFOに記録する。musl版にはlibgccも記録する。
対応依存パッケージの生成とライセンス確定は未完のため、公開・導入許可は出さない。
本スクリプトはパッケージレシピをホスト上で実行するため、レビュー済みcheckoutのみを
使用する。一時領域と環境変数の分離はOSのセキュリティサンドボックスではない。

署名・DB生成は `router-infra/package-repository/repository.py` で別工程として実行する。

ローカル試験: `python3 packaging/test-preview-package`。
使い捨てGitリポジトリに実際の内製ソースを固定して2回ビルドし、成果物一致、
ULA生成、dirty checkout・既存出力の拒否を検証する。元リポジトリをコミットしない。
