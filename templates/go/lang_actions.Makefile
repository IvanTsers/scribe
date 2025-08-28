lang_actions: $(NAME).go
	gofmt -w $(NAME).go
	go mod init $(NAME).go
	go mod tidy
	go build $(NAME).go
