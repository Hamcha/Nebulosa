package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"github.com/Hamcha/go-socket.io"
	"io/ioutil"
	"net"
	"net/http"
	"strings"
)

var sio *socketio.SocketIOServer
var conn net.Conn

var namespaces map[string]*socketio.NameSpace

func onConnect(ns *socketio.NameSpace) {
	namespaces[ns.Id()] = ns
	fmt.Fprintln(conn, "GREET "+ns.Id())
}

func onDisconnect(ns *socketio.NameSpace) {
	delete(namespaces, ns.Id())
}

func main() {
	// Load config
	var conf Config

	confFile, err := ioutil.ReadFile("webui.json")
	if err != nil {
		panic(err.Error())
	}
	err = json.Unmarshal(confFile, &conf)
	if err != nil {
		panic(err.Error())
	}

	// Create namespace map
	namespaces = make(map[string]*socketio.NameSpace)

	// Connect to Nebulosa
	conn, err = net.Dial("tcp", conf.Server)
	if err != nil {
		panic(err)
	}
	fmt.Println("Connected to Nebulosa!")
	go receive(conn)

	// Initialize Socket IO
	sock_config := &socketio.Config{}
	sock_config.HeartbeatTimeout = 2
	sock_config.ClosingTimeout = 4

	sio = socketio.NewSocketIOServer(sock_config)

	// Setup event handlers
	sio.On("connect", onConnect)
	sio.On("disconnect", onDisconnect)

	sio.Handle("/", http.FileServer(http.Dir("./web/"+conf.Theme+"/")))
	http.ListenAndServe(conf.Listen, sio)
}

func receive(c net.Conn) {
	// Setup reader
	b := bufio.NewReader(c)
	defer c.Close()
	for {
		// Read one line and convert it to string (strip \r\n)
		bytes, _, err := b.ReadLine()
		if err != nil {
			panic(err)
		}
		divider := strings.Index(string(bytes), " ")
		msgType := strings.ToUpper(string(bytes[0:divider]))

		if msgType == "GREET" {
			var msgContent Greet
			err = json.Unmarshal(bytes[divider+1:], &msgContent)
			if err != nil {
				fmt.Printf("ERROR reading JSON: %s\r\n", err.Error())
			}
			go greet(msgContent)
		}

		if msgType == "IRC" {
			var msgContent ClientMessage
			err = json.Unmarshal(bytes[divider+1:], &msgContent)
			if err != nil {
				fmt.Printf("ERROR reading JSON: %s\r\n", err.Error())
			}
			// Call handler
			go handle(msgType, msgContent)
		}
	}
}

func handle(msgType string, msgContent ClientMessage) {
	sio.Broadcast(strings.ToLower(msgType), msgContent)
}

func greet(msgContent Greet) {
	// Check if namespace is still available
	if val, ok := namespaces[msgContent.ClientId]; ok {
		val.Emit("greet", msgContent.Servers)
	}
}
