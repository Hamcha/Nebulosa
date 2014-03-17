package irc

import (
	"bufio"
	"fmt"
	"net"
	"strings"
	"time"
)

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

type Client struct {
	Socket     net.Conn
	Proxyaddr  string
	Serveraddr string
	Channels   map[string]Channel
	ServerName string
	ServerInfo Server
	Sid        string
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

type Server struct {
	ServName string
	Address  string
	Username string
	Nickname string
	Altnick  string
	Realname string
	Channels []string
}

func (c *Client) Connect(server string) (error, chan ClientMessage) {
	fmt.Printf("[%s] Trying to connect to %s (%s)..\r\n", c.Sid, c.ServerName, server)
	// Connect to server
	conn, err := net.Dial("tcp", server)
	if err != nil {
		return err, nil
	}
	// Send USER/NICK command to auth
	fmt.Fprintf(conn, "USER %s 8 * :%s\r\n", c.ServerInfo.Username, c.ServerInfo.Realname)
	fmt.Fprintf(conn, "NICK %s\r\n", c.ServerInfo.Nickname)
	// Setup socket attribute and other variables
	c.Socket = conn
	c.Serveraddr = server
	c.Channels = make(map[string]Channel)
	// Start receiving loop
	messages := make(chan ClientMessage)
	go receive(c, messages)
	return nil, messages
}

func receive(client *Client, messages chan ClientMessage) {
	// Setup reader
	b := bufio.NewReader(client.Socket)
	defer client.Socket.Close()
	for {
		// Read one line and convert it to string (strip \r\n)
		bytes, _, err := b.ReadLine()
		if err != nil {
			panic(err)
		}
		line := string(bytes)
		// Check for : (irc string)
		cmdtxt := strings.Index(line[1:], ":")
		var parts []string
		var text string
		// Split all command parts (retaining whole string if any)
		if cmdtxt >= 0 {
			parts = append(strings.Split(line[:cmdtxt], " "))
			text = line[(cmdtxt + 2):]
		} else {
			parts = strings.Split(line, " ")
			text = ""
		}
		// Call handler
		go handle(client, parts, text, messages)
	}
}

func handle(c *Client, parts []string, text string, messages chan ClientMessage) {
	// If PING autorespond PONG and quit
	if parts[0] == "PING" {
		fmt.Fprintf(c.Socket, "PONG %s\r\n", text)
		return
	}
	// Create message var
	var msg Message
	msg.Source = parseUser(parts[0])

	if len(parts) > 1 {
		msg.Command = parts[1]
	}
	if len(parts) > 2 {
		msg.Target = parts[2]
	}

	msg.Text = text

	// If 376 (End of MOTD) then join all the channels
	if msg.Command == "376" {
		fmt.Printf("[%s] Connected! joining channels.. \r\n", c.Sid)
		for _, name := range c.ServerInfo.Channels {
			fmt.Fprintf(c.Socket, "JOIN %s\r\n", name)
		}
	}

	// Have we joined somewhere?
	if msg.Command == "JOIN" && msg.Source.Nickname == c.ServerInfo.Nickname {
		fmt.Fprintf(c.Socket, "NAMES %s\r\n", msg.Target)
		c.Channels[msg.Target] = Channel{Name: msg.Target}
	}

	// Pass it to the clients
	messages <- ClientMessage{ServerId: c.Sid, Message: msg, DateTime: time.Now().Unix()}
}

func parseUser(s string) User {
	// Format : Nickname!Username@Host
	idiv := strings.Index(s, "!")
	adiv := strings.Index(s, "@")
	if (idiv < 0) || (adiv < 0) {
		return User{Nickname: s}
	}
	nick := s[1:idiv]
	user := s[(idiv + 1):adiv]
	host := s[(adiv + 1):]
	return User{Nickname: nick, Username: user, Host: host}
}

func Prepare(msg Message) string {
	// Create one irc full message from struct
	out := msg.Command
	if msg.Target != "" {
		out += " " + msg.Target
	}
	if msg.Text != "" {
		out += " :" + msg.Text
	}
	return out + "\r\n"
}
