USERS=(${users})

rm -rf keys
mkdir -p keys/public
mkdir -p keys/private

for i in "$${USERS[@]}"; do
  openssl genrsa -out keys/private/$i.pem 2>/dev/null
  openssl rsa -in keys/private/$i.pem -pubout -out keys/public/$i.pub 2>/dev/null
done
