package main

type Config struct {
	Server string
	Listen string
	Theme  string
}
type User struct {
	Nickname string
	Username string
	Host     string
}

type Message struct {
	Source  User
	Command string
	Target  string
	Text    string
}

type ClientMessage struct {
	ServerId string
	Message  Message
	DateTime int64
}

type Channel struct {
	Name  string
	Modes string
	Users []struct {
		User  User
		Modes string
	}
	Topic   string
	TopicBy User
}

type Server struct {
	ServName string
	Address  string
	Username string
	Nickname string
	Altnick  string
	Realname string
	Channels []string
}

type GreetServers struct {
	ServerInfo Server
	Channels   map[string]Channel
}

type Greet struct {
	ClientId string
	Servers  map[string]GreetServers
}
