echo Vendoring Go dependencies ... $1
pushd $1
GO111MODULE=on go mod vendor
popd
echo Finished vendoring Go dependencies