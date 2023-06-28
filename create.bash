docker build . --tag fd2-spike

docker create --name fd2-spike --mount type=bind,source=.,target=/home/student/FarmData2-V2-Spike --publish 5901:5901 --publish 6901:6901 fd2-spike