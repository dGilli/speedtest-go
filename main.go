package main

import (
	"fmt"
	"time"

	"github.com/showwin/speedtest-go/speedtest"
)

func main() {
	var speedtestClient = speedtest.New()

	serverList, _ := speedtestClient.FetchServers()
	targets, _ := serverList.FindServer([]int{})

	for _, s := range targets {
		s.PingTest(nil)
		s.DownloadTest()
		s.UploadTest()
        fmt.Printf("Latency: %s, Download: %s, Upload: %s, Timestamp: %s\n", s.Latency, s.DLSpeed, s.ULSpeed, time.Now().String())
		s.Context.Reset()
	}
}
