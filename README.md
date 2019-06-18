# ExfileSendfile

Sample app to demostrate Exfile bug with sendfile.

## Run

```
% curl -v localhost:4422/exfile > /dev/null
```

## Results

```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 4422 (#0)
> GET /exfile HTTP/1.1
> Host: localhost:4422
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< cache-control: max-age=0, private, must-revalidate
< content-length: 100000
< date: Tue, 18 Jun 2019 14:22:36 GMT
< server: Cowboy
<
  0   97k    0     0    0     0      0      0 --:--:--  0:00:04 --:--:--     0{ [0 bytes data]
* transfer closed with 100000 bytes remaining to read
* stopped the pause stream!
  0   97k    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* Closing connection 0
curl: (18) transfer closed with 100000 bytes remaining to read
```

Last line indicates that random file has already been deleted and sendfile kernel call can't stream to the client.
