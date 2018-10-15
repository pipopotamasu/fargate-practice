# デフォルトは localhost
# 既にAPP_SERVERという環境変数が与えられていればそれを使い、なければlocalhostを使う
[ -z "$APP_SERVER" ] && APP_SERVER=localhost

# nginx.conf の該当設定箇所を文字列置換
sed "s|%APP_SERVER%|$APP_SERVER|g" -i /etc/nginx/conf.d/default.conf

/usr/sbin/nginx -g "daemon off;"