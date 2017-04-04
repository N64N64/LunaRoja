#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <malloc.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <3ds.h>
#include <fcntl.h>

int _listenfd = -1;

static int
ftp_set_socket_nonblocking(int fd)
{
  int rc, flags;

  /* get the socket flags */
  flags = fcntl(fd, F_GETFL, 0);
  if(flags == -1)
  {
    return -1;
  }

  /* add O_NONBLOCK to the socket flags */
  rc = fcntl(fd, F_SETFL, flags | O_NONBLOCK);
  if(rc != 0)
  {
    return -1;
  }

  return 0;
}

int server_getconnection(int port)
{
    if(_listenfd < 0) {
        struct sockaddr_in serv_addr;

        _listenfd = socket(AF_INET, SOCK_STREAM, 0);
        memset(&serv_addr, '0', sizeof(serv_addr));

        serv_addr.sin_family = AF_INET;
#ifdef _3DS
        serv_addr.sin_addr.s_addr = gethostid();
        serv_addr.sin_port        = htons(port);
#else
        serv_addr.sin_addr.s_addr = INADDR_ANY;
        serv_addr.sin_port        = htons(port);
#endif

        bind(_listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
        ftp_set_socket_nonblocking(_listenfd);

        //int yes = 1;
        //setsockopt(_listenfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

        listen(_listenfd, 5);
    }

    int connfd = -1;

    if(_listenfd >= 0) {
      connfd = accept(_listenfd, (struct sockaddr*)NULL, NULL);

      if(connfd >= 0) {
          //closesocket(_listenfd);
          //_listenfd = -1;
          ftp_set_socket_nonblocking(connfd);
      }
    }

    return connfd;
}
