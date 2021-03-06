# About DFiles

DFiles is a delete files utility written by dart language - supported sound null-safety.

* Storing a large number of files in a folder can slow down the operating system and, in severe cases, hang.

* If you use DFiles, you can monitor both the monitored path and the sub-path
If there are more files than the specified count, you can get a service that deletes them in the oldest order.

* DFiles is a simple REST server that can be executed lightly as a process by specifying parameters.

* DFiles can also mount the local path to be watched as a volume and run it as a docker container.

* So you can calling something like curl localhost:8088/stop or curl localhost:8088/start,
You can stop or run the dfiles service.

* DFiles is written in the dart language.

* Native performance can be expected because it builds natively in the process of making the dfiles into a docker image.

# Mechanism

DFiles operation is simple, but it can be applied to various projects.

**State Management**

* When the timer is running, it is called active. You can check it with the isActive property.

* If deletion is in progress, it is called running. You can check it with the isRunning property.

**Timer Service**

* The timer can be controlled by calling /start, /stop through the REST server. You can check the active and running status in response to such request.

* If you set the timer to 1 second (operation variable: DFILES_TIMER), it will repeatedly request deletion every 1 second. The timer is an asynchronous activity, so it will fire repeatedly during deletion. If the value is set to 0, the deletion is requested once and not repeated.

* Even if the timer repeats every second, if the deletion is still in progress, it does not request deletion and passes. The timer can be set in seconds.

* You can change the number of files to be deleted from the folder to 7000 by calling /count/7000 through the REST server. The changed result is reflected when the next timer is run.

* You can change the period of files to be deleted from the folder to 30 days by calling /days/30 through the REST server. The changed result is reflected when the next timer is run.

* You can change the time of repeating the timer to 5 seconds by calling like /timer/5 through the REST server.

**Deletion Flow**

* The more complicated the path to be monitored and the larger the number of files, the longer the deletion time will be. Such a process can take longer than expected and can increase CPU usage.

* Read the list of folders from the monitored path (operating variable: DFILES_MONITOR). Basically we will do the same thing like this on all subpaths, including the one we watch.

* If necessary, the list of folders is read from the monitored path, but sub paths can be excluded (operating variable: DFILES_MONITOR_RECURSIVE).

* When the number of files in the folder exceeds the specified count of files (operation variable: DFILES_COUNT), It reads a list of all files in the folder and creates a sorted list using the modified time. And more than the specified count of files (operating variable: DFILES_COUNT) will now actually delete the files. If the value is set to 0, the function to delete files by number of files is not used.

* If the files in the folder are older than the specified days (operation variable: DFILES_DAYS), the files will be deleted. If the value is set to 0, the function to delete files on the specified day is not used.

* It prints information about deleted files, and prints the number of files deleted last and the total time spent for deletion (operation variable: DFILES_PRINT_ALL). If you run it in Docker, you can check it with the docker logs -t -f dfiles command.

* It seems simple to check the number of files in each folder, but if the number of files is large, the CPU usage can be higher than expected. So the operator will be able to determine the time to repeat appropriately in the monitored path, taking into account the number of files deleted, the total time spent, and CPU usage.

# Screenshot

![](https://github.com/ilshookim/dfiles/blob/master/snapshot/dfiles-localhost-snapshot.png)

# Docker

Create a Docker image on your system

$ docker build -t dfiles .

src/server.dart causes the server to exit as soon as it is ready to listen for requests.

$ docker run -d -it -p 8088:8088 --name dfiles dfiles

Time how long it takes to lauch a server

$ time docker run -it -p 8088:8088 --name dfiles dfiles

The server using default root changed from invalid DFILES_MONITOR

$ touch dfiles.env <br/>
$ vi dfiles.env <br/>
DFILES_PORT=8086 <br/>
DFILES_COUNT=5 <br/>
DFILES_DAYS=10 <br/>
DFILES_TIMER=3 <br/>
DFILES_MONITOR=/app/monitor <br/>
DFILES_MONITOR_RECURSIVE=false <br/>
DFILES_PRINT_ALL=true <br/>

$ docker run -d -it -p 8088:8086 --env-file=dfiles.env --name dfiles dfiles

The server using volume mounted DFILES_MONITOR for ~/monitor

$ mkdir ~/monitor

$ docker run -d -it -p 8088:8086 --env-file=dfiles.env -v ~/monitor:/app/monitor --name dfiles dfiles

Watch logs such as tail

$ docker logs -t -f dfiles

Remove the container

$ docker rm -f dfiles

Remove the image

$ docker image rm dfiles

# Docker build on docker-machine

[docker build on docker-machine for macOS](https://github.com/ilshookim/dfiles/blob/master/docker-machine.md)

---

# Korean

디파일은 파일을 삭제하는 유틸리티를 다트 언어(dart langauge)로 작성하였습니다 - null 안정화를 지원.

* 많은 수의 파일이 폴더에 남으면 운영체제가 느려지고 심각한 경우에 중지가 될 수 있습니다.

* 디파일을 활용하면 감시하는 경로와 하위 경로를 모두 감시하고
지정한 수 보다 파일이 많아지면 오래된 순으로 삭제하는 서비스를 제공받을 수 있습니다.

* 디파일은 파라메터를 지정하여 가볍게 프로세스로 실행할 수 있는 심플한 REST서버입니다.

* 또한 디파일은 감시할 경로를 볼륨으로 마운트하고 도커 컨테이너로 실행할 수 있습니다.

* 그러므로 curl localhost:8088/stop 또는 curl localhost:8088/start와 같은 호출하여
디파일 서비스를 중지하거나 실행할 수가 있습니다.

* 디파일은 다트 언어(dart language)로 작성하였습니다.

* 디파일을 도커 이미지로 만드는 과정에서 네이티브로 빌드를 하기 때문에 네이티브 성능을 기대할 수가 있습니다.

# 동작방식

디파일의 동작은 단순하지만 다양한 프로젝트에 응용할 수 있을 것입니다.

**상태의 관리**

* 타이머가 동작을 하는 중이면 active라고 부릅니다. isActive 프로퍼티로 확인을 할 수 있을 것입니다.

* 삭제를 하는 중이면 running이라고 부릅니다. isRunning 프로퍼티로 확인을 할 수 있을 것입니다.

**타이머의 동작**

* 타이머는 REST서버를 통해 /start, /stop을 호출하여 제어할 수 있습니다. 그러한 요청의 응답으로 active, running 상태를 확인할 수 있습니다.

* 타이머를 1초(운영변수: DFILES_TIMER)로 설정하면 1초마다 반복하여 삭제를 요구할 것입니다. 타이머는 비동기적인 활동이므로 삭제하는 동안에도 반복적으로 발생할 것입니다. 값을 0으로 설정하면 삭제를 한번 요구하고 반복하지 않습니다.

* 타이머가 1초마다 반복하더라도 아직 삭제를 하는 중이면 삭제를 요구하지 않고 그냥 지나갑니다. 타이머는 초 단위로 설정을 할 수 있습니다.

* REST서버를 통해 /count/7000 과 같이 호출하여 폴더에서 삭제할 파일의 수를 7000개로 변경할 수 있습니다. 다음 타이머를 실행하였을 때 변경한 결과를 반영합니다.

* REST서버를 통해 /days/30 과 같이 호출하여 폴더에서 삭제할 파일의 기간을 30일로 변경할 수 있습니다. 다음 타이머를 실행하였을 때 변경한 결과를 반영합니다.

* REST서버를 통해 /timer/5 와 같이 호출하여 타이머에 반복하는 시간을 5초로 변경을 할 수 있습니다.

**삭제의 동작**

* 감시할 경로가 복잡하고 파일의 수가 많을 수록 삭제하는 시간이 길어질 것입니다. 그러한 과정은 예상보다 오래 걸릴 수가 있고 CPU점유율을 높일 수가 있습니다.

* 감시하는 경로(운영변수: DFILES_MONITOR)에서 폴더의 목록을 읽습니다. 기본적으로 감시하는 경로를 포함하여 모든 하위 경로에서 이와 같은 동일한 실행을 할 것입니다.

* 필요한 경우에 감시하는 경로에서 폴더의 목록을 읽지만 하위 경로를 제외(운영변수: DFILES_MONITOR_RECURSIVE)할 수 있습니다.

* 폴더에 있을 파일이 지정한 파일수(운영변수: DFILES_COUNT) 보다 많은 경우에 전체 파일 목록을 읽고 수정일시(modified time)을 활용해 다시 정렬(sort)한 목록을 만듭니다. 그리고 지정한 파일수(운영변수: DFILES_COUNT) 이상은 이제 실제로 파일을 삭제할 것입니다. 값을 0으로 지정한 경우 파일수로 파일을 삭제하는 기능을 사용하지 않습니다.

* 폴더에 있을 파일이 지정한 날(운영변수: DFILES_DAYS) 보다 오래된 경우에 실제로 파일을 삭제할 것입니다. 값을 0으로 지정한 경우 지정한 날로 파일을 삭제하는 기능을 사용하지 않습니다.

* 삭제한 파일에 대한 정보를 출력하고, 마지막으로 삭제한 파일수와 삭제를 위해 소요한 전체 시간을 출력(운영변수: DFILES_PRINT_ALL)합니다. 도커에서 실행을 한 경우에 docker logs -t -f dfiles 명령어를 통해 확인을 할 수 있을 것입니다.

* 폴더 마다 파일의 수를 확인하는 것은 단순할 것 같지만 파일의 수가 많으면 예상보다 CPU점유율을 높일 수가 있습니다. 그러므로 운영자는 삭제한 파일의 수, 소요한 전체 시간, CPU점유율 등을 고려해서 감시하는 경로에서 적절히 반복할 시간을 정해야 할 것입니다.
