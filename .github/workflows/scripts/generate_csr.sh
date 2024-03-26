
# generate CA cerficate
openssl genrsa -out fortio.com.key 2048
openssl req -new -x509 -days 365 -key fortio.com.key -subj "/C=CN/ST=GD/L=SZ/O=fortio.com, Inc./CN=fortio.com Root CA" -out fortio.com.crt

# generate CSR
openssl req -newkey rsa:2048 -nodes -keyout httpbin.fortio.com.key -subj "/C=CN/ST=GD/L=SZ/O=fortio.com, Inc./CN=*.fortio.com" -out httpbin.fortio.com.csr
openssl x509 -req -extfile <(printf "subjectAltName=IP:10.239.241.168,DNS:fortio.com,DNS:www.fortio.com") -days 365 -in httpbin.fortio.com.csr -CA fortio.com.crt -CAkey fortio.com.key -CAcreateserial -out httpbin.fortio.com.crt

# upload key and crt as a secret
kubectl create -n istio-system secret tls httpbin-fortio-credential --key=httpbin.fortio.com.key --cert=httpbin.fortio.com.crt