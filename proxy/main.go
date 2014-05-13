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

const BUFFER_SIZE = 50

var buffer map[string][]ClientMessage

var allowBufferCmd = []string{"PRIVMSG", "NOTICE", "JOIN", "PART", "QUIT", "NICK", "TOPIC"}

func onConnect(ns *socketio.NameSpace) {
	// Request greeting
	namespaces[ns.Id()] = ns
	fmt.Fprintln(conn, "GREET "+ns.Id())
}

func onDisconnect(ns *socketio.NameSpace) {
	delete(namespaces, ns.Id())
}

func onCommand(ns *socketio.NameSpace, server, command, target, text string) {
	msg := Message{
		Command: command,
		Target:  target,
		Text:    text,
	}
	cmsg := ClientMessage{
		ServerId: server,
		Message:  msg,
	}
	val, err := json.Marshal(cmsg)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	fmt.Fprintln(conn, "EXECUTE "+string(val))
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

	// Create buffer map
	buffer = make(map[string][]ClientMessage)

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
	sio.On("command", onCommand)

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
	// Do we need to save it into the buffer?
	if isin(msgContent.Message.Command, allowBufferCmd) {
		// Get buffer id
		target := msgContent.ServerId + "." + msgContent.Message.Target
		// Create buffer if it doesn't exist
		if _, ok := buffer[target]; !ok {
			buffer[target] = make([]ClientMessage, 0, BUFFER_SIZE)
		}
		// Put message into buffer
		buffer[target] = append(buffer[target], msgContent)
	}

	// Broadcast to connected clients
	sio.Broadcast(strings.ToLower(msgType), msgContent)
}

func greet(msgContent Greet) {
	// Check if namespace is still available
	if val, ok := namespaces[msgContent.ClientId]; ok {
		// Send greeting
		val.Emit("greet", msgContent.Servers)
		// Send buffers
		for _, v := range buffer {
			val.Emit("buffer", v)
		}
	}
}

func isin(a string, list []string) bool {
	for _, b := range list {
		if b == a {
			return true
		}
	}
	return false
}
