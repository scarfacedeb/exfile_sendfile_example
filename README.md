# ExfileSendfile

Sample app to demostrate Exfile and Briefly bugs with sendfile.

## Running the tests

Start the application:

```
iex -s mix
```

Make a request in the other shell. To have more consistent results, restart the application after every request.

### Exfile

To test Exfile.Tempfile:

```
curl --limit-rate 500 "localhost:4422/exfile/5000" | tail -c 5
```

### Briefly

To test Briefly package that has similar implementation of temp files to Exfile.Tempfile:

```
curl --limit-rate 500 "localhost:4422/briefly/5000" | tail -c 5
```

### Stripped down implementation

To test stripped down minimal implementation of Temp files

```
curl --limit-rate 500 "localhost:4422/custom/5000" | tail -c 5
```

### Fixed version

To test the fixed version of stripped down implementation:

```
curl --limit-rate 500 "localhost:4422/fixed/5000" | tail -c 5
```

It's the only version that should consistently return the response without any errors.


## Results

### First run

You should get similar results after running any of the tests (except for the fixed one).

Curl will report that it haven't received any body:

```
scarfacedeb@scarfacedeb-macbook-pro-4 exfile_sendfile % curl --limit-rate 500 "localhost:4422/exfile/5000" | tail -c 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0  5000    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
curl: (18) transfer closed with 5000 bytes remaining to read
```

Application logs will report that the random file has been deleted before the connection shutdown:

```
2019-09-12 19:55:47.624 [info] GET /exfile/5000
2019-09-12 19:55:47.649 [info] label=self #PID<0.396.0>
2019-09-12 19:55:47.649 [info] label=connection_pid #PID<0.395.0>
2019-09-12 19:55:47.650 [info] Sent 200 in 25ms
2019-09-12 19:55:47.650 [info] >> End request
2019-09-12 19:55:47.650 [info] label=request {:DOWN, #Reference<0.105115889.1320681474.11443>, :process, #PID<0.396.0>, :normal}
2019-09-12 19:55:47.650 [info] label=File exists? false
2019-09-12 19:55:52.654 [info] label=connection {:DOWN, #Reference<0.105115889.1320681474.11445>, :process, #PID<0.395.0>, {:shutdown, {:connection_error, :timeout, :"No request-line received before timeout."}}}
2019-09-12 19:55:52.654 [info] label=File exists? false
```

You'll also notice that the request process terminated almost immediately, causing the temp file deletion.

### The second run

If you try to run it the second time, the request could succeed and you'll notice the trace message in the iex log:

```
2019-09-12 19:57:45.720 [info] GET /exfile/5000
2019-09-12 19:57:45.721 [info] label=self #PID<0.347.0>
2019-09-12 19:57:45.721 [info] label=connection_pid #PID<0.346.0>
2019-09-12 19:57:45.721 [info] Sent 200 in 884µs
2019-09-12 19:57:45.721 [info] >> End request
2019-09-12 19:57:45.721 [info] label=request {:DOWN, #Reference<0.2965400933.1320943617.2050>, :process, #PID<0.347.0>, :normal}
2019-09-12 19:57:45.721 [info] label=File exists? false
9/12/2019-16:57:45: #PID<0.346.0> >> :erlang.port_control/3  [port: #Port<0.7>, args: [<<48, 0, 0, 0>>, [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 19, 136]]]
2019-09-12 19:57:51.724 [info] label=connection {:DOWN, #Reference<0.2965400933.1320943617.2052>, :process, #PID<0.346.0>, {:shutdown, {:connection_error, :timeout, :"No request-line received before timeout."}}}
2019-09-12 19:57:51.724 [info] label=File exists? false
```

It means that the connection process was able to send SENDFILE command to the TCP socket, before the request process died. And as expected, curl returned the response without any issues.

## Cause of the issue

The reason why Exfile and Briefly sometimes can't return return the response, because `:cowboy_req:reply` sends the sendfile process message to connection process, instead of request.

It means that while the connection process is still running and trying to call `:ranc_tcp.sendfile` with the random file path, request process terminates and it removes the random file at that moment.

## The fixed version

To fix the issue, you should monitor the connection process, instead of the request.

If you try the fixed route, you should always get the full response.

```
iex(1)> 2019-09-12 20:04:01.131 [info] GET /fixed/5000
File created
2019-09-12 20:04:01.155 [info] label=self #PID<0.352.0>
2019-09-12 20:04:01.155 [info] label=connection_pid #PID<0.351.0>
2019-09-12 20:04:01.156 [info] Sent 200 in 25ms
2019-09-12 20:04:01.156 [info] >> End request
2019-09-12 20:04:01.159 [info] label=request {:DOWN, #Reference<0.1169381897.516947973.227240>, :process, #PID<0.352.0>, :normal}
2019-09-12 20:04:01.159 [info] label=File exists? true
9/12/2019-17:4:1: #PID<0.351.0> >> :erlang.port_control/3  [port: #Port<0.19>, args: [<<50, 0, 0, 0>>, [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 19, 136]]]
2019-09-12 20:04:07.160 [info] label=connection {:DOWN, #Reference<0.1169381897.516947973.227242>, :process, #PID<0.351.0>, {:shutdown, {:connection_error, :timeout, :"No request-line received before timeout."}}}
File deleted!
2019-09-12 20:04:07.160 [info] label=File exists? false
```

## Async sendfile

You could also notice that sometimes connection process is terminated before curl has finished downloading the file. 

AFAIK, it's caused by the async nature of the sendfile system call. In short, it means that erlang doesn't stream the file directly, it sends sendfile command to tcp socket instead and finishes with the request.

You can test the socket command with `ExfileSendfile.SocketTest.run_and_exit/0`:

```
iex -s mix
iex(1)> ExfileSendfile.SocketTest.run_and_exit()
ok
iex(2)> 
```

It'll wait for the connection on 4433 port (by default):

```
curl --limit-rate 500 "localhost:4433" | tail -c 5
```

Curl's limited rate allows to witness that it continues to download the data, despite the fact that the elixir OS process is already dead.
