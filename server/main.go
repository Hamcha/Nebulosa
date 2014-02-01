package main

import (
	"./irc"
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
)

type Server struct {
	ServName string
	Address  string
	Username string
	Nickname string
	Altnick  string
	Realname string
	Channels []string
}

type Config struct {
	Listen  string
	Servers map[string]Server
}

var Servers map[string]*irc.Client
var Clients []net.Conn

func main() {
	var conf Config

	confFile, err := ioutil.ReadFile("config.json")
	if err != nil {
		panic(err.Error())
	}
	err = json.Unmarshal(confFile, &conf)
	if err != nil {
		panic(err.Error())
	}

	Servers = map[string]*irc.Client{}

	for sid, sval := range conf.Servers {
		Servers[sid] = new(irc.Client)
		Servers[sid].Username = sval.Username
		Servers[sid].Nickname = sval.Nickname
		Servers[sid].Altnick = sval.Altnick
		Servers[sid].Realname = sval.Realname
		Servers[sid].Channels = sval.Channels
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
		}
		Clients = append(Clients, c)
		go handleClient(c)
	}
}

func handleClient(c net.Conn) {
	b := bufio.NewReader(c)
	defer c.Close()
	for {
		bytes, _, err := b.ReadLine()
		if err != nil {
			break
		}
		fmt.Printf(string(bytes) + "\r\n")
	}
	removeCon(c)
}

func handleServer(c chan irc.ClientMessage) {
	var message irc.ClientMessage
	for {
		message = <-c
		out, _ := json.Marshal(message)
		broadcast(string(out))
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
