package main

import (
	"./irc"
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
)

type Config struct {
	Listen  string
	Servers map[string]irc.Server
}

var Servers map[string]*irc.Client
var Clients []net.Conn

func main() {
	// Load config
	var conf Config

	confFile, err := ioutil.ReadFile("config.json")
	if err != nil {
		panic(err.Error())
	}
	err = json.Unmarshal(confFile, &conf)
	if err != nil {
		panic(err.Error())
	}

	// Start connections to IRC servers
	Servers = map[string]*irc.Client{}

	for sid, sval := range conf.Servers {
		Servers[sid] = new(irc.Client)
		Servers[sid].ServerInfo = sval
		Servers[sid].Sid = sid
		Servers[sid].ServerName = sval.ServName
		err, messages := Servers[sid].Connect(sval.Address)
		if err != nil {
			panic(err)
		}
		go handleServer(messages)
	}

	// Create server for clients to connect
	listener, err := net.Listen("tcp", conf.Listen)
	if err != nil {
		panic(err)
	}

	// Accept loop for clients
	for {
		c, err := listener.Accept()
		if err != nil {
			fmt.Printf("CAN'T ACCEPT CLIENT : %s\r\n", err.Error())
			continue
		}
		Clients = append(Clients, c)
		go handleClient(c)
	}
}

type GreetServers struct {
	ServerInfo irc.Server
	Channels   map[string]*irc.Channel
}

type Greet struct {
	ClientId string
	Servers  map[string]GreetServers
}

func handleClient(c net.Conn) {
	b := bufio.NewReader(c)
	defer c.Close()

	// Start reading messages
	for {
		bytes, _, err := b.ReadLine()
		if err != nil {
			break
		}
		if len(bytes) > 7 && string(bytes)[0:5] == "GREET" {
			greet(c, string(bytes)[6:])
		}

		if len(bytes) > 7 && string(bytes)[0:7] == "EXECUTE" {
			var cmd irc.ClientMessage
			err := json.Unmarshal(bytes[8:], &cmd)
			if err != nil {
				fmt.Printf("CAN'T PARSE JSON: %s\r\n", err.Error())
				continue
			}
			if sid, ok := Servers[cmd.ServerId]; ok {
				out := irc.Prepare(cmd.Message)
				fmt.Fprintf(sid.Socket, out)
			} else {
				fmt.Printf("UNEXPECTED SERVER ID: %s\r\n", cmd.ServerId)
			}
		}
	}
	removeCon(c)
}

func handleServer(c chan irc.ClientMessage) {
	var message irc.ClientMessage
	for {
		message = <-c
		out, _ := json.Marshal(message)
		broadcast("IRC " + string(out))
	}
}

func removeCon(c net.Conn) {
	for i, con := range Clients {
		if c == con {
			Clients = append(Clients[:i], Clients[i+1:]...)
		}
	}
}

func broadcast(message string) {
	for _, c := range Clients {
		_, err := fmt.Fprintf(c, message+"\r\n")
		if err != nil {
			removeCon(c)
		}
	}
}

func greet(c net.Conn, id string) {
	var greetMessage Greet
	greetMessage.ClientId = id
	greetMessage.Servers = make(map[string]GreetServers)
	for k, v := range Servers {
		greetMessage.Servers[k] = GreetServers{
			ServerInfo: v.ServerInfo,
			Channels:   v.Channels,
		}
	}
	greetJSON, err := json.Marshal(greetMessage)
	if err != nil {
		fmt.Printf("CAN'T GREET: %s\r\n", err.Error())
		return
	}

	fmt.Fprintf(c, "GREET "+string(greetJSON)+"\r\n")
}
