# dcache

delete cache utility with dart language.

* 많은 수의 파일이 폴더에 남으면 운영체제가 느려지고 심각한 경우에 중지가 될 수 있습니다.

* 디캐쉬를 활용하면 감시하는 경로와 하위 경로를 모두 감시하고
지정한 수 보다 파일이 많아지면 오래된 순으로 삭제하는 서비스를 제공받을 수 있습니다.

* 디캐쉬는 파라메터를 지정하여 가볍게 프로세스로 실행할 수 있는 심플한 REST서버입니다.

* 또한 디캐쉬는 감시할 경로를 볼륨으로 마운트하고 도커 컨테이너로 실행할 수 있습니다.

* 그러므로 curl localhost:8088/stop 또는 curl localhost:8088/start와 같은 호출하여
디캐쉬 서비스를 중지하거나 실행할 수가 있습니다.

* 디캐쉬는 다트 언어(dart language)로 작성되었습니다.

* 디캐쉬를 도커 이미지로 만드는 과정에서 네이티브로 빌드를 하기 때문에 네이티브 성능을 기대할 수가 있습니다.

# mechanism

디캐쉬의 동작은 단순하지만 다양한 프로젝트에 응용할 수 있을 것입니다.

**상태의 확인**

* 타이머가 동작을 하는 중이면 active라고 부릅니다. isActive 프로퍼티로 확인을 할 수 있을 것입니다.

* 삭제를 하는 중이면 running이라고 부릅니다. isRunning 프로퍼티로 확인을 할 수 있을 것입니다.

**서비스의 동작**

* 타이머는 REST서버를 통해 /start, /stop, /restart을 호출하여 제어할 수 있습니다. 그러한 요청의 응답으로 active, running 상태를 확인할 수 있습니다.

* 타이머가 1초(운영변수: DCACHE_PERIOD)마다 반복하여 삭제를 요구할 것입니다. 타이머는 비동기적인 활동이므로 삭제하는 동안에도 반복적으로 발생할 것입니다.

* 타이머는 1초마다 반복하지만 아직 삭제를 하는 중이면 삭제를 요구하지 않고 그냥 지나갑니다. 타이머는 초 단위로 설정을 할 수 있습니다.

* REST서버를 통해 /period/5 와 같이 호출하여 타이머에 반복하는 주기를 1초에서 5초로 변경을 할 수 있습니다.

* 서비스가 동작하는 도중에 타이머를 반복하는 주기를 변경하였다면 실제로 변경한 주기를 적용하기 위해서는 /restart를 호출하여 서비스를 다시 시작해야 할 것입니다.

**삭제의 동작**

* 감시할 경로가 복잡하고 파일의 수가 많을 수록 삭제하는 시간이 길어질 것입니다. 그러한 과정은 예상보다 오래 걸릴 수가 있고 CPU점유율을 높일 수가 있습니다.

* 감시하는 경로(운영변수: DCACHE_ROOT)에서 폴더의 목록을 읽습니다. 감시하는 경로를 포함하여 모든 하위 경로에서 이와 같은 동일한 실행을 할 것입니다.

* 폴더에 있을 파일이 지정한 파일수(운영변수: DCACHE_COUNT) 보다 많은 경우에 실제로 삭제를 시작합니다. 폴더 마다 파일의 수를 확인하는 것은 단순할 것 같지만 파일의 수가 많으면 예상보다 CPU점유율을 높일 수가 있습니다.

* 폴더에 있을 전체 파일 목록을 읽고 수정일시(modified time)을 활용해 다시 정렬(sort)한 목록을 만듭니다. 그리고 지정한 파일수(운영변수: DCACHE_COUNT) 이상은 이제 실제로 파일을 삭제할 것입니다.

* 삭제한 파일에 대한 정보를 출력하고, 마지막으로 삭제한 파일수와 삭제를 위해 소요한 전체 시간을 출력(운영변수: DCACHE_PRINT_ALL)합니다. 도커에서 실행을 한 경우에 docker logs -t -f dcache 명령어를 통해 확인을 할 수 있을 것입니다.

* 운영자는 삭제한 파일의 수, 소요한 전체 시간, CPU점유율 등을 고려해서 감시하는 경로에서 적절히 반복할 시간을 정할 수가 있을 것입니다.

# docker

Create a Docker image on your system

$ docker build -t dcache .

Line 30 of bin/server.dart causes the server to exit as soon as it is ready to listen for requests.

$ docker run -d -it -p 8088:8088 --name dcache dcache

Time how long it takes to lauch a server

$ time docker run -it -p 8088:8088 --name dcache dcache

The server using default root changed from invalid DCACHE_ROOT

$ touch dcache.env <br/>
$ vi dcache.env <br/>
DCACHE_PORT=8086 <br/>
DCACHE_COUNT=5 <br/>
DCACHE_PERIOD=5 <br/>
DCACHE_ROOT=/app/dcache/mounted <br/>
DCACHE_PRINT_ALL=true <br/>

$ docker run -d -it -p 8088:8086 --env-file=dcache.env --name dcache dcache

The server using volume mounted DCACHE_ROOT for ~/mounted

$ mkdir ~/mounted

$ docker run -d -it -p 8088:8086 --env-file=dcache.env -v ~/mounted:/app/dcache/mounted --name dcache dcache

Watch logs such as tail

$ docker logs -t -f dcache

Remove the container

$ docker rm -f dcache

Remove the image

$ docker image rm dcache

# docker build on docker-machine

[docker build on docker-machine for macOS](https://github.com/ilshookim/dcache/blob/master/docker-machine.md)
